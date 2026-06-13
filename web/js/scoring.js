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

function toggleRubricSection(cat) {
  const section = document.getElementById('rubric-section-' + cat);
  const chevron = document.getElementById('rubric-chevron-' + cat);
  if (!section) return;
  const collapsed = section.style.display === 'none';
  section.style.display = collapsed ? '' : 'none';
  if (chevron) chevron.style.transform = collapsed ? '' : 'rotate(-90deg)';
}

function importAllOfficialRubrics() {
  ['innovation', 'values', 'robot'].forEach(cat => importOfficialRubric(cat));
}

// ── Scoring ──
function renderScoring() {
  const el = document.getElementById('scoring-missions');
  el.innerHTML = MISSIONS_2026.map(m => `
    <div class="mission-row">
      <input type="checkbox" class="mission-checkbox" id="sc-${m.id}" ${state.missionChecks[m.id] ? 'checked' : ''} onchange="toggleScoringMission(${m.id})">
      <label class="mission-row-name" for="sc-${m.id}">${m.name}</label>
      <span class="mission-row-pts">${m.pts}</span>
    </div>
  `).join('');
  updateScoreFromMissions();
  try { renderScoringJudgingDoc(); } catch(e) {}
}

function toggleScoringMission(id) {
  state.missionChecks[id] = !state.missionChecks[id];
  saveState(); renderMissions(); updateScoreFromMissions();
}

function updateScoreFromMissions() {
  const total = MISSIONS_2026.reduce((a, m) => a + (state.missionChecks[m.id] ? m.pts : 0), 0);
  document.getElementById('total-score').textContent = total;
  document.getElementById('stat-score').textContent = total;
  // sync checkboxes
  MISSIONS_2026.forEach(m => {
    const cb = document.getElementById('sc-' + m.id);
    if (cb) cb.checked = !!state.missionChecks[m.id];
  });
}

function saveRunScore() {
  const total = MISSIONS_2026.reduce((a, m) => a + (state.missionChecks[m.id] ? m.pts : 0), 0);
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
  inclusion:  { label: '🤝 שילוב', bg: '#c4a000', text: '#fffbe0' },
  teamwork:   { label: '👥 עבודת צוות', bg: '#7c4fc4', text: '#f3e8ff' },
  fun:        { label: '🎉 כיף', bg: '#c43060', text: '#ffe8f0' },
};

function showAddStickyModal() { openModal('modal-sticky'); }

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
    date: new Date().toISOString().split('T')[0],
    // No author name shown on board
  });
  saveState(); closeModal('modal-sticky');
  document.getElementById('sticky-text').value = '';
  renderStickyBoard();
  notify('📌 פתק נוסף!', 'success');
}

function deleteSticky(id) {
  state.stickies = (state.stickies || []).filter(s => s.id !== id);
  saveState(); renderStickyBoard();
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
  // Group by value
  const groups = {};
  Object.keys(STICKY_VALUES).forEach(v => { groups[v] = stickies.filter(s => s.value === v); });
  board.innerHTML = Object.entries(STICKY_VALUES).map(([key, cfg]) => {
    const notes = groups[key] || [];
    if (!notes.length) return '';
    return `
      <div class="sticky-column">
        <div class="sticky-column-title" style="color:${cfg.bg}">${cfg.label}</div>
        ${notes.map(s => `
          <div class="sticky-note" style="background:${cfg.bg};color:${cfg.text};margin-bottom:10px">
            ${state.isAdmin ? `<button class="sticky-note-delete" onclick="deleteSticky(${s.id})">✕</button>` : ''}
            <div class="sticky-note-text">${sanitize(s.text)}</div>
            <div class="sticky-note-date">${formatDate(s.date)}</div>
          </div>
        `).join('')}
      </div>`;
  }).join('');
}

// ── Admin: assign member tasks ──
function showAddMemberTaskModal(preselect) {
  const sel = document.getElementById('task-member-select');
  if (!sel) return;
  const students = state.members.filter(m => m.role !== 'admin');
  sel.innerHTML =
    (state.isAdmin ? `<option value="all">👥 כולם (משימה לכל הקבוצה)</option>` : '') +
    students.map(m => `<option value="${m.id}" ${String(m.id) === String(preselect) ? 'selected' : ''}>${sanitize(m.name)}</option>`).join('');
  document.getElementById('task-desc').value = '';
  document.getElementById('task-due').value = '';
  openModal('modal-member-task');
}

function saveMemberTask() {
  const memberId = document.getElementById('task-member-select').value;
  const desc = document.getElementById('task-desc').value.trim().slice(0, 500);
  if (!desc) { notify('נדרש תיאור משימה', 'error'); return; }
  if (!state.memberTasks) state.memberTasks = [];
  const isAll = memberId === 'all';
  const member = isAll ? null : state.members.find(m => String(m.id) === String(memberId));
  const task = {
    id: Date.now(),
    memberId,
    memberName: isAll ? 'כולם' : (member?.name || ''),
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
  notify(isAll ? '✅ משימה נוספה לכל הקבוצה' : `✅ משימה נוספה ל-${member?.name || 'חבר'}`, 'success');
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
