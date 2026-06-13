// ═══════════════════════════════════════════════════════
// § 17 · MEMBER TASKS & MY TASKS
// ═══════════════════════════════════════════════════════
function switchMyTasksTab(tab) {
  document.getElementById('mytasks-panel-pending').style.display = tab === 'pending' ? '' : 'none';
  document.getElementById('mytasks-panel-done').style.display    = tab === 'done'    ? '' : 'none';
  document.getElementById('mytasks-tab-pending').className = tab === 'pending' ? 'btn btn-primary' : 'btn btn-ghost';
  document.getElementById('mytasks-tab-done').className    = tab === 'done'    ? 'btn btn-primary' : 'btn btn-ghost';
  ['mytasks-tab-pending','mytasks-tab-done'].forEach(id => { const b = document.getElementById(id); if (b) b.style.flex = '1'; });
}

function renderMyTasks() {
  const uid = state.currentUser?.id;
  const allTasks = (state.memberTasks || []).filter(t =>
    t.memberId === 'all' || String(t.memberId) === String(uid)
  );
  const pending = allTasks.filter(t => !t.done);
  const done    = allTasks.filter(t =>  t.done);

  const taskHtml = (tasks, isDone) => tasks.length ? tasks.map(t => `
    <div class="card" style="padding:12px 16px;margin-bottom:8px">
      <div style="display:flex;align-items:center;gap:12px">
        <input type="checkbox" ${isDone ? 'checked' : ''} onchange="toggleMemberTask(${t.id})" style="accent-color:var(--accent2);width:20px;height:20px;flex-shrink:0">
        <div style="flex:1">
          <div style="${isDone ? 'text-decoration:line-through;color:var(--text3)' : 'font-weight:600'};font-size:14px">${sanitize(t.desc)}</div>
          <div style="display:flex;gap:8px;margin-top:4px;flex-wrap:wrap">
            ${t.memberId === 'all' ? `<span style="background:var(--accent);color:#fff;border-radius:8px;padding:1px 6px;font-size:11px">👥 לכולם</span>` : ''}
            ${t.due  ? `<span style="color:var(--text3);font-size:12px">📅 ${sanitize(t.due)}</span>` : ''}
            ${t.date ? `<span style="color:var(--text3);font-size:12px">${sanitize(t.date)}</span>` : ''}
          </div>
        </div>
      </div>
    </div>
  `).join('') : `<div style="color:var(--text3);padding:32px;text-align:center;font-size:14px">${isDone ? '✅ אין משימות שהושלמו עדיין' : '🎉 אין משימות פעילות'}</div>`;

  const pEl = document.getElementById('mytasks-list-pending');
  const dEl = document.getElementById('mytasks-list-done');
  if (pEl) pEl.innerHTML = taskHtml(pending, false);
  if (dEl) dEl.innerHTML = taskHtml(done,    true);
}
