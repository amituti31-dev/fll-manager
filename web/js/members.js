// ═══════════════════════════════════════════════════════
// § 09 · MEMBERS
// ═══════════════════════════════════════════════════════
function renderMembers() {
  const el = document.getElementById('members-list');
  el.innerHTML = state.members.map(m => {
    const tasks = (state.memberTasks || []).filter(t => (!t.done) && (String(t.memberId) === String(m.id) || t.memberId === 'all'));
    const pending = tasks.length;
    return `
    <div class="member-card" style="flex-direction:column;align-items:stretch${String(m.id) !== String(state.currentUser?.id) ? ';cursor:pointer' : ''}"
      onclick="if(event.target===this||event.target.classList.contains('member-info')||event.target.classList.contains('member-name')||event.target.classList.contains('member-role')||event.target.classList.contains('member-avatar'))openPrivateChat('${sanitize(String(m.id))}','${sanitize(m.name)}')">
      <div style="display:flex;align-items:center;gap:12px">
        <div class="member-avatar" style="background:${sanitize(m.color)}">${sanitize(m.name ? m.name[0] : '?')}</div>
        <div class="member-info" style="flex:1">
          <div class="member-name">${sanitize(m.name)}</div>
          <div class="member-role"><span class="badge badge-${m.role === 'admin' ? 'admin' : 'student'}">${m.role === 'admin' ? '👑 מנטור' : '🎓 תלמיד'}</span></div>
          <div style="font-size:11px;color:var(--text3)">${sanitize(m.email || '')}</div>
        </div>
        ${pending > 0 ? `<span style="background:var(--accent3);color:#fff;border-radius:20px;padding:2px 8px;font-size:11px;font-weight:700;white-space:nowrap">${pending} משימות</span>` : ''}
        ${String(m.id) !== String(state.currentUser?.id) ? `
          <button class="btn btn-ghost btn-icon" style="font-size:14px;padding:4px" onclick="event.stopPropagation();openPrivateChat('${sanitize(String(m.id))}','${sanitize(m.name)}')" title="צ'אט פרטי">💬</button>` : ''}
        ${m.role !== 'admin' && String(m.id) !== String(state.currentUser?.id) ? `
          <button class="btn btn-ghost btn-icon" style="font-size:13px;padding:4px" onclick="event.stopPropagation();showAddMemberTaskModal('${sanitize(String(m.id))}')" title="הוסף משימה">📋</button>` : ''}
        ${state.isAdmin && String(m.id) !== String(state.currentUser?.id) ? `
          <button class="btn btn-ghost btn-icon" style="color:var(--accent);font-size:12px;padding:4px" onclick="event.stopPropagation();adminChangeName('${sanitize(String(m.id))}')" title="שנה שם">✏️</button>
          <button class="btn btn-ghost btn-icon" style="color:var(--red)" onclick="event.stopPropagation();removeMember('${sanitize(String(m.id))}')" title="הסר">✕</button>` : ''}
      </div>
      ${tasks.length ? `
      <div style="margin-top:10px;border-top:1px solid var(--border);padding-top:8px">
        ${tasks.map(t => `
          <div style="display:flex;align-items:center;gap:8px;padding:4px 0;font-size:12px">
            <input type="checkbox" ${t.done ? 'checked' : ''} onchange="toggleMemberTask(${t.id})" style="accent-color:var(--accent2);width:16px;height:16px">
            <span style="${t.done ? 'text-decoration:line-through;color:var(--text3)' : ''};flex:1">${sanitize(t.desc)}</span>
            ${t.memberId === 'all' ? `<span style="background:var(--accent);color:#fff;border-radius:8px;padding:1px 6px;font-size:10px">👥 לכולם</span>` : ''}
            ${t.due ? `<span style="color:var(--text3);font-size:11px">${sanitize(t.due)}</span>` : ''}
            ${state.isAdmin ? `<button onclick="deleteMemberTask(${t.id})" style="background:none;border:none;color:var(--red);cursor:pointer;font-size:11px;padding:0 4px">✕</button>` : ''}
          </div>
        `).join('')}
      </div>` : ''}
    </div>`;
  }).join('');
  document.getElementById('team-count').textContent = (state.members || []).length;
  document.getElementById('stat-members').textContent = (state.members || []).length;
  // עדכן גם את הפירוט (מנטורים/תלמידים)
  const membersChange = document.getElementById('stat-members-change');
  if (membersChange) {
    const members = state.members || [];
    const mentors  = members.filter(m => m.role === 'admin').length;
    const students = members.filter(m => m.role === 'student').length;
    membersChange.textContent = members.length === 0
      ? 'אין חברים עדיין'
      : `${mentors} מנטורים, ${students} תלמידים`;
  }
}

function showAddMemberModal() { openModal('modal-member'); }
async function saveMember() {
  const name = document.getElementById('member-name').value.trim().slice(0, 100);
  const email = document.getElementById('member-email').value.trim().toLowerCase();
  if (!name) { notify('נדרש שם מלא', 'error'); return; }
  if (!email) { notify('נדרש אימייל', 'error'); return; }
  // Validate email format
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { notify('אימייל לא תקין', 'error'); return; }
  if (state.members.find(m => m.email === email)) { notify('אימייל כבר קיים בקבוצה', 'error'); return; }
  const colors = ['#3d7fff','#00d4a0','#ff6b35','#f5c842','#ff4d6d','#9c6fe4'];
  state.members.push({
    id: Date.now().toString(),
    name,
    role: document.getElementById('member-role').value,
    email,
    color: colors[state.members.length % colors.length],
  });
  await saveState(); closeModal('modal-member'); renderMembers();

  // רשום את החבר החדש ב-registry כדי שיוכל למצוא את הקבוצה
  if (window.FB_PROJECT) {
    try {
      await registerUserToTeam(email, window.FB_PROJECT);
      notify(`✅ ${name} נוסף לקבוצה — יכול להתחבר עם האימייל הזה`, 'success');
    } catch(e) {
      notify(`✅ ${name} נוסף, אך ההרשמה לרשת נכשלה — שלח לו את קוד ההצטרפות`, 'warning');
    }
  } else {
    notify(`✅ ${name} נוסף לקבוצה`, 'success');
  }
}
async function removeMember(id) {
  if (!state.isAdmin) { notify('רק מנטור יכול להסיר חברים', 'error'); return; }
  if (!confirm('להסיר את החבר מהקבוצה לצמיתות?')) return;
  const member = state.members.find(m => String(m.id) === String(id));
  // הסר מהרשימה
  state.members = state.members.filter(m => String(m.id) !== String(id));
  // מחק מרגיסטרי
  if (window.db && member?.email) {
    try {
      const key = member.email.replace(/[.@]/g, '_');
      await window.db.collection(window.FB_REGISTRY).doc(key).delete();
    } catch(e) { console.warn('Registry delete failed:', e); }
  }
  saveState(); renderMembers();
  notify('✅ חבר הוסר מהקבוצה ומבסיס הנתונים', 'success');
}

// מחיקת חשבון עצמי
async function deleteMyAccount() {
  if (!state.currentUser) return;
  const confirmed = confirm(`למחוק את החשבון שלך (${state.currentUser.name}) לצמיתות?

הפעולה לא ניתנת לביטול!`);
  if (!confirmed) return;
  try {
    const email = state.currentUser.email;
    const id    = state.currentUser.id;
    // הסר מרשימת חברים
    state.members = state.members.filter(m => String(m.id) !== String(id));
    await saveState();
    // מחק מרגיסטרי
    if (window.db && email) {
      const key = email.replace(/[.@]/g, '_');
      await window.db.collection(window.FB_REGISTRY).doc(key).delete();
    }
    // התנתק
    if (window.auth) await window.auth.signOut();
    try { localStorage.removeItem('fll_team_id'); } catch(e) {}
    notify('✅ החשבון נמחק', 'success');
    setTimeout(() => location.reload(), 1500);
  } catch(e) {
    notify('שגיאה במחיקה: ' + e.message, 'error');
  }
}

// יציאה מהקבוצה — החשבון נשמר, המשתמש מוסר מהקבוצה
async function leaveTeam() {
  if (!state.currentUser) return;
  const adminCount = state.members.filter(m => m.role === 'admin').length;
  if (state.isAdmin && adminCount === 1) {
    notify('⚠️ אתה המנטור היחיד — מנה מנטור אחר לפני היציאה, או מחק את הקבוצה.', 'error');
    return;
  }
  if (!confirm(`לצאת מהקבוצה "${state.teamName}"?\n\nתוכל להצטרף מחדש עם קוד הצטרפות.`)) return;
  const { email, id } = state.currentUser;
  state.members = state.members.filter(m => String(m.id) !== String(id));
  await saveState();
  if (window.db && email) {
    try { await window.db.collection(window.FB_REGISTRY).doc(email.replace(/[.@]/g, '_')).delete(); } catch(e) {}
  }
  if (window.auth) await window.auth.signOut();
  try { localStorage.removeItem('fll_team_id'); } catch(e) {}
  notify('✅ יצאת מהקבוצה', 'success');
  setTimeout(() => location.reload(), 1500);
}

// איפוס נתוני קבוצה — Admin only, חברים נשמרים
async function resetTeamData() {
  if (!state.isAdmin) return;
  if (!confirm('לאפס את כל נתוני הקבוצה?\n\nיומנים, שיפורים, ממצאים, ניקוד, מחוונים ופתקים יימחקו לצמיתות.\nחברי הקבוצה ישמרו.')) return;
  state.logs = [];
  state.improvements = [];
  state.findings = [];
  state.rubrics = { values: [], robot: [], innovation: [] };
  state.scores = [];
  state.missionChecks = {};
  state.stickies = [];
  state.memberTasks = [];
  state.checklist = state.checklist.map(c => ({ ...c, done: false }));
  await saveState();
  populateAll();
  notify('✅ הנתונים אופסו בהצלחה', 'success');
}

// מחיקת קבוצה — Admin only, מוחק הכל
async function deleteTeam() {
  if (!state.isAdmin) return;
  if (!confirm(`למחוק את הקבוצה "${state.teamName}" לצמיתות?\n\nכל הנתונים יימחקו ולא ניתן לשחזרם!\nכל חברי הקבוצה יאבדו גישה.`)) return;
  if (!confirm('אישור סופי — מחיקת הקבוצה אינה ניתנת לביטול. להמשיך?')) return;
  try {
    const teamId = window.FB_PROJECT;
    if (window.db && teamId) {
      const deletions = [
        window.db.collection(teamId).doc('settings').delete().catch(() => {}),
        window.db.collection(teamId).doc('data').delete().catch(() => {}),
      ];
      if (state.mentorCode)  deletions.push(window.db.collection(window.FB_REGISTRY).doc('mentor_'  + state.mentorCode).delete().catch(() => {}));
      if (state.studentCode) deletions.push(window.db.collection(window.FB_REGISTRY).doc('student_' + state.studentCode).delete().catch(() => {}));
      state.members.forEach(m => {
        if (m.email) deletions.push(window.db.collection(window.FB_REGISTRY).doc(m.email.replace(/[.@]/g, '_')).delete().catch(() => {}));
      });
      await Promise.all(deletions);
    }
    if (window.auth) await window.auth.signOut();
    try { localStorage.removeItem('fll_team_id'); localStorage.removeItem('fll_app_v1'); } catch(e) {}
    notify('✅ הקבוצה נמחקה', 'success');
    setTimeout(() => location.reload(), 1500);
  } catch(e) {
    notify('שגיאה במחיקה: ' + e.message, 'error');
  }
}
