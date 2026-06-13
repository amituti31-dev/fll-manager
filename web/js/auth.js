// ═══════════════════════════════════════════════════════
// § 04 · PIN SYSTEM
// ═══════════════════════════════════════════════════════
let pinBuffer = '';
let selectedLoginRole = 'student'; // default

function selectLoginRole(role) {
  selectedLoginRole = role;
  const sBtn = document.getElementById('role-btn-student');
  const mBtn = document.getElementById('role-btn-mentor');
  if (role === 'student') {
    sBtn.style.background = 'var(--accent)'; sBtn.style.color = '#fff';
    mBtn.style.background = 'transparent'; mBtn.style.color = 'var(--text2)';
  } else {
    mBtn.style.background = 'var(--accent3)'; mBtn.style.color = '#fff';
    sBtn.style.background = 'transparent'; sBtn.style.color = 'var(--text2)';
  }
  pinBuffer = ''; updatePinDots();
  document.getElementById('pin-error').textContent = '';
}

function pinInput(d) {
  if (d === '') return;
  if (pinBuffer.length < 6) { pinBuffer += d; updatePinDots(); }
  if (pinBuffer.length === 6) setTimeout(checkPin, 100);
}
function clearPin() { pinBuffer = pinBuffer.slice(0, -1); updatePinDots(); }
function updatePinDots() {
  document.querySelectorAll('.pin-dot').forEach((d, i) => d.classList.toggle('filled', i < pinBuffer.length));
}
function checkPin() {
  document.getElementById('pin-error').textContent = '';
  // Filter members by selected role
  const roleFilter = selectedLoginRole === 'mentor' ? 'admin' : 'student';
  const user = state.members.find(m => m.pin === pinBuffer && m.role === roleFilter);
  if (user) {
    state.currentUser = user;
    // Admin mode only if user is actually a mentor
    state.isAdmin = user.role === 'admin';
    document.getElementById('pin-screen').style.display = 'none';
    initApp();
  } else {
    document.getElementById('pin-error').textContent = '❌ קוד שגוי או תפקיד לא מתאים';
    pinBuffer = '';
    updatePinDots();
  }
}
function showForgotPin() { notify('📧 בקשת איפוס נשלחה לאימייל', 'success'); }

// ═══════════════════════════════════════════════════════
// § 05 · TEAM SETUP
// ═══════════════════════════════════════════════════════
function loginGoTo(step) {
  ['choose','auth','create','join'].forEach(s => {
    const el = document.getElementById('login-step-' + s);
    if (el) el.style.display = s === step ? 'block' : 'none';
  });
  const errEl = document.getElementById('pin-error');
  if (errEl) errEl.textContent = '';
  const joinErrEl = document.getElementById('join-login-error');
  if (joinErrEl) joinErrEl.textContent = '';
  // שמור כוונת משתמש — חשוב לonAuthStateChanged
  if (step === 'create') window._loginIntent = 'create';
  else if (step === 'join') window._loginIntent = 'join';
  else if (step === 'auth') window._loginIntent = 'auth';
  // לא מאפסים ב-choose כדי לשמור intent קודם
}

// הרשמה ויצירת קבוצה
async function registerForCreate() {
  window._loginIntent = 'create'; // חשוב!
  const email = document.getElementById('create-email').value.trim();
  const pass  = document.getElementById('create-password').value;
  if (!email || !pass) { showLoginError('נא למלא אימייל וסיסמא'); return; }
  if (pass.length < 6) { showLoginError('סיסמא חייבת לפחות 6 תווים'); return; }
  try {
    const result = await window.auth.createUserWithEmailAndPassword(email, pass);
    // שמור fbUser ישירות — לא לחכות ל-onAuthStateChanged
    window._pendingFbUser = result.user;
    // הצג setup-screen מיד
    document.getElementById('pin-screen').style.display = 'none';
    document.getElementById('setup-screen').style.display = 'flex';
    showSetupStep('create');
  } catch(e) {
    if (e.code === 'auth/email-already-in-use') {
      // אם האימייל קיים — נסה להתחבר
      try {
        const result2 = await window.auth.signInWithEmailAndPassword(email, pass);
        window._pendingFbUser = result2.user;
        // בדוק אם כבר יש קבוצה לפי מייל זה
        const existingTeam = await findTeamForUser(email);
        if (existingTeam) {
          showLoginError('אימייל זה כבר שייך לקבוצה אחרת. השתמש באימייל אחר.');
          await window.auth.signOut();
          window._pendingFbUser = null;
          return;
        }
        document.getElementById('pin-screen').style.display = 'none';
        document.getElementById('setup-screen').style.display = 'flex';
        showSetupStep('create');
      } catch(e2) {
        showLoginError('אימייל כבר קיים — בדוק סיסמא');
      }
    } else {
      showLoginError(e.message);
    }
  }
}

// הצטרפות עם קוד ישירות ממסך הכניסה
async function joinWithCode() {
  const fullName = document.getElementById('join-fullname').value.trim();
  const code     = document.getElementById('join-code-input').value.trim().toUpperCase();
  const email    = document.getElementById('join-email').value.trim();
  const pass     = document.getElementById('join-password').value;
  const errEl    = document.getElementById('join-login-error');
  errEl.textContent = '';

  if (!fullName) { errEl.textContent = '❌ נדרש שם מלא'; return; }
  if (!code)     { errEl.textContent = '❌ נדרש קוד הצטרפות'; return; }
  if (!email)    { errEl.textContent = '❌ נדרש אימייל'; return; }
  if (pass.length < 6) { errEl.textContent = '❌ סיסמא חייבת לפחות 6 תווים'; return; }
  if (!window.db) { errEl.textContent = '❌ Firebase לא מחובר'; return; }

  window._joiningInProgress = true;

  try {
    // שלב 1: התחבר קודם — Firestore דורש auth
    errEl.textContent = '⏳ מתחבר...';
    let fbUser;
    try {
      fbUser = (await window.auth.createUserWithEmailAndPassword(email, pass)).user;
    } catch(authErr) {
      if (authErr.code === 'auth/email-already-in-use') {
        try {
          fbUser = (await window.auth.signInWithEmailAndPassword(email, pass)).user;
        } catch(e2) {
          window._joiningInProgress = false;
          errEl.textContent = e2.code === 'auth/wrong-password' ? '❌ סיסמא שגויה' : '❌ ' + e2.message;
          return;
        }
      } else {
        window._joiningInProgress = false;
        errEl.textContent = '❌ ' + authErr.message;
        return;
      }
    }

    // שלב 2: עכשיו יש auth — חפש קוד ב-Firestore
    errEl.textContent = '⏳ מחפש קבוצה...';
    const [mentorSnap, studentSnap] = await Promise.all([
      window.db.collection(window.FB_REGISTRY).doc('mentor_' + code).get(),
      window.db.collection(window.FB_REGISTRY).doc('student_' + code).get(),
    ]);

    let teamId = null, role = 'student';
    if (mentorSnap.exists)       { teamId = mentorSnap.data().teamId; role = 'admin'; }
    else if (studentSnap.exists) { teamId = studentSnap.data().teamId; role = 'student'; }
    else {
      await window.auth.signOut();
      window._joiningInProgress = false;
      errEl.textContent = '❌ קוד לא נמצא. בדוק שהקוד נכון';
      return;
    }

    // שלב 3: טען נתוני קבוצה
    errEl.textContent = '⏳ טוען נתונים...';
    window.FB_PROJECT = teamId;
    await loadState();

    // בדוק אם כבר חבר
    const existing = state.members.find(m => m.email === fbUser.email);
    if (existing) {
      state.currentUser = existing;
      state.isAdmin = existing.role === 'admin';
      await registerUserToTeam(fbUser.email, teamId);
      try { localStorage.setItem('fll_team_id', teamId); } catch(e) {}
      window._joiningInProgress = false;
      document.getElementById('pin-screen').style.display = 'none';
      initApp();
      notify('✅ ברוך הבא בחזרה!', 'success');
      return;
    }

    // הוסף חבר חדש
    const colors = ['#3d7fff','#00d4a0','#ff6b35','#f5c842','#ff4d6d','#9c6fe4'];
    const newMember = {
      id: fbUser.uid, name: fullName, role, email: fbUser.email,
      color: colors[state.members.length % colors.length], pin: '',
    };
    state.members.push(newMember);
    state.currentUser = newMember;
    state.isAdmin = (role === 'admin');
    await saveState();
    await registerUserToTeam(fbUser.email, teamId);
    try { localStorage.setItem('fll_team_id', teamId); } catch(e) {}
    window._joiningInProgress = false;
    document.getElementById('pin-screen').style.display = 'none';
    initApp();
    notify(`✅ הצטרפת לקבוצה כ${role === 'admin' ? 'מנטור 👑' : 'תלמיד 🎓'}!`, 'success');

  } catch(e) {
    window._joiningInProgress = false;
    errEl.textContent = '❌ שגיאה: ' + e.message;
    console.error('joinWithCode:', e);
  }
}

// ── Setup wizard steps ──
function showSetupStep(step) {
  ['choose','create','join','code'].forEach(s => {
    const el = document.getElementById('setup-step-' + s);
    if (el) el.style.display = s === step ? 'block' : 'none';
  });
}

function backFromSetup() {
  // חזור למסך הכניסה
  document.getElementById('setup-screen').style.display = 'none';
  document.getElementById('pin-screen').style.display = 'flex';
  // התנתק כדי שהמשתמש יוכל לבחור מחדש
  if (window.auth) window.auth.signOut().catch(() => {});
  window._loginIntent = null;
  window._pendingFbUser = null;
  try { localStorage.removeItem('fll_team_id'); } catch(e) {}
  loginGoTo('choose');
}

// כניסה עם Google ליצירת קבוצה
async function loginWithGoogleForCreate() {
  window._loginIntent = 'create';
  if (!window.auth) { showLoginError('Firebase לא מחובר'); return; }
  try {
    const provider = new firebase.auth.GoogleAuthProvider();
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    if (isSafari) {
      // Safari חוסם popup — שמור intent ועשה redirect
      window._loginIntent = 'create';
      try { sessionStorage.setItem('fll_login_intent', 'create'); } catch(e) {}
      await window.auth.signInWithRedirect(provider);
      return;
    }
    const result = await window.auth.signInWithPopup(provider);
    const fbUser = result.user;
    window._pendingFbUser = fbUser;
    const existingTeam = await findTeamForUser(fbUser.email);
    if (existingTeam) {
      showLoginError('חשבון Google זה כבר שייך לקבוצה אחרת. השתמש בחשבון אחר.');
      await window.auth.signOut();
      window._pendingFbUser = null;
      return;
    }
    document.getElementById('pin-screen').style.display = 'none';
    document.getElementById('setup-screen').style.display = 'flex';
    showSetupStep('create');
  } catch(e) {
    if (e.code !== 'auth/popup-closed-by-user')
      showLoginError('שגיאה: ' + e.message);
  }
}

// יצירת קוד קריא לבני אדם — 4 אותיות + 4 ספרות
function generateJoinCode() {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // ללא I,O שמבלבלים
  const digits  = '23456789';                  // ללא 0,1 שמבלבלים
  let code = '';
  for (let i = 0; i < 4; i++) code += letters[Math.floor(Math.random() * letters.length)];
  code += '-';
  for (let i = 0; i < 4; i++) code += digits[Math.floor(Math.random() * digits.length)];
  return code;
}

function copyCode(type) {
  const id = type === 'mentor' ? 'display-mentor-code' : 'display-student-code';
  const code = document.getElementById(id)?.textContent || '';
  const label = type === 'mentor' ? '👑 קוד מנטורים' : '🎓 קוד תלמידים';
  navigator.clipboard?.writeText(code).then(() => notify(`📋 ${label} הועתק: ${code}`, 'success'))
    .catch(() => notify(`קוד: ${code}`, 'success'));
}

function copyJoinCode() { copyCode('student'); }

let _pendingTeamId = null;
let _pendingJoinCode = null;

// ── Create new team ──
async function completeSetup() {
  const name = document.getElementById('setup-name').value.trim();
  const teamName = document.getElementById('setup-team').value.trim();
  if (!name) { notify('נדרש שם מלא', 'error'); return; }
  if (!teamName) { notify('נדרש שם קבוצה', 'error'); return; }

  const fbUser = window._pendingFbUser || (window.auth && window.auth.currentUser);
  if (!fbUser) { notify('שגיאה — לא מחובר', 'error'); return; }

  // יצירת teamId ייחודי
  const teamSlug = teamName.trim().replace(/\s+/g, '-').replace(/[^a-zA-Z0-9\u0590-\u05FF-]/g, '').toLowerCase();
  const uniqueSuffix = Math.random().toString(36).substring(2, 6);
  const teamId = 'team-' + teamSlug + '-' + uniqueSuffix;

  // יצירת קוד הצטרפות קריא
  const joinCode = generateJoinCode();

  window.FB_PROJECT = teamId;
  _pendingTeamId = teamId;
  _pendingJoinCode = joinCode;

  const firstMentor = {
    id: fbUser.uid, name, role: 'admin',
    email: fbUser.email, color: '#3d7fff', pin: '',
  };

  state.setup = true;
  state.teamName = teamName;
  state.teamId = teamId;
  state.joinCode = joinCode;
  state.members = [firstMentor];
  state.currentUser = firstMentor;
  state.isAdmin = true;

  // שמור נתונים
  await saveState();

  // יצור קוד נפרד למנטורים ולתלמידים
  const mentorCode  = generateJoinCode();
  const studentCode = generateJoinCode();
  state.mentorCode  = mentorCode;
  state.studentCode = studentCode;

  // שמור שני קודים ברגיסטרי
  if (window.db) {
    try {
      await Promise.all([
        window.db.collection(window.FB_REGISTRY).doc('mentor_' + mentorCode).set({ teamId, joinCode: mentorCode, role: 'admin', teamName, createdAt: new Date().toISOString() }),
        window.db.collection(window.FB_REGISTRY).doc('student_' + studentCode).set({ teamId, joinCode: studentCode, role: 'student', teamName, createdAt: new Date().toISOString() }),
      ]);
    } catch(e) { console.warn('Join code registry failed:', e); }
  }

  // רשום מנטור ב-registry
  await registerUserToTeam(fbUser.email, teamId);

  // שמור ב-localStorage
  try { localStorage.setItem('fll_team_id', teamId); } catch(e) {}

  // הצג את שני הקודים
  document.getElementById('display-mentor-code').textContent  = mentorCode;
  document.getElementById('display-student-code').textContent = studentCode;
  showSetupStep('code');
}

function finishSetup() {
  document.getElementById('setup-screen').style.display = 'none';
  initApp();
  notify('✅ ברוך הבא לקבוצה!', 'success');
}

// ── Join existing team ──
async function joinTeam() {
  const name = document.getElementById('join-name').value.trim();
  const code = document.getElementById('join-code').value.trim().toUpperCase();
  const errEl = document.getElementById('join-error');
  errEl.textContent = '';

  if (!name) { errEl.textContent = '❌ נדרש שם מלא'; return; }
  if (!code || code.length < 4) { errEl.textContent = '❌ נדרש קוד הצטרפות'; return; }

  const fbUser = window._pendingFbUser || (window.auth && window.auth.currentUser);
  if (!fbUser) { errEl.textContent = '❌ שגיאה — לא מחובר'; return; }

  errEl.textContent = '⏳ מחפש קבוצה...';

  try {
    // חפש teamId לפי קוד ב-registry (mentor_ / student_)
    let teamId = null, joinRole = 'student';
    if (window.db) {
      const [mentorSnap, studentSnap] = await Promise.all([
        window.db.collection(window.FB_REGISTRY).doc('mentor_' + code).get(),
        window.db.collection(window.FB_REGISTRY).doc('student_' + code).get(),
      ]);
      if (mentorSnap.exists)       { teamId = mentorSnap.data().teamId;  joinRole = 'admin'; }
      else if (studentSnap.exists) { teamId = studentSnap.data().teamId; joinRole = 'student'; }
    }

    if (!teamId) {
      errEl.textContent = '❌ קוד לא נמצא. בדוק שהקוד נכון ונסה שוב';
      return;
    }

    // טען את נתוני הקבוצה
    window.FB_PROJECT = teamId;
    await loadState();

    // בדוק שהמייל לא כבר קיים
    const existing = state.members.find(m => m.email === fbUser.email);
    if (existing) {
      // כבר חבר — פשוט היכנס
      state.currentUser = existing;
      state.isAdmin = existing.role === 'admin';
      await registerUserToTeam(fbUser.email, teamId);
      try { localStorage.setItem('fll_team_id', teamId); } catch(e) {}
      document.getElementById('setup-screen').style.display = 'none';
      initApp();
      notify('✅ ברוך הבא בחזרה!', 'success');
      return;
    }

    // הוסף חבר חדש לקבוצה עם התפקיד לפי הקוד
    const colors = ['#3d7fff','#00d4a0','#ff6b35','#f5c842','#ff4d6d','#9c6fe4'];
    const newMember = {
      id: fbUser.uid, name, role: joinRole,
      email: fbUser.email,
      color: colors[state.members.length % colors.length],
      pin: '',
    };

    state.members.push(newMember);
    state.currentUser = newMember;
    state.isAdmin = false;

    await saveState();
    await registerUserToTeam(fbUser.email, teamId);
    try { localStorage.setItem('fll_team_id', teamId); } catch(e) {}

    document.getElementById('setup-screen').style.display = 'none';
    initApp();
    notify('✅ הצטרפת לקבוצה בהצלחה!', 'success');

  } catch(e) {
    errEl.textContent = '❌ שגיאה: ' + e.message;
  }
}

function handleLogoUpload(e, ctx) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    state.teamLogo = ev.target.result;
    if (ctx === 'setup') {
      const canvas = document.getElementById('setup-crop-canvas');
      document.getElementById('setup-crop-area').style.display = 'block';
      const img = new Image(); img.onload = () => {
        canvas.width = Math.min(img.width, 300); canvas.height = Math.min(img.height, 300);
        const ctx2 = canvas.getContext('2d');
        ctx2.drawImage(img, 0, 0, canvas.width, canvas.height);
      }; img.src = ev.target.result;
    }
    updateLogoDisplay();
    saveState();
  };
  reader.readAsDataURL(file);
}

function updateLogoDisplay() {
  const logo = state.teamLogo;
  const els = ['sidebar-logo'];
  els.forEach(id => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = logo ? `<img src="${logo}" alt="logo">` : '🤖';
  });
}

// ═══════════════════════════════════════════════════════
// § 28 · AUTH & BOOT
// ═══════════════════════════════════════════════════════
async function loginWithGoogle() {
  if (!window.auth) { showLoginError('Firebase לא מחובר'); return; }
  // שמור intent לפני הפנייה לGoogle (כי לפעמים intent מתאפס)
  if (!window._loginIntent) window._loginIntent = 'auth';
  try {
    const provider = new firebase.auth.GoogleAuthProvider();
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    if (isSafari) {
      try { sessionStorage.setItem('fll_login_intent', window._loginIntent || 'auth'); } catch(e) {}
      await window.auth.signInWithRedirect(provider);
      return;
    }
    await window.auth.signInWithPopup(provider);
  } catch(e) {
    showLoginError('שגיאה בכניסה עם Google: ' + e.message);
  }
}

async function loginWithEmail() {
  const email = document.getElementById('login-email').value.trim();
  const pass = document.getElementById('login-password').value;
  if (!email || !pass) { showLoginError('נא למלא אימייל וסיסמא'); return; }
  try {
    await window.auth.signInWithEmailAndPassword(email, pass);
  } catch(e) {
    showLoginError('שגיאה בכניסה: ' + (e.code === 'auth/wrong-password' ? 'סיסמא שגויה' : e.code === 'auth/user-not-found' ? 'משתמש לא קיים' : e.message));
  }
}

async function registerWithEmail() {
  const email = document.getElementById('login-email').value.trim();
  const pass = document.getElementById('login-password').value;
  if (!email || !pass) { showLoginError('נא למלא אימייל וסיסמא'); return; }
  if (pass.length < 6) { showLoginError('סיסמא חייבת לפחות 6 תווים'); return; }
  try {
    await window.auth.createUserWithEmailAndPassword(email, pass);
  } catch(e) {
    showLoginError('שגיאה בהרשמה: ' + (e.code === 'auth/email-already-in-use' ? 'אימייל כבר קיים' : e.message));
  }
}

async function resetPassword() {
  const email = document.getElementById('login-email').value.trim();
  if (!email) { showLoginError('הכנס אימייל לאיפוס'); return; }
  try {
    await window.auth.sendPasswordResetEmail(email);
    showLoginError('✅ אימייל איפוס נשלח!');
  } catch(e) {
    showLoginError('שגיאה: ' + e.message);
  }
}

function showLoginError(msg) {
  const el = document.getElementById('pin-error');
  if (el) el.textContent = msg;
}

async function signOut() {
  if (window.auth) await window.auth.signOut();
  state.currentUser = null;
  state.isAdmin = false;
  window.FB_PROJECT = null;
  try { localStorage.removeItem('fll_team_id'); } catch(e) {}
  document.getElementById('app').style.display = 'none';
  document.getElementById('pin-screen').style.display = 'flex';
}

// ── Boot & auth state listener ──
async function boot() {
  // Load Firebase SDKs dynamically
  await new Promise((resolve) => {
    const sdks = [
      'https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js',
      'https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js',
      'https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js',
    ];
    function loadNext(i) {
      if (i >= sdks.length) { resolve(); return; }
      const s = document.createElement('script');
      s.src = sdks[i];
      s.onload = () => loadNext(i + 1);
      s.onerror = () => loadNext(i + 1);
      document.head.appendChild(s);
    }
    loadNext(0);
  });

  try {
    if (!firebase.apps.length) {
      firebase.initializeApp({
        apiKey: "AIzaSyBok0hLHN9nRflFEjZoiSg0GL8a90kAESU",
        authDomain: "fll-manger.firebaseapp.com",
        projectId: "fll-manger",
        storageBucket: "fll-manger.firebasestorage.app",
        messagingSenderId: "493332319136",
        appId: "1:493332319136:web:ee2268657dbf4b29b532c5"
      });
    }
    window.db = firebase.firestore();
    window.auth = firebase.auth();
    window.FB_PROJECT = null; // יוגדר דינמי לפי קבוצה
    window._loginIntent = 'auth'; // ברירת מחדל
    window._joiningInProgress = false;
    window.FB_REGISTRY = 'fll-teams-registry'; // קולקציה ראשית שמחזיקה את מפת אימייל → קבוצה
    console.log('Firebase connected!');
    // IMPORTANT: Set Firestore rules in Firebase Console to:
    // rules_version = '2';
    // service cloud.firestore {
    //   match /databases/{database}/documents {
    //     match /{document=**} {
    //       allow read, write: if request.auth != null;
    //     }
    //   }
    // }
  } catch(e) {
    console.warn('Firebase failed:', e);
    window.db = null; window.auth = null;
  }

  // Load shared state (team settings, members etc)
  await loadState();
  document.getElementById('loading').style.display = 'none';

  if (!window.auth) {
    state.currentUser = { name: 'מנטור', role: 'admin', email: 'local' };
    state.isAdmin = true;
    initApp();
    return;
  }

  // Timeout — אם אחרי 8 שניות עדיין על מסך טעינה, הצג כניסה
  setTimeout(() => {
    if (document.getElementById('loading').style.display !== 'none') {
      document.getElementById('loading').style.display = 'none';
      document.getElementById('pin-screen').style.display = 'flex';
      loginGoTo('choose');
    }
  }, 8000);

  // טיפול בחזרה מ-Google Redirect (Safari)
  try {
    const redirectResult = await window.auth.getRedirectResult();
    if (redirectResult && redirectResult.user) {
      // שחזר intent מ-sessionStorage
      try {
        const savedIntent = sessionStorage.getItem('fll_login_intent');
        if (savedIntent) { window._loginIntent = savedIntent; sessionStorage.removeItem('fll_login_intent'); }
      } catch(e) {}
    }
  } catch(e) { console.warn('getRedirectResult:', e); }

  // Listen for auth state changes
  window.auth.onAuthStateChanged(async (fbUser) => {
    // אם joinWithCode או registerForCreate מטפלים בתהליך — אל תתערב
    if (window._joiningInProgress) return;

    if (fbUser) {
      // 1. נסה למצוא teamId מ-localStorage (כניסה מהירה)
      let teamId = null;
      try { teamId = localStorage.getItem('fll_team_id'); } catch(e) {}

      // 2. אם אין — חפש ב-registry
      if (!teamId) {
        teamId = await findTeamForUser(fbUser.email);
      }

      if (teamId) {
        // קבוצה נמצאה — טען את הנתונים שלה
        window.FB_PROJECT = teamId;
        await loadState();
        try { localStorage.setItem('fll_team_id', teamId); } catch(e) {}

        const member = state.members.find(m => m.email === fbUser.email);
        if (member) {
          state.currentUser = member;
          state.isAdmin = member.role === 'admin';
          document.getElementById('pin-screen').style.display = 'none';
          document.getElementById('app').style.display = 'flex';
          initApp();
        } else {
          document.getElementById('pin-screen').style.display = 'flex';
          showLoginError('⚠️ החשבון לא רשום בקבוצה. בקש ממנטור להוסיף אותך.');
          await window.auth.signOut();
        }
      } else {
        // לא נמצאה קבוצה ב-registry
        document.getElementById('loading').style.display = 'none';
        window._pendingFbUser = fbUser;

        if (window._loginIntent === 'create') {
          document.getElementById('setup-screen').style.display = 'flex';
          showSetupStep('create');
        } else {
          await window.auth.signOut();
          try { localStorage.removeItem('fll_team_id'); } catch(e) {}
          document.getElementById('pin-screen').style.display = 'flex';
          loginGoTo('choose');
          showLoginError('⚠️ החשבון לא רשום בקבוצה. בקש ממנטור להוסיף אותך, או בחר "הצטרף לקבוצה".');
        }
      }
    } else {
      // לא מחובר — מסך התחברות
      try { localStorage.removeItem('fll_team_id'); } catch(e) {}
      document.getElementById('loading').style.display = 'none';
      document.getElementById('pin-screen').style.display = 'flex';
      loginGoTo('choose');
    }
  });
}
boot();
