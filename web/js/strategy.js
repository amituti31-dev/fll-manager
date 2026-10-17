// ═══════════════════════════════════════════════════════
// § 30 · STRATEGY BOARDS (shared with Android)
// ═══════════════════════════════════════════════════════
// Named boards saved in the /{teamId}/strategy doc as { boards: [...] } — the
// same format Android uses (models.dart StrategyBoard, v2):
//   { id, title, bg: dataURL|null, date, author, v: 2,
//     strokes: [{ pts: [{x, y}], color: <ARGB int>, width: <‰ of board width> }] }
// Points are fractions (0..1) of a fixed 2:1 board (an FLL table), so a drawing
// looks the same on every screen. Boards saved by older Android versions (no v)
// used raw phone pixels and are converted on load (normalizeStrategyBoard).
// Saves go through a transaction that replaces only the edited board, so two
// people editing different boards don't overwrite each other.
const SB_ASPECT = 2;                 // width : height
const SB_COLORS = ['#ff4d6d', '#3d7fff', '#00d4a0', '#f5c842', '#ffffff', '#111111'];
let _sbBoards = [];                  // loaded from the strategy doc
let _sbEdit = null;                  // board being edited (deep copy) or null
let _sbCanvas = null, _sbCtx = null, _sbBgImg = null;
let _sbColor = '#ff4d6d', _sbWidth = 8, _sbCurrent = null, _sbDirty = false;

function _sbRef() { return window.db.collection(window.FB_PROJECT).doc('strategy'); }
function _sbHexToInt(hex) { return parseInt('ff' + hex.replace('#', ''), 16); }
function _sbIntToHex(n) { return '#' + ((Number(n) >>> 0) & 0xffffff).toString(16).padStart(6, '0'); }

// Older Android boards: raw pixel coordinates of the drawing phone's canvas.
// Fit their bounding area into the 2:1 board and convert widths to ‰.
function normalizeStrategyBoard(b) {
  if (!b || b.v === 2) return b;
  const pts = (b.strokes || []).flatMap(s => s.pts || []);
  const maxX = Math.max(1, ...pts.map(p => p.x)), maxY = Math.max(1, ...pts.map(p => p.y));
  const W = Math.max(maxX, maxY * SB_ASPECT) * 1.02, H = W / SB_ASPECT;
  return {
    ...b, v: 2,
    strokes: (b.strokes || []).map(s => ({
      ...s,
      pts: (s.pts || []).map(p => ({ x: p.x / W, y: p.y / H })),
      width: (Number(s.width) || 3) / W * 1000,
    })),
  };
}

async function loadStrategyBoards() {
  if (!window.db || !window.FB_PROJECT) return;
  try {
    const snap = await _sbRef().get();
    _sbBoards = ((snap.exists && snap.data().boards) || []).map(normalizeStrategyBoard);
  } catch (e) { console.warn('Strategy boards load:', e); _sbBoards = []; }
  // The old single web board kept only a background image in this browser —
  // turn it into a real shared board once.
  if (state.strategyBoardImage && !_sbBoards.length) {
    const board = { id: Date.now(), title: 'לוח אסטרטגיה', bg: state.strategyBoardImage, strokes: [],
      date: _localIsoToday(), author: state.currentUser?.name || '', v: 2 };
    if (await _sbUpsert(board)) { state.strategyBoardImage = null; saveState(); }
  }
}

async function _sbUpsert(board) {
  try {
    await window.db.runTransaction(async tx => {
      const snap = await tx.get(_sbRef());
      const boards = ((snap.exists && snap.data().boards) || []).filter(b => b.id !== board.id);
      const i = ((snap.exists && snap.data().boards) || []).findIndex(b => b.id === board.id);
      if (i >= 0) boards.splice(i, 0, board); else boards.push(board);
      tx.set(_sbRef(), { boards });
    });
    const i = _sbBoards.findIndex(b => b.id === board.id);
    if (i >= 0) _sbBoards[i] = board; else _sbBoards.push(board);
    return true;
  } catch (e) {
    console.error('Strategy board save:', e);
    notify('❌ השמירה נכשלה' + (String(e.message || e).includes('exceeds') ? ' — תמונת הרקע גדולה מדי' : ''), 'error');
    return false;
  }
}

async function _sbDelete(id) {
  try {
    await window.db.runTransaction(async tx => {
      const snap = await tx.get(_sbRef());
      tx.set(_sbRef(), { boards: ((snap.exists && snap.data().boards) || []).filter(b => b.id !== id) });
    });
    _sbBoards = _sbBoards.filter(b => b.id !== id);
    return true;
  } catch (e) { notify('❌ המחיקה נכשלה', 'error'); return false; }
}

// ── Drawing ──
function _sbDrawStrokes(ctx, w, h, strokes) {
  strokes.forEach(s => {
    const pts = s.pts || [];
    if (!pts.length) return;
    ctx.strokeStyle = ctx.fillStyle = _sbIntToHex(s.color);
    ctx.lineWidth = Math.max(1, (Number(s.width) || 6) / 1000 * w);
    ctx.lineCap = ctx.lineJoin = 'round';
    if (pts.length === 1) {
      ctx.beginPath(); ctx.arc(pts[0].x * w, pts[0].y * h, ctx.lineWidth / 2, 0, Math.PI * 2); ctx.fill(); return;
    }
    ctx.beginPath();
    ctx.moveTo(pts[0].x * w, pts[0].y * h);
    pts.slice(1).forEach(p => ctx.lineTo(p.x * w, p.y * h));
    ctx.stroke();
  });
}

function _sbDrawBg(ctx, w, h, img) {
  ctx.fillStyle = '#1a2235';
  ctx.fillRect(0, 0, w, h);
  if (!img || !img.width) return;
  const scale = Math.min(w / img.width, h / img.height);
  const dw = img.width * scale, dh = img.height * scale;
  ctx.drawImage(img, (w - dw) / 2, (h - dh) / 2, dw, dh);
}

function _sbRender() {
  if (!_sbCanvas || !_sbEdit) return;
  const w = _sbCanvas.width, h = _sbCanvas.height;
  _sbDrawBg(_sbCtx, w, h, _sbBgImg);
  _sbDrawStrokes(_sbCtx, w, h, _sbCurrent ? [..._sbEdit.strokes, _sbCurrent] : _sbEdit.strokes);
}

function _sbSizeCanvas() {
  const wrap = document.getElementById('sb-canvas-wrap');
  if (!wrap || !_sbCanvas) return;
  const cssW = wrap.clientWidth || 600;
  const dpr = window.devicePixelRatio || 1;
  _sbCanvas.style.width = cssW + 'px';
  _sbCanvas.style.height = (cssW / SB_ASPECT) + 'px';
  _sbCanvas.width = Math.round(cssW * dpr);
  _sbCanvas.height = Math.round(cssW / SB_ASPECT * dpr);
  _sbRender();
}

function _sbPos(e) {
  const r = _sbCanvas.getBoundingClientRect();
  return { x: Math.min(1, Math.max(0, (e.clientX - r.left) / r.width)), y: Math.min(1, Math.max(0, (e.clientY - r.top) / r.height)) };
}
function _sbStart(e) {
  e.preventDefault();
  _sbCanvas.setPointerCapture?.(e.pointerId);
  _sbCurrent = { pts: [_sbPos(e)], color: _sbHexToInt(_sbColor), width: _sbWidth };
  _sbRender();
}
function _sbMove(e) {
  if (!_sbCurrent) return;
  e.preventDefault();
  _sbCurrent.pts.push(_sbPos(e));
  _sbRender();
}
function _sbEnd() {
  if (!_sbCurrent) return;
  _sbEdit.strokes.push(_sbCurrent);
  _sbCurrent = null; _sbDirty = true;
  _sbRender();
}

// ── Screens ──
function initStrategyBoard() {
  loadStrategyBoards().then(() => { if (!_sbEdit) renderStrategyList(); });
  renderStrategyList();
}

function renderStrategyList() {
  document.getElementById('sb-list-view').style.display = '';
  document.getElementById('sb-editor-view').style.display = 'none';
  const grid = document.getElementById('sb-board-grid');
  if (!_sbBoards.length) {
    grid.innerHTML = `<div style="grid-column:1/-1;text-align:center;color:var(--text3);padding:40px">
      <div style="font-size:40px">🗺️</div><div style="margin-top:8px">אין לוחות אסטרטגיה — לחצו "➕ לוח חדש"</div></div>`;
    return;
  }
  grid.innerHTML = _sbBoards.map(b => `
    <div class="card" style="padding:0;overflow:hidden;cursor:pointer" data-action="sb-open-board" data-id="${b.id}">
      <canvas class="sb-thumb" data-board="${b.id}" width="400" height="200" style="width:100%;display:block"></canvas>
      <div style="padding:8px 12px">
        <div style="font-weight:700;font-size:14px">${sanitize(b.title || 'לוח')}</div>
        <div style="font-size:11px;color:var(--text3)">${sanitize(b.author || '')} · ${b.date ? formatDate(b.date) : ''}</div>
      </div>
    </div>`).join('');
  grid.querySelectorAll('canvas.sb-thumb').forEach(c => {
    const b = _sbBoards.find(x => String(x.id) === c.dataset.board);
    const ctx = c.getContext('2d');
    const draw = img => { _sbDrawBg(ctx, c.width, c.height, img); _sbDrawStrokes(ctx, c.width, c.height, b.strokes || []); };
    if (b.bg) { const img = new Image(); img.onload = () => draw(img); img.src = b.bg; } else draw(null);
  });
}

function showNewStrategyBoardModal() {
  if (!state.isAdmin) { notify('רק מנטור יכול ליצור לוח אסטרטגיה', 'error'); return; }
  document.getElementById('sb-new-title').value = '';
  const bg = document.getElementById('sb-new-bg');
  if (bg) bg.value = '';
  openModal('modal-sb-new');
}

async function createStrategyBoard() {
  if (!state.isAdmin) return;
  const title = document.getElementById('sb-new-title').value.trim().slice(0, 80);
  if (!title) { notify('נדרש שם ללוח', 'error'); return; }
  const file = document.getElementById('sb-new-bg')?.files?.[0];
  let bg = null;
  if (file && state.isAdmin) {
    try { bg = await compressImage(file, { maxDim: 1400, quality: 0.7 }); } catch (e) { notify('❌ שגיאה בעיבוד התמונה', 'error'); return; }
  }
  const board = { id: Date.now(), title, bg, strokes: [], date: _localIsoToday(), author: state.currentUser?.name || '', v: 2 };
  if (!(await _sbUpsert(board))) return;
  closeModal('modal-sb-new');
  openStrategyBoard(board.id);
}

function openStrategyBoard(id) {
  const b = _sbBoards.find(x => String(x.id) === String(id));
  if (!b) return;
  _sbEdit = JSON.parse(JSON.stringify(b));
  _sbDirty = false;
  document.getElementById('sb-list-view').style.display = 'none';
  document.getElementById('sb-editor-view').style.display = '';
  document.getElementById('sb-editor-title').textContent = _sbEdit.title || 'לוח';
  document.getElementById('sb-delete-board').style.display = state.isAdmin ? '' : 'none';
  _sbCanvas = document.getElementById('strategy-canvas');
  _sbCtx = _sbCanvas.getContext('2d');
  if (!_sbCanvas._sbBound) {
    _sbCanvas.addEventListener('pointerdown', _sbStart);
    _sbCanvas.addEventListener('pointermove', _sbMove);
    ['pointerup', 'pointerleave', 'pointercancel'].forEach(ev => _sbCanvas.addEventListener(ev, _sbEnd));
    _sbCanvas.addEventListener('contextmenu', e => e.preventDefault());
    window.addEventListener('resize', () => { if (_sbEdit) _sbSizeCanvas(); });
    _sbCanvas._sbBound = true;
  }
  _sbBgImg = null;
  if (_sbEdit.bg) { const img = new Image(); img.onload = () => { _sbBgImg = img; _sbRender(); }; img.src = _sbEdit.bg; }
  _sbUpdateToolUI();
  setTimeout(_sbSizeCanvas, 30);
}

function closeStrategyBoard() {
  if (_sbDirty && !confirm('יש שינויים שלא נשמרו. לצאת בלי לשמור?')) return;
  _sbEdit = null; _sbCurrent = null;
  renderStrategyList();
}

async function sbSaveBoard() {
  if (!_sbEdit) return;
  const btn = document.getElementById('sb-save-btn');
  btn.disabled = true;
  const ok = await _sbUpsert(JSON.parse(JSON.stringify(_sbEdit)));
  btn.disabled = false;
  if (ok) { _sbDirty = false; notify('💾 הלוח נשמר — זמין לכל הקבוצה', 'success'); }
}

async function sbDeleteBoard() {
  if (!state.isAdmin) return;
  if (!_sbEdit || !confirm(`למחוק את הלוח "${_sbEdit.title}"?`)) return;
  if (await _sbDelete(_sbEdit.id)) { _sbEdit = null; renderStrategyList(); }
}

function sbSetColor(color) { _sbColor = color; _sbUpdateToolUI(); }
function sbSetWidth(w) { _sbWidth = Number(w) || 8; _sbUpdateToolUI(); }
function _sbUpdateToolUI() {
  document.querySelectorAll('#sb-colors .sb-color').forEach(el =>
    el.style.boxShadow = el.dataset.arg === _sbColor ? '0 0 0 3px var(--accent)' : 'none');
  document.querySelectorAll('.sb-width-btn').forEach(el => el.classList.toggle('active', Number(el.dataset.w) === _sbWidth));
}
function sbUndo() { if (_sbEdit && _sbEdit.strokes.length) { _sbEdit.strokes.pop(); _sbDirty = true; _sbRender(); } }
function sbClearDrawing() {
  if (!_sbEdit || !_sbEdit.strokes.length || !confirm('לנקות את כל הציור בלוח?')) return;
  _sbEdit.strokes = []; _sbDirty = true; _sbRender();
}
function sbUploadBackground(event) {
  const file = event.target.files[0];
  if (!file || !_sbEdit || !state.isAdmin) return;
  compressImage(file, { maxDim: 1400, quality: 0.7 }).then(dataUrl => {
    _sbEdit.bg = dataUrl; _sbDirty = true;
    const img = new Image(); img.onload = () => { _sbBgImg = img; _sbRender(); }; img.src = dataUrl;
  }).catch(() => notify('❌ שגיאה בעיבוד התמונה', 'error'));
  event.target.value = '';
}
function sbClearBackground() {
  if (!_sbEdit || !state.isAdmin) return;
  _sbEdit.bg = null; _sbBgImg = null; _sbDirty = true; _sbRender();
}
// Download the board as a PNG.
function sbSaveImage() {
  if (!_sbCanvas) return;
  const a = document.createElement('a');
  a.download = `${(_sbEdit?.title || 'strategy').replace(/[^\w֐-׿-]+/g, '_')}.png`;
  a.href = _sbCanvas.toDataURL('image/png');
  a.click();
}
