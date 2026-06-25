// ═══════════════════════════════════════════════════════
// § 27 · PWA
// ═══════════════════════════════════════════════════════
async function installPWA() {
  const overlay = document.createElement('div');
  overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:1000;display:flex;align-items:center;justify-content:center;padding:16px';
  overlay.innerHTML = `
    <div style="background:var(--surface);border-radius:20px;padding:28px;width:100%;max-width:360px;border:1px solid var(--border);text-align:center">
      <div style="font-size:52px;margin-bottom:12px">📲</div>
      <div style="font-weight:800;font-size:18px;margin-bottom:8px">הוסף למסך הבית</div>
      <div style="color:var(--text2);font-size:13px;margin-bottom:24px;line-height:1.6">
        הוסף את FLL Team Manager למסך הבית שלך לגישה מהירה — ייראה ויעבוד כמו אפליקציה אמיתית!
      </div>
      <div style="display:flex;flex-direction:column;gap:10px">
        <button id="pwa-confirm" style="padding:14px;border-radius:12px;border:none;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;font-family:inherit;font-size:15px;font-weight:700;cursor:pointer">
          ✅ כן, הוסף למסך הבית
        </button>
        <button id="pwa-cancel" style="padding:12px;border-radius:12px;border:1px solid var(--border);background:transparent;color:var(--text2);font-family:inherit;font-size:14px;cursor:pointer">
          ✕ סגור
        </button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  document.getElementById('pwa-cancel').onclick = () => overlay.remove();
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.remove(); });

  document.getElementById('pwa-confirm').onclick = async () => {
    overlay.remove();
    if (_deferredInstall) {
      _deferredInstall.prompt();
      const { outcome } = await _deferredInstall.userChoice;
      if (outcome === 'accepted') {
        notify('✅ האפליקציה נוספה למסך הבית!', 'success');
        _deferredInstall = null;
        const btn = document.getElementById('install-btn');
        if (btn) btn.style.display = 'none';
      }
    } else {
      const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
      const guide = document.createElement('div');

      if (isIOS) {
        guide.style.cssText = 'position:fixed;inset:0;z-index:9999;pointer-events:auto';
        guide.innerHTML = `
          <div id="ios-guide-bg" style="position:absolute;inset:0;background:rgba(0,0,0,0.65)"></div>
          <div style="position:absolute;bottom:0;left:0;right:0;padding:16px 16px 90px">
            <div style="background:var(--surface);border-radius:20px;padding:22px;border:1px solid var(--border);text-align:center">
              <div style="font-size:42px;margin-bottom:10px">📲</div>
              <div style="font-weight:800;font-size:17px;color:var(--text);margin-bottom:18px">הוסף למסך הבית</div>
              <div style="display:flex;flex-direction:column;gap:10px;text-align:right">
                <div style="display:flex;align-items:center;gap:12px;background:var(--surface2);border-radius:12px;padding:12px">
                  <div style="width:38px;height:38px;background:linear-gradient(135deg,var(--accent),var(--accent2));border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:22px">⬆️</div>
                  <div>
                    <div style="font-weight:700;font-size:14px;color:var(--text)">שלב 1</div>
                    <div style="font-size:13px;color:var(--text2)">לחץ כפתור השיתוף בתחתית Safari</div>
                  </div>
                </div>
                <div style="display:flex;align-items:center;gap:12px;background:var(--surface2);border-radius:12px;padding:12px">
                  <div style="width:38px;height:38px;background:linear-gradient(135deg,var(--accent3),var(--gold));border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:22px">➕</div>
                  <div>
                    <div style="font-weight:700;font-size:14px;color:var(--text)">שלב 2</div>
                    <div style="font-size:13px;color:var(--text2)">בחר "הוסף למסך הבית"</div>
                  </div>
                </div>
                <div style="display:flex;align-items:center;gap:12px;background:var(--surface2);border-radius:12px;padding:12px">
                  <div style="width:38px;height:38px;background:linear-gradient(135deg,var(--accent2),#00a080);border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:22px">✅</div>
                  <div>
                    <div style="font-weight:700;font-size:14px;color:var(--text)">שלב 3</div>
                    <div style="font-size:13px;color:var(--text2)">לחץ "הוסף" — זהו!</div>
                  </div>
                </div>
              </div>
              <button id="ios-guide-close" style="margin-top:16px;width:100%;padding:12px;border-radius:12px;border:1px solid var(--border);background:transparent;color:var(--text2);font-family:inherit;font-size:14px;cursor:pointer">סגור</button>
            </div>
            <div style="text-align:center;margin-top:10px">
              <span style="font-size:38px;color:#fff;display:inline-block;filter:drop-shadow(0 2px 8px rgba(0,0,0,0.5));animation:fll-bounce 1s ease-in-out infinite">↓</span>
            </div>
          </div>
          <style>@keyframes fll-bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(10px)}}</style>
        `;
        document.body.appendChild(guide);
        document.getElementById('ios-guide-bg').onclick = () => guide.remove();
        document.getElementById('ios-guide-close').onclick = () => guide.remove();
      } else {
        guide.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:9999;display:flex;align-items:center;justify-content:center;padding:16px;pointer-events:auto';
        guide.innerHTML = `
          <div style="background:var(--surface);border-radius:20px;padding:24px;width:100%;max-width:360px;border:1px solid var(--border);text-align:center">
            <div style="font-size:42px;margin-bottom:10px">📲</div>
            <div style="font-weight:800;font-size:17px;color:var(--text);margin-bottom:18px">הוסף למסך הבית</div>
            <div style="display:flex;flex-direction:column;gap:10px;text-align:right">
              <div style="display:flex;align-items:center;gap:12px;background:var(--surface2);border-radius:12px;padding:12px">
                <div style="width:38px;height:38px;background:linear-gradient(135deg,var(--accent),var(--accent2));border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:22px">⋮</div>
                <div>
                  <div style="font-weight:700;font-size:14px;color:var(--text)">שלב 1</div>
                  <div style="font-size:13px;color:var(--text2)">לחץ על תפריט ⋮ בפינה העליונה</div>
                </div>
              </div>
              <div style="display:flex;align-items:center;gap:12px;background:var(--surface2);border-radius:12px;padding:12px">
                <div style="width:38px;height:38px;background:linear-gradient(135deg,var(--accent3),var(--gold));border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:22px">➕</div>
                <div>
                  <div style="font-weight:700;font-size:14px;color:var(--text)">שלב 2</div>
                  <div style="font-size:13px;color:var(--text2)">בחר "הוסף למסך הבית"</div>
                </div>
              </div>
            </div>
            <button onclick="this.closest('[style*=fixed]').remove()" style="margin-top:16px;width:100%;padding:12px;border-radius:12px;border:1px solid var(--border);background:transparent;color:var(--text2);font-family:inherit;font-size:14px;cursor:pointer">סגור</button>
          </div>
        `;
        document.body.appendChild(guide);
        guide.addEventListener('click', e => { if (e.target === guide) guide.remove(); });
      }
    }
  };
}

// ─── Task Reminders ───────────────────────────────────
let _reminderTimers = {};

function requestNotifPermission(callback) {
  if (!('Notification' in window)) return;
  if (Notification.permission === 'granted') { if (callback) callback(); return; }
  if (Notification.permission === 'denied') return;
  Notification.requestPermission().then(p => { if (p === 'granted' && callback) callback(); });
}

function scheduleTaskReminder(task) {
  if (!task.due) return;
  requestNotifPermission(() => {
    const due          = new Date(task.due + 'T09:00:00');
    const reminderTime = new Date(due.getTime() - 24 * 60 * 60 * 1000);
    const reminders    = _getStoredReminders();
    reminders.push({ taskId: task.id, desc: task.desc, memberName: task.memberName || '', due: task.due, reminderTime: reminderTime.toISOString(), shown: false });
    _saveStoredReminders(reminders);
    const msUntil = reminderTime.getTime() - Date.now();
    if (msUntil > 0 && msUntil < 24 * 60 * 60 * 1000) {
      _reminderTimers[task.id] = setTimeout(() => _fireTaskNotif(task.desc, task.memberName, task.due, task.id), msUntil);
    }
  });
}

function cancelTaskReminder(id) {
  if (_reminderTimers[id]) { clearTimeout(_reminderTimers[id]); delete _reminderTimers[id]; }
  _saveStoredReminders(_getStoredReminders().filter(r => r.taskId !== id));
}

function checkTaskReminders() {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  const now       = Date.now();
  const reminders = _getStoredReminders();
  let changed     = false;
  reminders.forEach(r => {
    if (r.shown) return;
    const rt = new Date(r.reminderTime).getTime();
    if (rt <= now) {
      _fireTaskNotif(r.desc, r.memberName, r.due, r.taskId);
      r.shown = true; changed = true;
    } else if (rt - now < 24 * 60 * 60 * 1000) {
      _reminderTimers[r.taskId] = setTimeout(() => {
        _fireTaskNotif(r.desc, r.memberName, r.due, r.taskId);
        const rs = _getStoredReminders();
        const idx = rs.findIndex(x => x.taskId === r.taskId);
        if (idx >= 0) { rs[idx].shown = true; _saveStoredReminders(rs); }
      }, rt - now);
    }
  });
  if (changed) _saveStoredReminders(reminders);
}

function _fireTaskNotif(desc, memberName, due, taskId) {
  if (Notification.permission !== 'granted') return;
  const title = '📋 תזכורת משימה — FLL Manager';
  const body  = `${desc}${memberName && memberName !== 'כולם' ? ' (' + memberName + ')' : ''}\n📅 מועד: ${due}`;
  try { new Notification(title, { body, icon: '/icon-192.png', tag: 'task-' + taskId }); } catch(e) {}
}

function _getStoredReminders() {
  try { return JSON.parse(localStorage.getItem('fll_task_reminders') || '[]'); } catch(e) { return []; }
}
function _saveStoredReminders(r) {
  try { localStorage.setItem('fll_task_reminders', JSON.stringify(r)); } catch(e) {}
}

// ─── Service Worker Registration + Update Detection ──
let _swReg = null;

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').then(reg => {
    _swReg = reg;
    if (reg.waiting) _showUpdateBanner(reg.waiting);
    reg.addEventListener('updatefound', () => {
      const incoming = reg.installing;
      incoming.addEventListener('statechange', () => {
        if (incoming.state === 'installed' && navigator.serviceWorker.controller) {
          _showUpdateBanner(incoming);
        }
      });
    });
  }).catch(() => {});

  let _reloadOnChange = false;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (_reloadOnChange) window.location.reload();
  });

  navigator.serviceWorker.addEventListener('message', e => {
    if (e.data?.type === 'NAVIGATE') navigate(e.data.screen);
  });

  function _showUpdateBanner(waitingSW) {
    if (document.getElementById('sw-update-banner')) return;
    const banner = document.createElement('div');
    banner.id = 'sw-update-banner';
    banner.style.cssText = [
      'position:fixed', 'bottom:16px', 'left:50%', 'transform:translateX(-50%)',
      'z-index:9999', 'background:linear-gradient(135deg,var(--accent),var(--accent2))',
      'color:#fff', 'padding:12px 18px', 'border-radius:16px',
      'display:flex', 'align-items:center', 'gap:14px',
      'font-family:inherit', 'direction:rtl', 'white-space:nowrap',
      'box-shadow:0 4px 24px rgba(0,0,0,0.4)', 'font-size:14px'
    ].join(';');
    banner.innerHTML = `
      <span>⬆️ עדכון v1.0.6 זמין!</span>
      <button id="sw-update-btn" style="padding:7px 16px;border-radius:10px;border:2px solid rgba(255,255,255,0.7);background:rgba(255,255,255,0.2);color:#fff;font-family:inherit;font-size:13px;font-weight:700;cursor:pointer">
        🔄 עדכן עכשיו
      </button>
      <button id="sw-dismiss-btn" style="padding:4px 8px;border:none;background:none;color:rgba(255,255,255,0.7);font-size:18px;cursor:pointer;line-height:1">✕</button>
    `;
    document.body.appendChild(banner);

    document.getElementById('sw-update-btn').onclick = () => {
      banner.remove();
      _reloadOnChange = true;
      waitingSW.postMessage({ type: 'SKIP_WAITING' });
    };
    document.getElementById('sw-dismiss-btn').onclick = () => banner.remove();
  }
}

window.addEventListener('resize', () => {
  if (window.innerWidth >= 1024) {
    document.getElementById('sidebar').classList.remove('mobile-hidden', 'closed');
    document.getElementById('sidebar-overlay').classList.remove('show');
  } else if (window.innerWidth < 1024) {
  }
});

document.querySelectorAll('.modal-overlay').forEach(ov => {
  ov.addEventListener('click', e => { if (e.target === ov) ov.classList.remove('open'); });
});

