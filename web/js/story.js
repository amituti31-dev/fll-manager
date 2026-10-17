// ═══════════════════════════════════════════════════════
// § 33 · SEASON STORY (Gemini) & STICKY EXPORT
// ═══════════════════════════════════════════════════════
// The app has no backend, so the AI call goes straight from the device to
// Google's Gemini API. The team's key is saved once by a mentor in the
// /{teamId}/ai-config doc, which firestore.rules make readable/writable by
// MENTORS ONLY (isMentorOnlyDoc) — so every mentor on every device can use it,
// students can't read it, and it's never in the code or the backup file.
// The generated story is saved to data.seasonStory so the whole team (and
// Android) can read it. Student names are not sent.
const GEMINI_KEY_STORE = 'fll_gemini_key'; // old per-browser copy — migrated to ai-config
const GEMINI_MODELS = ['gemini-flash-latest', 'gemini-2.5-flash']; // first that works
const STORY_INPUT_LIMIT = 60000; // characters of season data sent to the model

function _aiConfigRef() { return window.db.collection(window.FB_PROJECT).doc('ai-config'); }

// The team key from the cloud (mentors only — a student's read is rejected).
async function _getGeminiKey() {
  if (!state.isAdmin || !window.db) return '';
  try {
    const snap = await _aiConfigRef().get();
    return (snap.exists && snap.data().geminiKey) || '';
  } catch (e) { return ''; }
}

async function renderAiSettings() {
  const status = document.getElementById('ai-key-status');
  if (!status || !state.isAdmin || !window.db) return;
  let key = await _getGeminiKey();
  // One-time move of a key saved in this browser by the earlier version.
  let local = '';
  try { local = localStorage.getItem(GEMINI_KEY_STORE) || ''; } catch (e) {}
  if (local) {
    try {
      if (!key) {
        await _aiConfigRef().set({ geminiKey: local, setBy: state.currentUser?.name || '', setAt: new Date().toISOString() });
        key = local;
        notify('🔑 המפתח שנשמר בדפדפן הועבר לענן — זמין עכשיו לכל המנטורים', 'success');
      }
      localStorage.removeItem(GEMINI_KEY_STORE);
    } catch (e) { console.warn('AI key migration failed:', e); }
  }
  status.textContent = key ? `✅ מפתח שמור לכל המנטורים (…${key.slice(-4)})` : 'עוד לא נשמר מפתח לקבוצה';
  status.style.color = key ? 'var(--accent2)' : 'var(--text3)';
}
async function saveGeminiKey() {
  if (!state.isAdmin) return;
  const v = document.getElementById('ai-key-input').value.trim();
  if (!v) { notify('הדביקו מפתח', 'error'); return; }
  try {
    await _aiConfigRef().set({ geminiKey: v, setBy: state.currentUser?.name || '', setAt: new Date().toISOString() });
  } catch (e) { notify('❌ השמירה נכשלה: ' + (e.message || e), 'error'); return; }
  document.getElementById('ai-key-input').value = '';
  renderAiSettings(); notify('✅ המפתח נשמר בענן — זמין לכל המנטורים', 'success');
}
async function removeGeminiKey() {
  if (!state.isAdmin || !confirm('להסיר את המפתח לכל המנטורים?')) return;
  try { await _aiConfigRef().delete(); } catch (e) { notify('❌ ההסרה נכשלה', 'error'); return; }
  try { localStorage.removeItem(GEMINI_KEY_STORE); } catch (e) {}
  renderAiSettings(); notify('המפתח הוסר', 'success');
}
function openAiKeyPage() { window.open('https://aistudio.google.com/apikey', '_blank'); }

// Everything that happened this season, grouped by date — no author names.
function _seasonStoryInput() {
  const days = {};
  const day = d => (days[d] = days[d] || { meeting: null, logs: [], notes: [], milestones: [] });
  (state.meetingPlans || []).forEach(m => { if (m.date) day(m.date).meeting = m; });
  dailyLogs().forEach(l => { if (l.date) day(l.date).logs.push(l); });
  (state.stickies || []).forEach(s => { if (s.date) day(s.date).notes.push(s); });
  (state.milestones || []).forEach(m => {
    const d = m.done ? (m.actualDate || m.targetDate) : m.targetDate;
    if (d) day(d).milestones.push(m);
  });
  const valueName = v => (STICKY_VALUES[v] ? STICKY_VALUES[v].label.replace(/^\S+\s/, '') : v);
  const out = [
    `קבוצה: ${state.teamName || ''}`,
    `עונה: ${state.currentSeason || OFFICIAL_SEASON_NAME}`,
    `הבעיה שבחרנו בפרויקט החדשנות: ${state.innovationProblem || '—'}`,
    `הפתרון שלנו: ${state.innovationSolution || '—'}`,
    `הניקוד הטוב ביותר בריצת רובוט: ${(state.scores || []).length ? Math.max(...state.scores.map(s => s.score)) : '—'} מתוך ${getMaxScore()}`,
    '',
  ];
  Object.keys(days).sort().forEach(d => {
    const x = days[d];
    out.push(`## ${d}`);
    if (x.meeting) {
      out.push(`מפגש: ${x.meeting.title || ''}`);
      if (x.meeting.plan) out.push(`  תכנון: ${x.meeting.plan}`);
      if (x.meeting.summary) out.push(`  מה קרה בפועל: ${x.meeting.summary}`);
    }
    x.logs.forEach(l => out.push(`- תיעוד [${logTopics(l).map(topicLabel).join(', ')}${(l.values || []).length ? ' | ערכים: ' + l.values.map(valueName).join(', ') : ''}]: ${l.text}`));
    x.notes.forEach(s => out.push(`- פתק ערך ליבה (${valueName(s.value)}): ${s.text}`));
    x.milestones.forEach(m => out.push(`- אבן דרך${m.done ? ' שהושגה' : ''}: ${m.title}`));
    out.push('');
  });
  const text = out.join('\n');
  return text.length > STORY_INPUT_LIMIT ? text.slice(text.length - STORY_INPUT_LIMIT) : text;
}

const STORY_INSTRUCTIONS = `אתה עוזר לקבוצת FIRST LEGO League בישראל לכתוב את "סיפור העונה" שלה, על סמך התיעוד שהקבוצה אספה לאורך העונה (מפגשים, תיעודים יומיים, פתקי ערכי ליבה ואבני דרך).
כתוב בעברית, בגוף ראשון רבים ("אנחנו"), טקסט רציף, חם ומעניין שאפשר להציג לשופטים ולהורים.
היצמד לעובדות שבנתונים בלבד — אל תמציא אירועים, שמות, מספרים או הישגים שלא מופיעים בהם.
מבנה: כותרת קצרה; פתיחה; פרקים לפי שלבי העונה (לפי חודשים או נושאים); פרק על ערכי הליבה (גילוי, חדשנות, השפעה, הכלה, עבודת צוות, הנאה) עם דוגמאות קונקרטיות מהפתקים; סיכום ומה למדנו.
אורך: 500 עד 900 מילים. טקסט פשוט בלבד — בלי Markdown, בלי כוכביות ובלי סימני #. כותרות פרקים בשורה נפרדת.`;

async function _callGemini(key, input) {
  let lastErr = null;
  for (const model of GEMINI_MODELS) {
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: STORY_INSTRUCTIONS }] },
        contents: [{ role: 'user', parts: [{ text: input }] }],
        generationConfig: { temperature: 0.7, maxOutputTokens: 8192 },
      }),
    });
    const body = await res.json().catch(() => ({}));
    if (res.ok) {
      const text = ((body.candidates || [])[0]?.content?.parts || []).map(p => p.text || '').join('').trim();
      if (text) return { text, model };
      lastErr = 'ה-AI לא החזיר טקסט (ייתכן שהתוכן נחסם). נסו שוב.';
      break;
    }
    const msg = (body.error && body.error.message) || res.statusText;
    if (res.status === 404) { lastErr = msg; continue; } // model name not available — try the next
    if (res.status === 400 && /api key/i.test(msg)) throw new Error('המפתח לא תקין. בדקו אותו בהגדרות.');
    if (res.status === 403) throw new Error('אין הרשאה למפתח הזה (בדקו שהוא מ-Google AI Studio).');
    if (res.status === 429) throw new Error('הגעתם למגבלת השימוש החינמית לעכשיו. נסו שוב מאוחר יותר.');
    throw new Error(msg);
  }
  throw new Error(lastErr || 'שגיאה לא ידועה');
}

function showSeasonStoryModal() {
  renderSeasonStory();
  openModal('modal-story');
}

function renderSeasonStory() {
  const story = state.seasonStory;
  const body = document.getElementById('story-body');
  body.innerHTML = story && story.text
    ? `<div style="white-space:pre-wrap;line-height:1.8;font-size:14px">${sanitize(story.text)}</div>
       <div style="font-size:11px;color:var(--text3);margin-top:10px">נוצר ${sanitize(new Date(story.createdAt).toLocaleString('he-IL'))} · Gemini</div>`
    : `<div style="color:var(--text3);font-size:13px;padding:10px 0">עוד לא נוצר סיפור עונה.${state.isAdmin ? ' לחצו "✨ צור סיפור" כדי לבנות אותו מכל התיעוד של העונה.' : ' מנטור יכול ליצור אותו.'}</div>`;
  const has = !!(story && story.text);
  document.getElementById('story-copy').style.display = has ? '' : 'none';
  document.getElementById('story-download').style.display = has ? '' : 'none';
  const gen = document.getElementById('story-generate');
  gen.style.display = state.isAdmin ? '' : 'none';
  gen.textContent = has ? '✨ צור מחדש' : '✨ צור סיפור';
}

async function generateSeasonStory() {
  if (!state.isAdmin) return;
  const key = await _getGeminiKey();
  if (!key) {
    notify('קודם צריך לשמור מפתח Gemini בהגדרות (פעם אחת לכל הקבוצה)', 'error');
    closeModal('modal-story'); navigate('settings'); return;
  }
  if (!(state.stickies || []).length && !(state.logs || []).length && !(state.meetingPlans || []).length) {
    notify('אין עדיין מספיק תיעוד לסיפור', 'error'); return;
  }
  if (state.seasonStory && state.seasonStory.text && !confirm('ליצור סיפור חדש במקום הקיים?')) return;
  const btn = document.getElementById('story-generate');
  btn.disabled = true; btn.textContent = '⏳ כותב...';
  try {
    const { text, model } = await _callGemini(key, _seasonStoryInput());
    state.seasonStory = { text, createdAt: new Date().toISOString(), model };
    saveState();
    notify('✨ סיפור העונה מוכן', 'success');
  } catch (e) {
    notify('❌ ' + (e.message || e), 'error');
  } finally {
    btn.disabled = false;
    renderSeasonStory();
  }
}

function copySeasonStory() {
  const text = (state.seasonStory || {}).text || '';
  navigator.clipboard.writeText(text).then(() => notify('📋 הועתק', 'success'), () => notify('ההעתקה נכשלה', 'error'));
}

function downloadSeasonStory() {
  const text = (state.seasonStory || {}).text || '';
  const blob = new Blob(['﻿' + text], { type: 'text/plain;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `סיפור_העונה_${(state.currentSeason || '').replace(/[^\w֐-׿-]+/g, '_')}.txt`;
  document.body.appendChild(a); a.click(); a.remove();
}

// ── Sticky export: printable page (→ "Save as PDF") + CSV ──
function _stickiesByDate() {
  const byDate = {};
  (state.stickies || []).forEach(s => { (byDate[s.date || ''] = byDate[s.date || ''] || []).push(s); });
  return Object.keys(byDate).sort().map(date => ({
    date, meeting: (state.meetingPlans || []).find(m => m.date === date) || null, notes: byDate[date],
  }));
}

function exportStickiesPrintable() {
  const groups = _stickiesByDate();
  if (!groups.length) { notify('אין פתקים לייצא', 'error'); return; }
  const esc = s => String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const win = window.open('', '_blank');
  if (!win) { notify('הדפדפן חסם את החלון — אפשרו חלונות קופצים', 'error'); return; }
  win.document.write(`<!DOCTYPE html><html dir="rtl" lang="he"><head><meta charset="utf-8"><title>פתקי ערכי ליבה – ${esc(state.teamName)}</title>
    <style>
      body { font-family: Arial, sans-serif; padding: 28px; color: #1a1f36; }
      h1 { margin: 0 0 4px; } .sub { color: #666; margin-bottom: 20px; }
      h2 { font-size: 16px; margin: 22px 0 8px; padding: 6px 10px; background: #eef2fb; border-radius: 6px; }
      .note { border: 1px solid #ddd; border-right: 5px solid var(--c); border-radius: 6px; padding: 8px 12px; margin: 6px 0; page-break-inside: avoid; }
      .val { font-weight: 700; color: var(--c); font-size: 13px; }
      @media print { body { padding: 10px; } }
    </style></head><body>
    <h1>📌 פתקי ערכי ליבה</h1>
    <div class="sub">${esc(state.teamName)} · ${esc(state.currentSeason)} · ${(state.stickies || []).length} פתקים</div>
    ${groups.map(g => `
      <h2>${g.meeting ? '📋 ' + esc(g.meeting.title || 'מפגש') + ' · ' : ''}${g.date ? esc(formatDate(g.date)) : 'ללא תאריך'}</h2>
      ${g.notes.map(n => {
        const cfg = STICKY_VALUES[n.value] || { label: n.value, bg: '#999' };
        return `<div class="note" style="--c:${cfg.bg}"><div class="val">${esc(cfg.label)}</div><div>${esc(n.text)}</div></div>`;
      }).join('')}`).join('')}
    </body></html>`);
  win.document.close();
  setTimeout(() => win.print(), 400);
}

function exportStickiesCsv() {
  const groups = _stickiesByDate();
  if (!groups.length) { notify('אין פתקים לייצא', 'error'); return; }
  const rows = [['תאריך', 'מפגש', 'ערך ליבה', 'פתק']];
  groups.forEach(g => g.notes.forEach(n => rows.push([
    g.date, g.meeting ? (g.meeting.title || 'מפגש') : '', (STICKY_VALUES[n.value] || { label: n.value }).label, n.text,
  ])));
  const csv = '﻿' + rows.map(r => r.map(v => '"' + String(v || '').replace(/"/g, '""') + '"').join(',')).join('\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
  a.download = `פתקי_ערכים_${_localIsoToday()}.csv`;
  document.body.appendChild(a); a.click(); a.remove();
}
