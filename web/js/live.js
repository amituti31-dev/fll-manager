// ═══════════════════════════════════════════════════════
// § 34 · LIVE SYNC — show other people's changes without a refresh
// ═══════════════════════════════════════════════════════
// Listens to the team's documents; when someone ELSE changes one (our own
// writes are skipped via metadata.hasPendingWrites), reloads the team state and
// re-renders. Guards:
//  - never while our own debounced save is pending/in flight (window._savePending)
//    — reloading then would replace a not-yet-saved local change;
//  - never mid-typing — deferred until the focused field loses focus;
//  - never during a restore.
// The chat has its own listener (chat.js).
let _liveUnsubs = [];
let _liveTimer = null;
let _liveDeferred = false;

function stopLiveSync() {
  _liveUnsubs.forEach(u => { try { u(); } catch (e) {} });
  _liveUnsubs = [];
  clearTimeout(_liveTimer);
}

function startLiveSync() {
  stopLiveSync();
  if (!window.db || !window.FB_PROJECT) return;
  const team = window.db.collection(window.FB_PROJECT);
  const watch = (ref, onRemoteChange) => {
    let first = true; // the initial snapshot is what we already loaded
    _liveUnsubs.push(ref.onSnapshot(snap => {
      if (first) { first = false; return; }
      if (snap.metadata.hasPendingWrites) return; // our own write echoing back
      onRemoteChange();
    }, err => console.warn('Live sync:', err)));
  };
  ['settings', 'data', 'admin-data'].forEach(id => watch(team.doc(id), scheduleLiveReload));
  watch(_photoCollRef('gallery'), scheduleLiveReload);
  watch(_photoCollRef('improvements'), scheduleLiveReload);
  watch(team.doc('strategy'), () => {
    if (typeof loadStrategyBoards !== 'function') return;
    loadStrategyBoards().then(() => {
      if (!_sbEdit && document.getElementById('screen-strategy')?.classList.contains('active')) renderStrategyList();
    });
  });
}

function scheduleLiveReload(delay = 800) {
  clearTimeout(_liveTimer);
  _liveTimer = setTimeout(liveReload, delay);
}

function _isTyping() {
  const el = document.activeElement;
  return !!el && (el.tagName === 'TEXTAREA' || el.tagName === 'SELECT' ||
    (el.tagName === 'INPUT' && !['checkbox', 'radio', 'button', 'file'].includes(el.type)));
}

async function liveReload() {
  if (window._restoreInProgress || !window.FB_PROJECT) return;
  if (window._savePending) { scheduleLiveReload(1500); return; }
  if (_isTyping()) { _liveDeferred = true; return; }
  const myEmail = state.currentUser?.email;
  const wasAdmin = state.isAdmin;
  try {
    await loadState();
  } catch (e) { console.warn('Live reload:', e); return; }
  const me = (state.members || []).find(m => m.email === myEmail);
  if (me) state.currentUser = me;
  state.isAdmin = wasAdmin; // keep the current mentor/student view mode
  try { populateAll(); } catch (e) { console.warn('Live render:', e); }
  try { updateAdminUI(); } catch (e) {}
}

// A reload that waited for typing to finish runs when the field loses focus.
document.addEventListener('focusout', () => {
  if (!_liveDeferred) return;
  setTimeout(() => { if (!_isTyping() && _liveDeferred) { _liveDeferred = false; scheduleLiveReload(300); } }, 50);
});
