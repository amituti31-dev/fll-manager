// ═══════════════════════════════════════════════════════
// § 10 · MISSIONS
// ═══════════════════════════════════════════════════════
let _missionFilter = 'all';

function filterMissions(filter) {
  _missionFilter = filter;
  document.getElementById('mf-all').className    = filter === 'all'    ? 'btn btn-primary' : 'btn btn-ghost';
  document.getElementById('mf-done').className   = filter === 'done'   ? 'btn btn-primary' : 'btn btn-ghost';
  document.getElementById('mf-undone').className = filter === 'undone' ? 'btn btn-primary' : 'btn btn-ghost';
  ['mf-all','mf-done','mf-undone'].forEach(id => { const b = document.getElementById(id); if (b) b.style.flex = '1'; });
  renderMissions();
}

function renderMissions() {
  const el = document.getElementById('missions-grid');
  const list = MISSIONS_2026.filter(m => {
    if (_missionFilter === 'done')   return  !!state.missionChecks[m.id];
    if (_missionFilter === 'undone') return !state.missionChecks[m.id];
    return true;
  });
  el.innerHTML = list.map(m => {
    const done = state.missionChecks[m.id];
    const status = (state.missionStatuses || {})[m.id] || 'not_tried';
    const statusLabels = { not_tried: 'לא ניסינו', in_progress: 'בתהליך', ready: 'מוכן ✓' };
    return `
      <div class="mission-card ${done ? 'done' : ''}" onclick="toggleMission(${m.id})">
        <span class="mission-check">${done ? '✅' : '⬜'}</span>
        <div class="mission-icon">⛏️</div>
        <div class="mission-name">${m.name}</div>
        <div class="mission-pts">${m.pts} נקודות</div>
        <div class="mission-status-row" onclick="event.stopPropagation()">
          ${['not_tried','in_progress','ready'].map(s => `<button class="ms-btn ${status === s ? 'ms-active-'+s : ''}" onclick="setMissionStatus(${m.id},'${s}')">${statusLabels[s]}</button>`).join('')}
        </div>
      </div>
    `;
  }).join('') || `<div style="color:var(--text3);padding:20px;text-align:center;grid-column:1/-1">אין משימות בקטגוריה זו</div>`;

  const done = MISSIONS_2026.filter(m => state.missionChecks[m.id]).length;
  document.getElementById('stat-missions').textContent = `${done}/15`;

  // Status stats
  const statuses = state.missionStatuses || {};
  const notTried   = MISSIONS_2026.filter(m => !statuses[m.id] || statuses[m.id] === 'not_tried').length;
  const inProgress = MISSIONS_2026.filter(m => statuses[m.id] === 'in_progress').length;
  const ready      = MISSIONS_2026.filter(m => statuses[m.id] === 'ready').length;
  const statsEl = document.getElementById('mission-status-stats');
  if (statsEl) statsEl.innerHTML = `
    <span class="mission-stat-pill not-tried">❌ לא ניסינו: ${notTried}</span>
    <span class="mission-stat-pill in-progress">⏳ בתהליך: ${inProgress}</span>
    <span class="mission-stat-pill ready">✅ מוכן: ${ready}</span>
  `;
}

function setMissionStatus(id, status) {
  if (!state.missionStatuses) state.missionStatuses = {};
  state.missionStatuses[id] = status;
  saveState(); renderMissions();
}

function toggleMission(id) {
  state.missionChecks[id] = !state.missionChecks[id];
  saveState(); renderMissions(); updateScoreFromMissions();
}

function populateMissionSelects() {
  const opts = MISSIONS_2026.map(m => `<option value="${m.id}">${m.name}</option>`).join('');
  const selects = [document.getElementById('imp-mission'), document.getElementById('mission-filter')];
  selects.forEach(s => { if (s) s.innerHTML = (s.id === 'mission-filter' ? '<option value="">כל המשימות</option>' : '') + opts; });
}

function filterRobotByMission() { renderGallery(); }
