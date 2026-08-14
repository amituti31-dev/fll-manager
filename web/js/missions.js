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
  const missions = getMissions();
  const list = missions.filter(m => {
    if (_missionFilter === 'done')   return  !!state.missionChecks[m.id];
    if (_missionFilter === 'undone') return !state.missionChecks[m.id];
    return true;
  });
  const extras = state.missionExtra || {};
  el.innerHTML = list.map(m => {
    const done = state.missionChecks[m.id];
    const status = (state.missionStatuses || {})[m.id] || 'not_tried';
    const statusLabels = { not_tried: 'לא ניסינו', in_progress: 'בתהליך', ready: 'מוכן ✓' };
    const extra = extras[m.id] || {};
    const hasBonus = !!(extra.bonus || extra.rules);
    return `
      <div class="mission-card ${done ? 'done' : ''}" data-action="toggle-mission" data-id="${m.id}">
        <span class="mission-check">${done ? '✅' : '⬜'}</span>
        <div class="mission-icon">⛏️</div>
        <div class="mission-name">${sanitize(m.name)}</div>
        <div class="mission-pts">${m.pts} נקודות</div>
        <div class="mission-status-row">
          ${['not_tried','in_progress','ready'].map(s => `<button class="ms-btn ${status === s ? 'ms-active-'+s : ''}" data-action="set-mission-status" data-id="${m.id}" data-status="${s}">${statusLabels[s]}</button>`).join('')}
        </div>
        <button class="mission-notes-btn ${hasBonus ? 'has-bonus' : ''}" data-action="open-mission-extra" data-id="${m.id}">✏️ עריכה${extra.bonusDone ? ` 🎁+${extra.bonusPts || 0}` : ''}</button>
      </div>
    `;
  }).join('') || `<div style="color:var(--text3);padding:20px;text-align:center;grid-column:1/-1">אין משימות בקטגוריה זו</div>`;

  const done = missions.filter(m => state.missionChecks[m.id]).length;
  document.getElementById('stat-missions').textContent = `${done}/${missions.length}`;

  const seasonLabel = state.currentSeason || 'Unearthed 2026';
  const headerCount = document.getElementById('robot-header-mission-count');
  if (headerCount) headerCount.textContent = `${seasonLabel} – ${missions.length} משימות`;
  const cardTitle = document.getElementById('missions-card-title');
  if (cardTitle) cardTitle.textContent = `${missions.length} משימות – ${seasonLabel}`;
  const customBadge = document.getElementById('missions-custom-badge');
  if (customBadge) customBadge.style.display = (state.customMissions && state.customMissions.length) ? '' : 'none';

  // Status stats
  const statuses = state.missionStatuses || {};
  const notTried   = missions.filter(m => !statuses[m.id] || statuses[m.id] === 'not_tried').length;
  const inProgress = missions.filter(m => statuses[m.id] === 'in_progress').length;
  const ready      = missions.filter(m => statuses[m.id] === 'ready').length;
  const statsEl = document.getElementById('mission-status-stats');
  if (statsEl) statsEl.innerHTML = `
    <span class="mission-stat-pill not-tried">❌ לא ניסינו: ${notTried}</span>
    <span class="mission-stat-pill in-progress">⏳ בתהליך: ${inProgress}</span>
    <span class="mission-stat-pill ready">✅ מוכן: ${ready}</span>
  `;
}

// ── Mission edit (bonus/rules/achieved for everyone; name/pts for admin
// only — admin fields are in an .admin-only block, hidden by updateAdminUI()
// for non-mentors, since the mission list itself lives in mentor-only
// admin-data while bonus/rules/bonusDone live in student-writable data) ──
let _missionExtraId = null;
function openMissionExtraModal(id) {
  const m = getMissions().find(m => m.id === id);
  if (!m) return;
  _missionExtraId = id;
  const extra = (state.missionExtra || {})[id] || {};
  document.getElementById('mission-extra-title').textContent = `✏️ ${m.name}`;
  document.getElementById('mission-extra-name').value = m.name;
  document.getElementById('mission-extra-pts').value = m.pts;
  document.getElementById('mission-extra-bonus').value = extra.bonus || '';
  document.getElementById('mission-extra-bonus-pts').value = extra.bonusPts || '';
  document.getElementById('mission-extra-rules').value = extra.rules || '';
  document.getElementById('mission-extra-done').checked = !!extra.bonusDone;
  openModal('modal-mission-extra');
}
function saveMissionExtra() {
  if (_missionExtraId === null) return;
  if (!state.missionExtra) state.missionExtra = {};
  const bonusPts = Number(document.getElementById('mission-extra-bonus-pts').value);
  state.missionExtra[_missionExtraId] = {
    bonus: document.getElementById('mission-extra-bonus').value.trim().slice(0, 1000),
    bonusPts: Number.isFinite(bonusPts) && bonusPts > 0 ? Math.round(bonusPts) : 0,
    rules: document.getElementById('mission-extra-rules').value.trim().slice(0, 1000),
    bonusDone: document.getElementById('mission-extra-done').checked,
  };
  if (state.isAdmin) {
    const name = document.getElementById('mission-extra-name').value.trim().slice(0, 200);
    const pts = Math.max(0, Math.min(200, Math.round(Number(document.getElementById('mission-extra-pts').value) || 0)));
    const id = _missionExtraId;
    // NOTE: editing a single mission snapshots the *entire* current list into
    // state.customMissions, not just this one mission's diff. From this point
    // the team stops following MISSIONS_2026 automatically — future changes
    // to that built-in fallback (e.g. an app update) won't reach them, since
    // they're now on their own frozen copy. This is intentional (Android's
    // `missions` list works the same way, always a concrete copy, never a
    // live reference) but worth knowing: "🔄 איפוס משימות" is the only way
    // back to a live-following default list, and it discards this edit too.
    state.customMissions = getMissions().map(m => m.id === id ? { id, name: name || m.name, pts } : m);
  }
  saveState(); renderMissions(); renderScoring(); populateMissionSelects();
  closeModal('modal-mission-extra');
}

// Quick one-tap bonus toggle for the competition-prep (scoring) screen —
// same interaction as toggleMission(), but flips bonusDone instead of the
// mission's own missionChecks entry. Doesn't touch bonus/rules/bonusPts.
function toggleMissionBonus(id) {
  const extra = (state.missionExtra || {})[id];
  if (!extra) return;
  extra.bonusDone = !extra.bonusDone;
  saveState(); renderMissions(); renderScoring();
}

// ── JSON mission import (mentor-only, full replace) ──
// Validates a { season, missions:[{id,name,pts,bonus?,bonusPts?,rules?},...] }
// file. bonus/bonusPts/rules are optional, pre-filled into missionExtra on
// confirm (the same fields the "✏️ עריכה" modal edits by hand).
// On confirm, this fully replaces the mission list and resets everything
// keyed by mission id (missionChecks/missionExtra/missionStatuses), since
// imported ids have no guaranteed relationship to the previous set.
function validateMissionsJson(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw) || !Array.isArray(raw.missions)) {
    return { error: 'מבנה קובץ לא תקין — נדרש אובייקט עם שדה missions (מערך)' };
  }
  const missions = raw.missions;
  if (missions.length < 10) {
    return { error: `מספר משימות נמוך מדי (${missions.length}) — נדרשות לפחות 10` };
  }
  const seenIds = new Set();
  const cleaned = [];
  const extras = {};
  for (let i = 0; i < missions.length; i++) {
    const m = missions[i];
    if (!m || typeof m !== 'object') return { error: `משימה #${i + 1} אינה אובייקט תקין` };
    const id = Number(m.id);
    const name = typeof m.name === 'string' ? m.name.trim() : '';
    const pts = Number(m.pts);
    if (!Number.isInteger(id) || id <= 0) return { error: `משימה #${i + 1}: מזהה (id) לא תקין` };
    if (seenIds.has(id)) return { error: `מזהה משימה כפול: ${id}` };
    if (!name) return { error: `משימה #${i + 1}: חסר שם` };
    if (!Number.isFinite(pts) || pts < 0 || pts > 200) return { error: `משימה #${i + 1}: ניקוד לא סביר (${m.pts})` };
    seenIds.add(id);
    cleaned.push({ id, name: name.slice(0, 200), pts: Math.round(pts) });
    const bonus = typeof m.bonus === 'string' ? m.bonus.trim().slice(0, 1000) : '';
    const rules = typeof m.rules === 'string' ? m.rules.trim().slice(0, 1000) : '';
    const bonusPtsRaw = Number(m.bonusPts);
    const bonusPts = Number.isFinite(bonusPtsRaw) && bonusPtsRaw > 0 && bonusPtsRaw <= 200 ? Math.round(bonusPtsRaw) : 0;
    if (bonus || rules || bonusPts) extras[id] = { bonus, bonusPts, rules, bonusDone: false };
  }
  return { missions: cleaned, extras, season: typeof raw.season === 'string' ? raw.season.trim().slice(0, 100) : null };
}

let _pendingMissionImport = null;
let _pendingMissionImportExtras = null;
let _pendingMissionImportSeason = null;
function importMissionsJson(el) {
  const file = el.files && el.files[0];
  el.value = ''; // allow re-selecting the same file again later
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    let parsed;
    try { parsed = JSON.parse(reader.result); }
    catch (err) { notify('⚠️ קובץ JSON לא תקין: ' + err.message, 'error'); return; }
    const result = validateMissionsJson(parsed);
    if (result.error) { notify('⚠️ ' + result.error, 'error'); return; }
    _pendingMissionImport = result.missions;
    _pendingMissionImportExtras = result.extras;
    _pendingMissionImportSeason = result.season;
    showMissionImportPreview(result.missions, result.extras, result.season);
  };
  reader.onerror = () => notify('⚠️ שגיאה בקריאת הקובץ', 'error');
  reader.readAsText(file);
}

function showMissionImportPreview(missions, extras, season) {
  document.getElementById('mission-import-list').innerHTML = missions.map(m => `
    <div style="display:flex;justify-content:space-between;padding:6px 0;border-bottom:1px solid var(--border);font-size:13px">
      <span>${sanitize(m.name)}${extras[m.id] ? ' <span style="color:var(--gold)">🎁</span>' : ''}</span>
      <span style="color:var(--accent2);font-family:'Space Mono'">${m.pts} נק'</span>
    </div>
  `).join('');
  document.getElementById('mission-import-count').textContent = missions.length;
  document.getElementById('mission-import-season').textContent = season ? ` — ${season}` : '';
  openModal('modal-mission-import');
}

function confirmMissionImport() {
  if (!_pendingMissionImport) return;
  state.customMissions = _pendingMissionImport;
  state.missionChecks = {};
  state.missionExtra = _pendingMissionImportExtras || {};
  state.missionStatuses = {};
  if (_pendingMissionImportSeason) {
    state.currentSeason = _pendingMissionImportSeason;
    // Rename the active (non-archived) season entry in place instead of
    // pushing a new one — there's always exactly one non-archived season
    // (see createNewSeason() in archive.js), and adding another would
    // duplicate it and desync it from state.currentSeason.
    const active = (state.seasons || []).find(s => !s.archived);
    if (active) active.name = _pendingMissionImportSeason;
  }
  _pendingMissionImport = null;
  _pendingMissionImportExtras = null;
  _pendingMissionImportSeason = null;
  saveState();
  renderMissions(); renderScoring(); populateMissionSelects();
  try { renderSeasons(); } catch(e) {}
  closeModal('modal-mission-import');
  notify('✅ המשימות הוחלפו בהצלחה', 'success');
}

function cancelMissionImport() {
  _pendingMissionImport = null;
  _pendingMissionImportExtras = null;
  _pendingMissionImportSeason = null;
  closeModal('modal-mission-import');
}

function resetMissionsToDefault() {
  if (!confirm('לאפס לרשימת ברירת המחדל? הפעולה תמחק שינויים שנעשו בשמות/ניקוד המשימות.')) return;
  state.customMissions = [];
  saveState(); renderMissions(); renderScoring(); populateMissionSelects();
  notify('✅ המשימות אופסו לברירת המחדל', 'success');
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
  const opts = getMissions().map(m => `<option value="${m.id}">${sanitize(m.name)}</option>`).join('');
  const selects = [document.getElementById('imp-mission'), document.getElementById('mission-filter')];
  selects.forEach(s => { if (s) s.innerHTML = (s.id === 'mission-filter' ? '<option value="">כל המשימות</option>' : '') + opts; });
}

function filterRobotByMission() { renderGallery(); }
