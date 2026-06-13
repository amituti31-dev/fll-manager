// ═══════════════════════════════════════════════════════
// § 06 · APP CORE
// ═══════════════════════════════════════════════════════
function initApp() {
  updateLogoDisplay();
  const stnEl = document.getElementById('sidebar-team-name');
  if (stnEl) stnEl.textContent = state.teamName;
  document.getElementById('app').style.display = 'flex';
  applyTheme(state.theme);
  updateAdminUI();
  populateAll();
  navigate('dashboard');
  try { checkTaskReminders(); } catch(e) {}
}

function updateAdminUI() {
  document.querySelectorAll('.admin-only').forEach(el => {
    el.style.display = state.isAdmin ? '' : 'none';
  });
  document.getElementById('role-pill').textContent = state.isAdmin ? 'מנטור' : 'תלמיד';
  document.getElementById('role-label').textContent = state.isAdmin ? 'מצב אדמין' : 'מצב תלמיד';
}

function populateAll() {
  try { renderTimeline(); } catch(e) { console.warn('renderTimeline:', e); }
  try { renderMembers(); } catch(e) { console.warn('renderMembers:', e); }
  try { renderMissions(); } catch(e) { console.warn('renderMissions:', e); }
  try { renderRubrics('values'); } catch(e) { console.warn('renderRubrics values:', e); }
  try { renderStickyBoard(); } catch(e) { console.warn('renderStickyBoard:', e); }
  try { renderRubrics('robot'); } catch(e) { console.warn('renderRubrics robot:', e); }
  try { renderRubrics('innovation'); } catch(e) { console.warn('renderRubrics innov:', e); }
  try { renderInnovProject(); } catch(e) { console.warn('renderInnovProject:', e); }
  try { renderResearchHub(); } catch(e) { console.warn('renderResearchHub:', e); }
  try { renderScoring(); } catch(e) { console.warn('renderScoring:', e); }
  try { renderScoreHistory(); } catch(e) { console.warn('renderScoreHistory:', e); }
  try { renderChecklist(); } catch(e) { console.warn('renderChecklist:', e); }
  try { renderSeasons(); } catch(e) { console.warn('renderSeasons:', e); }
  try { renderRecentLogs(); } catch(e) { console.warn('renderRecentLogs:', e); }
  try { populateMissionSelects(); } catch(e) { console.warn('populateMissionSelects:', e); }
  try { renderMyTasks(); } catch(e) { console.warn('renderMyTasks:', e); }
  try { initCharts(); } catch(e) { console.warn('initCharts:', e); }
  try { renderTeamGallery(); } catch(e) { console.warn('renderTeamGallery:', e); }
  try { renderJudging(); } catch(e) { console.warn('renderJudging:', e); }
  try { renderLinks(); } catch(e) { console.warn('renderLinks:', e); }
  try { renderCompetitionCountdown(); } catch(e) { console.warn('renderCompetitionCountdown:', e); }
}

// ── Navigation ──
function navigate(screen) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const el = document.getElementById('screen-' + screen);
  if (el) el.classList.add('active');
  const nav = document.querySelector(`.nav-item[onclick*="${screen}"]`);
  if (nav) nav.classList.add('active');
  // Unsubscribe chat listener when leaving chat
  if (screen !== 'chat' && _chatUnsubscribe) { _chatUnsubscribe(); _chatUnsubscribe = null; }
  const titles = {
    dashboard: 'דשבורד ראשי', daily: 'תיעוד יומי',
    values: 'ערכי יסוד', robot: 'תכנון רובוט',
    innovation: 'פרויקט חדשנות', scoring: 'הכנה לתחרות',
    team: 'ניהול קבוצה', chat: 'צ\'אט קבוצה', archive: 'עונות וארכיון',
    settings: 'הגדרות', mytasks: 'המשימות שלי',
    gallery: 'גלריית עונה', judging: 'שאלות שיפוט', links: 'ספריית קישורים', strategy: 'לוח אסטרטגיה',
  };
  if (screen === 'mytasks') renderMyTasks();
  if (screen === 'gallery') renderTeamGallery();
  if (screen === 'judging') renderJudging();
  if (screen === 'links') renderLinks();
  if (screen === 'scoring') { try { renderScoring(); } catch(e) {} try { renderScoringJudgingDoc(); } catch(e) {} }
  if (screen === 'team')    { try { renderMembers(); } catch(e) {} }
  if (screen === 'strategy') { updateAdminUI(); setTimeout(initStrategyBoard, 50); }
  document.getElementById('page-title').textContent = titles[screen] || screen;
  if (screen === 'settings') {
    renderCompetitionCountdown();
    document.getElementById('settings-team-name').value = state.teamName;
    // Show team ID
    const teamIdEl = document.getElementById('team-id-display');
    if (teamIdEl) teamIdEl.textContent = window.FB_PROJECT || 'לא מוגדר';
    // Show name change info
    const infoEl = document.getElementById('name-change-info');
    if (infoEl && state.currentUser) {
      const member = state.members.find(m => String(m.id) === String(state.currentUser.id));
      const changes = member?.nameChanges || 0;
      if (changes >= 2 && !state.isAdmin) {
        infoEl.textContent = '⚠️ השתמשת ב-2 שינויי שם. פנה למנטור לשינוי נוסף.';
        infoEl.style.color = 'var(--accent3)';
      } else {
        infoEl.textContent = `נותרו ${2 - changes} שינויי שם`;
        infoEl.style.color = 'var(--text2)';
      }
    }
    // הצג קודי הצטרפות — צור חדשים אם אין
    if (!state.mentorCode || !state.studentCode) {
      regenerateCodes(true); // silent
    } else {
      const mEl = document.getElementById('settings-mentor-code');
      const sEl = document.getElementById('settings-student-code');
      if (mEl) mEl.textContent = state.mentorCode;
      if (sEl) sEl.textContent = state.studentCode;
    }
    // הצג team ID
  }
  if (screen === 'chat') { initChatScreen(); }
  // close mobile sidebar
  if (window.innerWidth <= 768) {
    document.getElementById('sidebar').classList.add('mobile-hidden');
    document.getElementById('sidebar-overlay').classList.remove('show');
  }
}

function showAddModal() {
  const active = document.querySelector('.screen.active');
  if (!active) return;
  const id = active.id.replace('screen-', '');
  if (id === 'daily') showAddLogModal();
  else if (id === 'robot') openAddImprovement();
  else if (id === 'innovation') showAddFindingModal();
  else if (id === 'team') showAddMemberModal();
  else if (id === 'judging') addJudgingQuestion();
  else if (id === 'links') showAddLinkModal();
  else if (id === 'strategy') {
    document.querySelector('#screen-strategy label input[type="file"]')?.click();
  }
  else showAddLogModal();
}

// ── Sidebar ──
let sidebarOpen = true;
function toggleSidebarCollapse() {
  sidebarOpen = !sidebarOpen;
  document.getElementById('sidebar').classList.toggle('closed', !sidebarOpen);
  document.querySelector('.collapse-btn').textContent = sidebarOpen ? '◀' : '▶';
}
function toggleSidebar() {
  const sb = document.getElementById('sidebar');
  const ov = document.getElementById('sidebar-overlay');
  const hidden = sb.classList.toggle('mobile-hidden');
  ov.classList.toggle('show', !hidden);
}

// ═══════════════════════════════════════════════════════
// § 07 · THEME & ROLE
// ═══════════════════════════════════════════════════════
function setTheme(t) {
  state.theme = t;
  // Save theme ONLY locally - each user has their own preference
  try { localStorage.setItem('fll_theme', t); } catch(e) {}
  applyTheme(t);
}
function applyTheme(t) {
  document.body.classList.toggle('light-mode', t === 'light');
  document.querySelectorAll('.theme-btn').forEach(b => b.classList.remove('active'));
  const btn = t === 'dark' ? document.getElementById('dark-btn') : document.getElementById('light-btn');
  if (btn) btn.classList.add('active');
}

// ── Role ──
function toggleRole() {
  // Only mentors (admin role) can switch to admin mode
  if (!state.isAdmin && state.currentUser?.role !== 'admin') {
    notify('🚫 רק מנטורים יכולים להפעיל מצב אדמין', 'error');
    return;
  }
  state.isAdmin = !state.isAdmin; updateAdminUI();
  notify(state.isAdmin ? '🔑 מצב אדמין מופעל' : '👤 מצב תלמיד', 'success');
}
