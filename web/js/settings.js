// ═══════════════════════════════════════════════════════
// § 24 · SETTINGS
// ═══════════════════════════════════════════════════════
// יצור קודים חדשים לקבוצה קיימת
async function regenerateCodes(silent = false) {
  if (!window.FB_PROJECT || !window.db) return;
  const teamId   = window.FB_PROJECT;
  const teamName = state.teamName;

  const mentorCode  = generateJoinCode();
  const studentCode = generateJoinCode();

  state.mentorCode  = mentorCode;
  state.studentCode = studentCode;

  try {
    // עדכן settings
    await window.db.collection(window.FB_PROJECT).doc('settings').set(
      { mentorCode, studentCode }, { merge: true }
    );
    // שמור ברגיסטרי
    await Promise.all([
      window.db.collection(window.FB_REGISTRY).doc('mentor_' + mentorCode).set(
        { teamId, joinCode: mentorCode, role: 'admin', teamName, createdAt: new Date().toISOString() }
      ),
      window.db.collection(window.FB_REGISTRY).doc('student_' + studentCode).set(
        { teamId, joinCode: studentCode, role: 'student', teamName, createdAt: new Date().toISOString() }
      ),
    ]);
  } catch(e) { console.warn('regenerateCodes error:', e); }

  // עדכן תצוגה
  const mEl = document.getElementById('settings-mentor-code');
  const sEl = document.getElementById('settings-student-code');
  if (mEl) mEl.textContent = mentorCode;
  if (sEl) sEl.textContent = studentCode;

  if (!silent) notify('✅ קודים חדשים נוצרו!', 'success');
}

function copySettingsCode(type) {
  const code  = type === 'mentor' ? (state.mentorCode || '----') : (state.studentCode || '----');
  const label = type === 'mentor' ? '👑 קוד מנטורים' : '🎓 קוד תלמידים';
  const text  = `${label} לקבוצה ${state.teamName}: ${code}`;
  navigator.clipboard?.writeText(text).then(() => notify('📋 קוד הועתק!', 'success')).catch(() => notify('קוד: ' + code, 'success'));
}
function copySettingsJoinCode() { copySettingsCode('student'); }

function saveTeamSettings() {
  const newName = document.getElementById('settings-team-name').value.trim().slice(0, 100);
  state.teamName = newName || state.teamName;
  document.getElementById('sidebar-team-name').textContent = state.teamName;

  const newSeason = document.getElementById('settings-season-name').value.trim().slice(0, 100);
  if (newSeason && newSeason !== state.currentSeason) {
    state.currentSeason = newSeason;
    // Same rule as a JSON import's season field: rename the one active
    // (non-archived) entry in place rather than adding a new one.
    const active = (state.seasons || []).find(s => !s.archived);
    if (active) active.name = newSeason;
    try { renderMissions(); } catch(e) {}
    try { renderSeasons(); } catch(e) {}
  }

  saveState(); notify('✅ הגדרות נשמרו', 'success');
}

function changeMyName() {
  const newName = document.getElementById('my-new-name').value.trim().slice(0, 100);
  if (!newName) { notify('נדרש שם', 'error'); return; }
  const user = state.currentUser;
  if (!user) return;
  const member = state.members.find(m => String(m.id) === String(user.id));
  if (!member) return;
  
  // Check name change count
  const changes = member.nameChanges || 0;
  if (changes >= 2 && !state.isAdmin) {
    notify('🚫 שינית שם פעמיים כבר. פנה למנטור לשינוי נוסף.', 'error');
    return;
  }
  
  member.name = newName;
  member.nameChanges = changes + 1;
  state.currentUser.name = newName;
  document.getElementById('sidebar-team-name').textContent = state.teamName;
  saveState(); renderMembers();
  document.getElementById('my-new-name').value = '';
  notify(`✅ שם שונה ל-${newName}${member.nameChanges >= 2 && !state.isAdmin ? ' (שינוי אחרון!)' : ''}`, 'success');
}

function adminChangeName(memberId) {
  const newName = prompt('שם חדש למשתמש:');
  if (!newName) return;
  const member = state.members.find(m => String(m.id) === String(memberId));
  if (member) {
    member.name = newName;
    member.nameChanges = 0; // reset counter
    saveState(); renderMembers();
    notify(`✅ שם שונה ל-${newName}`, 'success');
  }
}
function changePin() {
  const np = document.getElementById('new-pin').value.trim();
  if (!np || np.length !== 6 || !/^\d+$/.test(np)) { notify('קוד חייב להיות 6 ספרות', 'error'); return; }
  if (state.currentUser) { state.currentUser.pin = np; const m = state.members.find(m => m.id === state.currentUser.id); if (m) m.pin = np; }
  saveState(); notify('✅ קוד שונה בהצלחה', 'success');
  document.getElementById('new-pin').value = '';
}
function setupBiometric() {
  if (!window.PublicKeyCredential) { notify('הדפדפן לא תומך ב-WebAuthn', 'error'); return; }
  notify('👆 הגדרת טביעת אצבע בתהליך...', 'success');
}

// ═══════════════════════════════════════════════════════
// § 25 · STATS & CHARTS
// ═══════════════════════════════════════════════════════
function updateStats() {
  // משימות
  const missionsForStats = getRealMissions();
  const done = missionsForStats.filter(m => state.missionChecks[m.id]).length;
  document.getElementById('stat-missions').textContent = `${done}/${missionsForStats.length}`;
  const bar = document.getElementById('stat-missions-bar');
  if (bar) bar.style.width = `${Math.round(done / (missionsForStats.length || 1) * 100)}%`;

  // ניקוד
  const scores = state.scores || [];
  const lastScore = scores.length ? scores[scores.length - 1].score : 0;
  const prevScore = scores.length > 1 ? scores[scores.length - 2].score : null;
  document.getElementById('stat-score').textContent = lastScore;
  const scoreChange = document.getElementById('stat-score-change');
  if (scoreChange) {
    if (prevScore !== null) {
      const diff = lastScore - prevScore;
      scoreChange.textContent = `${diff >= 0 ? '↑ +' : '↓ '}${Math.abs(diff)} מריצה קודמת`;
      scoreChange.style.color = diff >= 0 ? 'var(--accent2)' : 'var(--red)';
    } else {
      scoreChange.textContent = scores.length ? 'ריצה ראשונה!' : 'אין ריצות עדיין';
    }
  }
  try { renderDashboardCalendar(); } catch(e) { console.warn('renderDashboardCalendar:', e); }
}

// ─── CHARTS ───
let charts = {};
function initCharts() {
  const isDark = state.theme !== 'light';
  const textColor = isDark ? '#8a9bb5' : '#4a5a80';
  const gridColor = isDark ? 'rgba(100,150,255,0.08)' : 'rgba(61,127,255,0.1)';

  // ── גרף התקדמות — מחושב מהנתונים האמיתיים ──

  // תכנון רובוט: ממוצע של 4 מדדים
  const missionsForChart = getRealMissions();
  const doneMissions  = missionsForChart.filter(m => state.missionChecks[m.id]).length;
  const maxPts        = getMaxScore() || 1;
  const bestScore     = (state.scores?.length) ? Math.max(...state.scores.map(s => s.score)) : 0;
  const imprCount     = (state.improvements || []).length;
  const runsCount     = (state.scores || []).length;
  const robotPct = Math.round((
    (doneMissions / (missionsForChart.length || 1)) +
    Math.min(bestScore / maxPts, 1) +
    Math.min(imprCount / 15, 1) +
    Math.min(runsCount / 10, 1)
  ) / 4 * 100);

  // פרויקט חדשנות: ממוצע של 4 מדדים
  const innRubricRatio = rubricRatio('innovation');
  const innovLogs = (state.logs || []).filter(l => logTopics(l).includes('innovation')).length;
  const innPct = Math.round((
    (getInnovStep('problem')  ? 1 : 0) +
    (getInnovStep('solution') ? 1 : 0) +
    innRubricRatio +
    Math.min(innovLogs / 5, 1)
  ) / 4 * 100);

  // ערכי ליבה: כמה מתוך 6 הערכים קיבלו לפחות פתק אחד
  const valCoverage = new Set((state.stickies || []).map(s => s.value)).size;
  const valPct = Math.round(valCoverage / 6 * 100);

  const ctx1 = document.getElementById('chart-progress');
  if (ctx1) {
    if (charts.progress) charts.progress.destroy();
    charts.progress = new Chart(ctx1, {
      type: 'bar',
      data: {
        labels: ['ערכי ליבה', 'פרויקט חדשנות', 'תכנון רובוט'],
        datasets: [{
          label: '% השלמה',
          data: [valPct, innPct, robotPct],
          backgroundColor: ['rgba(245,200,66,0.6)', 'rgba(0,212,160,0.6)', 'rgba(61,127,255,0.6)'],
          borderColor: ['#f5c842', '#00d4a0', '#3d7fff'],
          borderWidth: 2, borderRadius: 8,
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: ctx => `${ctx.parsed.y}%` } }
        },
        scales: {
          y: { beginAtZero: true, max: 100, ticks: { color: textColor, callback: v => v + '%' }, grid: { color: gridColor } },
          x: { ticks: { color: textColor }, grid: { display: false } }
        }
      }
    });
  }

  // ── גרף 5 הריצות האחרונות — מהנתונים האמיתיים ──
  const ctx2 = document.getElementById('chart-scores');
  if (ctx2) {
    if (charts.scores) charts.scores.destroy();
    const scores = (state.scores || []).slice(-5);
    charts.scores = new Chart(ctx2, {
      type: 'line',
      data: {
        labels: scores.length ? scores.map(s => formatDate(s.date)) : ['אין נתונים'],
        datasets: [{
          label: 'ניקוד',
          data: scores.length ? scores.map(s => s.score) : [0],
          borderColor: '#00d4a0', backgroundColor: 'rgba(0,212,160,0.1)',
          borderWidth: 2, pointBackgroundColor: '#00d4a0',
          pointRadius: 5, tension: 0.3, fill: true,
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { color: textColor }, grid: { color: gridColor } },
          x: { ticks: { color: textColor, maxRotation: 0 }, grid: { display: false } }
        }
      }
    });
  }
}

function updateCharts() { initCharts(); updateStats(); }

// ── Full score history popup (tap the dashboard mini chart) ──
function showScoreHistoryModal() {
  openModal('modal-score-history');
  const canvas = document.getElementById('chart-score-history-full');
  if (!canvas) return;
  const isDark    = !document.body.classList.contains('light-mode');
  const textColor = isDark ? '#8a9bb5' : '#4a5a80';
  const gridColor = isDark ? 'rgba(100,150,255,0.08)' : 'rgba(61,127,255,0.1)';
  const scores    = state.scores || [];
  const maxScore  = scores.length ? Math.max(...scores.map(s => s.score)) : 0;
  const maxIdx    = scores.map(s => s.score).lastIndexOf(maxScore);

  if (charts.scoreHistoryFull) charts.scoreHistoryFull.destroy();
  charts.scoreHistoryFull = new Chart(canvas, {
    type: 'line',
    data: {
      labels: scores.length ? scores.map((_, i) => 'ריצה ' + (i + 1)) : ['אין נתונים'],
      datasets: [{
        data: scores.length ? scores.map(s => s.score) : [0],
        borderColor: '#3d7fff', backgroundColor: 'rgba(61,127,255,0.12)',
        borderWidth: 2, tension: 0.3, fill: true,
        pointBackgroundColor: scores.map((_, i) => i === maxIdx ? '#f5c842' : '#3d7fff'),
        pointRadius: scores.map((_, i) => i === maxIdx ? 7 : 4),
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: { callbacks: { label: ctx => `${ctx.raw} נק'${ctx.dataIndex === maxIdx ? ' 🏆' : ''}` } },
      },
      scales: {
        y: { beginAtZero: true, ticks: { color: textColor }, grid: { color: gridColor } },
        x: { ticks: { color: textColor, maxRotation: 0 }, grid: { display: false } },
      }
    }
  });
}

// ─── Competition Date ─────────────────────────────────
function saveCompetitionDate() {
  const val = document.getElementById('competition-date-input')?.value;
  state.competitionDate = val || null;
  saveState();
  renderCompetitionCountdown();
  notify(val ? `📅 תאריך תחרות נשמר: ${val}` : '📅 תאריך תחרות נמחק', 'success');
}

function renderCompetitionCountdown() {
  const card = document.getElementById('competition-countdown-card');
  const cw   = document.getElementById('competition-countdown');
  const ct   = document.getElementById('competition-countdown-total');
  if (!card || !cw) return;

  const input = document.getElementById('competition-date-input');
  if (input && state.competitionDate) input.value = state.competitionDate;

  if (!state.competitionDate) { card.style.display = 'none'; return; }

  const today = new Date(); today.setHours(0,0,0,0);
  const target = new Date(state.competitionDate + 'T00:00:00');
  const diff = Math.round((target - today) / 86400000);

  if (diff < 0) {
    card.style.display = '';
    cw.innerHTML = `<div class="countdown-unit"><div class="countdown-num">🏆</div><div class="countdown-label">התחרות הייתה</div></div>`;
    ct.textContent = `לפני ${Math.abs(diff)} ימים`;
    return;
  }

  const d = diff;
  const weeks = Math.floor(d / 7);
  const days  = d % 7;

  card.style.display = '';
  cw.innerHTML = `
    <div class="countdown-unit"><div class="countdown-num">${weeks}</div><div class="countdown-label">שבועות</div></div>
    <div class="countdown-unit"><div class="countdown-num">${days}</div><div class="countdown-label">ימים</div></div>
  `;
  ct.textContent = diff === 0 ? '🎉 היום יום התחרות!' : `${diff} ימים עד התחרות`;
}
