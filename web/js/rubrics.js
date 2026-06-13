// ═══════════════════════════════════════════════════════
// § 11 · RUBRICS
// ═══════════════════════════════════════════════════════
function renderRubrics(cat) {
  const rubrics = state.rubrics[cat] || [];
  const total = rubrics.length * 4;
  const scored = rubrics.reduce((a, r) => a + (r.score || 0), 0);
  const pct = total ? Math.round((scored / total) * 100) : 0;

  if (cat === 'values') {
    const pctEl = document.getElementById('values-pct');
    const progEl = document.getElementById('values-progress');
    if (pctEl) pctEl.textContent = pct + '%';
    if (progEl) progEl.style.width = pct + '%';
  }

  const html = rubrics.map(r => `
    <div class="rubric-item">
      <div class="rubric-q">${sanitize(r.q)}</div>
      <div class="score-group">
        ${[1,2,3,4].map(s => `<button class="score-btn ${r.score === s ? 'active' : ''}" onclick="setScore('${sanitize(cat)}',${Number(r.id)},${s})">${s}<br><small style="font-weight:400">${scoreLabel(s)}</small></button>`).join('')}
      </div>
      <div class="rubric-notes">
        <textarea class="form-input" rows="2" placeholder="הערות..." onchange="setNotes('${sanitize(cat)}',${Number(r.id)},this.value)" style="font-size:12px">${sanitize(r.notes)}</textarea>
      </div>
      ${state.isAdmin ? `<button onclick="deleteRubric('${sanitize(cat)}',${Number(r.id)})" style="background:none;border:none;color:var(--red);cursor:pointer;font-size:13px;margin-top:4px">🗑️ מחק</button>` : ''}
    </div>
  `).join('') || '<div style="color:var(--text3);padding:20px;text-align:center">אין שאלות עדיין. הוסף שאלות או ייבא מחוון רשמי.</div>';

  const mainEl = document.getElementById(`${cat === 'values' ? 'values' : cat}-rubrics`);
  if (mainEl) mainEl.innerHTML = html;
  const scoringEl = document.getElementById(`scoring-${cat}-rubrics`);
  if (scoringEl) scoringEl.innerHTML = html;
}

function scoreLabel(s) { return ['','מתחיל','מתפתח','מוצלח','מצטיין'][s]; }

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

function importOfficialRubric(cat) {
  const existing = new Set(state.rubrics[cat].map(r => r.q));
  let added = 0;
  OFFICIAL_RUBRICS[cat].forEach(q => {
    if (!existing.has(q)) { state.rubrics[cat].push({ id: Date.now() + Math.random(), q, score: 0, notes: '' }); added++; }
  });
  saveState(); renderRubrics(cat);
  notify(added ? `✅ נוספו ${added} קריטריונים` : 'כל הקריטריונים כבר קיימים', 'success');
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
