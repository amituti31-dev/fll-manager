// ═══════════════════════════════════════════════════════
// § 28 · JUDGING Q&A
// ═══════════════════════════════════════════════════════

const DEFAULT_JUDGING_QS = {
  robot: [
    'כיצד הגדרתם את בעיית המשימה שבחרתם לפתור?',
    'תארו את תהליך עיצוב הזרוע — כמה גרסאות בניתם?',
    'מה הייתה הסיבה העיקרית לשינוי בין גרסה לגרסה?',
    'כיצד מאורגן הקוד שלכם? האם יש פונקציות / בלוקים?',
    'אילו משימות הרובוט מבצע בריצה אחת ובאיזה סדר?',
    'מה הייתה האתגר הגדול ביותר בתכנון הרובוט?',
  ],
  innovation: [
    'מה הבעיה שבחרתם ומדוע היא חשובה?',
    'ממי ראיינתם ומה למדתם מהם?',
    'כיצד הפתרון שלכם שונה ממה שקיים כיום?',
    'מה השלב הבא בפיתוח הפתרון?',
    'כיצד בדקתם שהפתרון אכן פותר את הבעיה?',
    'כיצד שיתפתם את הפתרון עם הקהילה?',
  ],
  values: [
    'תנו דוגמה לרגע שבו הצוות התמודד עם אתגר יחד.',
    'כיצד מחליטים בצוות כשיש חילוקי דעות?',
    'מה כל חבר תורם ייחודית לקבוצה?',
    'כיצד הצוות מוודא שכולם מרגישים שייכים?',
    'מהי הגאווה הגדולה ביותר שלכם כצוות השנה?',
    'כיצד הפרויקט שלכם משפיע על הקהילה מחוץ לתחרות?',
  ],
};

let _judgingTab = 'robot';

function _getJudgingQs() {
  if (!state.judgingQs) {
    state.judgingQs = {
      robot:      DEFAULT_JUDGING_QS.robot.map((q, i) => ({ id: Date.now() + i, category: 'robot', question: q, answer: '' })),
      innovation: DEFAULT_JUDGING_QS.innovation.map((q, i) => ({ id: Date.now() + 100 + i, category: 'innovation', question: q, answer: '' })),
      values:     DEFAULT_JUDGING_QS.values.map((q, i) => ({ id: Date.now() + 200 + i, category: 'values', question: q, answer: '' })),
    };
  }
  return state.judgingQs;
}

function switchJudgingTab(cat) {
  _judgingTab = cat;
  ['robot', 'innovation', 'values'].forEach(c => {
    const tab = document.getElementById('judg-tab-' + c);
    if (tab) tab.classList.toggle('active', c === cat);
  });
  renderJudging();
}

function renderJudging() {
  renderJudgingDoc();
  const el = document.getElementById('judging-content');
  if (!el) return;
  const qs = _getJudgingQs()[_judgingTab] || [];
  const answered = qs.filter(q => q.answer && q.answer.trim()).length;
  const pct = qs.length ? Math.round(answered / qs.length * 100) : 0;

  const adminBtns = state.isAdmin
    ? `<button class="btn btn-ghost" style="font-size:12px" onclick="addJudgingQuestion()">＋ הוסף שאלה</button>`
    : '';

  el.innerHTML = `
    <div class="judging-progress-wrap">
      <div class="judging-progress-track">
        <div class="judging-progress-fill" style="width:${pct}%"></div>
      </div>
      <span class="judging-progress-label">${answered}/${qs.length} נענו</span>
      ${adminBtns}
    </div>
    ${qs.length === 0
      ? `<div style="text-align:center;color:var(--text3);padding:40px">אין שאלות. לחץ + להוסיף.</div>`
      : qs.map((q, i) => {
          const hasAns = q.answer && q.answer.trim();
          return `
            <div class="judging-q-card ${hasAns ? 'answered' : ''}" onclick="editJudgingAnswer(${q.id})">
              <div class="judging-q-header">
                <div class="judging-q-num">${i + 1}</div>
                <div class="judging-q-text">${sanitize(q.question)}</div>
                ${state.isAdmin ? `<button onclick="event.stopPropagation();deleteJudgingQuestion(${q.id})" style="background:none;border:none;cursor:pointer;color:var(--text3);font-size:14px;padding:2px 4px" title="מחק">🗑️</button>` : ''}
                <span style="font-size:14px;margin-right:2px">${hasAns ? '✅' : '✏️'}</span>
              </div>
              <div class="judging-q-answer">
                ${hasAns
                  ? `<span>${sanitize(q.answer)}</span>`
                  : `<span class="judging-q-empty">לחץ לכתיבת תשובה...</span>`}
              </div>
            </div>
          `;
        }).join('')
    }
  `;
}

function editJudgingAnswer(id) {
  const qs = _getJudgingQs();
  const all = [...(qs.robot || []), ...(qs.innovation || []), ...(qs.values || [])];
  const q = all.find(x => x.id === id);
  if (!q) return;
  const ans = prompt(q.question + '\n\nתשובה נוכחית: ' + (q.answer || '(ריק)') + '\n\nהכנס תשובה חדשה:', q.answer || '');
  if (ans === null) return;
  q.answer = ans.trim();
  saveState(); renderJudging();
}

function addJudgingQuestion() {
  if (!state.isAdmin) { notify('🚫 רק מנטורים יכולים להוסיף שאלות', 'error'); return; }
  const text = prompt('טקסט השאלה החדשה:');
  if (!text || !text.trim()) return;
  const qs = _getJudgingQs();
  if (!qs[_judgingTab]) qs[_judgingTab] = [];
  qs[_judgingTab].push({ id: Date.now(), category: _judgingTab, question: text.trim(), answer: '' });
  saveState(); renderJudging();
  notify('✅ שאלה נוספה', 'success');
}

function deleteJudgingQuestion(id) {
  if (!state.isAdmin) return;
  if (!confirm('למחוק שאלה זו?')) return;
  const qs = _getJudgingQs();
  ['robot', 'innovation', 'values'].forEach(cat => {
    if (qs[cat]) qs[cat] = qs[cat].filter(q => q.id !== id);
  });
  saveState(); renderJudging();
  notify('🗑️ שאלה נמחקה', 'success');
}

// ─── Judging Document ────────────────────────────────
function renderJudgingDoc() {
  const el = document.getElementById('judging-doc-card');
  if (!el) return;
  const doc = state.judgingDoc;

  if (!doc) {
    el.innerHTML = `
      <div class="card-header" style="margin-bottom:10px"><span class="card-icon">📄</span><span class="card-title">מסמך חדר שיפוט</span></div>
      <div style="display:flex;align-items:center;justify-content:space-between;gap:12px">
        <span style="color:var(--text3);font-size:13px">אין מסמך מצורף עדיין</span>
        ${state.isAdmin ? `<label class="btn btn-primary" style="cursor:pointer;font-size:13px;padding:8px 14px">
          📤 העלה PDF
          <input type="file" accept="application/pdf" style="display:none" onchange="uploadJudgingDoc(event)">
        </label>` : ''}
      </div>`;
  } else {
    el.innerHTML = `
      <div class="card-header" style="margin-bottom:10px"><span class="card-icon">📄</span><span class="card-title">מסמך חדר שיפוט</span></div>
      <div style="display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap">
        <div style="flex:1;min-width:0">
          <div style="font-weight:600;font-size:14px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${sanitize(doc.name)}">${sanitize(doc.name)}</div>
          <div style="color:var(--text3);font-size:11px;margin-top:3px">${sanitize(doc.uploadedBy)} · ${sanitize(doc.date)}</div>
        </div>
        <div style="display:flex;gap:8px;flex-shrink:0;align-items:center">
          <button class="btn btn-primary" style="font-size:13px;padding:8px 14px" onclick="openJudgingDoc()">📂 פתח מסמך</button>
          ${state.isAdmin ? `
            <label class="btn btn-ghost" style="cursor:pointer;font-size:13px;padding:8px 12px" title="החלף מסמך">
              ↺ החלף
              <input type="file" accept="application/pdf" style="display:none" onchange="uploadJudgingDoc(event)">
            </label>
            <button class="btn btn-ghost" style="color:var(--accent3);font-size:13px;padding:8px 10px" onclick="deleteJudgingDoc()" title="מחק מסמך">🗑️</button>
          ` : ''}
        </div>
      </div>`;
  }
}

async function uploadJudgingDoc(event) {
  if (!state.isAdmin) { notify('🚫 רק מנטורים יכולים להעלות מסמכים', 'error'); return; }
  const file = event.target.files[0];
  if (!file) return;
  event.target.value = '';

  if (!file.name.toLowerCase().endsWith('.pdf')) { notify('רק קבצי PDF מותרים', 'error'); return; }
  if (file.size > 700 * 1024) { notify('הקובץ גדול מדי (מקסימום 700KB)', 'error'); return; }
  if (!window.db || !window.FB_PROJECT) { notify('נדרש חיבור למסד הנתונים', 'error'); return; }

  notify('⏳ מעלה מסמך...', 'success');
  try {
    const base64 = await _fileToBase64(file);
    const meta = { name: file.name, uploadedBy: state.currentUser?.name || 'מנטור', date: new Date().toISOString().split('T')[0] };
    await window.db.collection(window.FB_PROJECT).doc('judging_pdf').set({ ...meta, data: base64 });
    state.judgingDoc = meta;
    await saveState();
    renderJudgingDoc();
    renderScoringJudgingDoc();
    notify('📄 מסמך הועלה בהצלחה!', 'success');
  } catch(e) {
    console.error('Upload error:', e);
    notify('שגיאה בהעלאת המסמך — ייתכן שהקובץ גדול מדי', 'error');
  }
}

function _fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload  = e => resolve(e.target.result.split(',')[1]);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

async function openJudgingDoc() {
  if (!window.db || !window.FB_PROJECT) { notify('נדרש חיבור לאינטרנט', 'error'); return; }
  try {
    const snap = await window.db.collection(window.FB_PROJECT).doc('judging_pdf').get();
    if (!snap.exists) { notify('המסמך לא נמצא', 'error'); return; }
    const { data } = snap.data();
    const bytes = Uint8Array.from(atob(data), c => c.charCodeAt(0));
    const url   = URL.createObjectURL(new Blob([bytes], { type: 'application/pdf' }));
    const a = document.createElement('a');
    a.href = url; a.target = '_blank'; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 15000);
  } catch(e) {
    console.error('Open error:', e);
    notify('שגיאה בפתיחת המסמך', 'error');
  }
}

// ─── Doc card in scoring panel ───────────────────────
function renderScoringJudgingDoc() {
  const el  = document.getElementById('sq-doc-card');
  if (!el) return;
  const doc = state.judgingDoc;
  if (!doc) {
    el.innerHTML = `
      <div class="card-header" style="margin-bottom:10px"><span class="card-icon">📄</span><span class="card-title">מסמך חדר שיפוט</span></div>
      <div style="display:flex;align-items:center;justify-content:space-between;gap:12px">
        <span style="color:var(--text3);font-size:13px">אין מסמך מצורף עדיין</span>
        ${state.isAdmin ? `<label class="btn btn-primary" style="cursor:pointer;font-size:13px;padding:8px 14px">📤 העלה PDF<input type="file" accept="application/pdf" style="display:none" onchange="uploadJudgingDoc(event)"></label>` : ''}
      </div>`;
  } else {
    el.innerHTML = `
      <div class="card-header" style="margin-bottom:10px"><span class="card-icon">📄</span><span class="card-title">מסמך חדר שיפוט</span></div>
      <div style="display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap">
        <div style="flex:1;min-width:0">
          <div style="font-weight:600;font-size:14px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${sanitize(doc.name)}</div>
          <div style="color:var(--text3);font-size:11px;margin-top:3px">${sanitize(doc.uploadedBy)} · ${sanitize(doc.date)}</div>
        </div>
        <div style="display:flex;gap:8px;flex-shrink:0;align-items:center">
          <button class="btn btn-primary" style="font-size:13px;padding:8px 14px" onclick="openJudgingDoc()">📂 פתח מסמך</button>
          ${state.isAdmin ? `
            <label class="btn btn-ghost" style="cursor:pointer;font-size:13px;padding:8px 12px">↺ החלף<input type="file" accept="application/pdf" style="display:none" onchange="uploadJudgingDoc(event)"></label>
            <button class="btn btn-ghost" style="color:var(--accent3);font-size:13px;padding:8px 10px" onclick="deleteJudgingDoc()" title="מחק">🗑️</button>
          ` : ''}
        </div>
      </div>`;
  }
}

async function deleteJudgingDoc() {
  if (!state.isAdmin) return;
  if (!confirm('למחוק את המסמך?')) return;
  if (window.db && window.FB_PROJECT) {
    try { await window.db.collection(window.FB_PROJECT).doc('judging_pdf').delete(); } catch(e) {}
  }
  state.judgingDoc = null;
  await saveState();
  renderJudgingDoc();
  renderScoringJudgingDoc();
  notify('🗑️ מסמך נמחק', 'success');
}
