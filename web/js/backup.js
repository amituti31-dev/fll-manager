// ═══════════════════════════════════════════════════════
// § 32 · FULL BACKUP & RESTORE (mentors)
// ═══════════════════════════════════════════════════════
// A backup is the team's Firestore documents verbatim (not a hand-picked list of
// state fields), so nothing is forgotten — including fields added later. Same
// format as Android's backup (FirebaseService.exportRawBackup):
//   { format: 'fll-manager-backup', version: 1, createdAt, teamId, teamName,
//     docs: { <docId>: {...} }, photos: { gallery: [...], improvements: [...] } }
// Firestore Timestamps are encoded as { __ts: <millis> }.
const BACKUP_FORMAT = 'fll-manager-backup';
const BACKUP_REMIND_DAYS = 14;
let _pendingRestore = null;

// Every document the apps write under /{teamId}/ (registry docs live elsewhere),
// plus one archive_<season> doc per archived season (see createNewSeason()).
// 'ai-config' (the Gemini key) is deliberately NOT backed up — a backup file
// sitting on someone's computer shouldn't contain a secret.
function _backupDocIds() {
  const ids = ['settings', 'data', 'admin-data', 'archives', 'gallery', 'improvements',
               'links', 'strategy', 'chats', 'judging_pdf'];
  (state.seasons || []).forEach(s => { if (s.name) ids.push('archive_' + String(s.name).replace(/\s+/g, '-')); });
  return [...new Set(ids)];
}

function _encFs(v) {
  if (v && typeof v.toMillis === 'function') return { __ts: v.toMillis() };
  if (Array.isArray(v)) return v.map(_encFs);
  if (v && typeof v === 'object') { const o = {}; for (const k in v) o[k] = _encFs(v[k]); return o; }
  return v;
}
function _decFs(v) {
  if (v && typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length === 1 && typeof v.__ts === 'number') {
    return firebase.firestore.Timestamp.fromMillis(v.__ts);
  }
  if (Array.isArray(v)) return v.map(_decFs);
  if (v && typeof v === 'object') { const o = {}; for (const k in v) o[k] = _decFs(v[k]); return o; }
  return v;
}

async function createFullBackup() {
  if (!state.isAdmin) { notify('גיבוי זמין למנטורים בלבד', 'error'); return; }
  if (!window.db || !window.FB_PROJECT) { notify('אין חיבור לענן', 'error'); return; }
  notify('⏳ מכין גיבוי...', 'info');
  try {
    const team = window.db.collection(window.FB_PROJECT);
    const docs = {};
    await Promise.all(_backupDocIds().map(async id => {
      const snap = await team.doc(id).get();
      if (snap.exists) docs[id] = _encFs(snap.data());
    }));
    const photos = {};
    for (const anchor of ['gallery', 'improvements']) {
      const snap = await team.doc(anchor).collection('photos').get();
      photos[anchor] = snap.docs.map(d => ({ id: d.id, data: _encFs(d.data()) }));
    }
    const now = new Date();
    const backup = {
      format: BACKUP_FORMAT, version: 1, createdAt: now.toISOString(),
      teamId: window.FB_PROJECT, teamName: state.teamName || '', docs, photos,
    };
    const blob = new Blob([JSON.stringify(backup)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `FLL_backup_${(state.teamName || 'team').replace(/[^\w֐-׿-]+/g, '_')}_${_localIsoToday()}.json`;
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 5000);
    state.lastBackupAt = now.toISOString();
    saveState(); renderBackupReminder();
    const photoCount = photos.gallery.length + photos.improvements.length;
    notify(`💾 הגיבוי נשמר (${Object.keys(docs).length} מסמכים, ${photoCount} תמונות)`, 'success');
  } catch (e) {
    console.error('Backup failed:', e);
    notify('❌ הגיבוי נכשל: ' + (e.message || e), 'error');
  }
}

// Step 1: pick a file → validate → show what's in it.
function pickRestoreFile() {
  if (!state.isAdmin) { notify('שחזור זמין למנטורים בלבד', 'error'); return; }
  const input = document.getElementById('restore-file-input');
  input.value = '';
  input.click();
}

function onRestoreFileChosen(el) {
  const file = el.files && el.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    let b;
    try { b = JSON.parse(reader.result); } catch (e) { notify('❌ הקובץ אינו JSON תקין', 'error'); return; }
    if (!b || b.format !== BACKUP_FORMAT || !b.docs || typeof b.docs !== 'object') {
      notify('❌ זה לא קובץ גיבוי של FLL Manager (גיבויים ישנים לא נתמכים לשחזור)', 'error'); return;
    }
    _pendingRestore = b;
    const data = b.docs.data || {}, admin = b.docs['admin-data'] || {};
    const photos = ((b.photos || {}).gallery || []).length + ((b.photos || {}).improvements || []).length;
    const otherTeam = b.teamId && b.teamId !== window.FB_PROJECT;
    document.getElementById('restore-summary').innerHTML = `
      <div>📅 נוצר: <b>${sanitize(new Date(b.createdAt).toLocaleString('he-IL'))}</b></div>
      <div>👥 קבוצה: <b>${sanitize(b.teamName || '—')}</b></div>
      <div>📝 ${(data.logs || []).length} תיעודים · 📌 ${(data.stickies || []).length} פתקים · 📋 ${(data.meetingPlans || []).length} מפגשים</div>
      <div>👤 ${(admin.members || []).length} חברי קבוצה · 🏁 ${(admin.scores || []).length} ריצות · 📷 ${photos} תמונות</div>
      ${otherTeam ? `<div style="color:var(--red);font-weight:700;margin-top:8px">⚠️ הגיבוי שייך לקבוצה אחרת. השחזור יעתיק את הנתונים שלה לקבוצה הזו.</div>` : ''}`;
    document.getElementById('restore-confirm-text').value = '';
    openModal('modal-restore');
  };
  reader.readAsText(file);
}

// Step 2: replace everything with the backup.
async function confirmRestore() {
  const b = _pendingRestore;
  if (!b || !state.isAdmin) return;
  if (document.getElementById('restore-confirm-text').value.trim() !== 'שחזר') {
    notify('הקלידו "שחזר" כדי לאשר', 'error'); return;
  }
  // Stop the debounced autosave so it can't write the old state over the restore.
  window._restoreInProgress = true;
  clearTimeout(_saveTimer);
  notify('⏳ משחזר...', 'info');
  try {
    const team = window.db.collection(window.FB_PROJECT);
    for (const [id, raw] of Object.entries(b.docs)) {
      const doc = _decFs(raw);
      if (id === 'settings') {
        // Keep this team's identity and current join codes so nobody gets locked out.
        Object.assign(doc, {
          teamId: window.FB_PROJECT, joinCode: state.joinCode || null,
          mentorCode: state.mentorCode || null, studentCode: state.studentCode || null,
        });
      }
      await team.doc(id).set(doc);
    }
    for (const anchor of ['gallery', 'improvements']) {
      const coll = team.doc(anchor).collection('photos');
      const wanted = ((b.photos || {})[anchor] || []);
      const keep = new Set(wanted.map(p => String(p.id)));
      const current = await coll.get();
      await Promise.all(current.docs.filter(d => !keep.has(d.id)).map(d => d.ref.delete()));
      for (const p of wanted) await coll.doc(String(p.id)).set(_decFs(p.data));
    }
    try { localStorage.removeItem(STORE_KEY); } catch (e) {}
    notify('✅ השחזור הושלם — טוען מחדש...', 'success');
    setTimeout(() => location.reload(), 1200);
  } catch (e) {
    window._restoreInProgress = false;
    console.error('Restore failed:', e);
    notify('❌ השחזור נכשל באמצע: ' + (e.message || e) + ' — כדאי לנסות שוב עם אותו קובץ', 'error');
  }
}

// Dashboard nudge for mentors when the last backup is old (or never made).
function renderBackupReminder() {
  const card = document.getElementById('dashboard-backup-reminder');
  if (!card) return;
  const last = state.lastBackupAt ? new Date(state.lastBackupAt) : null;
  const days = last ? Math.floor((Date.now() - last.getTime()) / 86400000) : null;
  const show = state.isAdmin && (days === null || days >= BACKUP_REMIND_DAYS);
  card.style.display = show ? '' : 'none';
  if (show) {
    document.getElementById('dashboard-backup-reminder-text').textContent =
      days === null ? 'עוד לא נעשה גיבוי לנתוני הקבוצה.' : `הגיבוי האחרון נעשה לפני ${days} ימים.`;
  }
}
