// ═══════════════════════════════════════════════════════
// § 29 · GUIDED TOUR
// ═══════════════════════════════════════════════════════
// Spotlight-style walkthrough: dims the page, highlights one real element
// at a time with an explanation bubble, and (for steps flagged action:
// 'click') requires the user to actually click the real element — its
// normal onclick still fires — to advance.
const TOUR_STORAGE_PREFIX = 'fll_tour_seen_';
let _tourSteps = [];
let _tourIndex = 0;
let _tourInteractHandler = null;
let _tourResizeHandler = null;

function _tourStorageKey() {
  const email = state.currentUser?.email || 'local';
  return TOUR_STORAGE_PREFIX + email;
}

// Called once after login — shows the tour automatically the first time
// this user ever reaches the app, never again after that.
function maybeAutoStartTour() {
  try { if (localStorage.getItem(_tourStorageKey())) return; } catch(e) {}
  setTimeout(() => startTour(), 700);
}

// Demo tour: covers the sidebar + dashboard screen only, for now.
// Steps support: selector ('#id'), screen (navigate() there first),
// action:'click' (advance only when the real element is clicked).
function buildTourSteps() {
  const steps = [
    { screen: 'dashboard', title: '👋 ברוכים הבאים ל-FLL Manager!',
      text: 'בואו נעשה סיור קצר על המסך הראשי. אפשר להפעיל את הסיור הזה שוב בכל רגע דרך ההגדרות.' },
    { screen: 'dashboard', selector: '#nav-dashboard', title: '🏠 דשבורד ראשי',
      text: 'התפריט הצדדי מוביל לכל מסכי האפליקציה. "דשבורד" הוא מסך הבית — תמיד יראה סיכום מהיר של מצב הקבוצה.' },
    { screen: 'dashboard', selector: '#dashboard-stats', title: '📊 כרטיסי סיכום',
      text: 'ארבעה מספרים שמתעדכנים לבד: כמה משימות רובוט הושלמו, מה הניקוד האחרון, כמה יומנים נכתבו וכמה חברים בקבוצה.' },
    { screen: 'dashboard', selector: '#dashboard-charts', title: '📈 גרפים',
      text: 'שני גרפים שמראים איך הקבוצה מתקדמת — לפי קטגוריה (ערכים/רובוט/חדשנות) ולפי ציון לאורך הזמן.' },
    { screen: 'dashboard', selector: '#dashboard-recent-logs', title: '📋 עדכונים אחרונים',
      text: 'התיעודים האחרונים שחברי הקבוצה כתבו, כדי שתדעו מה קרה גם אם לא הייתם שם.' },
    { screen: 'dashboard', selector: '#dashboard-quick-actions', title: '⚡ פעולות מהירות',
      text: 'קיצורי דרך לפעולות נפוצות — תיעוד חדש, הוספת תמונת שיפור, מחשבון ניקוד וטיימר ריצה.' },
    { screen: 'dashboard', selector: '#light-btn', title: '🌙 / ☀️ ערכת נושא',
      text: 'אפשר להחליף בין מצב כהה למצב בהיר בכל רגע. נסו ללחוץ על הכפתור עכשיו!', action: 'click' },
    { screen: 'dashboard', selector: '#nav-settings', title: '⚙️ עוד בדרך',
      text: 'זה היה סיור לדוגמה על מסך אחד — בהמשך יתווספו כאן סיורים גם לשאר המסכים. את הסיור הזה תמיד אפשר להפעיל שוב מההגדרות.' },
  ];
  return steps.filter(s => !s.selector || document.querySelector(s.selector));
}

function startTour() {
  endTour();
  _tourSteps = buildTourSteps();
  if (!_tourSteps.length) return;
  _tourIndex = 0;

  const overlay = document.createElement('div');
  overlay.id = 'tour-overlay';
  document.body.appendChild(overlay);

  const skipBtn = document.createElement('button');
  skipBtn.className = 'tour-skip';
  skipBtn.textContent = '✕ דלג על הסיור';
  skipBtn.onclick = endTour;
  document.body.appendChild(skipBtn);

  _tourResizeHandler = () => _renderTourStep();
  window.addEventListener('resize', _tourResizeHandler);

  _renderTourStep();
}

function _tourClearHighlights() {
  document.querySelectorAll('.tour-mask, .tour-ring, .tour-shield').forEach(el => el.remove());
  if (_tourInteractHandler) {
    document.removeEventListener('click', _tourInteractHandler, true);
    _tourInteractHandler = null;
  }
}

function _addTourMask(overlay, x, y, w, h) {
  if (w <= 0 || h <= 0) return;
  const m = document.createElement('div');
  m.className = 'tour-mask';
  Object.assign(m.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: h + 'px' });
  overlay.appendChild(m);
}

function _renderTourStep() {
  const step = _tourSteps[_tourIndex];
  if (!step) { endTour(); return; }
  if (step.screen) navigate(step.screen);

  _tourClearHighlights();
  const overlay = document.getElementById('tour-overlay');
  if (!overlay) return;

  const target = step.selector ? document.querySelector(step.selector) : null;
  if (target && target.scrollIntoView) target.scrollIntoView({ block: 'nearest' });
  const r = target ? target.getBoundingClientRect() : null;
  const pad = 8;

  if (r) {
    const top = Math.max(r.top - pad, 0);
    const left = Math.max(r.left - pad, 0);
    const right = Math.min(r.right + pad, window.innerWidth);
    const bottom = Math.min(r.bottom + pad, window.innerHeight);

    _addTourMask(overlay, 0, 0, window.innerWidth, top);
    _addTourMask(overlay, 0, bottom, window.innerWidth, window.innerHeight - bottom);
    _addTourMask(overlay, 0, top, left, bottom - top);
    _addTourMask(overlay, right, top, window.innerWidth - right, bottom - top);

    const ring = document.createElement('div');
    ring.className = 'tour-ring';
    Object.assign(ring.style, { top: top + 'px', left: left + 'px', width: (right - left) + 'px', height: (bottom - top) + 'px' });
    overlay.appendChild(ring);

    if (step.action === 'click') {
      _tourInteractHandler = (e) => {
        if (target.contains(e.target)) setTimeout(() => _tourAdvance(), 350);
      };
      document.addEventListener('click', _tourInteractHandler, true);
    } else {
      // Block real clicks during explanation-only steps — the ring is
      // only decorative there.
      const shield = document.createElement('div');
      shield.className = 'tour-shield';
      Object.assign(shield.style, { top: top + 'px', left: left + 'px', width: (right - left) + 'px', height: (bottom - top) + 'px' });
      overlay.appendChild(shield);
    }
  } else {
    _addTourMask(overlay, 0, 0, window.innerWidth, window.innerHeight);
  }

  let tooltip = document.getElementById('tour-tooltip');
  if (!tooltip) {
    tooltip = document.createElement('div');
    tooltip.id = 'tour-tooltip';
    document.body.appendChild(tooltip);
  }
  tooltip.className = 'tour-tooltip' + (r ? '' : ' center');
  tooltip.innerHTML = `
    <div class="tour-tooltip-title">${sanitize(step.title)}</div>
    <div class="tour-tooltip-text">${sanitize(step.text)}</div>
    ${step.action === 'click' ? `<div class="tour-tooltip-hint">לחצו על הכפתור המודגש כדי להמשיך</div>` : ''}
    <div class="tour-tooltip-footer">
      <span class="tour-tooltip-progress">${_tourIndex + 1} / ${_tourSteps.length}</span>
      <div class="tour-tooltip-actions">
        ${_tourIndex > 0 ? `<button class="tour-btn-back" onclick="_tourBack()">חזרה</button>` : ''}
        ${step.action === 'click' ? '' : `<button class="tour-btn-next" onclick="_tourAdvance()">${_tourIndex === _tourSteps.length - 1 ? 'סיום' : 'הבא'}</button>`}
      </div>
    </div>
  `;
  _positionTourTooltip(tooltip, r);
}

function _positionTourTooltip(tooltip, r) {
  const margin = 16;
  if (!r) {
    tooltip.style.top = '50%'; tooltip.style.left = '50%'; tooltip.style.transform = 'translate(-50%,-50%)';
    return;
  }
  tooltip.style.transform = 'none';
  const tw = tooltip.offsetWidth || 300;
  const th = tooltip.offsetHeight || 160;
  const spaceBelow = window.innerHeight - r.bottom;
  const spaceAbove = r.top;
  let top = (spaceBelow >= th + margin || spaceBelow >= spaceAbove)
    ? Math.min(r.bottom + margin, window.innerHeight - th - margin)
    : Math.max(r.top - th - margin, margin);
  let left = Math.max(margin, Math.min(r.left + r.width / 2 - tw / 2, window.innerWidth - tw - margin));
  tooltip.style.top = Math.max(top, margin) + 'px';
  tooltip.style.left = left + 'px';
}

function _tourAdvance() {
  _tourClearHighlights();
  _tourIndex++;
  if (_tourIndex >= _tourSteps.length) { endTour(); return; }
  _renderTourStep();
}

function _tourBack() {
  _tourClearHighlights();
  _tourIndex = Math.max(0, _tourIndex - 1);
  _renderTourStep();
}

function endTour() {
  _tourClearHighlights();
  if (_tourResizeHandler) { window.removeEventListener('resize', _tourResizeHandler); _tourResizeHandler = null; }
  document.getElementById('tour-overlay')?.remove();
  document.getElementById('tour-tooltip')?.remove();
  document.querySelector('.tour-skip')?.remove();
  try { localStorage.setItem(_tourStorageKey(), '1'); } catch(e) {}
}
