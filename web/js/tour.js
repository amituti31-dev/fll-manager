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

// Full app tour — one pass over every screen in sidebar order.
// Steps support: selector ('#id'), screen (navigate() there first),
// before (a function run before rendering, e.g. to switch an in-screen
// tab), action:'click' (advance only when the real element is clicked),
// adminOnly (skip entirely for non-mentors — most admin-only selectors
// are already skipped automatically because they're display:none).
function buildTourSteps() {
  const steps = [
    // ── Welcome + Dashboard ──
    { screen: 'dashboard', title: '👋 ברוכים הבאים ל-FLL Manager!',
      text: 'בואו נעשה סיור מלא באפליקציה, מסך אחר מסך. אפשר להפעיל את הסיור הזה שוב בכל רגע דרך ההגדרות.' },
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

    // ── Daily log ──
    { screen: 'daily', selector: '#nav-daily', title: '📅 תיעוד יומי',
      text: 'כאן כותבים "מה עשינו היום" — כל פעילות שכדאי לתעד. זה גם מה ששופטים אוהבים לראות: תיעוד רציף לאורך העונה.' },
    { screen: 'daily', selector: '#daily-search', title: '🔍 חיפוש וסינון',
      text: 'אפשר לחפש תיעוד ישן, או לסנן לפי נושא — רובוט, חדשנות, ערכים או כללי.' },
    { screen: 'daily', selector: '#daily-add-btn', title: '➕ עדכון חדש',
      text: 'לחצו כאן בכל פעם שיש משהו לתעד — אפשר גם לצרף תמונה.' },
    { screen: 'daily', selector: '#timeline-container', title: '🕒 ציר הזמן',
      text: 'כל התיעודים מוצגים כאן לפי סדר כרונולוגי, עם שם הכותב והתאריך.' },

    // ── Values ──
    { screen: 'values', selector: '#nav-values', title: '⭐ ערכי יסוד',
      text: 'מסך שמרכז את מחוון ערכי הליבה של FLL, ולוח פתקים לרעיונות ומחשבות של הקבוצה.' },
    { screen: 'values', before: () => switchValuesTab('rubrics'), selector: '#values-rubrics', title: '📋 המחוון',
      text: 'לכל קריטריון אפשר לדרג את הקבוצה ולהוסיף הערות — בדיוק כמו ששופט יעשה.' },
    { screen: 'values', selector: '#values-admin-box', title: '🔵 כלים למנטור',
      text: 'מנטורים יכולים לייבא את המחוון הרשמי של FIRST או להוסיף שאלות מותאמות אישית.', adminOnly: true },
    { screen: 'values', before: () => switchValuesTab('sticky'), selector: '#values-tab-sticky', title: '📝 לוח פתקים',
      text: 'תיעוד רגעים בהם הקבוצה הפגינה אחד מערכי הליבה של FLL — כל פתק משויך לערך ספציפי (גילוי, חדשנות, השפעה, שילוב, עבודת צוות או כיף).' },
    { screen: 'values', selector: '#values-sticky-add-btn', title: '➕ הוספת פתק',
      text: 'כל חבר קבוצה יכול להוסיף פתק — בוחרים ערך ומתארים את הרגע.' },

    // ── Robot ──
    { screen: 'robot', selector: '#nav-robot', title: '🤖 תכנון רובוט',
      text: 'המסך המרכזי לניהול 15 המשימות הרשמיות של העונה, תיעוד שיפורים, ומחווני עיצוב הרובוט.' },
    { screen: 'robot', selector: '#robot-actions-card', title: '📸 הוספת שיפור',
      text: 'תעדו שיפור ברובוט עם תמונה — ישירות מהנייד או מהמחשב.' },
    { screen: 'robot', selector: '#missions-grid', title: '📋 15 המשימות',
      text: 'לחצו על משימה כדי לסמן שהצליחה. אפשר גם לסנן לפי "הושלמו"/"לא הושלמו", ולעדכן סטטוס לכל משימה.' },
    { screen: 'robot', selector: '#robot-gallery', title: '🖼️ גלריית שיפורים',
      text: 'כל התמונות שצילמתם מצטברות כאן — ואפשר אפילו ליצור מהן סרטון טיים-לאפס של ההתקדמות.' },
    { screen: 'robot', selector: '#robot-admin-box', title: '🔵 כלים למנטור',
      text: 'ייבוא מחוון עיצוב הרובוט הרשמי, או הוספת קריטריונים משלכם.', adminOnly: true },
    { screen: 'robot', selector: '#robot-rubrics', title: '⭐ מחוון עיצוב הרובוט',
      text: 'דירוג הקבוצה מול קריטריוני העיצוב הרשמיים.' },

    // ── Innovation project ──
    { screen: 'innovation', selector: '#nav-innovation', title: '💡 פרויקט חדשנות',
      text: 'ניהול כל שלבי פרויקט החדשנות: הגדרת הבעיה, מחקר, ראיונות עם מומחים, והפתרון.' },
    { screen: 'innovation', before: () => switchInnovTab('project'), selector: '#innov-steps-list', title: '🎯 שלבי הפרויקט',
      text: 'חמישה שלבים שמובילים אתכם משלב הגדרת הבעיה ועד שיתוף הפתרון עם הקהילה.' },
    { screen: 'innovation', selector: '#innov-admin-box', title: '🟢 כלים למנטור',
      text: 'ייבוא מחוון חדשנות רשמי או הוספת שאלות מותאמות.', adminOnly: true },
    { screen: 'innovation', before: () => switchInnovTab('research'), selector: '#innov-add-finding-btn', title: '🔬 ממצאי מחקר',
      text: 'כל מקור, נתון או תובנה שמצאתם במחקר — מתעדים כאן.' },
    { screen: 'innovation', before: () => switchInnovTab('interviews'), selector: '#innov-add-interview-btn', title: '🎙️ ראיונות עם מומחים',
      text: 'תיעוד ראיונות: שם המומחה, תפקידו, מה למדתם, וציטוטים מרכזיים.' },
    { screen: 'innovation', selector: '#innov-record-card', title: '🎤 הקלטת פגישה',
      text: 'אפשר גם להקליט את הריאיון ולהוריד כקובץ שמע.' },

    // ── Scoring / competition prep ──
    { screen: 'scoring', selector: '#nav-scoring', title: '🎯 הכנה לתחרות',
      text: 'שני חלקים: חדר שיפוט (טיימר לריאיון) וריצת רובוט (מחשבון ניקוד וטיימר).' },
    { screen: 'scoring', before: () => switchScoringTab('judging'), selector: '#judging-timer-card', title: '🏛️ טיימר חדר שיפוט',
      text: 'עוקב אחרי שלבי הריאיון (קבלת פנים → חדשנות → רובוט → סיום) עם טיימר לכל שלב.' },
    { screen: 'scoring', selector: '#scoring-innovation-rubrics', title: '⭐ מחווני שיפוט',
      text: 'כל מחווני השיפוט הרשמיים — חדשנות, ערכים ורובוט — במקום אחד, מתקפלים לחיסכון במקום.' },
    { screen: 'scoring', before: () => switchScoringTab('robot'), selector: '#total-score-card', title: '🤖 ריצת רובוט וניקוד',
      text: 'מחשבון ניקוד חי שמתעדכן לפי המשימות שסימנתם.' },
    { screen: 'scoring', selector: '#scoring-robot-timer-btn', title: '⏱️ טיימר ריצה',
      text: 'טיימר של 2:30 דקות — בדיוק כמו בתחרות. נסו ללחוץ עליו!', action: 'click' },
    { screen: 'scoring', selector: '#scoring-missions-card', title: '📋 סימון משימות',
      text: 'סמנו אילו משימות ביצעתם בריצה הזו — הניקוד מתעדכן אוטומטית.' },

    // ── My tasks ──
    { screen: 'mytasks', selector: '#nav-mytasks', title: '✅ המשימות שלי',
      text: 'כל המשימות שהוקצו לכם אישית — מהמנטור או מהקבוצה — במקום אחד.' },
    { screen: 'mytasks', selector: '#mytasks-tab-pending', title: '📋 פתוחות מול הושלמו',
      text: 'עברו בין מה שעוד צריך לעשות למה שכבר סיימתם.' },

    // ── Team ──
    { screen: 'team', selector: '#nav-team', title: '👥 ניהול קבוצה',
      text: 'רשימת כל חברי הקבוצה, התפקידים שלהם, ומשימות אישיות שהוקצו לכל אחד.' },
    { screen: 'team', selector: '#team-add-btn', title: '➕ הוספת חבר',
      text: 'מנטורים יכולים להוסיף חברי קבוצה חדשים ולתת להם קוד הצטרפות.', adminOnly: true },
    { screen: 'team', selector: '#members-list', title: '👤 רשימת חברים',
      text: 'לחיצה על חבר פותחת צ׳אט פרטי איתו. מנטורים יכולים גם להקצות משימות אישיות ולערוך פרטים.' },
    { screen: 'team', selector: '#team-checklist-box', title: '✅ צ׳קליסט הכנה לתחרות',
      text: 'רשימת ציוד ומטלות לפני יום התחרות — עדכנו אותה ככל שמתקדמים.', adminOnly: true },

    // ── Chat ──
    { screen: 'chat', selector: '#nav-chat', title: '💬 צ׳אט קבוצה',
      text: 'תקשורת פנים-קבוצתית — כללי, לפי נושא, או פרטי בין שני חברים.' },
    { screen: 'chat', selector: '#chat-tab-general', title: '📌 ערוצים',
      text: 'ערוץ כללי, וערוצים ייעודיים לרובוט ולחדשנות — כדי לשמור על סדר.' },
    { screen: 'chat', selector: '#chat-input-row', title: '⌨️ שליחת הודעה',
      text: 'כתבו הודעה ולחצו Enter או על "שלח".' },
    { screen: 'chat', selector: '#chat-poll-btn', title: '🗳️ הצבעה קבוצתית',
      text: 'מנטורים יכולים ליצור הצבעה מהירה לכל הקבוצה.', adminOnly: true },
    { screen: 'chat', selector: '#chat-announce-btn', title: '📣 הכרזה',
      text: 'הודעה שנשארת נעוצה למעלה, לכל הקבוצה.', adminOnly: true },

    // ── Archive ──
    { screen: 'archive', selector: '#nav-archive', title: '📦 עונות וארכיון',
      text: 'כשעונה מסתיימת, אפשר לארכב אותה ולהתחיל עונה חדשה — כל הנתונים ההיסטוריים נשמרים.' },
    { screen: 'archive', selector: '#seasons-list', title: '📅 רשימת עונות',
      text: 'לחצו על עונה ארכיונית כדי לצפות בנתונים שלה בכל רגע.' },
    { screen: 'archive', selector: '#archive-export-card', title: '💾 ייצוא נתונים',
      text: 'ייצוא כל נתוני העונה כ-PDF, Excel או JSON — לגיבוי או לשיתוף.' },

    // ── Gallery ──
    { screen: 'gallery', selector: '#nav-gallery', title: '🖼️ גלריית עונה',
      text: 'אלבום תמונות משותף לכל הקבוצה — מהאימונים ומהתחרות.' },
    { screen: 'gallery', selector: '#gallery-header-card', title: '📷 הוספת תמונה',
      text: 'כל חבר קבוצה יכול להוסיף תמונות לגלריה המשותפת.' },

    // ── Judging ──
    { screen: 'judging', selector: '#nav-judging', title: '🎓 שאלות שיפוט',
      text: 'בנק שאלות נפוצות מראיון השיפוט, מחולק לפי רובוט / חדשנות / ערכים — טוב להתכונן מראש.' },
    { screen: 'judging', selector: '#judging-doc-card', title: '📄 מסמך שיפוט',
      text: 'ניתן להעלות ולשמור כאן את מסמך ההגשה הרשמי לשיפוט.' },
    { screen: 'judging', selector: '#judg-tab-robot', title: '🗂️ קטגוריות',
      text: 'מעבר בין קטגוריות השאלות: רובוט, חדשנות וערכים.' },

    // ── Links ──
    { screen: 'links', selector: '#nav-links', title: '🔗 ספריית קישורים',
      text: 'מקום לשמור קישורים שימושיים לקבוצה — מחקר, כלים, השראה ועוד.' },
    { screen: 'links', selector: '#links-add-btn', title: '➕ הוספת קישור',
      text: 'כל חבר קבוצה יכול להוסיף קישור ולתייג אותו לפי קטגוריה.' },
    { screen: 'links', selector: '#links-filter-bar', title: '🗂️ סינון לפי קטגוריה',
      text: 'קישורים כלליים, רובוט, חדשנות או שיפוט — כדי למצוא מה שצריך מהר.' },

    // ── Strategy board ──
    { screen: 'strategy', selector: '#nav-strategy', title: '🗺️ לוח אסטרטגיה',
      text: 'לוח ציור חופשי לתכנון מסלול הרובוט על גבי מפת המשחק.' },
    { screen: 'strategy', selector: '#sb-btn-pen', title: '🖊️ כלי ציור',
      text: 'עט או מחק — פשוט התחילו לצייר על הלוח.' },
    { screen: 'strategy', selector: '#sb-colors', title: '🎨 צבעים ועובי קו',
      text: 'בחרו צבע ועובי קו לפני שמתחילים לתכנן.' },
    { screen: 'strategy', selector: '#sb-save-btn', title: '💾 שמירה',
      text: 'שמרו את התכנון כדי שכל הקבוצה תוכל לראות אותו.' },

    // ── Settings ──
    { screen: 'settings', selector: '#nav-settings', title: '⚙️ הגדרות',
      text: 'ניהול החשבון שלכם, מראה האפליקציה, ופעולות ניהול לקבוצה.' },
    { screen: 'settings', selector: '#settings-theme-card', title: '🎨 מראה',
      text: 'ערכת נושא כהה או בהירה — לפי מה שנוח לכם.' },
    { screen: 'settings', selector: '#settings-team-card', title: '👥 פרטי קבוצה',
      text: 'שינוי שם הקבוצה והלוגו — למנטורים בלבד.', adminOnly: true },
    { screen: 'settings', selector: '#settings-codes-card', title: '🔗 קודי הצטרפות',
      text: 'קוד נפרד למנטורים ולתלמידים — שתפו את הקוד המתאים עם כל חבר חדש.', adminOnly: true },
    { screen: 'settings', selector: '#settings-competition-date-card', title: '📅 תאריך תחרות',
      text: 'הגדירו את תאריך התחרות כדי לראות ספירה לאחור בדשבורד.' },
    { screen: 'settings', selector: '#settings-account-card', title: '🚪 פעולות חשבון',
      text: 'יציאה מהקבוצה או מחיקת החשבון — בזהירות!' },
    { screen: 'settings', selector: '#settings-admin-card', title: '⚠️ פעולות אדמין',
      text: 'איפוס נתונים או מחיקת הקבוצה כולה — פעולות בלתי הפיכות, שמורות למנטורים בלבד.', adminOnly: true },
    { screen: 'settings', selector: '#settings-help-btn', title: '🎓 סיימנו!',
      text: 'עברתם על כל האפליקציה 🎉 את הסיור הזה תמיד אפשר להפעיל שוב מכאן.' },
  ];
  return steps;
}

// Some steps target elements that only exist/show for mentors (.admin-only
// sections use display:none for students) — skip those dynamically instead
// of pre-filtering, since visibility depends on which screen is active.
function _tourStepUsable(step) {
  if (step.adminOnly && !state.isAdmin) return false;
  if (!step.selector) return true;
  const el = document.querySelector(step.selector);
  if (!el) return false;
  const r = el.getBoundingClientRect();
  return r.width > 0 && r.height > 0 && el.offsetParent !== null;
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

function _renderTourStep(direction = 1) {
  const step = _tourSteps[_tourIndex];
  if (!step) { endTour(); return; }
  if (step.screen) navigate(step.screen);
  if (step.before) { try { step.before(); } catch(e) {} }

  if (!_tourStepUsable(step)) {
    _tourIndex += direction;
    if (_tourIndex < 0 || _tourIndex >= _tourSteps.length) { endTour(); return; }
    _renderTourStep(direction);
    return;
  }

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
        ${_tourIndex > 0 ? `<button class="tour-btn-back" data-action="tour-back">חזרה</button>` : ''}
        ${step.action === 'click' ? '' : `<button class="tour-btn-next" data-action="tour-advance">${_tourIndex === _tourSteps.length - 1 ? 'סיום' : 'הבא'}</button>`}
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
  _renderTourStep(1);
}

function _tourBack() {
  _tourClearHighlights();
  _tourIndex--;
  if (_tourIndex < 0) { _tourIndex = 0; return; }
  _renderTourStep(-1);
}

function endTour() {
  _tourClearHighlights();
  if (_tourResizeHandler) { window.removeEventListener('resize', _tourResizeHandler); _tourResizeHandler = null; }
  document.getElementById('tour-overlay')?.remove();
  document.getElementById('tour-tooltip')?.remove();
  document.querySelector('.tour-skip')?.remove();
  try { localStorage.setItem(_tourStorageKey(), '1'); } catch(e) {}
}
