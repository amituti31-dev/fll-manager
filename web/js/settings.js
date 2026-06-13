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
  const done = MISSIONS_2026.filter(m => state.missionChecks[m.id]).length;
  document.getElementById('stat-missions').textContent = `${done}/15`;
  const bar = document.getElementById('stat-missions-bar');
  if (bar) bar.style.width = `${Math.round(done / 15 * 100)}%`;

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

  // יומנים
  document.getElementById('stat-logs').textContent = state.logs.length;
  const logsChange = document.getElementById('stat-logs-change');
  if (logsChange) {
    const weekAgo = new Date(); weekAgo.setDate(weekAgo.getDate() - 7);
    const weekStr = weekAgo.toISOString().split('T')[0];
    const thisWeek = (state.logs || []).filter(l => l.date >= weekStr).length;
    logsChange.textContent = `↑ ${thisWeek} השבוע`;
  }

  // חברים
  const members = state.members || [];
  document.getElementById('stat-members').textContent = members.length;
  const membersChange = document.getElementById('stat-members-change');
  if (membersChange) {
    const mentors  = members.filter(m => m.role === 'admin').length;
    const students = members.filter(m => m.role === 'student').length;
    if (members.length === 0) {
      membersChange.textContent = 'אין חברים עדיין';
    } else {
      membersChange.textContent = `${mentors} מנטורים, ${students} תלמידים`;
    }
  }
}

// ─── CHARTS ───
let charts = {};
function initCharts() {
  const isDark = state.theme !== 'light';
  const textColor = isDark ? '#8a9bb5' : '#4a5a80';
  const gridColor = isDark ? 'rgba(100,150,255,0.08)' : 'rgba(61,127,255,0.1)';

  // ── גרף התקדמות — מחושב מהנתונים האמיתיים ──

  // תכנון רובוט: ממוצע של 4 מדדים
  const doneMissions  = MISSIONS_2026.filter(m => state.missionChecks[m.id]).length;
  const maxPts        = MISSIONS_2026.reduce((a, m) => a + m.pts, 0) || 1;
  const bestScore     = (state.scores?.length) ? Math.max(...state.scores.map(s => s.score)) : 0;
  const imprCount     = (state.improvements || []).length;
  const runsCount     = (state.scores || []).length;
  const robotPct = Math.round((
    (doneMissions / 15) +
    (bestScore / maxPts) +
    Math.min(imprCount / 15, 1) +
    Math.min(runsCount / 10, 1)
  ) / 4 * 100);

  // פרויקט חדשנות: ממוצע של 4 מדדים
  const innRubrics    = state.rubrics?.innovation || [];
  const innRubricRatio = innRubrics.length
    ? innRubrics.reduce((s, r) => s + (r.score || 0), 0) / (innRubrics.length * 4)
    : 0;
  const innovLogs = (state.logs || []).filter(l => l.topic === 'innovation').length;
  const innPct = Math.round((
    (state.innovSteps?.problem  ? 1 : 0) +
    (state.innovSteps?.solution ? 1 : 0) +
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
        labels: ['ערכי יסוד', 'פרויקט חדשנות', 'תכנון רובוט'],
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

  // ── גרף ניקוד לאורך העונה — מהנתונים האמיתיים ──
  const ctx2 = document.getElementById('chart-scores');
  if (ctx2) {
    if (charts.scores) charts.scores.destroy();
    const scores = state.scores || [];
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
