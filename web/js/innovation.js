// ═══════════════════════════════════════════════════════
// § 13 · INNOVATION PROJECT
// ═══════════════════════════════════════════════════════

const INNOV_STEPS = [
  { key: 'problem',    label: 'הגדרת הבעיה',     icon: '🔍', color: '#3d7fff', question: 'איזו בעיה אמיתית זיהיתם?',        emptyText: 'טרם הוגדרה הבעיה. לחצו על עריכה כדי להגדיר את הבעיה שהקבוצה מתמודדת איתה.',   btnLabel: 'הגדר' },
  { key: 'research',   label: 'מחקר',             icon: '🔬', color: '#00d4a0', question: 'מה גיליתם במחקר שלכם?',           emptyText: 'עברו לטאב "מחקר" להוסיף ממצאים.',                                              btnLabel: 'מחקר', tab: 'research' },
  { key: 'interviews', label: 'ראיונות',           icon: '🎙️', color: '#9c6fe4', question: 'עם מי דיברתם? מה למדתם?',         emptyText: 'עברו לטאב "ראיונות" להוסיף ראיונות.',                                          btnLabel: 'ראיונות', tab: 'interviews' },
  { key: 'solution',   label: 'הפתרון שלנו',      icon: '✅', color: '#00d4a0', question: 'מה הפתרון שבחרתם ולמה?',          emptyText: 'טרם הוגדר פתרון. אחרי סיעור מוחות – תארו את הפתרון שבחרתם.',                   btnLabel: 'הגדר' },
  { key: 'sharing',    label: 'שיתוף עם הקהילה', icon: '📢', color: '#ff6b35', question: 'עם מי שיתפתם את הפתרון?',          emptyText: 'אין תיעוד שיתוף עדיין.',                                                        btnLabel: 'הוסף' },
];

function switchInnovTab(tab) {
  ['project','research','interviews'].forEach(t => {
    const panel = document.getElementById('innov-panel-' + t);
    const tabEl  = document.getElementById('innov-tab-' + t);
    const active = t === tab;
    if (panel) panel.style.display = active ? '' : 'none';
    if (tabEl) {
      tabEl.style.borderBottomColor = active ? 'var(--accent2)' : 'transparent';
      tabEl.style.color = active ? 'var(--accent2)' : 'var(--text2)';
      tabEl.style.fontWeight = active ? '700' : '600';
    }
  });
  if (tab === 'research')   renderResearchHub();
  if (tab === 'interviews') renderInterviewsList();
}

function renderInnovProject() {
  const steps = state.innovSteps || {};
  const findings   = state.findings   || [];
  const interviews = state.interviews || [];

  const isDone = {
    problem:    !!(steps.problem),
    research:   findings.length > 0,
    interviews: interviews.length > 0,
    solution:   !!(steps.solution),
    sharing:    !!(steps.sharing),
  };
  const doneCount = Object.values(isDone).filter(Boolean).length;

  // Update counter
  const countEl = document.getElementById('innov-step-count');
  if (countEl) countEl.textContent = doneCount + '/5 שלבים';

  // Progress bars
  const barsEl = document.getElementById('innov-progress-bars');
  if (barsEl) {
    barsEl.innerHTML = INNOV_STEPS.map((s, i) => {
      const done = isDone[s.key];
      return `<div style="text-align:center">
        <div style="height:6px;border-radius:4px;background:${done ? s.color : 'var(--surface3)'};margin-bottom:5px;transition:background 0.4s"></div>
        <div style="font-size:10px;color:${done ? s.color : 'var(--text3)'};font-weight:${done ? '700' : '400'}">${s.label.split(' ')[0]}</div>
      </div>`;
    }).join('');
  }

  // Step cards
  const listEl = document.getElementById('innov-steps-list');
  if (!listEl) return;
  listEl.innerHTML = INNOV_STEPS.map(s => {
    const done = isDone[s.key];
    let contentText = '';
    if (s.key === 'research')   contentText = findings.length   ? `${findings.length} ממצאים נוספו`   : s.emptyText;
    else if (s.key === 'interviews') contentText = interviews.length ? `${interviews.length} ראיונות נוספו` : s.emptyText;
    else contentText = steps[s.key] || s.emptyText;

    const hasContent = done;
    const btnStyle = `background:${s.color}20;border:1px solid ${s.color};color:${s.color};padding:5px 12px;border-radius:20px;font-size:12px;font-weight:700;cursor:pointer;white-space:nowrap;font-family:inherit`;
    const btnClick = s.tab
      ? `switchInnovTab('${s.tab}')`
      : `openInnovStepModal('${s.key}')`;

    return `<div style="background:var(--surface2);border:1px solid var(--border);border-radius:var(--radius-sm);
              border-right:4px solid ${s.color};padding:16px;margin-bottom:12px;display:flex;gap:12px;align-items:flex-start">
      <div style="flex:1;min-width:0">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px">
          <span style="font-size:20px">${s.icon}</span>
          <span style="font-weight:800;font-size:15px">${s.label}</span>
          ${done ? `<span style="font-size:14px;margin-right:auto">✅</span>` : ''}
        </div>
        <div style="font-size:12px;color:${s.color};margin-bottom:8px;font-weight:600">${s.question}</div>
        <div style="font-size:13px;color:${hasContent ? 'var(--text)' : 'var(--text3)'};font-style:${hasContent ? 'normal' : 'italic'};line-height:1.6">
          ${sanitize(contentText)}
        </div>
      </div>
      <button style="${btnStyle}" onclick="${btnClick}">+ ${sanitize(s.btnLabel)}</button>
    </div>`;
  }).join('');
}

function openInnovStepModal(key) {
  const step = INNOV_STEPS.find(s => s.key === key);
  if (!step) return;
  document.getElementById('innov-step-modal-title').textContent = '✏️ ' + step.label;
  document.getElementById('innov-step-modal-question').textContent = step.question;
  document.getElementById('innov-step-key').value = key;
  document.getElementById('innov-step-text').value = (state.innovSteps || {})[key] || '';
  openModal('modal-innov-step');
}

function saveInnovStep() {
  const key  = document.getElementById('innov-step-key').value;
  const text = document.getElementById('innov-step-text').value.trim().slice(0, 2000);
  if (!text) { notify('נדרש תוכן', 'error'); return; }
  if (!state.innovSteps) state.innovSteps = {};
  state.innovSteps[key] = text;
  saveState();
  closeModal('modal-innov-step');
  renderInnovProject();
  notify('✅ נשמר', 'success');
}

// ═══════════════════════════════════════════════════════
// § 14 · RESEARCH & INTERVIEWS
// ═══════════════════════════════════════════════════════
function showAddInterviewModal() { openModal('modal-interview'); }

function saveInterview() {
  const expert = document.getElementById('interview-expert').value.trim().slice(0, 200);
  const text   = document.getElementById('interview-text').value.trim().slice(0, 3000);
  if (!expert) { notify('נדרש שם מומחה', 'error'); return; }
  if (!text)   { notify('נדרש תוכן', 'error'); return; }
  if (!state.interviews) state.interviews = [];
  state.interviews.push({
    id: Date.now(), expert, text,
    date: new Date().toISOString().split('T')[0],
    author: state.currentUser?.name || 'אנונימי',
  });
  saveState();
  closeModal('modal-interview');
  document.getElementById('interview-expert').value = '';
  document.getElementById('interview-text').value   = '';
  renderInterviewsList();
  renderInnovProject();
  notify('✅ ראיון נשמר', 'success');
}

function deleteInterview(id) {
  if (!state.isAdmin) return;
  if (!confirm('למחוק את הראיון?')) return;
  state.interviews = (state.interviews || []).filter(i => i.id !== id);
  saveState();
  renderInterviewsList();
  renderInnovProject();
}

function renderInterviewsList() {
  const el = document.getElementById('interviews-list');
  if (!el) return;
  const list = state.interviews || [];
  if (!list.length) {
    el.innerHTML = `<div style="text-align:center;padding:40px;color:var(--text3)">
      <div style="font-size:36px;margin-bottom:8px">🎙️</div>
      <div>טרם נוספו ראיונות עם מומחים</div>
    </div>`;
    return;
  }
  el.innerHTML = list.slice().reverse().map(i => `
    <div style="background:var(--surface2);border:1px solid var(--border);border-right:4px solid #9c6fe4;
                border-radius:var(--radius-sm);padding:14px;margin-bottom:10px">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:8px">
        <div style="flex:1">
          <div style="font-weight:700;font-size:14px;margin-bottom:4px">🎙️ ${sanitize(i.expert)}</div>
          <div style="font-size:11px;color:var(--text3);margin-bottom:8px">${sanitize(i.author)} · ${formatDate(i.date)}</div>
          <div style="font-size:13px;line-height:1.6;color:var(--text2)">${sanitize(i.text)}</div>
        </div>
        ${state.isAdmin ? `<button onclick="deleteInterview(${i.id})" style="background:none;border:none;cursor:pointer;color:var(--red);font-size:16px;padding:2px 4px" title="מחק">🗑️</button>` : ''}
      </div>
    </div>
  `).join('');
}

function showAddFindingModal() { openModal('modal-finding'); }
function saveFinding() {
  const text = document.getElementById('finding-text').value.trim().slice(0, 3000);
  if (!text) { notify('נדרש תוכן', 'error'); return; }
  const tag = document.getElementById('finding-tag').value.trim().slice(0, 50);
  state.findings.push({
    id: Date.now(), text, tag,
    date: new Date().toISOString().split('T')[0], author: state.currentUser?.name || 'אנונימי',
  });
  saveState(); closeModal('modal-finding'); renderResearchHub(); renderInnovProject();
  notify('✅ ממצא נשמר', 'success');
}

function renderResearchHub() {
  const el = document.getElementById('research-hub');
  if (!state.findings.length) {
    el.innerHTML = `<div style="color:var(--text3);font-size:13px;text-align:center;padding:20px"><div style="font-size:28px;margin-bottom:8px">🔬</div><div>הוסף ממצאי מחקר ופגישות עם מומחים</div></div>`;
    return;
  }
  el.innerHTML = state.findings.slice(-5).reverse().map(f => `
    <div style="border-bottom:1px solid var(--border);padding:10px 0">
      <div style="font-size:12px;color:var(--text3)">${sanitize(f.author)} · ${formatDate(f.date)}</div>
      <div style="font-size:13px;margin-top:4px">${sanitize(f.text)}</div>
      ${f.tag ? `<span class="timeline-tag tag-innovation">${sanitize(f.tag)}</span>` : ''}
    </div>
  `).join('');
}

// ═══════════════════════════════════════════════════════
// § 15 · RECORDING
// ═══════════════════════════════════════════════════════
let mediaRec = null;
let _recChunks = [];
function startRecording() {
  if (mediaRec) {
    mediaRec.stop();
    document.getElementById('recording-status').style.display = 'none';
    document.querySelector('[onclick="startRecording()"]').textContent = '🎤 התחל הקלטה';
    return;
  }
  if (!navigator.mediaDevices) { notify('הדפדפן לא תומך בהקלטה', 'error'); return; }
  navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
    _recChunks = [];
    // Pick the first supported MIME type — Safari uses audio/mp4, Chrome uses audio/webm
    const mimeType = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4', ''].find(
      t => t === '' || MediaRecorder.isTypeSupported(t)
    );
    mediaRec = new MediaRecorder(stream, mimeType ? { mimeType } : {});
    const recMime = mediaRec.mimeType || mimeType || 'audio/webm';
    mediaRec.ondataavailable = e => { if (e.data.size > 0) _recChunks.push(e.data); };
    mediaRec.onstop = () => {
      stream.getTracks().forEach(t => t.stop());
      mediaRec = null;
      const blob = new Blob(_recChunks, { type: recMime });
      const ext = recMime.includes('mp4') ? 'mp4' : 'webm';
      const filename = 'recording-' + new Date().toISOString().replace(/[:.]/g, '-') + '.' + ext;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = filename; a.click();
      setTimeout(() => URL.revokeObjectURL(url), 5000);
      notify('✅ ההקלטה הורדה!', 'success');
    };
    mediaRec.start();
    document.getElementById('recording-status').style.display = 'block';
    document.querySelector('[onclick="startRecording()"]').textContent = '⏹️ עצור הקלטה';
    notify('🎤 מקליט...', 'success');
  }).catch(() => notify('לא ניתן לגשת למיקרופון', 'error'));
}
