// ═══════════════════════════════════════════════════════
// § 11 · RUBRICS — official judging grid (judging room)
// ═══════════════════════════════════════════════════════
// Laid out like FIRST Israel's rubric tool (fll-events.firstisrael.org.il/tools/rubrics).
// state.officialRubric = { marks: { innovation|robot: {fieldId: 1-4} },
//   notes: { innovation|robot: {fieldId: text} }   ← "כיצד הקבוצה הצטיינה?" when marked מצטיינת
//   feedback: { innovation|robot|values: { greatJob, thinkAbout } } }  (admin-data, mentor-only)
let _rubricTab = 'innovation';
const _RUBRIC_TABS = [
  ['innovation', 'פרויקט החדשנות', '#5E82BF'],
  ['robot', 'תכנון הרובוט', '#64AF75'],
  ['values', 'ערכי הליבה', '#E4928B'],
];
// Section-header row color per tab, as on the official site.
const _RUBRIC_SECTION_BG = { innovation: '#D3DAED', robot: '#DAE8D8', values: '#F5DAD4' };

function _officialRubric() {
  if (!state.officialRubric) state.officialRubric = {};
  const r = state.officialRubric;
  ['marks', 'notes'].forEach(k => {
    if (!r[k]) r[k] = {};
    if (!r[k].innovation) r[k].innovation = {};
    if (!r[k].robot) r[k].robot = {};
  });
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

function setRubricNote(cat, fieldId, value) {
  if (!state.isAdmin) return;
  const notes = _officialRubric().notes[cat];
  if (!notes) return;
  notes[fieldId] = String(value).slice(0, 2000);
  saveState();
}

function setRubricFeedback(tab, key, value) {
  if (!state.isAdmin) return;
  const fb = _officialRubric().feedback;
  if (!fb[tab]) fb[tab] = { greatJob: '', thinkAbout: '' };
  fb[tab][key] = String(value).slice(0, 2000);
  saveState();
}

// "איפוס המחוון" — clears the current tab's marks, notes and feedback.
function resetRubricTab() {
  if (!state.isAdmin) return;
  if (!confirm('לאפס את כל הסימונים בתחום השיפוט הזה?')) return;
  const r = _officialRubric();
  _rubricRows(_rubricTab).forEach(({ cat, field }) => {
    delete r.marks[cat][field.id];
    delete r.notes[cat][field.id];
  });
  delete r.feedback[_rubricTab];
  saveState(); renderRubricGrid();
}

function renderRubricGrid() {
  const el = document.getElementById('rubric-grid');
  if (!el) return;
  const tab = _rubricTab;
  const colors = RUBRIC_COLORS[tab];
  const sectionBg = _RUBRIC_SECTION_BG[tab];
  const { marks, notes, feedback } = _officialRubric();
  const ro = state.isAdmin ? '' : ' readonly';

  let html = `
    <div class="rg-top">
      <span class="rg-title">מחווני שיפוט</span>
      ${state.isAdmin ? `<button class="rg-reset" data-action="reset-rubric-tab">איפוס המחוון</button>` : ''}
    </div>
    <div class="rg-card">
      <div class="rg-nav">
        <span class="rg-nav-title">תחומי שיפוט</span>
        ${_RUBRIC_TABS.map(([key, label, dot]) => `
          <button class="rg-chip${key === tab ? ' on' : ''}" data-action="switch-rubric-tab" data-arg="${key}">
            <span class="rg-dot" style="background:${dot}"></span>${label}</button>`).join('')}
      </div>
      ${tab === 'values' ? `<div class="rg-cv-note">ערכי הליבה נשפטים דרך הקריטריונים המסומנים בעיגול מקווקו במחווני פרויקט החדשנות ותכנון הרובוט, ומהווים 25% מהניקוד. סימון כאן הוא אותו סימון כמו שם.</div>` : ''}
      <div class="rg-scroll"><div class="rg-table">
        <div class="rg-row rg-head">${RUBRIC_LEVELS.map((l, i) =>
          `<div class="rg-cell" style="background:${colors[i]}">${l}</div>`).join('')}</div>`;

  let lastSection = null;
  _rubricRows(tab).forEach(({ cat, section, field }) => {
    const sectionKey = cat + '.' + section.id;
    if (sectionKey !== lastSection) {
      lastSection = sectionKey;
      const prefix = tab === 'values' ? `${RUBRIC_GRID[cat].title} · ` : '';
      html += `<div class="rg-section" style="background:${sectionBg}"><b>${prefix}${section.title}</b>&nbsp; - &nbsp;${section.description}</div>`;
    }
    const current = marks[cat][field.id] || 0;
    html += `<div class="rg-row">${[1, 2, 3, 4].map(level => {
      const on = current === level;
      const text = field.levels[level - 1] || '';
      return `<div class="rg-cell rg-option${text ? '' : ' rg-empty'}" data-action="set-rubric-mark" data-category="${cat}" data-field="${field.id}" data-score="${level}">
        <span class="rg-radio${field.coreValues ? ' cv' : ''}${on ? ' on' : ''}"></span>${text ? `<span>${text}</span>` : ''}</div>`;
    }).join('')}</div>`;
    if (current === 4) {
      html += `<div class="rg-notes">
        <label>הערות</label>
        <textarea rows="2" placeholder="כיצד הקבוצה הצטיינה?" data-onchange="set-rubric-note" data-category="${cat}" data-field="${field.id}"${ro}>${sanitize(notes[cat][field.id] || '')}</textarea>
      </div>`;
    }
  });

  const fb = feedback[tab] || {};
  html += `
        <div class="rg-fb-head" style="background:${sectionBg}"><div>עבודה מצוינת......</div><div>חשבו על......</div></div>
        <div class="rg-fb-body">
          <textarea rows="5" placeholder="עבודה מצוינת..." data-onchange="set-rubric-feedback" data-category="${tab}" data-field="greatJob"${ro}>${sanitize(fb.greatJob || '')}</textarea>
          <textarea rows="5" placeholder="חשבו על..." data-onchange="set-rubric-feedback" data-category="${tab}" data-field="thinkAbout"${ro}>${sanitize(fb.thinkAbout || '')}</textarea>
        </div>
      </div></div>
    </div>`;
  el.innerHTML = html;
}
