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
  const leading = new Date(y, m, 1).getDay(); // 0=Sunday already
  const today = new Date();
  const todayIso = _isoLocal(today.getFullYear(), today.getMonth(), today.getDate());

  const meetings = state.meetings || [];
  const milestones = state.milestones || [];

  let html = '';
  for (let i = 0; i < leading; i++) html += '<div></div>';
  for (let d = 1; d <= daysInMonth; d++) {
    const iso = _isoLocal(y, m, d);
    const isToday = iso === todayIso;
    const planned = meetings.filter(mt => mt.plannedDate === iso);
    const actual = meetings.filter(mt => mt.actualDate === iso);
    const dayMilestones = milestones.filter(ms => ms.targetDate === iso);
    const hasItems = planned.length || actual.length || dayMilestones.length;
    const dots = [
      planned.length ? '<span style="width:5px;height:5px;border-radius:50%;background:#3d7fff;display:inline-block"></span>' : '',
      actual.length ? '<span style="width:5px;height:5px;border-radius:50%;background:#00d4a0;display:inline-block"></span>' : '',
      dayMilestones.length ? '<span style="width:5px;height:5px;border-radius:50%;background:#f5c842;display:inline-block"></span>' : '',
    ].join('');
    html += `
      <div ${hasItems ? `data-action="show-cal-day" data-arg="${iso}" style="cursor:pointer"` : ''}
           style="aspect-ratio:1;display:flex;flex-direction:column;align-items:center;justify-content:center;border-radius:8px;
             ${isToday ? 'background:rgba(61,127,255,0.15);border:1.2px solid var(--accent)' : ''}">
        <span style="font-size:12px;font-weight:${isToday ? '800' : '500'};color:${isToday ? 'var(--accent)' : 'var(--text)'}">${d}</span>
        ${hasItems ? `<div style="display:flex;gap:2px;margin-top:2px">${dots}</div>` : ''}
      </div>`;
  }
  grid.innerHTML = html;
}

function showCalDay(iso) {
  const meetings = (state.meetings || []).filter(m => m.plannedDate === iso || m.actualDate === iso);
  const milestones = (state.milestones || []).filter(m => m.targetDate === iso);
  if (!meetings.length && !milestones.length) return;
  document.getElementById('cal-day-title').textContent = `📅 ${formatDate(iso)}`;
  document.getElementById('cal-day-items').innerHTML = [
    ...meetings.map(m => `<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:14px">🗓️ ${sanitize(m.title)}</div>`),
    ...milestones.map(m => `<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:14px">🚩 ${sanitize(m.title)}</div>`),
  ].join('');
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

  milestonesEl.innerHTML = milestones.length ? milestones.map(m => `
      <div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--border)">
        <input type="checkbox" style="width:18px;height:18px;accent-color:var(--accent2)" ${m.done ? 'checked' : ''} data-onchange="toggle-milestone" data-id="${m.id}">
        <span style="flex:1;font-size:14px;${m.done ? 'text-decoration:line-through;color:var(--text3)' : ''}">${sanitize(m.title)}</span>
        <span style="font-size:12px;color:var(--text3)">${formatDate(m.targetDate)}</span>
        <button data-action="delete-milestone" data-id="${m.id}" style="background:none;border:none;color:var(--text3);cursor:pointer">✕</button>
      </div>`).join('') : `<div style="color:var(--text3);font-size:13px;padding:12px 0">אין אבני דרך עדיין</div>`;
}

// ── Meetings ──
function showAddMeetingModal() {
  document.getElementById('meeting-title').value = '';
  document.getElementById('meeting-date').value = new Date().toISOString().split('T')[0];
  document.getElementById('meeting-notes').value = '';
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
function showAddMilestoneModal() {
  document.getElementById('milestone-title').value = '';
  const inWeek = new Date(); inWeek.setDate(inWeek.getDate() + 7);
  document.getElementById('milestone-date').value = inWeek.toISOString().split('T')[0];
  openModal('modal-milestone');
}

function saveMilestone() {
  const title = document.getElementById('milestone-title').value.trim();
  const date = document.getElementById('milestone-date').value;
  if (!title) { notify('נדרשת כותרת', 'error'); return; }
  if (!date) { notify('נדרש תאריך יעד', 'error'); return; }
  if (!state.milestones) state.milestones = [];
  state.milestones.push({ id: Date.now(), title, targetDate: date, done: false });
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
