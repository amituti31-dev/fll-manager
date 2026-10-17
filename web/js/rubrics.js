// ═══════════════════════════════════════════════════════
// § 11 · RUBRICS
// ═══════════════════════════════════════════════════════
function renderRubrics(cat) {
  const rubrics = state.rubrics[cat] || [];
  const html = rubrics.map(r => `
    <div class="rubric-item">
      <div class="rubric-q">${sanitize(r.q)}</div>
      <div class="score-group">
        ${[1,2,3,4].map(s => `<button class="score-btn ${r.score === s ? 'active' : ''}" data-action="set-score" data-category="${sanitize(cat)}" data-id="${Number(r.id)}" data-score="${s}">${s}<br><small style="font-weight:400">${scoreLabel(s)}</small></button>`).join('')}
      </div>
      <div class="rubric-notes">
        <textarea class="form-input" rows="2" placeholder="הערות..." data-onchange="set-notes" data-category="${sanitize(cat)}" data-id="${Number(r.id)}" style="font-size:12px">${sanitize(r.notes)}</textarea>
      </div>
      ${state.isAdmin ? `<button data-action="delete-rubric" data-category="${sanitize(cat)}" data-id="${Number(r.id)}" style="background:none;border:none;color:var(--red);cursor:pointer;font-size:13px;margin-top:4px">🗑️ מחק</button>` : ''}
    </div>
  `).join('') || '<div style="color:var(--text3);padding:20px;text-align:center">אין שאלות עדיין. הוסף שאלות או ייבא מחוון רשמי.</div>';

  // All rubrics live in one place — the judging room (scoring screen).
  const scoringEl = document.getElementById(`scoring-${cat}-rubrics`);
  if (scoringEl) scoringEl.innerHTML = html;
}

function scoreLabel(s) { return ['','מתחילה','מתפתחת','מיומנת','מצטיינת'][s]; }

function setScore(cat, id, score) {
  const r = state.rubrics[cat]?.find(r => r.id === id);
  if (r) { r.score = score; saveState(); renderRubrics(cat); }
}
function setNotes(cat, id, notes) {
  const r = state.rubrics[cat]?.find(r => r.id === id);
  if (r) { r.notes = notes; saveState(); }
}
function deleteRubric(cat, id) {
  state.rubrics[cat] = state.rubrics[cat].filter(r => r.id !== id);
  saveState(); renderRubrics(cat);
}

// Returns {added, removed}; caller saves/renders/notifies.
function _mergeOfficialRubric(cat) {
  // Drop the old made-up default criteria (kept if the team wrote notes on them).
  const legacy = new Set(LEGACY_RUBRIC_TEXTS);
  const before = state.rubrics[cat].length;
  state.rubrics[cat] = state.rubrics[cat].filter(r => !legacy.has(r.q) || (r.notes || '').trim());
  const removed = before - state.rubrics[cat].length;
  const existing = new Set(state.rubrics[cat].map(r => r.q));
  let added = 0;
  OFFICIAL_RUBRICS[cat].forEach(q => {
    if (!existing.has(q)) { state.rubrics[cat].push({ id: Date.now() + Math.random(), q, score: 0, notes: '' }); added++; }
  });
  return { added, removed };
}

function _notifyRubricImport(added, removed) {
  notify(added || removed
    ? `✅ נוספו ${added} קריטריונים רשמיים${removed ? ` (הוסרו ${removed} ישנים)` : ''}`
    : 'כל הקריטריונים כבר קיימים', 'success');
}

function importOfficialRubric(cat) {
  const { added, removed } = _mergeOfficialRubric(cat);
  saveState(); renderRubrics(cat);
  _notifyRubricImport(added, removed);
}

function importAllOfficialRubrics() {
  let added = 0, removed = 0;
  ['innovation', 'robot', 'values'].forEach(cat => {
    const r = _mergeOfficialRubric(cat);
    added += r.added; removed += r.removed;
    renderRubrics(cat);
  });
  saveState();
  _notifyRubricImport(added, removed);
}

function addCustomRubric(cat) { state.pendingRubricCategory = cat; openModal('modal-rubric'); }
function saveRubric() {
  const q = document.getElementById('rubric-question').value.trim().slice(0, 500);
  if (!q) { notify('נדרשת שאלה', 'error'); return; }
  const cat = state.pendingRubricCategory;
  state.rubrics[cat].push({ id: Date.now(), q, score: 0, notes: '' });
  saveState(); closeModal('modal-rubric'); renderRubrics(cat);
  document.getElementById('rubric-question').value = '';
  notify('✅ שאלה נוספה', 'success');
}
