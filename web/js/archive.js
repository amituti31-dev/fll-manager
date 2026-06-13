// ═══════════════════════════════════════════════════════
// § 22 · ARCHIVE & SEASONS
// ═══════════════════════════════════════════════════════
function renderSeasons() {
  const el = document.getElementById('seasons-list');
  if (!el) return;
  // עדכן תווית עונה פעילה
  const lbl = document.getElementById('active-season-label');
  if (lbl) lbl.textContent = state.currentSeason || 'Unearthed 2026';

  el.innerHTML = [...state.seasons].reverse().map((s, i) => `
    <div class="card" style="margin-bottom:10px">
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:24px">${s.archived ? '📦' : '⚡'}</span>
        <div style="flex:1">
          <div style="font-weight:700">${sanitize(s.name)}</div>
          <div style="font-size:12px;color:var(--text2)">${s.archived ? 'ארכיון – Read Only' : 'עונה פעילה'}</div>
          ${s.archived && s.logCount ? `<div style="font-size:11px;color:var(--text3);margin-top:2px">${s.logCount} יומנים · ${s.memberCount || 0} חברים · ${s.improvCount || 0} שיפורים</div>` : ''}
        </div>
        <div style="text-align:center;min-width:50px">
          <div style="font-family:'Space Mono';font-weight:700;color:var(--accent2);font-size:16px">${s.topScore || 0}</div>
          <div style="font-size:11px;color:var(--text3)">ניקוד שיא</div>
        </div>
        ${s.archived ? `<button class="btn btn-ghost btn-icon" style="font-size:12px" onclick="viewArchivedSeason(${state.seasons.indexOf(s)})">👁️ צפה</button>` : ''}
      </div>
    </div>
  `).join('');
}

function openNewSeasonModal() { openModal('modal-season'); }

async function createNewSeason() {
  const name = document.getElementById('new-season-name').value.trim();
  if (!name) { notify('נדרש שם עונה', 'error'); return; }

  // שמור snapshot של כל הנתונים הנוכחיים בעונה הנוכחית
  const topScore = state.scores.length ? Math.max(...state.scores.map(s => s.score)) : 0;
  const archivedData = {
    logs:        JSON.parse(JSON.stringify(state.logs)),
    members:     JSON.parse(JSON.stringify(state.members)),
    improvements:JSON.parse(JSON.stringify(state.improvements)),
    findings:    JSON.parse(JSON.stringify(state.findings)),
    scores:      JSON.parse(JSON.stringify(state.scores)),
    rubrics:     JSON.parse(JSON.stringify(state.rubrics)),
    missionChecks: JSON.parse(JSON.stringify(state.missionChecks)),
    checklist:   JSON.parse(JSON.stringify(state.checklist)),
    stickies:    JSON.parse(JSON.stringify(state.stickies || [])),
  };

  // עדכן את כל העונות הקיימות כ-archived + הוסף archivedData לעונה הפעילה
  state.seasons = state.seasons.map(s => {
    if (!s.archived) {
      return { ...s, archived: true, topScore,
        logCount: state.logs.length,
        memberCount: state.members.length,
        improvCount: state.improvements.length,
        archivedData };
    }
    return s;
  });

  // שמור ב-Firestore את ה-snapshot
  if (window.db && window.FB_PROJECT) {
    try {
      await window.db.collection(window.FB_PROJECT).doc('archive_' + (state.currentSeason || 'season').replace(/\s+/g,'-')).set(archivedData);
    } catch(e) { console.warn('Archive save error:', e); }
  }

  // אפס נתונים לעונה החדשה
  state.logs = [];
  state.improvements = [];
  state.findings = [];
  state.scores = [];
  state.missionChecks = {};
  state.rubrics = { values: [], robot: [], innovation: [] };
  state.stickies = [];

  state.seasons.push({ name, year: new Date().getFullYear(), archived: false, topScore: 0 });
  state.currentSeason = name;

  await saveState();
  closeModal('modal-season');
  renderSeasons();
  notify(`✅ עונה חדשה נפתחה: ${name}`, 'success');
}

// ── View archived season ──
let _viewingSeasonIdx = -1;
function viewArchivedSeason(idx) {
  const season = state.seasons[idx];
  if (!season || !season.archived) return;
  _viewingSeasonIdx = idx;

  document.getElementById('archive-main-view').style.display = 'none';
  document.getElementById('archive-season-view').style.display = 'block';
  document.getElementById('archive-season-title').textContent = '📦 ' + season.name + ' – ' + (season.year || '');

  const data = season.archivedData || {};
  const logs    = data.logs || [];
  const members = data.members || [];
  const scores  = data.scores || [];
  const improvements = data.improvements || [];
  const findings = data.findings || [];

  const topScore = scores.length ? Math.max(...scores.map(s => s.score)) : (season.topScore || 0);

  document.getElementById('archive-season-content').innerHTML = `
    <!-- סטטיסטיקות -->
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:10px;margin-bottom:16px">
      ${[
        ['📝', logs.length, 'יומנים'],
        ['👥', members.length, 'חברי צוות'],
        ['🏆', topScore, 'ניקוד שיא'],
        ['📸', improvements.length, 'שיפורים'],
        ['🔬', findings.length, 'ממצאים'],
        ['🎯', scores.length, 'ריצות'],
      ].map(([icon, val, lbl]) => `
        <div class="card" style="text-align:center;padding:12px">
          <div style="font-size:20px">${icon}</div>
          <div style="font-family:'Space Mono';font-weight:900;font-size:18px;color:var(--accent2)">${val}</div>
          <div style="font-size:11px;color:var(--text3)">${lbl}</div>
        </div>
      `).join('')}
    </div>

    <!-- חברי קבוצה -->
    ${members.length ? `
    <div class="card" style="margin-bottom:12px">
      <div class="card-header"><span class="card-icon">👥</span><span class="card-title">חברי הקבוצה</span></div>
      <div style="display:flex;flex-wrap:wrap;gap:8px">
        ${members.map(m => `
          <div style="display:flex;align-items:center;gap:8px;background:var(--surface2);border-radius:20px;padding:4px 12px">
            <div style="width:26px;height:26px;border-radius:50%;background:${sanitize(m.color || '#3d7fff')};display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#fff">${sanitize(m.name?.[0] || '?')}</div>
            <span style="font-size:13px">${sanitize(m.name)}</span>
            <span style="font-size:11px;color:var(--text3)">${m.role === 'admin' ? '👑' : '🎓'}</span>
          </div>
        `).join('')}
      </div>
    </div>` : ''}

    <!-- היסטוריית ניקוד -->
    ${scores.length ? `
    <div class="card" style="margin-bottom:12px">
      <div class="card-header"><span class="card-icon">🎯</span><span class="card-title">היסטוריית ניקוד</span></div>
      ${scores.map(s => `
        <div style="display:flex;justify-content:space-between;padding:6px 0;border-bottom:1px solid var(--border)">
          <span style="font-size:13px">${sanitize(s.notes || s.date)}</span>
          <span style="font-family:'Space Mono';font-weight:700;color:var(--accent2)">${s.score}</span>
        </div>
      `).join('')}
    </div>` : ''}

    <!-- יומן פעילות -->
    ${logs.length ? `
    <div class="card" style="margin-bottom:12px">
      <div class="card-header"><span class="card-icon">📝</span><span class="card-title">יומן פעילות (${logs.length})</span></div>
      <div style="max-height:300px;overflow-y:auto">
        ${[...logs].reverse().slice(0,20).map(l => `
          <div style="border-bottom:1px solid var(--border);padding:8px 0">
            <div style="font-size:13px">${sanitize(l.text)}</div>
            <div style="font-size:11px;color:var(--text3);margin-top:3px">${sanitize(l.author)} · ${l.date}</div>
          </div>
        `).join('')}
        ${logs.length > 20 ? `<div style="text-align:center;padding:8px;color:var(--text3);font-size:12px">+ עוד ${logs.length - 20} רשומות</div>` : ''}
      </div>
    </div>` : ''}

    <!-- שיפורי רובוט -->
    ${improvements.length ? `
    <div class="card" style="margin-bottom:12px">
      <div class="card-header"><span class="card-icon">📸</span><span class="card-title">שיפורי רובוט (${improvements.length})</span></div>
      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:8px">
        ${improvements.filter(i => i.image).map(i => `
          <div style="border-radius:10px;overflow:hidden;border:1px solid var(--border)">
            <img src="${i.image && i.image.startsWith('data:image') ? i.image : ''}" style="width:100%;height:90px;object-fit:cover;display:block" alt="${sanitize(i.name)}">
            <div style="padding:6px;font-size:11px;font-weight:600">${sanitize(i.name)}</div>
          </div>
        `).join('')}
      </div>
    </div>` : ''}

    <!-- ממצאי מחקר -->
    ${findings.length ? `
    <div class="card">
      <div class="card-header"><span class="card-icon">🔬</span><span class="card-title">ממצאי מחקר (${findings.length})</span></div>
      ${findings.slice(0,5).map(f => `
        <div style="border-bottom:1px solid var(--border);padding:8px 0">
          <div style="font-size:13px">${sanitize(f.text)}</div>
          ${f.tag ? `<span style="background:var(--accent2);color:#fff;border-radius:20px;padding:2px 8px;font-size:10px;display:inline-block;margin-top:4px">${sanitize(f.tag)}</span>` : ''}
        </div>
      `).join('')}
    </div>` : ''}
  `;
}

function closeArchiveView() {
  document.getElementById('archive-main-view').style.display = 'block';
  document.getElementById('archive-season-view').style.display = 'none';
  _viewingSeasonIdx = -1;
}

function exportArchivedSeason() {
  if (_viewingSeasonIdx < 0) return;
  const season = state.seasons[_viewingSeasonIdx];
  exportSeasonData(season.name, season.archivedData || {});
}

// ═══════════════════════════════════════════════════════
// § 23 · EXPORT & PDF
// ═══════════════════════════════════════════════════════
function exportData(type) {
  const data = {
    logs: state.logs, members: state.members,
    improvements: state.improvements, findings: state.findings,
    scores: state.scores, missionChecks: state.missionChecks,
  };
  exportSeasonData(state.currentSeason || 'עונה נוכחית', data, type);
}

function exportSeasonData(seasonName, data, type = 'pdf') {
  if (type === 'json') {
    const blob = new Blob([JSON.stringify({ season: seasonName, ...data }, null, 2)], { type: 'application/json' });
    const a = document.createElement('a'); a.href = URL.createObjectURL(blob);
    a.download = `FLL_${seasonName.replace(/\s+/g,'-')}_export.json`; a.click();
    notify('✅ קובץ JSON הורד!', 'success'); return;
  }

  if (type === 'excel') {
    const rows = [['תאריך','מחבר','נושא','תוכן']];
    (data.logs || []).forEach(l => rows.push([l.date, l.author, l.topic, l.text]));
    rows.push([]);
    rows.push(['שם חבר','אימייל','תפקיד']);
    (data.members || []).forEach(m => rows.push([m.name, m.email, m.role === 'admin' ? 'מנטור' : 'תלמיד']));
    rows.push([]);
    rows.push(['תאריך ריצה','ניקוד','הערות']);
    (data.scores || []).forEach(s => rows.push([s.date, s.score, s.notes]));
    const csv = '\uFEFF' + rows.map(function(r){return r.map(function(v){return '"'+String(v||'').replace(/"/g,'""')+'"';}).join(',');}).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const a = document.createElement('a'); a.href = URL.createObjectURL(blob);
    a.download = `FLL_${seasonName.replace(/\s+/g,'-')}_export.csv`; a.click();
    notify('✅ קובץ Excel (CSV) הורד!', 'success'); return;
  }

  // PDF — הדפסה מעוצבת
  const topScore = (data.scores||[]).length ? Math.max(...(data.scores||[]).map(s=>s.score)) : 0;
  const win = window.open('', '_blank');
  win.document.write(`<!DOCTYPE html><html dir="rtl"><head>
    <meta charset="UTF-8">
    <title>FLL Report – ${seasonName}</title>
    <style>
      body { font-family: Arial, sans-serif; direction: rtl; padding: 30px; color: #1a2340; }
      h1 { color: #3d7fff; border-bottom: 3px solid #3d7fff; padding-bottom: 10px; }
      h2 { color: #1a2340; margin-top: 28px; border-right: 4px solid #00d4a0; padding-right: 10px; }
      table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
      th { background: #3d7fff; color: #fff; padding: 8px; }
      td { border: 1px solid #ddd; padding: 7px; }
      tr:nth-child(even) { background: #f5f7ff; }
      .stat { display: inline-block; background: #f5f7ff; border-radius: 10px; padding: 12px 20px; margin: 8px; text-align: center; }
      .stat-num { font-size: 26px; font-weight: 900; color: #3d7fff; }
      @media print { body { padding: 10px; } }
    </style>
  </head><body>
    <h1>📊 דוח עונה – ${seasonName}</h1>
    <div>
      <div class="stat"><div class="stat-num">${(data.members||[]).length}</div><div>חברי קבוצה</div></div>
      <div class="stat"><div class="stat-num">${(data.logs||[]).length}</div><div>יומנים</div></div>
      <div class="stat"><div class="stat-num" style="color:#00d4a0">${topScore}</div><div>ניקוד שיא</div></div>
      <div class="stat"><div class="stat-num">${(data.improvements||[]).length}</div><div>שיפורים</div></div>
    </div>
    ${(data.members||[]).length ? `
    <h2>👥 חברי הקבוצה</h2>
    <table><tr><th>שם</th><th>אימייל</th><th>תפקיד</th></tr>
    ${(data.members||[]).map(m=>`<tr><td>${m.name}</td><td>${m.email||''}</td><td>${m.role==='admin'?'מנטור':'תלמיד'}</td></tr>`).join('')}
    </table>` : ''}
    ${(data.scores||[]).length ? `
    <h2>🎯 היסטוריית ניקוד</h2>
    <table><tr><th>תאריך</th><th>ניקוד</th><th>הערות</th></tr>
    ${(data.scores||[]).map(s=>`<tr><td>${s.date}</td><td><strong>${s.score}</strong></td><td>${s.notes||''}</td></tr>`).join('')}
    </table>` : ''}
    ${(data.logs||[]).length ? `
    <h2>📝 יומן פעילות</h2>
    <table><tr><th>תאריך</th><th>מחבר</th><th>נושא</th><th>תוכן</th></tr>
    ${(data.logs||[]).slice(0,50).map(l=>`<tr><td>${l.date}</td><td>${l.author}</td><td>${l.topic}</td><td>${l.text}</td></tr>`).join('')}
    </table>` : ''}
    ${(data.findings||[]).length ? `
    <h2>🔬 ממצאי מחקר</h2>
    <table><tr><th>תאריך</th><th>מחבר</th><th>תגית</th><th>תוכן</th></tr>
    ${(data.findings||[]).map(f=>`<tr><td>${f.date}</td><td>${f.author}</td><td>${f.tag||''}</td><td>${f.text}</td></tr>`).join('')}
    </table>` : ''}
    <p style="margin-top:30px;color:#aaa;font-size:12px">יוצא מ-FLL Team Manager · ${new Date().toLocaleDateString('he-IL')}</p>
    <script>window.onload=()=>{window.print();}<\/script>
  <script>
if('serviceWorker'in navigator){
  navigator.serviceWorker.register('/sw.js').catch(()=>{});
}
<\/script>
</body></html>`);
  win.document.close();
  notify('✅ הדוח נפתח להדפסה!', 'success');
}
