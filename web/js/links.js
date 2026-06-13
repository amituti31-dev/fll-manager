// ═══════════════════════════════════════════════════════
// § 29 · LINKS LIBRARY
// ═══════════════════════════════════════════════════════

const LINK_CAT_ICONS = { general: '📌', robot: '🤖', innovation: '💡', judging: '🎓' };
const LINK_CAT_LABELS = { general: 'כללי', robot: 'רובוט', innovation: 'חדשנות', judging: 'שיפוט' };

let _linksFilter = 'all';

function filterLinks(cat) {
  _linksFilter = cat;
  ['all', 'general', 'robot', 'innovation', 'judging'].forEach(c => {
    const btn = document.getElementById('lf-' + c);
    if (btn) btn.className = c === cat ? 'btn btn-primary' : 'btn btn-ghost';
  });
  renderLinks();
}

function renderLinks() {
  const el = document.getElementById('links-grid');
  if (!el) return;
  const all = state.links || [];
  const items = _linksFilter === 'all' ? all : all.filter(l => l.category === _linksFilter);

  const countEl = document.getElementById('links-count');
  if (countEl) countEl.textContent = all.length + ' קישורים';

  if (!items.length) {
    el.innerHTML = `<div class="links-empty">
      <div style="font-size:40px;margin-bottom:10px">🔗</div>
      <div style="font-size:15px;margin-bottom:6px">${all.length === 0 ? 'אין קישורים שמורים' : 'אין קישורים בקטגוריה זו'}</div>
      <div style="font-size:12px">לחץ ＋ כדי להוסיף קישור שימושי</div>
    </div>`;
    return;
  }

  el.innerHTML = items.map(link => {
    const icon = LINK_CAT_ICONS[link.category] || '📌';
    const catLabel = LINK_CAT_LABELS[link.category] || link.category;
    const safeUrl = sanitizeUrl(link.url);
    const canDelete = state.isAdmin || link.author === (state.currentUser?.name || '');
    return `
      <div class="link-card">
        <div class="link-cat-icon">${icon}</div>
        <div class="link-body">
          <div class="link-title">${sanitize(link.title)}</div>
          <a class="link-url" href="${safeUrl}" target="_blank" rel="noopener noreferrer" onclick="event.stopPropagation()">${sanitize(link.url)}</a>
          <div class="link-meta">
            <span class="link-cat-badge">${catLabel}</span>
            <span>${sanitize(link.author || '')}</span>
            <span>${link.date || ''}</span>
          </div>
        </div>
        ${canDelete ? `<button class="link-delete" onclick="deleteLink(${link.id})" title="מחק">🗑️</button>` : ''}
      </div>
    `;
  }).join('');
}

function showAddLinkModal() {
  document.getElementById('link-title').value = '';
  document.getElementById('link-url').value = '';
  document.getElementById('link-category').value = 'general';
  openModal('modal-link');
}

function saveLink() {
  const title = document.getElementById('link-title').value.trim().slice(0, 200);
  const raw   = document.getElementById('link-url').value.trim();
  if (!title) { notify('נדרשת כותרת', 'error'); return; }
  if (!raw)   { notify('נדרש URL', 'error'); return; }

  // Ensure protocol
  const url = /^https?:\/\//i.test(raw) ? raw : 'https://' + raw;
  const safeUrl = sanitizeUrl(url);
  if (!safeUrl) { notify('כתובת URL לא חוקית', 'error'); return; }

  const category = document.getElementById('link-category').value;
  if (!state.links) state.links = [];
  state.links.unshift({
    id: Date.now(),
    title,
    url: safeUrl,
    category,
    author: state.currentUser?.name || 'אנונימי',
    date: new Date().toISOString().split('T')[0],
  });
  saveState();
  closeModal('modal-link');
  renderLinks();
  notify('✅ קישור נשמר', 'success');
}

function deleteLink(id) {
  if (!confirm('למחוק קישור זה?')) return;
  state.links = (state.links || []).filter(l => l.id !== id);
  saveState(); renderLinks();
  notify('🗑️ קישור נמחק', 'success');
}
