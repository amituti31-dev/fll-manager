// ═══════════════════════════════════════════════════════
// § 08 · DAILY LOGS
// ═══════════════════════════════════════════════════════
function renderTimeline(filter = '', search = '') {
  const container = document.getElementById('timeline-container');
  let items = [...state.logs].reverse();
  if (filter) items = items.filter(l => l.topic === filter);
  if (search) items = items.filter(l => l.text.includes(search) || l.author.includes(search));
  if (!items.length) {
    container.innerHTML = `<div style="text-align:center;padding:40px;color:var(--text3)"><div style="font-size:36px">📝</div><div style="margin-top:8px">אין עדיין תיעוד. לחץ "+ עדכון חדש"</div></div>`;
    return;
  }
  container.innerHTML = items.map(l => `
    <div class="timeline-item">
      <div class="timeline-dot"></div>
      <div class="timeline-content">
        <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
          <div style="flex:1">
            <div class="timeline-meta">${sanitize(l.author)} · ${formatDate(l.date)}</div>
            <div class="timeline-text">${sanitize(l.text)}</div>
            ${l.image && l.image.startsWith('data:image') ? `<div style="margin-top:10px"><img src="${l.image}" alt="תמונה מצורפת" style="max-width:100%;max-height:260px;border-radius:10px;object-fit:cover;cursor:pointer;border:1px solid var(--border)" onclick="this.style.maxHeight=this.style.maxHeight==='none'?'260px':'none'" title="לחץ להגדלה"></div>` : ''}
            <span class="timeline-tag tag-${sanitize(l.topic)}">${topicLabel(l.topic)}</span>
          </div>
          ${state.isAdmin ? `
          <div style="display:flex;gap:2px;flex-shrink:0;margin-top:2px">
            <button onclick="editLog(${l.id})" style="background:none;border:none;cursor:pointer;color:var(--accent);font-size:15px;padding:4px" title="ערוך">✏️</button>
            <button onclick="deleteLog(${l.id})" style="background:none;border:none;cursor:pointer;color:var(--red);font-size:15px;padding:4px" title="מחק">🗑️</button>
          </div>` : ''}
        </div>
      </div>
    </div>
  `).join('');
}

function renderRecentLogs() {
  const el = document.getElementById('recent-logs');
  const items = [...state.logs].reverse().slice(0, 3);
  el.innerHTML = items.map(l => `
    <div class="timeline-item">
      <div class="timeline-dot"></div>
      <div class="timeline-content">
        <div class="timeline-meta">${sanitize(l.author)} · ${formatDate(l.date)}</div>
        <div class="timeline-text">${sanitize(l.text)}</div>
        ${l.image && l.image.startsWith('data:image') ? `<div style="margin-top:8px"><img src="${l.image}" alt="תמונה מצורפת" style="max-width:100%;max-height:160px;border-radius:10px;object-fit:cover;border:1px solid var(--border)"></div>` : ''}
        <span class="timeline-tag tag-${sanitize(l.topic)}">${topicLabel(l.topic)}</span>
      </div>
    </div>
  `).join('');
}

function filterLogs() {
  renderTimeline(document.getElementById('log-filter').value, document.getElementById('log-search').value);
}

function topicLabel(t) {
  return { robot: '🤖 רובוט', innovation: '💡 חדשנות', values: '⭐ ערכים', general: '📌 כללי' }[t] || t;
}
function formatDate(d) { return new Date(d).toLocaleDateString('he-IL'); }

// ── Logs ──
function showAddLogModal() { openModal('modal-log'); }
function saveLog() {
  const text = document.getElementById('log-text').value.trim().slice(0, 2000);
  if (!text) { notify('נא להוסיף תוכן', 'error'); return; }
  const allowedTopics = ['general', 'robot', 'innovation', 'values'];
  const topic = document.getElementById('log-topic').value;
  if (!allowedTopics.includes(topic)) { notify('נושא לא תקין', 'error'); return; }

  const fileInput = document.getElementById('log-image');
  const file = fileInput ? fileInput.files[0] : null;
  const logEntry = {
    id: Date.now(), topic, text,
    author: state.currentUser?.name || 'אנונימי',
    date: new Date().toISOString().split('T')[0],
    image: null,
  };

  const finish = () => {
    state.logs.push(logEntry);
    saveState(); closeModal('modal-log');
    document.getElementById('log-text').value = '';
    if (fileInput) fileInput.value = '';
    renderTimeline(); renderRecentLogs(); updateStats();
    notify('✅ תיעוד נשמר', 'success');
  };

  if (file) {
    const reader = new FileReader();
    reader.onload = e => { logEntry.image = e.target.result; finish(); };
    reader.readAsDataURL(file);
  } else { finish(); }
}

// ── Log edit / delete ──
function deleteLog(id) {
  if (!state.isAdmin) return;
  if (!confirm('למחוק את הרשומה לצמיתות?')) return;
  state.logs = state.logs.filter(l => l.id !== id);
  saveState(); renderTimeline(); renderRecentLogs(); updateStats();
  notify('🗑️ רשומה נמחקה', 'success');
}

function editLog(id) {
  if (!state.isAdmin) return;
  const log = state.logs.find(l => l.id === id);
  if (!log) return;
  const overlay = document.createElement('div');
  overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:1000;display:flex;align-items:center;justify-content:center;padding:16px';
  overlay.innerHTML = `
    <div style="background:var(--surface);border-radius:16px;padding:24px;width:100%;max-width:500px;border:1px solid var(--border)">
      <div style="font-weight:800;font-size:18px;margin-bottom:16px">✏️ עריכת רשומה</div>
      <div class="form-group">
        <label class="form-label">נושא</label>
        <select class="form-input" id="edit-log-topic">
          <option value="general" ${log.topic==='general'?'selected':''}>📌 כללי</option>
          <option value="robot" ${log.topic==='robot'?'selected':''}>🤖 רובוט</option>
          <option value="innovation" ${log.topic==='innovation'?'selected':''}>💡 חדשנות</option>
          <option value="values" ${log.topic==='values'?'selected':''}>⭐ ערכים</option>
        </select>
      </div>
      <div class="form-group" style="margin-top:12px">
        <label class="form-label">תוכן</label>
        <textarea class="form-input" id="edit-log-text" rows="5" style="resize:vertical">${log.text.replace(/</g,'&lt;').replace(/>/g,'&gt;')}</textarea>
      </div>
      <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:16px">
        <button class="btn btn-ghost" onclick="this.closest('[style*=fixed]').remove()">ביטול</button>
        <button class="btn btn-primary" onclick="
          const txt = document.getElementById('edit-log-text').value.trim().slice(0,2000);
          const top = document.getElementById('edit-log-topic').value;
          if (!txt) return;
          const entry = state.logs.find(l => l.id === ${id});
          if (entry) { entry.text = txt; entry.topic = top; }
          saveState(); renderTimeline(); renderRecentLogs();
          this.closest('[style*=fixed]').remove();
          notify('✅ רשומה עודכנה', 'success');
        ">💾 שמור</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.remove(); });
}
