// ═══════════════════════════════════════════════════════
// § 18 · VALUES & STICKY NOTES
// ═══════════════════════════════════════════════════════
function switchValuesTab(tab) {
  document.getElementById('values-panel-rubrics').style.display = tab === 'rubrics' ? '' : 'none';
  document.getElementById('values-panel-sticky').style.display  = tab === 'sticky'  ? '' : 'none';
  document.getElementById('values-tab-rubrics').className = tab === 'rubrics' ? 'btn btn-primary' : 'btn btn-ghost';
  document.getElementById('values-tab-sticky').className  = tab === 'sticky'  ? 'btn btn-primary' : 'btn btn-ghost';
  ['values-tab-rubrics','values-tab-sticky'].forEach(id => { const b = document.getElementById(id); if (b) b.style.flex = '1'; });
}
