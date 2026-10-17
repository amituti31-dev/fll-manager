// ═══════════════════════════════════════════════════════
// § 08 · DAILY LOGS
// ═══════════════════════════════════════════════════════
// A log has a topics checklist (at least one) and a core-values checklist (at
// least one). `topic` is kept = the first topic, for older app versions.
const LOG_TOPICS = [['general', '📌 כללי'], ['robot', '🤖 רובוט'], ['innovation', '💡 חדשנות'], ['values', '⭐ ערכים']];
const LOG_VALUES = ['discovery', 'innovation', 'impact', 'inclusion', 'teamwork', 'fun'];

// Android saves innovation research / ideas / community sharing as log entries
// with these topics — they belong to the innovation screen, not the daily log.
const INNOVATION_LOG_TOPICS = ['research', 'ideas', 'sharing'];
function isInnovationLog(l) { return INNOVATION_LOG_TOPICS.includes(l.topic); }
function dailyLogs() { return (state.logs || []).filter(l => !isInnovationLog(l)); }

function logTopics(l) { return (l.topics && l.topics.length) ? l.topics : [l.topic || 'general']; }

function _checkChipsHtml(group, options, selected) {
  return options.map(([value, label]) =>
    `<label class="check-chip"><input type="checkbox" data-group="${group}" value="${value}" ${selected.includes(value) ? 'checked' : ''}> ${label}</label>`).join('');
}
function _checkedValues(container, group) {
  return [...container.querySelectorAll(`input[data-group="${group}"]:checked`)].map(i => i.value);
}
function _logValueOptions() { return LOG_VALUES.map(v => [v, STICKY_VALUES[v].label]); }

function logTagsHtml(l) {
  const topics = logTopics(l).map(t => `<span class="timeline-tag tag-${sanitize(t)}">${topicLabel(t)}</span>`).join(' ');
  const values = (l.values || []).filter(v => STICKY_VALUES[v]).map(v =>
    `<span class="timeline-tag" style="background:${STICKY_VALUES[v].bg}22;color:${STICKY_VALUES[v].bg}">${STICKY_VALUES[v].label}</span>`).join(' ');
  return `<div style="display:flex;gap:4px;flex-wrap:wrap;margin-top:6px">${topics} ${values}</div>`;
}

function renderTimeline(filter = '', search = '') {
  const container = document.getElementById('timeline-container');
  let items = [...dailyLogs()].reverse();
  if (filter) items = items.filter(l => logTopics(l).includes(filter));
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
            ${imageSrc(l.image) ? `<div style="margin-top:10px"><img src="${imageSrc(l.image)}" alt="תמונה מצורפת" style="max-width:100%;max-height:260px;border-radius:10px;object-fit:cover;cursor:pointer;border:1px solid var(--border)" data-action="toggle-image-zoom" title="לחץ להגדלה"></div>` : ''}
            ${logTagsHtml(l)}
          </div>
          ${state.isAdmin ? `
          <div style="display:flex;gap:2px;flex-shrink:0;margin-top:2px">
            <button data-action="edit-log" data-id="${l.id}" style="background:none;border:none;cursor:pointer;color:var(--accent);font-size:15px;padding:4px" title="ערוך">✏️</button>
            <button data-action="delete-log" data-id="${l.id}" style="background:none;border:none;cursor:pointer;color:var(--red);font-size:15px;padding:4px" title="מחק">🗑️</button>
          </div>` : ''}
        </div>
      </div>
    </div>
  `).join('');
}

function renderRecentLogs() {
  const el = document.getElementById('recent-logs');
  const items = [...dailyLogs()].reverse().slice(0, 3);
  el.innerHTML = items.map(l => `
    <div class="timeline-item">
      <div class="timeline-dot"></div>
      <div class="timeline-content">
        <div class="timeline-meta">${sanitize(l.author)} · ${formatDate(l.date)}</div>
        <div class="timeline-text">${sanitize(l.text)}</div>
        ${imageSrc(l.image) ? `<div style="margin-top:8px"><img src="${imageSrc(l.image)}" alt="תמונה מצורפת" style="max-width:100%;max-height:160px;border-radius:10px;object-fit:cover;border:1px solid var(--border)"></div>` : ''}
        ${logTagsHtml(l)}
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
function showAddLogModal() {
  document.getElementById('log-topics').innerHTML = _checkChipsHtml('topic', LOG_TOPICS, []);
  document.getElementById('log-values').innerHTML = _checkChipsHtml('value', _logValueOptions(), []);
  openModal('modal-log');
}
function saveLog() {
  const text = document.getElementById('log-text').value.trim().slice(0, 2000);
  if (!text) { notify('נא להוסיף תוכן', 'error'); return; }
  const modal = document.getElementById('modal-log');
  const allowedTopics = LOG_TOPICS.map(t => t[0]);
  const topics = _checkedValues(modal, 'topic').filter(t => allowedTopics.includes(t));
  const values = _checkedValues(modal, 'value').filter(v => LOG_VALUES.includes(v));
  if (!topics.length) { notify('סמנו לפחות נושא אחד', 'error'); return; }
  if (!values.length) { notify('סמנו לפחות ערך ליבה אחד', 'error'); return; }
  const topic = topics[0];

  const fileInput = document.getElementById('log-image');
  const file = fileInput ? fileInput.files[0] : null;
  const logEntry = {
    id: Date.now(), topic, topics, values, text,
    author: state.currentUser?.name || 'אנונימי',
    date: _localIsoToday(),
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
    compressImage(file).then(dataUrl => { logEntry.image = dataUrl; finish(); })
      .catch(() => { notify('❌ שגיאה בעיבוד התמונה', 'error'); });
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
        <label class="form-label">נושאים</label>
        <div class="check-chips" id="edit-log-topics">${_checkChipsHtml('topic', LOG_TOPICS, logTopics(log))}</div>
      </div>
      <div class="form-group">
        <label class="form-label">ערכי ליבה</label>
        <div class="check-chips" id="edit-log-values">${_checkChipsHtml('value', _logValueOptions(), log.values || [])}</div>
      </div>
      <div class="form-group" style="margin-top:12px">
        <label class="form-label">תוכן</label>
        <textarea class="form-input" id="edit-log-text" rows="5" style="resize:vertical">${log.text.replace(/</g,'&lt;').replace(/>/g,'&gt;')}</textarea>
      </div>
      <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:16px">
        <button class="btn btn-ghost" data-action="close-dynamic-overlay">ביטול</button>
        <button class="btn btn-primary" data-action="save-edited-log" data-id="${id}">💾 שמור</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.remove(); });
}

function closeDynamicOverlay(el) {
  const overlay = el.closest('[style*="fixed"]');
  if (overlay) overlay.remove();
}

function saveEditedLog(el, id) {
  const txt = document.getElementById('edit-log-text').value.trim().slice(0, 2000);
  const box = el.closest('[style*="fixed"]') || document;
  const topics = _checkedValues(box, 'topic');
  const values = _checkedValues(box, 'value');
  if (!txt) return;
  if (!topics.length) { notify('סמנו לפחות נושא אחד', 'error'); return; }
  if (!values.length) { notify('סמנו לפחות ערך ליבה אחד', 'error'); return; }
  const entry = state.logs.find(l => l.id === id);
  if (entry) { entry.text = txt; entry.topic = topics[0]; entry.topics = topics; entry.values = values; }
  saveState(); renderTimeline(); renderRecentLogs();
  closeDynamicOverlay(el);
  notify('✅ רשומה עודכנה', 'success');
}

function toggleImageZoom(el) {
  el.style.maxHeight = el.style.maxHeight === 'none' ? '260px' : 'none';
}
