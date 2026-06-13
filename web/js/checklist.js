// ═══════════════════════════════════════════════════════
// § 21 · CHECKLIST
// ═══════════════════════════════════════════════════════
function renderChecklist() {
  const el = document.getElementById('competition-checklist');
  if (!el) return;
  el.innerHTML = state.checklist.map(c => `
    <div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--border)">
      <input type="checkbox" style="width:18px;height:18px;accent-color:var(--accent2)" ${c.done ? 'checked' : ''} onchange="toggleChecklist(${c.id})">
      <span style="font-size:14px;${c.done ? 'text-decoration:line-through;color:var(--text3)' : ''}">${c.text}</span>
      <button onclick="removeChecklistItem(${c.id})" style="background:none;border:none;color:var(--text3);cursor:pointer;margin-right:auto">✕</button>
    </div>
  `).join('');
}

function toggleChecklist(id) {
  const item = state.checklist.find(c => c.id === id);
  if (item) { item.done = !item.done; saveState(); renderChecklist(); }
}
function addChecklistItem() {
  const text = prompt('שם פריט חדש:'); if (!text) return;
  state.checklist.push({ id: Date.now(), text, done: false });
  saveState(); renderChecklist();
}
function removeChecklistItem(id) {
  state.checklist = state.checklist.filter(c => c.id !== id);
  saveState(); renderChecklist();
}
