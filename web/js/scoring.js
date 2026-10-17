// ═══════════════════════════════════════════════════════
// § 19 · SCORING
// ═══════════════════════════════════════════════════════
function switchScoringTab(tab) {
  document.getElementById('scoring-panel-judging').style.display = tab === 'judging' ? '' : 'none';
  document.getElementById('scoring-panel-robot').style.display   = tab === 'robot'   ? '' : 'none';
  ['judging','robot'].forEach(t => {
    const btn = document.getElementById('scoring-tab-' + t);
    if (btn) { btn.className = tab === t ? 'btn btn-primary' : 'btn btn-ghost'; btn.style.flex = '1'; }
  });
  if (tab === 'judging') renderScoringJudgingDoc();
}


// ── Scoring ──
function renderScoring() {
  const el = document.getElementById('scoring-missions');
  const extras = state.missionExtra || {};
  el.innerHTML = getMissions().map(m => {
    const extra = extras[m.id] || {};
    return `
    <div class="mission-row">
      <input type="checkbox" class="mission-checkbox" id="sc-${m.id}" ${state.missionChecks[m.id] ? 'checked' : ''} data-onchange="toggle-scoring-mission" data-id="${m.id}">
      <label class="mission-row-name" for="sc-${m.id}">${sanitize(m.name)}</label>
      ${extra.bonusPts > 0 ? `
        <input type="checkbox" class="mission-checkbox" id="scb-${m.id}" ${extra.bonusDone ? 'checked' : ''} data-onchange="toggle-mission-bonus" data-id="${m.id}">
        <label for="scb-${m.id}" style="font-size:12px;font-weight:700;white-space:nowrap;color:${extra.bonusDone ? 'var(--gold)' : 'var(--text3)'}">🎁+${extra.bonusPts}</label>
      ` : ''}
      ${isPrecisionTokens(m) ? precisionTokensSelect() : ''}
      <span class="mission-row-pts">${isPrecisionTokens(m) ? PRECISION_TOKEN_POINTS[getPrecisionTokens()] : m.pts}</span>
    </div>
  `;
  }).join('');
  updateScoreFromMissions();
  try { renderScoringJudgingDoc(); } catch(e) {}
}

function toggleScoringMission(id) {
  state.missionChecks[id] = !state.missionChecks[id];
  saveState(); renderMissions(); updateScoreFromMissions();
}

function updateScoreFromMissions() {
  const total = getMissionsScoreTotal();
  document.getElementById('total-score').textContent = total;
  document.getElementById('stat-score').textContent = total;
  // sync checkboxes
  getMissions().forEach(m => {
    const cb = document.getElementById('sc-' + m.id);
    if (cb) cb.checked = !!state.missionChecks[m.id];
  });
}

function saveRunScore() {
  const total = getMissionsScoreTotal();
  state.scores.push({ date: new Date().toISOString().split('T')[0], score: total, notes: 'ריצה ' + (state.scores.length + 1) });
  saveState(); renderScoreHistory(); updateCharts();
  notify(`✅ ריצה נשמרה – ${total} נקודות`, 'success');
}

let _runsChart = null;

function renderScoreHistory() {
  const el   = document.getElementById('score-history');
  const wrap = document.getElementById('chart-runs-wrap');
  const canvas = document.getElementById('chart-runs');

  if (!state.scores.length) {
    if (el) el.innerHTML = '<div style="color:var(--text3);font-size:13px">אין ריצות שמורות עדיין</div>';
    if (wrap) wrap.style.display = 'none';
    if (_runsChart) { _runsChart.destroy(); _runsChart = null; }
    return;
  }

  // ─── Chart ───────────────────────────────────────────
  if (canvas && wrap) {
    wrap.style.display = '';
    const scores  = state.scores.map(s => s.score);
    const labels  = state.scores.map((_, i) => 'ריצה ' + (i + 1));
    const maxScore = Math.max(...scores);
    const maxIdx   = scores.lastIndexOf(maxScore);

    const isDark     = !document.body.classList.contains('light-mode');
    const textColor  = isDark ? '#8a9bb5' : '#4a5a80';
    const gridColor  = isDark ? 'rgba(100,150,255,0.08)' : 'rgba(61,127,255,0.1)';

    const pointBg = scores.map((_, i) => i === maxIdx ? '#f0c040' : '#4f8ef7');
    const pointR  = scores.map((_, i) => i === maxIdx ? 8 : 4);

    if (_runsChart) { _runsChart.destroy(); _runsChart = null; }
    _runsChart = new Chart(canvas, {
      type: 'line',
      data: {
        labels,
        datasets: [{
          data: scores,
          borderColor: '#4f8ef7',
          backgroundColor: 'rgba(79,142,247,0.12)',
          fill: true,
          tension: 0.3,
          pointBackgroundColor: pointBg,
          pointBorderColor: pointBg,
          pointRadius: pointR,
          pointHoverRadius: scores.map((_, i) => i === maxIdx ? 11 : 6),
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: ctx => `${ctx.raw} נק'${ctx.dataIndex === maxIdx ? ' 🏆' : ''}`,
            },
          },
        },
        scales: {
          x: { ticks: { color: textColor, font: { size: 11 } }, grid: { color: gridColor } },
          y: { beginAtZero: true, ticks: { color: textColor }, grid: { color: gridColor } },
        },
      },
    });
  }

  // ─── Last 5 runs list ─────────────────────────────────
  if (el) {
    el.innerHTML = [...state.scores].reverse().slice(0, 5).map(s => `
      <div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid var(--border)">
        <span style="font-size:13px">${formatDate(s.date)}</span>
        <span style="font-family:'Space Mono';font-weight:700;color:var(--accent2)">${s.score}</span>
      </div>
    `).join('');
  }
}

// ═══════════════════════════════════════════════════════
// § 20 · TIMERS
// ═══════════════════════════════════════════════════════
let timers = { robot: null };
let timerVals = { robot: 150 };
function startTimer(t) {
  if (timers[t]) { clearInterval(timers[t]); timers[t] = null; return; }
  timers[t] = setInterval(() => {
    timerVals[t]--;
    if (timerVals[t] <= 0) { clearInterval(timers[t]); timers[t] = null; timerVals[t] = 0; playBuzzer(); }
    updateTimerDisplay(t);
  }, 1000);
}
function resetTimer(t) { clearInterval(timers[t]); timers[t] = null; timerVals[t] = 150; updateTimerDisplay(t); }
function updateTimerDisplay(t) {
  const v = timerVals[t]; const m = Math.floor(v / 60); const s = v % 60;
  const el = document.getElementById(t + '-timer');
  if (!el) return;
  el.textContent = `${m}:${s.toString().padStart(2,'0')}`;
  el.className = 'timer-display' + (v <= 10 ? ' danger' : v <= 30 ? ' warning' : '');
}

// ── Judging phased timer ──
const JUDGING_PHASES = [
  { label: 'קבלת פני הקבוצה', secs: 120 },
  { label: 'פרויקט חדשנות',   secs: 300 },
  { label: 'שאלות על חדשנות', secs: 300 },
  { label: 'תכנון רובוט',     secs: 300 },
  { label: 'שאלות על רובוט',  secs: 300 },
  { label: 'זמן חופשי',       secs: 360 },
];
let judgingPhase = 0, judgingVal = 120, judgingInterval = null;

function startJudgingTimer() {
  if (judgingInterval) { clearInterval(judgingInterval); judgingInterval = null; return; }
  judgingInterval = setInterval(() => {
    judgingVal--;
    if (judgingVal <= 0) {
      playBuzzer();
      if (judgingPhase < JUDGING_PHASES.length - 1) {
        judgingPhase++;
        judgingVal = JUDGING_PHASES[judgingPhase].secs;
        notify('📢 שלב הבא: ' + JUDGING_PHASES[judgingPhase].label, 'success');
      } else {
        clearInterval(judgingInterval); judgingInterval = null;
        notify('✅ חדר שיפוט הסתיים!', 'success');
      }
    }
    updateJudgingDisplay();
  }, 1000);
}

function resetJudgingTimer() {
  clearInterval(judgingInterval); judgingInterval = null;
  judgingPhase = 0; judgingVal = JUDGING_PHASES[0].secs;
  updateJudgingDisplay();
}

function nextJudgingPhase() {
  if (judgingPhase < JUDGING_PHASES.length - 1) {
    judgingPhase++; judgingVal = JUDGING_PHASES[judgingPhase].secs;
    updateJudgingDisplay();
    notify('⏭ ' + JUDGING_PHASES[judgingPhase].label, 'success');
  }
}

function jumpToPhase(idx) {
  judgingPhase = idx; judgingVal = JUDGING_PHASES[idx].secs;
  updateJudgingDisplay();
}

function updateJudgingDisplay() {
  const v = judgingVal; const m = Math.floor(v / 60); const s = v % 60;
  const el = document.getElementById('judging-timer');
  const lbl = document.getElementById('judging-phase-label');
  const badge = document.getElementById('judging-phase-badge');
  if (el) {
    el.textContent = `${m}:${s.toString().padStart(2,'0')}`;
    el.className = 'timer-display' + (v <= 10 ? ' danger' : v <= 30 ? ' warning' : '');
  }
  if (lbl) lbl.textContent = JUDGING_PHASES[judgingPhase].label;
  if (badge) badge.textContent = `שלב ${judgingPhase + 1}/${JUDGING_PHASES.length}`;
  document.querySelectorAll('.j-phase-icon').forEach((icon, i) => {
    icon.classList.remove('active', 'done');
    if (i === judgingPhase)    icon.classList.add('active');
    else if (i < judgingPhase) icon.classList.add('done');
  });
}
function playBuzzer() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator(); const gain = ctx.createGain();
    osc.connect(gain); gain.connect(ctx.destination);
    osc.frequency.value = 880; gain.gain.value = 0.3;
    osc.start(); osc.stop(ctx.currentTime + 0.5);
  } catch(e) {}
  notify('⏰ הזמן נגמר!', 'error');
}

// ── Sticky board ──
const STICKY_VALUES = {
  discovery: { label: '🔍 גילוי', bg: '#3d6fd4', text: '#e8f0ff' },
  innovation: { label: '💡 חדשנות', bg: '#00a882', text: '#e0fff8' },
  impact:     { label: '🌍 השפעה', bg: '#e05a20', text: '#fff0e8' },
  inclusion:  { label: '🤝 הכלה', bg: '#c4a000', text: '#fffbe0' },
  teamwork:   { label: '👥 עבודת צוות', bg: '#7c4fc4', text: '#f3e8ff' },
  fun:        { label: '🎉 הנאה', bg: '#c43060', text: '#ffe8f0' },
};

function showAddStickyModal() { openModal('modal-sticky'); }

// Local calendar day (not UTC) — the calendar screen places stickies by this date.
function _localIsoToday() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function saveSticky() {
  const text = document.getElementById('sticky-text').value.trim().slice(0, 500);
  if (!text) { notify('נדרש תוכן לפתק', 'error'); return; }
  const allowedValues = ['discovery','innovation','impact','inclusion','teamwork','fun'];
  const value = document.getElementById('sticky-value').value;
  if (!allowedValues.includes(value)) { notify('ערך לא תקין', 'error'); return; }
  if (!state.stickies) state.stickies = [];
  state.stickies.push({
    id: Date.now(),
    value,
    text,
    date: _localIsoToday(),
    // No author name shown on board
  });
  saveState(); closeModal('modal-sticky');
  document.getElementById('sticky-text').value = '';
  renderStickyBoard(); renderDashboardCalendar();
  notify('📌 פתק נוסף!', 'success');
}

function deleteSticky(id) {
  state.stickies = (state.stickies || []).filter(s => s.id !== id);
  saveState(); renderStickyBoard();
}

// Sticky board view: 'value' (a column per core value) or 'meeting' (grouped by
// date, under that day's meeting plan title when there is one).
let _stickyView = 'value';
function switchStickyView(view) {
  _stickyView = view === 'meeting' ? 'meeting' : 'value';
  document.getElementById('sticky-view-value').className = _stickyView === 'value' ? 'btn btn-primary' : 'btn btn-ghost';
  document.getElementById('sticky-view-meeting').className = _stickyView === 'meeting' ? 'btn btn-primary' : 'btn btn-ghost';
  renderStickyBoard();
}

function _stickyNoteHtml(s, cfg) {
  return `
          <div class="sticky-note" style="margin-bottom:10px">
            ${state.isAdmin ? `<button class="sticky-note-delete" data-action="delete-sticky" data-id="${s.id}">✕</button>` : ''}
            <div class="sticky-note-value" style="color:${cfg.bg}">${cfg.label}</div>
            <div class="sticky-note-text">${sanitize(s.text)}</div>
            <div class="sticky-note-date">${formatDate(s.date)}</div>
          </div>`;
}

function renderStickyBoard() {
  const board = document.getElementById('values-sticky-board');
  if (!board) return;
  const stickies = state.stickies || [];
  if (!stickies.length) {
    board.innerHTML = `<div style="color:var(--text3);text-align:center;padding:30px;grid-column:1/-1">
      <div style="font-size:36px;margin-bottom:8px">📌</div>
      <div>לחץ "+ הוסף פתק" כדי לשתף מחשבות על הערכים</div>
    </div>`;
    return;
  }
  if (_stickyView === 'meeting') {
    const byDate = {};
    stickies.forEach(st => { (byDate[st.date || ''] = byDate[st.date || ''] || []).push(st); });
    board.innerHTML = Object.keys(byDate).sort((a, b) => b.localeCompare(a)).map(date => {
      const meeting = (state.meetingPlans || []).find(m => m.date === date);
      return `
      <div class="sticky-column">
        <div class="sticky-column-title">${meeting ? `📋 ${sanitize(meeting.title || 'מפגש')}` : '📅 ללא מפגש'}</div>
        <div style="font-size:12px;color:var(--text3);margin:-4px 0 8px">${date ? formatDate(date) : 'ללא תאריך'} · ${byDate[date].length} פתקים</div>
        ${byDate[date].map(st => _stickyNoteHtml(st, STICKY_VALUES[st.value] || { label: '📌', bg: 'var(--text3)' })).join('')}
      </div>`;
    }).join('');
    return;
  }
  // Group by value
  const groups = {};
  Object.keys(STICKY_VALUES).forEach(v => { groups[v] = stickies.filter(s => s.value === v); });
  board.innerHTML = Object.entries(STICKY_VALUES).map(([key, cfg]) => {
    const notes = groups[key] || [];
    if (!notes.length) return '';
    return `
      <div class="sticky-column">
        <div class="sticky-column-title" style="color:${cfg.bg}">${cfg.label}</div>
        ${notes.map(s => _stickyNoteHtml(s, cfg)).join('')}
      </div>`;
  }).join('');
}

// ── Admin: assign member tasks ──
function showAddMemberTaskModal(preselect) {
  const sel = document.getElementById('task-member-select');
  if (!sel) return;
  // Mentors can assign to anyone (mentors too) or to a group; students to students.
  const assignable = state.isAdmin ? state.members : state.members.filter(m => m.role !== 'admin');
  const groups = state.isAdmin
    ? [['all', '👥 כולם (משימה לכל הקבוצה)'], ['all-mentors', '👑 כל המנטורים'], ['all-students', '🎓 כל התלמידים']]
    : [];
  sel.innerHTML =
    groups.map(([v, l]) => `<option value="${v}">${l}</option>`).join('') +
    assignable.map(m => `<option value="${m.id}" ${String(m.id) === String(preselect) ? 'selected' : ''}>${m.role === 'admin' ? '👑 ' : ''}${sanitize(m.name)}</option>`).join('');
  document.getElementById('task-desc').value = '';
  document.getElementById('task-due').value = '';
  openModal('modal-member-task');
}

function saveMemberTask() {
  const memberId = document.getElementById('task-member-select').value;
  const desc = document.getElementById('task-desc').value.trim().slice(0, 500);
  if (!desc) { notify('נדרש תיאור משימה', 'error'); return; }
  if (!state.memberTasks) state.memberTasks = [];
  const isGroup = Object.prototype.hasOwnProperty.call(TASK_GROUPS, memberId);
  const groupNames = { 'all': 'כולם', 'all-mentors': 'כל המנטורים', 'all-students': 'כל התלמידים' };
  const member = isGroup ? null : state.members.find(m => String(m.id) === String(memberId));
  const task = {
    id: Date.now(),
    memberId,
    memberName: isGroup ? groupNames[memberId] : (member?.name || ''),
    desc,
    due: document.getElementById('task-due').value,
    done: false,
    date: new Date().toISOString().split('T')[0],
  };
  state.memberTasks.push(task);
  saveState();
  if (task.due) scheduleTaskReminder(task);
  closeModal('modal-member-task');
  renderMembers();
  notify(isGroup ? `✅ משימה נוספה ל${groupNames[memberId]}` : `✅ משימה נוספה ל-${member?.name || 'חבר'}`, 'success');
}

function toggleMemberTask(id) {
  if (!state.memberTasks) return;
  const t = state.memberTasks.find(t => t.id === id);
  if (t) { t.done = !t.done; saveState(); renderMembers(); renderMyTasks(); }
}

function deleteMemberTask(id) {
  state.memberTasks = (state.memberTasks || []).filter(t => t.id !== id);
  cancelTaskReminder(id);
  saveState(); renderMembers();
}
