// ═══════════════════════════════════════════════════════════════════
//  FLL MANAGER — JavaScript Index
//  ───────────────────────────────────────────────────────────────
//  §01  UTILITIES .............. sanitize, sanitizeUrl, getMissions, getMissionsScoreTotal, notify
//  §01B FIXED REFERENCE DATA .... DEFAULT_CHECKLIST, MISSIONS_2026, OFFICIAL_RUBRICS
//  §02  CONSTANTS & STATE ....... state
//  §03  STATE PERSISTENCE ....... saveState, loadState, findTeamForUser
//  §05  TEAM SETUP .............. loginGoTo, create team, join team
//  §06  APP CORE ................ initApp, navigate, populateAll, sidebar
//  §07  THEME & ROLE ............ setTheme, applyTheme, toggleRole
//  §08  DAILY LOGS .............. saveLog, renderTimeline, deleteLog
//  §09  MEMBERS ................. renderMembers, saveMember, leaveTeam
//  §10  MISSIONS ................ renderMissions, filterMissions
//  §11  RUBRICS ................. renderRubrics, setScore, importOfficialRubric
//  §12  GALLERY & IMPROVEMENTS .. saveImprovement, renderGallery, makeTimelapse
//  §13  INNOVATION PROJECT ...... INNOV_STEPS, renderInnovProject, switchInnovTab
//  §14  RESEARCH & INTERVIEWS ... saveFinding, saveInterview, renderResearchHub
//  §15  RECORDING ............... startRecording
//  §16  CHAT .................... initChatScreen, switchChatTab, sendChatMessage
//  §17  MEMBER TASKS & MY TASKS . saveMemberTask, renderMyTasks, switchMyTasksTab
//  §18  VALUES & STICKY NOTES ... switchValuesTab, saveSticky, renderStickyBoard
//  §19  SCORING ................. switchScoringTab, renderScoring, saveRunScore
//  §20  TIMERS .................. startTimer, startJudgingTimer, playBuzzer
//  §21  CHECKLIST ............... renderChecklist, toggleChecklist
//  §22  ARCHIVE & SEASONS ....... renderSeasons, viewArchivedSeason
//  §23  EXPORT & PDF ............ exportData, exportSeasonData
//  §24  SETTINGS ................ changePin, saveTeamSettings, adminChangeName
//  §25  STATS & CHARTS .......... updateStats, initCharts, updateCharts
//  §26  MODALS & NOTIFICATIONS .. openModal, closeModal, notify
//  §27  PWA ..................... installPWA, service worker
//  §28  AUTH & BOOT ............. loginWithGoogle, signOut, boot
// ═══════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
// § 01 · UTILITIES
// ═══════════════════════════════════════════════════════

// sanitize() - escapes HTML special characters to prevent XSS
// Use on ALL user-supplied text before inserting into innerHTML
function sanitize(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;')
    .replace(/`/g, '&#x60;');
}

// sanitizeUrl() - validates URLs to prevent javascript: injection
function sanitizeUrl(url) {
  if (!url) return '';
  try {
    const u = new URL(url);
    if (!['http:', 'https:'].includes(u.protocol)) return '';
    return url;
  } catch(e) { return ''; }
}

// getMissions() - the mission list currently in effect: a mentor-imported
// list if one exists, otherwise the built-in MISSIONS_2026 fallback (kept
// so offline/first-load teams always have a working mission set).
function getMissions() {
  return (state.customMissions && state.customMissions.length) ? state.customMissions : MISSIONS_2026;
}

// getMissionsScoreTotal() - base mission points (for checked missions) plus
// any achieved bonus points (state.missionExtra[id].bonusDone), used by both
// the live scoring display and saved run history so they stay consistent.
function getMissionsScoreTotal() {
  const base = getMissions().reduce((a, m) => a + (state.missionChecks[m.id] ? m.pts : 0), 0);
  const extras = state.missionExtra || {};
  const bonus = Object.values(extras).reduce((a, e) => a + (e.bonusDone ? (e.bonusPts || 0) : 0), 0);
  return base + bonus;
}

// ═══════════════════════════════════════════════════════
// § 26 · MODALS & NOTIFICATIONS
// ═══════════════════════════════════════════════════════
function notify(msg, type = 'success') {
  const el = document.getElementById('notification');
  el.textContent = msg; el.className = `notif ${type} show`;
  clearTimeout(el._t); el._t = setTimeout(() => el.classList.remove('show'), 3000);
}
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }

// ── PIN title display ──
function updatePinTitle() {
  document.getElementById('pin-app-title').textContent = state.teamName || 'FLL Team Manager';
  if (state.teamLogo) document.getElementById('pin-team-logo').innerHTML = `<img src="${state.teamLogo}" style="width:64px;height:64px;border-radius:50%;object-fit:cover">`;
}

// ═══════════════════════════════════════════════════════
// BOOT
// ═══════════════════════════════════════════════════════
// ─── PWA INSTALL ───
let _deferredInstall = null;
window.addEventListener('beforeinstallprompt', e => {
  e.preventDefault();
  _deferredInstall = e;
  const btn = document.getElementById('install-btn');
  if (btn) btn.style.display = '';
});
window.addEventListener('appinstalled', () => {
  const btn = document.getElementById('install-btn');
  if (btn) btn.style.display = 'none';
  _deferredInstall = null;
  notify('✅ האפליקציה נוספה למסך הבית!', 'success');
});
