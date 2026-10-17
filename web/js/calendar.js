// ═══════════════════════════════════════════════════════
// § 31 · CALENDAR (meeting plans + milestones + value-sticky notes)
// ═══════════════════════════════════════════════════════
const _calHebrewMonths = ['ינואר','פברואר','מרץ','אפריל','מאי','יוני','יולי','אוגוסט','ספטמבר','אוקטובר','נובמבר','דצמבר'];
const _calHebrewWeekdays = ['א','ב','ג','ד','ה','ו','ש']; // Sunday-first
let _calMonth = new Date(); _calMonth.setDate(1);

function shiftCalMonth(delta) {
  _calMonth.setMonth(_calMonth.getMonth() + Number(delta));
  renderMonthGrid();
}

function _isoLocal(y, m, d) {
  return `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

function _stickiesForDay(iso) {
  return (state.stickies || []).filter(s => s.date === iso);
}

function _chipsForDay(iso) {
  const chips = [];
  const meeting = _meetingForDay(iso);
  if (meeting) chips.push({ icon: '📋', text: _meetingTitle(meeting), color: '#3d7fff' });
  (state.milestones || []).forEach(m => {
    if (m.targetDate === iso) chips.push({ icon: '🚩', text: m.title, color: '#f5c842' });
    if (m.actualDate === iso) chips.push({ icon: '✅', text: m.title, color: '#00d4a0' });
  });
  // Value stickies added that day — one chip per value (label already has its
  // emoji), with a count when several notes of the same value were added.
  const counts = {};
  _stickiesForDay(iso).forEach(s => { counts[s.value] = (counts[s.value] || 0) + 1; });
  Object.entries(STICKY_VALUES).forEach(([key, cfg]) => {
    if (counts[key]) chips.push({ icon: '', text: counts[key] > 1 ? `${cfg.label} ×${counts[key]}` : cfg.label, color: cfg.bg });
  });
  return chips;
}

// Google-Calendar-style grid: a full rectangle (greyed leading/trailing days
// from adjacent months fill it out), each cell showing small colored event
// chips (not just dots), a "+N" overflow, and a circular today marker.
function renderMonthGrid() {
  _renderMonthInto('cal', _calMonth);
}

// Dashboard: always the current month (October shows October, December shows December…).
function renderDashboardCalendar() {
  try { renderMeetingSummaryReminder(); } catch(e) {}
  const now = new Date();
  _renderMonthInto('dash-cal', new Date(now.getFullYear(), now.getMonth(), 1));
}

// Renders a month into the elements `${prefix}-month-label`, `${prefix}-weekday-row`, `${prefix}-grid`.
function _renderMonthInto(prefix, monthDate) {
  const label = document.getElementById(prefix + '-month-label');
  const weekdayRow = document.getElementById(prefix + '-weekday-row');
  const grid = document.getElementById(prefix + '-grid');
  if (!label || !grid) return;

  const y = monthDate.getFullYear(), m = monthDate.getMonth();
  label.textContent = `${_calHebrewMonths[m]} ${y}`;
  weekdayRow.innerHTML = _calHebrewWeekdays.map(w =>
    `<div style="text-align:center;font-size:11px;font-weight:700;color:var(--text3)">${w}</div>`).join('');

  const daysInMonth = new Date(y, m + 1, 0).getDate();
  const daysInPrevMonth = new Date(y, m, 0).getDate();
  const leading = new Date(y, m, 1).getDay(); // 0=Sunday already
  const totalCells = leading + daysInMonth;
  const trailing = (7 - totalCells % 7) % 7;
  const cellCount = leading + daysInMonth + trailing;
  const today = new Date();
  const todayIso = _isoLocal(today.getFullYear(), today.getMonth(), today.getDate());

  let html = '';
  for (let i = 0; i < cellCount; i++) {
    let dayNum, cellY = y, cellM = m, inMonth;
    if (i < leading) { dayNum = daysInPrevMonth - (leading - i - 1); cellM = m - 1; inMonth = false; }
    else if (i < leading + daysInMonth) { dayNum = i - leading + 1; inMonth = true; }
    else { dayNum = i - leading - daysInMonth + 1; cellM = m + 1; inMonth = false; }
    if (cellM < 0) { cellM = 11; cellY = y - 1; }
    if (cellM > 11) { cellM = 0; cellY = y + 1; }
    const iso = _isoLocal(cellY, cellM, dayNum);
    const isToday = iso === todayIso;
    const chips = inMonth ? _chipsForDay(iso) : [];
    const visible = chips.slice(0, 2);
    const overflow = chips.length - visible.length;

    const chipsHtml = visible.map(c => `
      <div style="background:${c.color}33;color:${c.color};border-radius:3px;padding:1px 3px;font-size:9px;font-weight:700;
           white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-bottom:1px">${c.icon ? c.icon + ' ' : ''}${sanitize(c.text)}</div>
    `).join('');

    html += `
      <div data-action="show-cal-day" data-arg="${iso}"
           style="cursor:pointer;background:var(--surface2);border-radius:6px;padding:3px;min-height:64px;display:flex;flex-direction:column;align-items:flex-end">
        <span style="display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;border-radius:50%;font-size:11px;
              font-weight:${isToday ? '800' : '500'};color:${isToday ? '#fff' : (inMonth ? 'var(--text)' : 'var(--text3)')};
              background:${isToday ? 'var(--accent)' : 'transparent'};opacity:${inMonth ? '1' : '0.5'}">${dayNum}</span>
        <div style="width:100%;margin-top:2px">${chipsHtml}</div>
        ${overflow > 0 ? `<div style="font-size:8px;color:var(--text3)">+${overflow} עוד</div>` : ''}
      </div>`;
  }
  grid.innerHTML = html;
}

function showCalDay(iso) {
  const milestones = (state.milestones || []).filter(m => m.targetDate === iso || m.actualDate === iso);
  const stickies = _stickiesForDay(iso);
  const meeting = _meetingForDay(iso);
  document.getElementById('cal-day-title').textContent = `📅 ${formatDate(iso)}`;
  const meetingHtml = meeting ? `
    <div style="background:var(--surface2);border-radius:10px;padding:10px 12px;margin-bottom:8px;border-right:3px solid var(--accent)">
      <div style="font-weight:800;font-size:14px;margin-bottom:6px">📋 ${sanitize(_meetingTitle(meeting))}</div>
      ${meeting.plan ? `<div style="font-size:12px;color:var(--accent);font-weight:700">מה מתכננים</div>
        <div style="font-size:13px;white-space:pre-wrap;margin-bottom:6px">${sanitize(meeting.plan)}</div>` : ''}
      ${meeting.summary ? `<div style="font-size:12px;color:var(--accent2);font-weight:700">מה קרה בפועל</div>
        <div style="font-size:13px;white-space:pre-wrap">${sanitize(meeting.summary)}</div>` : ''}
    </div>` : '';
  const itemsHtml = [
    meetingHtml,
    ...milestones.map(m => `<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:14px">🚩 ${sanitize(m.title)}</div>`),
    stickies.length ? `<div style="font-size:12px;font-weight:700;color:var(--text3);margin-top:8px">📌 ${meeting ? 'פתקים מהמפגש' : 'פתקים'} (${stickies.length})</div>` : '',
    ...stickies.map(s => {
      const cfg = STICKY_VALUES[s.value] || { label: '📌', bg: 'var(--text3)' };
      return `<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:14px">
        <span style="color:${cfg.bg};font-weight:700">${cfg.label}</span>
        <div style="color:var(--text2);margin-top:2px;white-space:pre-wrap">${sanitize(s.text)}</div>
      </div>`;
    }),
  ].join('');
  document.getElementById('cal-day-items').innerHTML = itemsHtml ||
    `<div style="color:var(--text3);font-size:13px;padding:6px 0">אין פריטים ביום הזה</div>`;
  document.getElementById('cal-day-add-milestone').dataset.arg = iso;
  const planBtn = document.getElementById('cal-day-meeting-plan');
  planBtn.dataset.arg = iso;
  planBtn.textContent = meeting ? '✏️ ערוך מפגש' : '📋 תכנית מפגש';
  openModal('modal-cal-day');
}

function renderCalendar() {
  renderMonthGrid();
  renderDashboardCalendar();
  renderMeetingPlans();
  const milestonesEl = document.getElementById('milestones-list');
  if (!milestonesEl) return;

  const milestones = [...(state.milestones || [])].sort((a, b) => a.targetDate.localeCompare(b.targetDate));

  milestonesEl.innerHTML = milestones.length ? milestones.map(m => {
    const changed = m.actualDate && m.actualDate !== m.targetDate;
    return `
      <div style="padding:8px 0;border-bottom:1px solid var(--border)">
        <div style="display:flex;align-items:center;gap:10px">
          <input type="checkbox" style="width:18px;height:18px;accent-color:var(--accent2)" ${m.done ? 'checked' : ''} data-onchange="toggle-milestone" data-id="${m.id}">
          <span style="flex:1;font-size:14px;${m.done ? 'text-decoration:line-through;color:var(--text3)' : ''}">${sanitize(m.title)}</span>
          <button data-action="delete-milestone" data-id="${m.id}" style="background:none;border:none;color:var(--text3);cursor:pointer">✕</button>
        </div>
        <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:6px;margin-right:28px">
          <span style="background:rgba(245,200,66,0.15);color:#f5c842;border-radius:20px;padding:3px 10px;font-size:11px;font-weight:600">🚩 יעד: ${formatDate(m.targetDate)}</span>
          <span style="cursor:pointer;background:${changed ? 'rgba(0,212,160,0.15)' : 'rgba(255,255,255,0.06)'};color:${changed ? 'var(--accent2)' : 'var(--text3)'};border-radius:20px;padding:3px 10px;font-size:11px;font-weight:600" data-action="show-milestone-actual-modal" data-id="${m.id}">${changed ? `✅ בוצע: ${formatDate(m.actualDate)}` : '➕ סמן תאריך בפועל'}</span>
        </div>
      </div>`;
  }).join('') : `<div style="color:var(--text3);font-size:13px;padding:12px 0">אין אבני דרך עדיין</div>`;
}

// ── Milestones ──
function showAddMilestoneModal(presetDate) {
  document.getElementById('milestone-title').value = '';
  if (presetDate) {
    document.getElementById('milestone-date').value = presetDate;
  } else {
    const inWeek = new Date(); inWeek.setDate(inWeek.getDate() + 7);
    document.getElementById('milestone-date').value = inWeek.toISOString().split('T')[0];
  }
  closeModal('modal-cal-day');
  openModal('modal-milestone');
}

function saveMilestone() {
  const title = document.getElementById('milestone-title').value.trim();
  const date = document.getElementById('milestone-date').value;
  if (!title) { notify('נדרשת כותרת', 'error'); return; }
  if (!date) { notify('נדרש תאריך יעד', 'error'); return; }
  if (!state.milestones) state.milestones = [];
  state.milestones.push({ id: Date.now(), title, targetDate: date, done: false, actualDate: null });
  saveState(); closeModal('modal-milestone'); renderCalendar();
  notify('🚩 אבן דרך נוספה!', 'success');
}

function toggleMilestone(id) {
  const m = (state.milestones || []).find(x => x.id === id);
  if (m) { m.done = !m.done; saveState(); renderCalendar(); }
}

function deleteMilestone(id) {
  state.milestones = (state.milestones || []).filter(m => m.id !== id);
  saveState(); renderCalendar();
}

let _editingMilestoneId = null;

function showMilestoneActualModal(id) {
  const m = (state.milestones || []).find(x => x.id === id);
  if (!m) return;
  _editingMilestoneId = id;
  document.getElementById('milestone-actual-date').value = m.actualDate || m.targetDate;
  openModal('modal-milestone-actual');
}

function saveMilestoneActual() {
  const m = (state.milestones || []).find(x => x.id === _editingMilestoneId);
  if (!m) return;
  const actual = document.getElementById('milestone-actual-date').value;
  m.actualDate = (actual && actual !== m.targetDate) ? actual : null;
  saveState(); closeModal('modal-milestone-actual'); renderCalendar();
}

// ── Meeting plans ──
// state.meetingPlans = [{id, date, title, plan, summary}] — "data" tier (any member).
// A plan is one meeting: what we intend to do, and afterwards what actually happened.
// The value stickies added on that date are shown under it ("the meeting's notes").
let _editingMeetingPlanId = null;

function _meetingForDay(iso) {
  return (state.meetingPlans || []).find(m => m.date === iso) || null;
}

function showMeetingPlanModal(presetDate, id) {
  const existing = id ? (state.meetingPlans || []).find(m => String(m.id) === String(id))
                      : (presetDate ? _meetingForDay(presetDate) : null);
  _editingMeetingPlanId = existing ? existing.id : null;
  document.getElementById('meeting-plan-modal-title').textContent = existing ? '📋 תכנית מפגש' : '📋 מפגש חדש';
  document.getElementById('meeting-plan-date').value = existing ? existing.date : (presetDate || _localIsoToday());
  document.getElementById('meeting-plan-title').value = existing ? existing.title : '';
  document.getElementById('meeting-plan-plan').value = existing ? (existing.plan || '') : '';
  document.getElementById('meeting-plan-summary').value = existing ? (existing.summary || '') : '';
  document.getElementById('meeting-plan-delete').style.display = existing ? '' : 'none';
  closeModal('modal-cal-day');
  openModal('modal-meeting-plan');
  // Past meeting with no summary yet → jump to "מה קרה בפועל".
  if (existing && !String(existing.summary || '').trim() && existing.date <= _localIsoToday()) {
    setTimeout(() => document.getElementById('meeting-plan-summary').focus(), 50);
  }
}

function saveMeetingPlan() {
  const date = document.getElementById('meeting-plan-date').value;
  const title = document.getElementById('meeting-plan-title').value.trim().slice(0, 120);
  const plan = document.getElementById('meeting-plan-plan').value.trim().slice(0, 3000);
  const summary = document.getElementById('meeting-plan-summary').value.trim().slice(0, 3000);
  if (!date) { notify('נדרש תאריך', 'error'); return; }
  if (!title && !plan) { notify('נדרשת כותרת או תכנית', 'error'); return; }
  if (!state.meetingPlans) state.meetingPlans = [];
  const clash = state.meetingPlans.find(m => m.date === date && m.id !== _editingMeetingPlanId);
  if (clash) { notify('כבר יש מפגש בתאריך הזה', 'error'); return; }
  const existing = state.meetingPlans.find(m => m.id === _editingMeetingPlanId);
  if (existing) Object.assign(existing, { date, title, plan, summary });
  else state.meetingPlans.push({ id: Date.now(), date, title, plan, summary });
  saveState(); closeModal('modal-meeting-plan'); renderCalendar(); renderStickyBoard();
  notify('📋 המפגש נשמר', 'success');
}

function deleteMeetingPlan() {
  if (!_editingMeetingPlanId || !confirm('למחוק את תכנית המפגש? הפתקים של אותו יום לא יימחקו.')) return;
  state.meetingPlans = (state.meetingPlans || []).filter(m => m.id !== _editingMeetingPlanId);
  saveState(); closeModal('modal-meeting-plan'); renderCalendar(); renderStickyBoard();
}

function _meetingTitle(m) { return m.title || 'מפגש'; }

// The "מפגשים" card on the calendar screen: a two-sided table —
// right: not summarized yet (oldest first; past ones flagged "חסר סיכום"),
// left: summarized (newest first).
function _meetingRowHtml(m, today) {
  const notes = _stickiesForDay(m.date).length;
  const pending = !String(m.summary || '').trim();
  const overdue = pending && m.date <= today;
  return `
    <div style="padding:10px;border:1px solid var(--border);border-radius:10px;margin-bottom:8px;cursor:pointer;background:var(--surface2)${overdue ? ';border-color:rgba(255,77,109,0.5)' : ''}"
         data-action="show-meeting-plan-modal" data-id="${m.id}">
      <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap">
        <span style="font-weight:700;font-size:13px">📋 ${sanitize(_meetingTitle(m))}</span>
        <span style="background:rgba(61,127,255,0.15);color:var(--accent);border-radius:20px;padding:1px 8px;font-size:11px;font-weight:600">${formatDate(m.date)}</span>
        ${overdue ? `<span style="color:var(--red);font-size:11px;font-weight:700">חסר סיכום</span>` : pending ? `<span style="color:var(--text3);font-size:11px">מתוכנן</span>` : ''}
        ${notes ? `<span style="color:var(--text3);font-size:11px">📌 ${notes}</span>` : ''}
      </div>
      ${!pending ? `<div style="font-size:12px;color:var(--text2);margin-top:4px;white-space:pre-wrap;max-height:3em;overflow:hidden">${sanitize(m.summary)}</div>`
        : m.plan ? `<div style="font-size:12px;color:var(--text3);margin-top:4px;white-space:pre-wrap;max-height:3em;overflow:hidden">${sanitize(m.plan)}</div>` : ''}
      ${overdue ? `<button class="btn btn-ghost" style="margin-top:6px;font-size:12px;padding:4px 10px" data-action="show-meeting-plan-modal" data-id="${m.id}">✍️ כתוב סיכום</button>` : ''}
    </div>`;
}

function renderMeetingPlans() {
  const el = document.getElementById('meeting-plans-list');
  if (el) {
    const today = _localIsoToday();
    const all = state.meetingPlans || [];
    const pending = all.filter(m => !String(m.summary || '').trim()).sort((a, b) => a.date.localeCompare(b.date));
    const done = all.filter(m => String(m.summary || '').trim()).sort((a, b) => b.date.localeCompare(a.date));
    const col = (title, color, items, empty) => `
      <div style="min-width:0">
        <div style="font-weight:800;font-size:13px;color:${color};margin-bottom:8px">${title} (${items.length})</div>
        ${items.length ? items.map(m => _meetingRowHtml(m, today)).join('') : `<div style="color:var(--text3);font-size:12px;padding:8px 0">${empty}</div>`}
      </div>`;
    el.innerHTML = all.length ? `
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:14px">
        ${col('✍️ לא סוכמו', 'var(--accent3)', pending, 'כל המפגשים סוכמו 🎉')}
        ${col('✅ סוכמו', 'var(--accent2)', done, 'עוד אין מפגשים מסוכמים')}
      </div>` : `<div style="color:var(--text3);font-size:13px;padding:12px 0">אין מפגשים עדיין. לחצו על יום בלוח כדי להוסיף תכנית מפגש.</div>`;
  }
  renderMeetingSummaryReminder();
}

// Dashboard reminder: meetings whose date has passed (or is today) with no summary yet.
function renderMeetingSummaryReminder() {
  const card = document.getElementById('dashboard-meeting-reminder');
  if (!card) return;
  const today = _localIsoToday();
  const overdue = (state.meetingPlans || [])
    .filter(m => m.date <= today && !String(m.summary || '').trim())
    .sort((a, b) => a.date.localeCompare(b.date));
  card.style.display = overdue.length ? '' : 'none';
  document.getElementById('dashboard-meeting-reminder-list').innerHTML = overdue.map(m => `
    <div style="display:flex;align-items:center;gap:8px;padding:6px 0;border-bottom:1px solid var(--border)">
      <span style="flex:1;font-size:13px">📋 ${sanitize(_meetingTitle(m))} <span style="color:var(--text3);font-size:12px">· ${formatDate(m.date)}</span></span>
      <button class="btn btn-ghost" style="font-size:12px;padding:4px 10px" data-action="show-meeting-plan-modal" data-id="${m.id}">✍️ כתוב סיכום</button>
    </div>`).join('');
}
