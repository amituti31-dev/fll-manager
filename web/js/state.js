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
    currentSeason: OFFICIAL_SEASON_NAME,
    members: [],
    logs: [],
    improvements: [],
    findings: [],
    interviews: [],
    rubrics: { values: [], robot: [], innovation: [] },
    scores: [],
    checklist: DEFAULT_CHECKLIST.map(item => ({ ...item })),
    seasons: [
      { name: OFFICIAL_SEASON_NAME, year: 2026, archived: false, topScore: 0 },
    ],
    missionChecks: {},
    precisionTokens: 6,       // precision tokens left (0-6) — see PRECISION_TOKEN_POINTS
    missionStatuses: {},      // id → 'not_tried'|'in_progress'|'ready'
    missionExtra: {},         // id → { bonus, rules, bonusDone, bonusPts } — free-text bonus/rule notes + bonus score per mission
    customMissions: [],       // mentor-imported mission list (overrides OFFICIAL_MISSIONS when populated; shared with Android)
    pendingRubricCategory: null,
    teamGallery: [],          // [{id, image, caption, date, author}]
    links: [],                // [{id, title, url, category, author, date}]
    milestones: [],            // [{id, title, targetDate, done}]
    meetingPlans: [],          // [{id, date, title, plan, summary}] — see calendar.js
    seasonStory: null,         // {text, createdAt, model} — AI season story (story.js)
    strategyBoardImage: null, // OLD local-only board background — migrated into a shared board (strategy.js)
    competitionDate: null,    // 'YYYY-MM-DD'
    judgingQs: null,          // null = use defaults (populated on first load)
    officialRubric: { marks: { innovation: {}, robot: {} }, notes: { innovation: {}, robot: {} }, feedback: {} }, // judging-room rubric marks (see rubrics.js)
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
  if (window._restoreInProgress) return; // a restore is rewriting the cloud copy — don't race it
  try { localStorage.setItem(STORE_KEY, JSON.stringify(state)); } catch(e) {}
  if (!window.db) return;
  // Debounce: wait 1s before writing to Firestore to batch rapid changes
  clearTimeout(_saveTimer);
  window._savePending = true; // live sync (live.js) waits for this save
  _saveTimer = setTimeout(async () => {
    if (!window.db) { window._savePending = false; return; }
  try {
    const { setup, teamName, teamLogo, currentSeason } = state;
    // competitionDate is shared with Android (settings doc), always 'YYYY-MM-DD'.
    const competitionDate = state.competitionDate ? String(state.competitionDate).slice(0, 10) : null;
    await window.db.collection(window.FB_PROJECT).doc("settings").set({ setup, teamName, teamLogo: teamLogo || null, currentSeason, competitionDate, teamId: window.FB_PROJECT, joinCode: state.joinCode || null, mentorCode: state.mentorCode || null, studentCode: state.studentCode || null }, { merge: true });

    // "data" — writable by any team member (students included). missionChecks
    // and links are here too: any member can toggle a mission or add a link.
    // NOTE: improvements/teamGallery are NOT written here — each photo is its
    // own document under a subcollection (see saveGalleryPhoto/
    // saveImprovementPhoto below), to keep this document well under 1MB.
    const { logs, findings, missionChecks } = state;
    const precisionTokens = getPrecisionTokens();
    const innovationProblem = state.innovationProblem || '';
    const innovationSolution = state.innovationSolution || '';
    const innovationSharing = state.innovationSharing || '';
    const stickies = state.stickies || [];
    const memberTasks = state.memberTasks || [];
    const links = state.links || [];
    const interviews = state.interviews || [];
    const missionExtra = state.missionExtra || {};
    const milestones = state.milestones || [];
    const meetingPlans = state.meetingPlans || [];
    const seasonStory = state.seasonStory || null;
    await window.db.collection(window.FB_PROJECT).doc("data").set({
      logs, findings, stickies, memberTasks, missionChecks, precisionTokens, links, interviews, missionExtra,
      innovationProblem, innovationSolution, innovationSharing,
      // Shared with Android: practice status per mission, and judging Q&A as a
      // flat list [{id, category, question, answer}] (web groups it by category).
      missionStatuses: state.missionStatuses || {},
      ...(state.judgingQs ? { judgingQuestions: [].concat(...Object.values(state.judgingQs)) } : {}),
      milestones, meetingPlans, seasonStory,
      // Clean up the copy written before images moved to their own subcollection.
      improvements: firebase.firestore.FieldValue.delete(),
      // Planned-meetings feature was removed — the calendar now shows value stickies instead.
      meetings: firebase.firestore.FieldValue.delete(),
    }, { merge: true });

    // "admin-data" — mentor-only per Firestore rules. Never sync raw PINs
    // to clients: strip them from the members list before writing.
    const { scores, rubrics, checklist, seasons } = state;
    const members = (state.members || []).map(({ pin, ...rest }) => rest);
    const customMissions = state.customMissions || [];
    const judgingDoc = state.judgingDoc || null;
    const officialRubric = state.officialRubric || null;
    const lastBackupAt = state.lastBackupAt || null;
    await window.db.collection(window.FB_PROJECT).doc("admin-data").set({
      members, scores, rubrics, checklist, seasons, customMissions, judgingDoc, officialRubric, lastBackupAt,
      // Old Android-only copy of the mission list — both clients now share customMissions.
      missions: firebase.firestore.FieldValue.delete(),
      // Clean up the copies written by v1.0.8, before these moved to "data".
      missionChecks: firebase.firestore.FieldValue.delete(),
      links: firebase.firestore.FieldValue.delete(),
    }, { merge: true });
  } catch(e) { console.error("Firestore save error:", e); }
  finally { window._savePending = false; }
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
    applyOfficialBonuses();

    // Judging Q&A comes from the cloud as a flat list (shared with Android).
    // data.judgingQuestions is current; admin-data's is an older Android copy
    // (Object.assign above applied admin-data last, so prefer data explicitly).
    const jqData = dataSnap.exists ? dataSnap.data().judgingQuestions : null;
    const jq = (Array.isArray(jqData) && jqData.length) ? jqData : state.judgingQuestions;
    if (Array.isArray(jq) && jq.length) {
      const g = { robot: [], innovation: [], values: [] };
      jq.forEach(q => (g[q.category] || (g[q.category] = [])).push(q));
      state.judgingQs = g;
    }
    delete state.judgingQuestions;

    // Links: older Android versions kept them in a separate 'links' doc —
    // merge those into data.links once, then empty that doc.
    try {
      const linksDoc = await window.db.collection(window.FB_PROJECT).doc('links').get();
      const legacy = (linksDoc.exists && linksDoc.data().items) || [];
      if (legacy.length) {
        const have = new Set((state.links || []).map(l => String(l.id)));
        state.links = [...(state.links || []), ...legacy.filter(l => !have.has(String(l.id)))
          .map(l => ({ ...l, author: l.author || l.addedBy || '' }))];
        await saveState();
        await window.db.collection(window.FB_PROJECT).doc('links').set({ items: [] });
      }
    } catch (e) { console.warn('Links migration:', e); }

    // Innovation steps used to be kept only in this browser (state.innovSteps,
    // localStorage). Move any text there into the synced fields Android uses —
    // only where the cloud copy is still empty — then drop the local copy.
    const legacySteps = state.innovSteps || {};
    let movedSteps = false;
    Object.entries({ problem: 'innovationProblem', solution: 'innovationSolution', sharing: 'innovationSharing' })
      .forEach(([key, field]) => {
        if (legacySteps[key] && !String(state[field] || '').trim()) { state[field] = legacySteps[key]; movedSteps = true; }
      });
    delete state.innovSteps;
    if (movedSteps) saveState();

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

    // Normalize images saved without the data-URL prefix so they render.
    [state.teamGallery, state.improvements, state.logs].forEach(list => (list || []).forEach(item => {
      if (item && item.image && !item.image.startsWith('data:image')) item.image = imageSrc(item.image) || item.image;
    }));

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
// The role in this user's own registry entry, if it points at teamId.
async function getOwnRegistryRole(email, teamId) {
  if (!window.db) return null;
  try {
    const snap = await window.db.collection(window.FB_REGISTRY).doc(email.replace(/[.@]/g, '_')).get();
    return snap.exists && snap.data().teamId === teamId ? (snap.data().role || null) : null;
  } catch (e) { return null; }
}

// Students can't write admin-data, but firestore.rules (isSelfJoin) let a
// registered member append exactly one entry — themselves, as a student — to
// admin-data.members. The transaction keeps the existing list identical and
// writes only that field, which is what the rule checks.
async function addSelfToMembers(member) {
  if (!window.db) return false;
  const ref = window.db.collection(window.FB_PROJECT).doc('admin-data');
  try {
    await window.db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      const members = (snap.exists && snap.data().members) || [];
      if (members.some(m => m.email === member.email)) return;
      tx.set(ref, { members: [...members, member] }, { merge: true });
    });
    return true;
  } catch (e) { console.warn('Self-join failed:', e); return false; }
}

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
