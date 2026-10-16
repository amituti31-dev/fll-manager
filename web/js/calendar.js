// ═══════════════════════════════════════════════════════
// § 31 · CALENDAR (meetings & milestones)
// ═══════════════════════════════════════════════════════
let _editingMeetingId = null;
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

function _chipsForDay(iso) {
  const chips = [];
  (state.meetings || []).forEach(m => {
    if (m.plannedDate === iso) chips.push({ icon: '🗓️', text: m.title, color: '#3d7fff' });
    if (m.actualDate === iso) chips.push({ icon: '✅', text: m.title, color: '#00d4a0' });
  });
  (state.milestones || []).forEach(m => {
    if (m.targetDate === iso) chips.push({ icon: '🚩', text: m.title, color: '#f5c842' });
    if (m.actualDate === iso) chips.push({ icon: '✅', text: m.title, color: '#00d4a0' });
  });
  return chips;
}

// Google-Calendar-style grid: a full rectangle (greyed leading/trailing days
// from adjacent months fill it out), each cell showing small colored event
// chips (not just dots), a "+N" overflow, and a circular today marker.
function renderMonthGrid() {
  const label = document.getElementById('cal-month-label');
  const weekdayRow = document.getElementById('cal-weekday-row');
  const grid = document.getElementById('cal-grid');
  if (!label || !grid) return;

  const y = _calMonth.getFullYear(), m = _calMonth.getMonth();
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
           white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-bottom:1px">${c.icon} ${sanitize(c.text)}</div>
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
  const meetings = (state.meetings || []).filter(m => m.plannedDate === iso || m.actualDate === iso);
  const milestones = (state.milestones || []).filter(m => m.targetDate === iso || m.actualDate === iso);
  document.getElementById('cal-day-title').textContent = `📅 ${formatDate(iso)}`;
  const itemsHtml = [
    ...meetings.map(m => `<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:14px">🗓️ ${sanitize(m.title)}</div>`),
    ...milestones.map(m => `<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:14px">🚩 ${sanitize(m.title)}</div>`),
  ].join('');
  document.getElementById('cal-day-items').innerHTML = itemsHtml ||
    `<div style="color:var(--text3);font-size:13px;padding:6px 0">אין פריטים ביום הזה</div>`;
  document.getElementById('cal-day-add-meeting').dataset.arg = iso;
  document.getElementById('cal-day-add-milestone').dataset.arg = iso;
  openModal('modal-cal-day');
}

function renderCalendar() {
  renderMonthGrid();
  const meetingsEl = document.getElementById('meetings-list');
  const milestonesEl = document.getElementById('milestones-list');
  if (!meetingsEl || !milestonesEl) return;

  const meetings = [...(state.meetings || [])].sort((a, b) => a.plannedDate.localeCompare(b.plannedDate));
  const milestones = [...(state.milestones || [])].sort((a, b) => a.targetDate.localeCompare(b.targetDate));

  meetingsEl.innerHTML = meetings.length ? meetings.map(m => {
    const changed = m.actualDate && m.actualDate !== m.plannedDate;
    return `
      <div style="display:flex;align-items:flex-start;gap:10px;padding:10px 0;border-bottom:1px solid var(--border)">
        <div style="flex:1">
          <div style="font-weight:700;font-size:14px">${sanitize(m.title)}</div>
          <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:6px">
            <span style="background:rgba(61,127,255,0.15);color:var(--accent);border-radius:20px;padding:3px 10px;font-size:11px;font-weight:600">📅 מתוכנן: ${formatDate(m.plannedDate)}</span>
            <span style="cursor:pointer;background:${changed ? 'rgba(0,212,160,0.15)' : 'rgba(255,255,255,0.06)'};color:${changed ? 'var(--accent2)' : 'var(--text3)'};border-radius:20px;padding:3px 10px;font-size:11px;font-weight:600" data-action="show-meeting-actual-modal" data-id="${m.id}">${changed ? `✅ בפועל: ${formatDate(m.actualDate)}` : '➕ סמן תאריך בפועל'}</span>
          </div>
          ${m.notes ? `<div style="font-size:12px;color:var(--text2);margin-top:6px">${sanitize(m.notes)}</div>` : ''}
        </div>
        <button data-action="delete-meeting" data-id="${m.id}" style="background:none;border:none;color:var(--text3);cursor:pointer;font-size:16px">✕</button>
      </div>`;
  }).join('') : `<div style="color:var(--text3);font-size:13px;padding:12px 0">אין מפגשים מתוכננים עדיין</div>`;

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

// ── Meetings ──
function showAddMeetingModal(presetDate) {
  document.getElementById('meeting-title').value = '';
  document.getElementById('meeting-date').value = presetDate || new Date().toISOString().split('T')[0];
  document.getElementById('meeting-notes').value = '';
  closeModal('modal-cal-day');
  openModal('modal-meeting');
}

function saveMeeting() {
  const title = document.getElementById('meeting-title').value.trim();
  const date = document.getElementById('meeting-date').value;
  if (!title) { notify('נדרש נושא למפגש', 'error'); return; }
  if (!date) { notify('נדרש תאריך', 'error'); return; }
  if (!state.meetings) state.meetings = [];
  state.meetings.push({
    id: Date.now(),
    title,
    plannedDate: date,
    actualDate: null,
    notes: document.getElementById('meeting-notes').value.trim(),
  });
  saveState(); closeModal('modal-meeting'); renderCalendar();
  notify('🗓️ מפגש נוסף!', 'success');
}

function deleteMeeting(id) {
  state.meetings = (state.meetings || []).filter(m => m.id !== id);
  saveState(); renderCalendar();
}

function showMeetingActualModal(id) {
  const m = (state.meetings || []).find(x => x.id === id);
  if (!m) return;
  _editingMeetingId = id;
  document.getElementById('meeting-actual-date').value = m.actualDate || m.plannedDate;
  openModal('modal-meeting-actual');
}

function saveMeetingActual() {
  const m = (state.meetings || []).find(x => x.id === _editingMeetingId);
  if (!m) return;
  const actual = document.getElementById('meeting-actual-date').value;
  m.actualDate = (actual && actual !== m.plannedDate) ? actual : null;
  saveState(); closeModal('modal-meeting-actual'); renderCalendar();
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
