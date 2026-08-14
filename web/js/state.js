// ═══════════════════════════════════════════════════════
// § 02 · CONSTANTS & STATE
// ═══════════════════════════════════════════════════════
const STORE_KEY = 'fll_app_v1';
// defaultState() - a fresh state object. Used both for the initial `state`
// below AND to reset `state` before creating a brand-new team: without this
// reset, any field left over from a previous team's session in this same
// page load (findings, interviews, logs, scores, gallery, …) would get
// written wholesale into the new team's Firestore docs on the first save.
function defaultState() {
  return {
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
    missionExtra: {},         // id → { bonus, rules, bonusDone, bonusPts } — free-text bonus/rule notes + bonus score per mission
    customMissions: [],       // mentor-imported mission list (overrides MISSIONS_2026 when populated)
    pendingRubricCategory: null,
    teamGallery: [],          // [{id, image, caption, date, author}]
    links: [],                // [{id, title, url, category, author, date}]
    strategyBoardImage: null, // base64 background image (localStorage only, not Firestore)
    competitionDate: null,    // 'YYYY-MM-DD'
    judgingQs: null,          // null = use defaults (populated on first load)
    judgingDoc: null,         // { name, url, uploadedBy, date } — stored in Firebase Storage + Firestore
  };
}
let state = defaultState();

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
    // NOTE: improvements/teamGallery are NOT written here — each photo is its
    // own document under a subcollection (see saveGalleryPhoto/
    // saveImprovementPhoto below), to keep this document well under 1MB.
    const { logs, findings, missionChecks } = state;
    const stickies = state.stickies || [];
    const memberTasks = state.memberTasks || [];
    const links = state.links || [];
    const interviews = state.interviews || [];
    const missionExtra = state.missionExtra || {};
    await window.db.collection(window.FB_PROJECT).doc("data").set({
      logs, findings, stickies, memberTasks, missionChecks, links, interviews, missionExtra,
      // Clean up the copy written before images moved to their own subcollection.
      improvements: firebase.firestore.FieldValue.delete(),
    }, { merge: true });

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

// ── Per-photo image documents ──────────────────────────
// Gallery/improvement photos are each their own document, in a "photos"
// subcollection under a small anchor doc (/{team}/gallery/photos/{id},
// /{team}/improvements/photos/{id}) — this keeps any single Firestore
// document (including the anchor doc and the "data" doc above) well under
// the 1MB limit no matter how many photos a team accumulates.
function _photoCollRef(anchorDoc) {
  return window.db.collection(window.FB_PROJECT).doc(anchorDoc).collection('photos');
}
async function saveGalleryPhoto(item) {
  if (!window.db) return;
  try { await _photoCollRef('gallery').doc(String(item.id)).set(item); } catch(e) { console.error('Gallery photo save error:', e); }
}
async function deleteGalleryPhotoDoc(id) {
  if (!window.db) return;
  try { await _photoCollRef('gallery').doc(String(id)).delete(); } catch(e) { console.error('Gallery photo delete error:', e); }
}
async function saveImprovementPhoto(item) {
  if (!window.db) return;
  try { await _photoCollRef('improvements').doc(String(item.id)).set(item); } catch(e) { console.error('Improvement photo save error:', e); }
}
async function deleteImprovementPhotoDoc(id) {
  if (!window.db) return;
  try { await _photoCollRef('improvements').doc(String(id)).delete(); } catch(e) { console.error('Improvement photo delete error:', e); }
}
// Wipes every doc in the improvements/photos subcollection — needed whenever
// state.improvements is reset in bulk (new season, full data reset), since
// clearing the local array alone would leave the per-photo docs behind for
// the next loadState() to resurrect.
async function deleteAllImprovementPhotos() {
  if (!window.db) return;
  try {
    const snap = await _photoCollRef('improvements').get();
    await Promise.all(snap.docs.map(d => d.ref.delete()));
  } catch(e) { console.error('Clear improvement photos error:', e); }
}

// mergeAndMigratePhotos() - merges the new per-photo subcollection docs with
// any legacy embedded array (the pre-split format, or Android's older
// single-document gallery) into one array. Legacy items are lazily migrated
// into their own documents (idempotent: doc id = item.id, so a retry just
// overwrites the same doc) and the legacy field is cleared only once the
// migration write has actually succeeded, so a failed/offline migration is
// retried on the next load instead of silently losing the images.
async function mergeAndMigratePhotos(photosSnap, legacyItems, saveFn, clearLegacyFn) {
  const byId = new Map();
  photosSnap.forEach(doc => byId.set(String(doc.id), doc.data()));
  if (legacyItems && legacyItems.length) {
    const toMigrate = legacyItems.filter(item => item && item.id != null && !byId.has(String(item.id)));
    if (toMigrate.length) {
      try {
        await Promise.all(toMigrate.map(item => saveFn(item)));
        await clearLegacyFn();
      } catch(e) { console.warn('Photo migration failed, will retry next load:', e); }
    }
    legacyItems.forEach(item => { if (item && item.id != null && !byId.has(String(item.id))) byId.set(String(item.id), item); });
  }
  return [...byId.values()].sort((a, b) => (a.id || 0) - (b.id || 0));
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
    const [settingsSnap, dataSnap, adminDataSnap, galleryAnchorSnap, galleryPhotosSnap, improvementPhotosSnap] = await Promise.all([
      window.db.collection(window.FB_PROJECT).doc("settings").get(),
      window.db.collection(window.FB_PROJECT).doc("data").get(),
      window.db.collection(window.FB_PROJECT).doc("admin-data").get(),
      window.db.collection(window.FB_PROJECT).doc("gallery").get(),
      _photoCollRef('gallery').get(),
      _photoCollRef('improvements').get(),
    ]);
    if (settingsSnap.exists) Object.assign(state, settingsSnap.data());
    if (dataSnap.exists) Object.assign(state, dataSnap.data());
    if (adminDataSnap.exists) Object.assign(state, adminDataSnap.data());

    // teamGallery: legacy source is the "items" field on the gallery anchor
    // doc itself (the pre-split web/Android format).
    const legacyGalleryItems = galleryAnchorSnap.exists ? (galleryAnchorSnap.data().items || null) : null;
    state.teamGallery = await mergeAndMigratePhotos(galleryPhotosSnap, legacyGalleryItems, saveGalleryPhoto,
      () => window.db.collection(window.FB_PROJECT).doc('gallery').set({ items: firebase.firestore.FieldValue.delete() }, { merge: true }));

    // improvements: legacy source is the "improvements" field on the "data"
    // doc (already picked up by Object.assign above, before this migration).
    const legacyImprovements = (dataSnap.exists && dataSnap.data().improvements) || null;
    state.improvements = await mergeAndMigratePhotos(improvementPhotosSnap, legacyImprovements, saveImprovementPhoto,
      () => window.db.collection(window.FB_PROJECT).doc('data').set({ improvements: firebase.firestore.FieldValue.delete() }, { merge: true }));

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
