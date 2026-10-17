// ═══════════════════════════════════════════════════════
// § 11 · RUBRICS — official judging grid (judging room)
// ═══════════════════════════════════════════════════════
// Marks live in state.officialRubric = { marks: { innovation: {fieldId: 1-4}, robot: {...} },
// feedback: { innovation|robot|values: { greatJob, thinkAbout } } } (admin-data, mentor-only).
let _rubricTab = 'innovation';
const _RUBRIC_TABS = [
  ['innovation', '💡 פרויקט החדשנות'],
  ['robot', '🤖 תכנון הרובוט'],
  ['values', '⭐ ערכי הליבה'],
];

function _officialRubric() {
  if (!state.officialRubric) state.officialRubric = {};
  const r = state.officialRubric;
  if (!r.marks) r.marks = {};
  if (!r.marks.innovation) r.marks.innovation = {};
  if (!r.marks.robot) r.marks.robot = {};
  if (!r.feedback) r.feedback = {};
  return r;
}

// [{cat, section, field}] — every criterion shown on a tab. The core-values
// tab is the flagged criteria of the other two, so a mark there is the same mark.
function _rubricRows(tab) {
  const rows = [];
  const cats = tab === 'values' ? ['innovation', 'robot'] : [tab];
  cats.forEach(cat => RUBRIC_GRID[cat].sections.forEach(section => section.fields.forEach(field => {
    if (tab !== 'values' || field.coreValues) rows.push({ cat, section, field });
  })));
  return rows;
}

// 0..1 — average marked level out of 4 (unmarked criteria count as 0).
function rubricRatio(tab) {
  const rows = _rubricRows(tab);
  const marks = _officialRubric().marks;
  const sum = rows.reduce((a, r) => a + (marks[r.cat][r.field.id] || 0), 0);
  return rows.length ? sum / (rows.length * 4) : 0;
}

function switchRubricTab(tab) {
  _rubricTab = tab;
  renderRubricGrid();
}

function setRubricMark(cat, fieldId, level) {
  if (!state.isAdmin) { notify('רק מנטור יכול לסמן במחוון', 'error'); return; }
  const marks = _officialRubric().marks[cat];
  if (!marks) return;
  // Clicking the selected level again clears it.
  if (marks[fieldId] === level) delete marks[fieldId]; else marks[fieldId] = level;
  saveState(); renderRubricGrid();
}

function setRubricFeedback(tab, key, value) {
  if (!state.isAdmin) return;
  const fb = _officialRubric().feedback;
  if (!fb[tab]) fb[tab] = { greatJob: '', thinkAbout: '' };
  fb[tab][key] = String(value).slice(0, 2000);
  saveState();
}

function renderRubricGrid() {
  const tabsEl = document.getElementById('rubric-tabs');
  const gridEl = document.getElementById('rubric-grid');
  if (!tabsEl || !gridEl) return;
  const tab = _rubricTab;
  const colors = RUBRIC_COLORS[tab];
  const { marks, feedback } = _officialRubric();
  const rows = _rubricRows(tab);
  const marked = rows.filter(r => marks[r.cat][r.field.id]).length;

  tabsEl.innerHTML = _RUBRIC_TABS.map(([key, label]) =>
    `<button class="btn ${key === tab ? 'btn-primary' : 'btn-ghost'}" style="flex:1;font-size:13px" data-action="switch-rubric-tab" data-arg="${key}">${label}</button>`
  ).join('');

  let html = `<div class="rg-summary">סומנו ${marked} מתוך ${rows.length} קריטריונים${state.isAdmin ? '' : ' · רק מנטור יכול לסמן'}</div>`;
  if (tab === 'values') {
    html += `<div class="rg-note">ערכי הליבה נשפטים דרך הקריטריונים המסומנים בעיגול מקווקו בשני המחוונים האחרים (25% מהניקוד). סימון כאן הוא אותו סימון כמו שם.</div>`;
  }
  html += `<div class="rg-scroll"><div class="rg-table">`;
  html += `<div class="rg-row rg-head">${RUBRIC_LEVELS.map((l, i) =>
    `<div class="rg-cell" style="background:${colors[i]}">${l}</div>`).join('')}</div>`;

  let lastSection = null;
  rows.forEach(({ cat, section, field }) => {
    const sectionKey = cat + '.' + section.id;
    if (sectionKey !== lastSection) {
      lastSection = sectionKey;
      const prefix = tab === 'values' ? `${RUBRIC_GRID[cat].title} · ` : '';
      html += `<div class="rg-section" style="background:${colors[0]}"><b>${prefix}${section.title}</b> - ${section.description}</div>`;
    }
    const current = marks[cat][field.id] || 0;
    html += `<div class="rg-row">${[1, 2, 3, 4].map(level => {
      const on = current === level;
      const text = field.levels[level - 1] || '';
      return `<div class="rg-cell rg-option${on ? ' on' : ''}" style="${on ? `background:${colors[level - 1]};color:#1a1f36` : ''}"
        data-action="set-rubric-mark" data-category="${cat}" data-field="${field.id}" data-score="${level}">
        <span class="rg-radio${field.coreValues ? ' cv' : ''}">${on ? '●' : ''}</span><span>${text}</span></div>`;
    }).join('')}</div>`;
  });
  html += `</div></div>`;

  const fb = feedback[tab] || {};
  const ro = state.isAdmin ? '' : ' readonly';
  html += `
    <div class="rg-feedback">
      <label class="form-label">עבודה מצוינת...</label>
      <textarea class="form-input" rows="2" data-onchange="set-rubric-feedback" data-category="${tab}" data-field="greatJob"${ro}>${sanitize(fb.greatJob || '')}</textarea>
      <label class="form-label" style="margin-top:8px">חשבו על...</label>
      <textarea class="form-input" rows="2" data-onchange="set-rubric-feedback" data-category="${tab}" data-field="thinkAbout"${ro}>${sanitize(fb.thinkAbout || '')}</textarea>
    </div>`;
  gridEl.innerHTML = html;
}
