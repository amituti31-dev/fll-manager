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
  interviews: [],
  rubrics: { values: [], robot: [], innovation: [] },
  scores: [],
  checklist: DEFAULT_CHECKLIST.map(item => ({ ...item })),
  seasons: [
    { name: 'Unearthed 2026', year: 2026, archived: false, topScore: 0 },
  ],
  missionChecks: {},
  missionStatuses: {},      // id → 'not_tried'|'in_progress'|'ready'
  missionExtra: {},         // id → { bonus, rules, bonusDone } — free-text bonus/rule notes per mission
  customMissions: [],       // mentor-imported mission list (overrides MISSIONS_2026 when populated)
  pendingRubricCategory: null,
  teamGallery: [],          // [{id, image, caption, date, author}]
  links: [],                // [{id, title, url, category, author, date}]
  strategyBoardImage: null, // base64 background image (localStorage only, not Firestore)
  competitionDate: null,    // 'YYYY-MM-DD'
  judgingQs: null,          // null = use defaults (populated on first load)
  judgingDoc: null,         // { name, url, uploadedBy, date } — stored in Firebase Storage + Firestore
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
    const { setup, teamName, teamLogo, currentSeason } = state;
    await window.db.collection(window.FB_PROJECT).doc("settings").set({ setup, teamName, teamLogo: teamLogo || null, currentSeason, teamId: window.FB_PROJECT, joinCode: state.joinCode || null, mentorCode: state.mentorCode || null, studentCode: state.studentCode || null }, { merge: true });

    // "data" — writable by any team member (students included). missionChecks
    // and links are here too: any member can toggle a mission or add a link.
    const { logs, improvements, findings, missionChecks } = state;
    const stickies = state.stickies || [];
    const memberTasks = state.memberTasks || [];
    const links = state.links || [];
    const interviews = state.interviews || [];
    const missionExtra = state.missionExtra || {};
    await window.db.collection(window.FB_PROJECT).doc("data").set({ logs, improvements, findings, stickies, memberTasks, missionChecks, links, interviews, missionExtra }, { merge: true });

    // "admin-data" — mentor-only per Firestore rules. Never sync raw PINs
    // to clients: strip them from the members list before writing.
    const { scores, rubrics, checklist, seasons } = state;
    const members = (state.members || []).map(({ pin, ...rest }) => rest);
    const customMissions = state.customMissions || [];
    const judgingDoc = state.judgingDoc || null;
    await window.db.collection(window.FB_PROJECT).doc("admin-data").set({
      members, scores, rubrics, checklist, seasons, customMissions, judgingDoc,
      // Clean up the copies written by v1.0.8, before these moved to "data".
      missionChecks: firebase.firestore.FieldValue.delete(),
      links: firebase.firestore.FieldValue.delete(),
    }, { merge: true });
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
    const [settingsSnap, dataSnap, adminDataSnap] = await Promise.all([
      window.db.collection(window.FB_PROJECT).doc("settings").get(),
      window.db.collection(window.FB_PROJECT).doc("data").get(),
      window.db.collection(window.FB_PROJECT).doc("admin-data").get(),
    ]);
    if (settingsSnap.exists) Object.assign(state, settingsSnap.data());
    if (dataSnap.exists) Object.assign(state, dataSnap.data());
    if (adminDataSnap.exists) Object.assign(state, adminDataSnap.data());
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

// רושם מייל ברגיסטרי — קושר אותו לקבוצה ולתפקיד (מנטור/תלמיד), כדי
// שחוקי ה-Firestore יוכלו לאכוף הרשאות בצד השרת
async function registerUserToTeam(email, teamId, role) {
  if (!window.db) return;
  try {
    const key = email.replace(/[.@]/g, '_');
    await window.db.collection(window.FB_REGISTRY).doc(key).set({ teamId, email, role });
  } catch(e) { console.warn('Registry write failed:', e); }
}
