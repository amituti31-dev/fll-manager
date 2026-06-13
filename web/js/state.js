// ═══════════════════════════════════════════════════════
// § 02 · CONSTANTS & STATE
// ═══════════════════════════════════════════════════════
const STORE_KEY = 'fll_app_v1';
let state = {
  setup: false,
  teamName: 'FLL Team',
  teamLogo: null,
  currentUser: null,
  isAdmin: false,
  theme: 'dark',
  currentSeason: 'Unearthed 2026',
  members: [],
  logs: [],
  improvements: [],
  findings: [],
  rubrics: { values: [], robot: [], innovation: [] },
  scores: [],
  checklist: [
    { id: 1, text: 'ארגז כלים מוכן', done: false },
    { id: 2, text: 'סוללות טעונות', done: false },
    { id: 3, text: 'פוסטר פרויקט מודפס', done: false },
    { id: 4, text: 'תיקיית שיפוט מוכנה', done: false },
    { id: 5, text: 'זרועות ורובוט ארוזים', done: false },
  ],
  seasons: [
    { name: 'Unearthed 2026', year: 2026, archived: false, topScore: 0 },
  ],
  missionChecks: {},
  missionStatuses: {},      // id → 'not_tried'|'in_progress'|'ready'
  pendingRubricCategory: null,
  teamGallery: [],          // [{id, image, caption, date, author}]
  links: [],                // [{id, title, url, category, author, date}]
  strategyBoardImage: null, // base64 background image (localStorage only, not Firestore)
  competitionDate: null,    // 'YYYY-MM-DD'
  judgingQs: null,          // null = use defaults (populated on first load)
  judgingDoc: null,         // { name, url, uploadedBy, date } — stored in Firebase Storage + Firestore
};

// Official FLL Unearthed 2026 missions (source: FIRST Israel scorer)
const MISSIONS_2026 = [
  { id: 1,  name: 'M01 – ציוד הגנה', pts: 20 },
  { id: 2,  name: 'M02 – בית הגידול', pts: 20 },
  { id: 3,  name: 'M03 – ניטור מים', pts: 20 },
  { id: 4,  name: 'M04 – דגימת ליבה', pts: 20 },
  { id: 5,  name: 'M05 – שחרור עץ', pts: 25 },
  { id: 6,  name: 'M06 – הזזת מכון קידוח', pts: 25 },
  { id: 7,  name: 'M07 – משאבה', pts: 25 },
  { id: 8,  name: 'M08 – שחרור אבנים', pts: 20 },
  { id: 9,  name: 'M09 – אנרגיה סולארית', pts: 25 },
  { id: 10, name: 'M10 – אוורור מרחב', pts: 20 },
  { id: 11, name: 'M11 – כלי עבודה', pts: 20 },
  { id: 12, name: 'M12 – מכונת קידוח', pts: 30 },
  { id: 13, name: 'M13 – הרים חומר', pts: 25 },
  { id: 14, name: 'M14 – פינוי', pts: 20 },
  { id: 15, name: 'M15 – נקודת ציון', pts: 20 },
];

// Official FLL Unearthed 2026 rubrics (FIRST Israel judging criteria)
const OFFICIAL_RUBRICS = {
  values: [
    'גילוי – הצוות מחפש מידע חדש ומשתף ממצאים בשמחה',
    'חדשנות – הצוות משתמש בחשיבה יצירתית לפתרון בעיות',
    'השפעה – הצוות מבין שעבודתו משפיעה לטובה על הסביבה',
    'שילוב – הצוות מכיל ומכבד את כל חברי הקהילה',
    'עבודת צוות – כל חברי הצוות תורמים ותומכים אחד בשני',
    'כיף – הצוות נהנה מהתהליך כולו ומעורר הנאה בסביבתו',
    'ערכים בפועל – הצוות מפגין את ערכי FLL בכל אינטראקציה בתחרות',
  ],
  robot: [
    'זיהוי בעיה – הצוות מגדיר בבהירות את אתגר המשימה לפני הפתרון',
    'תכנון – הצוות מתעד תוכניות וסקיצות לפני הבנייה',
    'בנייה – הרובוט בנוי בצורה יציבה ועומד בדרישות הגודל',
    'שיפור איטרטיבי – הצוות מתעד לפחות 3 גרסאות שיפור לכל זרוע',
    'תכנות – הקוד מאורגן, מוסבר ומציג בקרת תנועה אמינה',
    'שת"פ קוד-מכניקה – יש קשר ברור בין תכנות לעיצוב מכני',
    'ביצוע – הרובוט מבצע לפחות 8 משימות בריצה אחת',
  ],
  innovation: [
    'בעיה ממוקדת – הצוות מגדיר בבהירות בעיה אמיתית הקשורה לחציבה/עפר',
    'מחקר – הצוות אסף מידע ממקורות מגוונים ומומחים',
    'ראיונות – הצוות ראיין לפחות 3 בעלי עניין או מומחים',
    'פתרון מקורי – הרעיון הוא מקורי ולא קיים בשוק',
    'הנחיה – הצוות שיתף את הפתרון עם מומחים וקיבל משוב',
    'ישימות – הפתרון ניתן לביצוע עם משאבים סבירים',
    'שיתוף – הצוות הציג את הפתרון לקהילה רחבה',
  ],
};

// ═══════════════════════════════════════════════════════
// § 03 · STATE PERSISTENCE
// ═══════════════════════════════════════════════════════
// Rate limit: max 1 Firestore write per second
let _lastSave = 0;
let _saveTimer = null;
async function saveState() {
  try { localStorage.setItem(STORE_KEY, JSON.stringify(state)); } catch(e) {}
  if (!window.db) return;
  // Debounce: wait 1s before writing to Firestore to batch rapid changes
  clearTimeout(_saveTimer);
  _saveTimer = setTimeout(async () => {
    if (!window.db) return;
  try {
    const { members, logs, improvements, findings, rubrics, scores, checklist, seasons, missionChecks, setup, teamName, teamLogo, currentSeason } = state;
    await window.db.collection(window.FB_PROJECT).doc("settings").set({ setup, teamName, teamLogo: teamLogo || null, currentSeason, teamId: window.FB_PROJECT, joinCode: state.joinCode || null, mentorCode: state.mentorCode || null, studentCode: state.studentCode || null }, { merge: true });
    const stickies = state.stickies || [];
    const memberTasks = state.memberTasks || [];
    const customMissions = state.customMissions || [];
    const links = state.links || [];
    const judgingDoc = state.judgingDoc || null;
    await window.db.collection(window.FB_PROJECT).doc("data").set({ members, logs, improvements, findings, rubrics, scores, checklist, seasons, missionChecks, stickies, memberTasks, customMissions, links, judgingDoc }, { merge: true });
  } catch(e) { console.error("Firestore save error:", e); }
  }, 1000);
}

async function loadState() {
  // טוען ערכת צבעים מקומית תמיד
  try {
    const localTheme = localStorage.getItem('fll_theme');
    if (localTheme) state.theme = localTheme;
  } catch(e) {}

  if (!window.db || !window.FB_PROJECT) {
    try {
      const s = localStorage.getItem(STORE_KEY);
      if (s) state = { ...state, ...JSON.parse(s) };
    } catch(e) {}
    return;
  }

  try {
    const [settingsSnap, dataSnap] = await Promise.all([
      window.db.collection(window.FB_PROJECT).doc("settings").get(),
      window.db.collection(window.FB_PROJECT).doc("data").get(),
    ]);
    if (settingsSnap.exists) Object.assign(state, settingsSnap.data());
    if (dataSnap.exists) Object.assign(state, dataSnap.data());
    console.log("Loaded from Firestore, project:", window.FB_PROJECT);
    return;
  } catch(e) {
    console.warn("Firestore load failed, fallback:", e);
    try {
      const s = localStorage.getItem(STORE_KEY);
      if (s) state = { ...state, ...JSON.parse(s) };
    } catch(e2) {}
  }
}

// מוצא לאיזה קבוצה שייך המשתמש לפי אימייל
async function findTeamForUser(email) {
  if (!window.db) return null;
  try {
    const key = email.replace(/[.@]/g, '_');
    const snap = await window.db.collection(window.FB_REGISTRY).doc(key).get();
    if (snap.exists) return snap.data().teamId;
  } catch(e) {}
  return null;
}

// רושם מייל ברגיסטרי — קושר אותו לקבוצה
async function registerUserToTeam(email, teamId) {
  if (!window.db) return;
  try {
    const key = email.replace(/[.@]/g, '_');
    await window.db.collection(window.FB_REGISTRY).doc(key).set({ teamId, email });
  } catch(e) { console.warn('Registry write failed:', e); }
}
