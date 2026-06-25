// ═══════════════════════════════════════════════════════
// § 30 · STRATEGY BOARD
// ═══════════════════════════════════════════════════════

let _sbBgCanvas = null;
let _sbBgCtx   = null;
let _sbCanvas  = null;
let _sbCtx     = null;
let _sbDrawing = false;
let _sbLastX   = 0;
let _sbLastY   = 0;
let _sbTool    = 'pen';
let _sbColor   = '#ff4d6d';
let _sbWidth   = 3;
let _sbHistory = []; // ImageData snapshots for undo (draw layer only)
let _sbInited  = false;

function initStrategyBoard() {
  _sbBgCanvas = document.getElementById('strategy-bg-canvas');
  _sbCanvas   = document.getElementById('strategy-canvas');
  if (!_sbCanvas || !_sbBgCanvas) return;
  _sbBgCtx = _sbBgCanvas.getContext('2d');
  _sbCtx   = _sbCanvas.getContext('2d');

  const wrap = document.getElementById('sb-canvas-wrap');
  const w    = wrap.clientWidth || 600;
  const h    = Math.max(380, Math.min(560, window.innerHeight - 260));

  [_sbBgCanvas, _sbCanvas].forEach(c => { c.width = w; c.height = h; });
  wrap.style.height = h + 'px';

  // Remove old listeners before adding new ones (avoid duplicates on re-navigate)
  if (_sbInited) {
    _sbCanvas.removeEventListener('pointerdown', _sbStart);
    _sbCanvas.removeEventListener('pointermove', _sbMove);
    _sbCanvas.removeEventListener('pointerup',   _sbEnd);
    _sbCanvas.removeEventListener('pointerleave',_sbEnd);
    _sbCanvas.removeEventListener('pointercancel',_sbEnd);
  }
  _sbCanvas.addEventListener('pointerdown',  _sbStart);
  _sbCanvas.addEventListener('pointermove',  _sbMove);
  _sbCanvas.addEventListener('pointerup',    _sbEnd);
  _sbCanvas.addEventListener('pointerleave', _sbEnd);
  _sbCanvas.addEventListener('pointercancel',_sbEnd);
  _sbCanvas.addEventListener('contextmenu',  e => e.preventDefault());
  _sbInited = true;

  // Load saved background image
  const placeholder = document.getElementById('sb-placeholder');
  if (state.strategyBoardImage) {
    if (placeholder) placeholder.style.display = 'none';
    _sbLoadBg(state.strategyBoardImage);
  } else {
    if (placeholder) placeholder.style.display = '';
  }

  _sbUpdateToolUI();
}

function _sbLoadBg(src) {
  const img = new Image();
  img.onload = () => {
    _sbBgCtx.clearRect(0, 0, _sbBgCanvas.width, _sbBgCanvas.height);
    // Fit image preserving aspect ratio
    const scale = Math.min(_sbBgCanvas.width / img.width, _sbBgCanvas.height / img.height);
    const dw = img.width * scale;
    const dh = img.height * scale;
    const dx = (_sbBgCanvas.width  - dw) / 2;
    const dy = (_sbBgCanvas.height - dh) / 2;
    _sbBgCtx.drawImage(img, dx, dy, dw, dh);
  };
  img.src = src;
}

function _sbGetPos(e) {
  const rect   = _sbCanvas.getBoundingClientRect();
  const scaleX = _sbCanvas.width  / rect.width;
  const scaleY = _sbCanvas.height / rect.height;
  return {
    x: (e.clientX - rect.left) * scaleX,
    y: (e.clientY - rect.top)  * scaleY,
  };
}

function _sbStart(e) {
  e.preventDefault();
  _sbCanvas.setPointerCapture(e.pointerId);
  _sbDrawing = true;
  const { x, y } = _sbGetPos(e);
  _sbLastX = x; _sbLastY = y;
  // Save snapshot for undo
  _sbHistory.push(_sbCtx.getImageData(0, 0, _sbCanvas.width, _sbCanvas.height));
  if (_sbHistory.length > 40) _sbHistory.shift();
}

function _sbMove(e) {
  if (!_sbDrawing) return;
  e.preventDefault();
  const { x, y } = _sbGetPos(e);
  _sbCtx.beginPath();
  _sbCtx.moveTo(_sbLastX, _sbLastY);
  _sbCtx.lineTo(x, y);
  _sbCtx.lineCap  = 'round';
  _sbCtx.lineJoin = 'round';
  if (_sbTool === 'eraser') {
    _sbCtx.globalCompositeOperation = 'destination-out';
    _sbCtx.lineWidth   = _sbWidth * 5;
    _sbCtx.strokeStyle = 'rgba(0,0,0,1)';
  } else {
    _sbCtx.globalCompositeOperation = 'source-over';
    _sbCtx.lineWidth   = _sbWidth;
    _sbCtx.strokeStyle = _sbColor;
  }
  _sbCtx.stroke();
  _sbLastX = x; _sbLastY = y;
}

function _sbEnd(e) {
  if (!_sbDrawing) return;
  _sbDrawing = false;
  _sbCtx.globalCompositeOperation = 'source-over';
}

// ─── Public API ──────────────────────────────────────
function sbSetTool(tool) {
  _sbTool = tool;
  _sbUpdateToolUI();
}

function sbSetColor(color) {
  _sbColor = color;
  _sbTool  = 'pen';
  const input = document.getElementById('sb-custom-color');
  if (input) input.value = color;
  _sbUpdateToolUI();
}

function sbSetWidth(w) {
  _sbWidth = w;
  document.querySelectorAll('.sb-width-btn').forEach(b => {
    b.classList.toggle('active', parseInt(b.dataset.w) === w);
  });
}

function _sbUpdateToolUI() {
  const penBtn    = document.getElementById('sb-btn-pen');
  const eraserBtn = document.getElementById('sb-btn-eraser');
  if (penBtn)    penBtn.className    = _sbTool === 'pen'    ? 'btn btn-primary sb-tool-btn' : 'btn btn-ghost sb-tool-btn';
  if (eraserBtn) eraserBtn.className = _sbTool === 'eraser' ? 'btn btn-primary sb-tool-btn' : 'btn btn-ghost sb-tool-btn';
}

function sbUndo() {
  if (!_sbHistory.length || !_sbCtx) { notify('אין פעולות לביטול', 'error'); return; }
  _sbCtx.putImageData(_sbHistory.pop(), 0, 0);
}

function sbClearDrawing() {
  if (!confirm('לנקות את הציור? תמונת הרקע תישמר.')) return;
  _sbHistory = [];
  if (_sbCtx) _sbCtx.clearRect(0, 0, _sbCanvas.width, _sbCanvas.height);
}

function sbUploadBackground(event) {
  if (!state.isAdmin) { notify('רק מנטור יכול להעלות תמונת רקע', 'error'); event.target.value = ''; return; }
  const file = event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    state.strategyBoardImage = e.target.result;
    saveState();
    _sbHistory = [];
    if (_sbCtx) _sbCtx.clearRect(0, 0, _sbCanvas.width, _sbCanvas.height);
    const placeholder = document.getElementById('sb-placeholder');
    if (placeholder) placeholder.style.display = 'none';
    _sbLoadBg(e.target.result);
    notify('📸 תמונת רקע עודכנה', 'success');
  };
  reader.readAsDataURL(file);
  event.target.value = '';
}

function sbClearBackground() {
  if (!state.isAdmin) { notify('רק מנטור יכול להסיר תמונת רקע', 'error'); return; }
  if (!confirm('למחוק את תמונת הרקע? הציור יישמר.')) return;
  state.strategyBoardImage = null;
  saveState();
  if (_sbBgCtx) _sbBgCtx.clearRect(0, 0, _sbBgCanvas.width, _sbBgCanvas.height);
  const placeholder = document.getElementById('sb-placeholder');
  if (placeholder) placeholder.style.display = '';
  notify('🗑️ רקע הוסר', 'success');
}

function sbSaveImage() {
  if (!_sbBgCanvas || !_sbCanvas) return;
  const out  = document.createElement('canvas');
  out.width  = _sbBgCanvas.width;
  out.height = _sbBgCanvas.height;
  const ctx  = out.getContext('2d');
  // Fill dark background (for transparent areas)
  ctx.fillStyle = '#0b0f1a';
  ctx.fillRect(0, 0, out.width, out.height);
  ctx.drawImage(_sbBgCanvas, 0, 0);
  ctx.drawImage(_sbCanvas,   0, 0);
  const link  = document.createElement('a');
  link.download = 'strategy-' + new Date().toISOString().split('T')[0] + '.png';
  link.href = out.toDataURL('image/png');
  link.click();
  notify('💾 לוח נשמר כתמונה', 'success');
}
