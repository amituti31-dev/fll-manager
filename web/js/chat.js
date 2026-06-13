// ═══════════════════════════════════════════════════════
// § 16 · CHAT
// ═══════════════════════════════════════════════════════
let _chatChannel = 'general';
let _chatPrivateKey = null;
let _chatPrivateName = null;
let _chatUnsubscribe = null;

function initChatScreen() {
  // Show/hide mentors tab based on role
  const mentorTab = document.getElementById('chat-tab-mentors');
  if (mentorTab) mentorTab.style.display = state.isAdmin ? '' : 'none';
  // Re-subscribe to current channel
  _subscribeChat();
}

function switchChatTab(channel, privateKey, privateName) {
  _chatChannel = channel;
  _chatPrivateKey = privateKey || null;
  _chatPrivateName = privateName || null;

  // Tab button styles
  ['general', 'robot', 'innovation'].forEach(t => {
    const btn = document.getElementById('chat-tab-' + t);
    if (btn) btn.className = channel === t ? 'btn btn-primary' : 'btn btn-ghost';
  });
  const mTab = document.getElementById('chat-tab-mentors');
  if (mTab) { mTab.className = channel === 'mentors' ? 'btn btn-primary' : 'btn btn-ghost'; mTab.style.display = state.isAdmin ? '' : 'none'; }
  const pvtWrap = document.getElementById('chat-tab-private-wrap');
  pvtWrap.style.display = channel === 'private' ? 'flex' : 'none';
  if (channel === 'private') document.getElementById('chat-private-title').textContent = '💬 ' + (privateName || 'פרטי');

  // Input visibility: students read-only in mentors channel
  const inputRow = document.getElementById('chat-input-row');
  const notice = document.getElementById('chat-mentor-notice');
  const readOnly = channel === 'mentors' && !state.isAdmin;
  inputRow.style.display = readOnly ? 'none' : 'flex';
  notice.style.display = readOnly ? 'block' : 'none';

  _subscribeChat();
}

function _subscribeChat() {
  if (_chatUnsubscribe) { _chatUnsubscribe(); _chatUnsubscribe = null; }
  if (!window.db) { _renderChatFallback(); return; }
  _chatUnsubscribe = window.db.collection(window.FB_PROJECT).doc('chats').onSnapshot(snap => {
    if (!snap.exists) { _renderMessages([]); _renderAnnouncements([]); return; }
    const data = snap.data();
    _renderAnnouncements(data.announcements || []);
    if (_chatChannel === 'private' && _chatPrivateKey) {
      _renderMessages((data.private || {})[_chatPrivateKey] || []);
    } else {
      _renderMessages(data[_chatChannel] || []);
    }
  }, () => { _renderMessages([]); _renderAnnouncements([]); });
}

function _renderChatFallback() {
  const chats = state.chats || {};
  _renderAnnouncements(state.announcements || []);
  if (_chatChannel === 'private' && _chatPrivateKey) {
    _renderMessages((chats.private || {})[_chatPrivateKey] || []);
  } else {
    _renderMessages(chats[_chatChannel] || []);
  }
}

function _renderMessages(messages) {
  const el = document.getElementById('chat-messages');
  if (!el) return;
  const myId = String(state.currentUser?.id || state.currentUser?.email || '');
  if (!messages.length) {
    el.innerHTML = '<div style="text-align:center;color:var(--text3);padding:40px;font-size:14px">אין הודעות עדיין — היה הראשון לכתוב! 💬</div>';
    return;
  }
  el.innerHTML = messages.map(m => {
    if (m.type === 'poll') return _renderPollBubble(m, myId);
    const isMe = String(m.authorId) === myId;
    return `
      <div style="display:flex;flex-direction:column;align-items:${isMe ? 'flex-end' : 'flex-start'};gap:2px">
        <div style="font-size:11px;color:var(--text3)">${sanitize(m.authorName)}</div>
        <div style="background:${isMe ? 'var(--accent)' : 'var(--surface2)'};color:${isMe ? '#fff' : 'var(--text)'};padding:8px 14px;border-radius:${isMe ? '14px 14px 4px 14px' : '14px 14px 14px 4px'};max-width:72%;font-size:14px;word-break:break-word;line-height:1.4">${sanitize(m.text)}</div>
        <div style="font-size:10px;color:var(--text3)">${m.ts ? m.ts.substring(0,10) : ''}</div>
      </div>`;
  }).join('');
  el.scrollTop = el.scrollHeight;
}

function _renderPollBubble(poll, myId) {
  const opts      = poll.options || [];
  const total     = opts.reduce((s, o) => s + (o.votes || []).length, 0);
  const myVoteIdx = opts.findIndex(o => (o.votes || []).includes(myId));
  const hasVoted  = myVoteIdx >= 0;
  const canVote   = !poll.closed && !!myId && !hasVoted;
  const maxVotes  = Math.max(...opts.map(o => (o.votes || []).length), 0);

  const optionsHtml = opts.map((opt, i) => {
    const count    = (opt.votes || []).length;
    const pct      = total > 0 ? Math.round(count / total * 100) : 0;
    const isWinner = poll.closed && count === maxVotes && maxVotes > 0;
    const isMyVote = myVoteIdx === i;

    if (canVote) {
      return `<button class="poll-option-btn" onclick="castVote('${poll.id}',${i})">${sanitize(opt.text)}</button>`;
    }
    return `
      <div class="poll-result-row">
        <div class="poll-result-label">${isWinner ? '🏆 ' : ''}${sanitize(opt.text)}</div>
        <div class="poll-bar-track"><div class="poll-bar-fill${isMyVote ? ' my-vote' : ''}" style="width:${pct}%"></div></div>
        <div class="poll-result-pct">${pct}%&nbsp;(${count})</div>
      </div>`;
  }).join('');

  const footer = `
    <div class="poll-footer">
      <span class="poll-total">${total} הצבעות</span>
      ${poll.closed
        ? `<span class="poll-closed-badge">🔒 סגורה</span>`
        : (state.isAdmin ? `<button class="poll-close-btn" onclick="closePoll('${poll.id}')">🔒 סגור הצבעה</button>` : '')}
    </div>`;

  return `
    <div style="display:flex;flex-direction:column;align-items:flex-start;gap:2px">
      <div class="poll-bubble">
        <div class="poll-header">🗳️ הצבעה &nbsp;·&nbsp; ${sanitize(poll.author || '')} &nbsp;·&nbsp; ${(poll.ts || '').substring(0,10)}</div>
        <div class="poll-question">${sanitize(poll.question)}</div>
        <div class="poll-options">${optionsHtml}</div>
        ${footer}
      </div>
    </div>`;
}

async function sendChatMessage() {
  const input = document.getElementById('chat-input');
  const text = (input.value || '').trim().slice(0, 500);
  if (!text) return;
  if (_chatChannel === 'mentors' && !state.isAdmin) { notify('רק מנטורים יכולים לכתוב בצ\'אט זה', 'error'); return; }

  const myId = String(state.currentUser?.id || state.currentUser?.email || 'unknown');
  const myName = state.currentUser?.name || 'אנונימי';
  const msg = { id: Date.now(), authorId: myId, authorName: myName, text, ts: new Date().toISOString() };

  if (window.db) {
    const docRef = window.db.collection(window.FB_PROJECT).doc('chats');
    const snap = await docRef.get();
    const data = snap.exists ? snap.data() : {};
    if (_chatChannel === 'private' && _chatPrivateKey) {
      const pvt = data.private || {};
      const msgs = [...(pvt[_chatPrivateKey] || []), msg].slice(-100);
      pvt[_chatPrivateKey] = msgs;
      await docRef.set({ private: pvt }, { merge: true });
    } else {
      const msgs = [...(data[_chatChannel] || []), msg].slice(-100);
      await docRef.set({ [_chatChannel]: msgs }, { merge: true });
    }
  } else {
    if (!state.chats) state.chats = { general: [], mentors: [], private: {} };
    if (_chatChannel === 'private' && _chatPrivateKey) {
      if (!state.chats.private[_chatPrivateKey]) state.chats.private[_chatPrivateKey] = [];
      state.chats.private[_chatPrivateKey].push(msg);
    } else {
      if (!state.chats[_chatChannel]) state.chats[_chatChannel] = [];
      state.chats[_chatChannel].push(msg);
    }
    saveState(); _renderChatFallback();
  }
  input.value = '';
}

// ─── Polls ───────────────────────────────────────────
async function createPoll() {
  if (!state.isAdmin) { notify('🚫 רק מנטורים יכולים ליצור הצבעות', 'error'); return; }
  const question = (document.getElementById('poll-question')?.value || '').trim().slice(0, 200);
  if (!question) { notify('נדרשת שאלה', 'error'); return; }

  const options = [];
  for (let i = 1; i <= 4; i++) {
    const t = (document.getElementById(`poll-opt-${i}`)?.value || '').trim().slice(0, 100);
    if (t) options.push({ text: t, votes: [] });
  }
  if (options.length < 2) { notify('נדרשות לפחות 2 אפשרויות', 'error'); return; }

  const myId = String(state.currentUser?.id || state.currentUser?.email || 'admin');
  const poll = {
    id: String(Date.now()), type: 'poll', question, options,
    closed: false,
    author: state.currentUser?.name || 'מנטור',
    authorId: myId,
    ts: new Date().toISOString(),
  };

  await _modifyChannelMessages(msgs => [...msgs, poll]);
  closeModal('modal-poll');
  // Clear form
  ['poll-question','poll-opt-1','poll-opt-2','poll-opt-3','poll-opt-4'].forEach(id => {
    const el = document.getElementById(id); if (el) el.value = '';
  });
  notify('🗳️ הצבעה נשלחה!', 'success');
}

async function castVote(pollId, optionIndex) {
  const myId = String(state.currentUser?.id || state.currentUser?.email || '');
  if (!myId) { notify('עליך להיות מחובר', 'error'); return; }
  await _modifyChannelMessages(msgs => msgs.map(m => {
    if (m.id !== pollId || m.type !== 'poll') return m;
    if (m.closed) return m;
    return {
      ...m,
      options: m.options.map((opt, i) => ({
        ...opt,
        votes: i === optionIndex
          ? [...(opt.votes || []).filter(v => v !== myId), myId]
          : (opt.votes || []).filter(v => v !== myId),
      })),
    };
  }));
}

async function closePoll(pollId) {
  if (!state.isAdmin) return;
  if (!confirm('לסגור הצבעה זו? לא ניתן יהיה להצביע יותר.')) return;
  await _modifyChannelMessages(msgs => msgs.map(m =>
    m.id === pollId && m.type === 'poll' ? { ...m, closed: true } : m
  ));
  notify('🔒 הצבעה נסגרה', 'success');
}

async function _modifyChannelMessages(transform) {
  if (window.db) {
    const docRef = window.db.collection(window.FB_PROJECT).doc('chats');
    const snap   = await docRef.get();
    const data   = snap.exists ? snap.data() : {};
    const key    = (_chatChannel === 'private' && _chatPrivateKey) ? null : _chatChannel;
    if (!key) return;
    const updated = transform((data[key] || [])).slice(-100);
    await docRef.set({ [key]: updated }, { merge: true });
  } else {
    if (!state.chats) state.chats = {};
    if (!state.chats[_chatChannel]) state.chats[_chatChannel] = [];
    state.chats[_chatChannel] = transform(state.chats[_chatChannel]).slice(-100);
    saveState();
    _renderChatFallback();
  }
}

// ─── Announcements ───────────────────────────────────
function _renderAnnouncements(items) {
  const el = document.getElementById('announcements-section');
  if (!el) return;
  if (!items || !items.length) { el.style.display = 'none'; return; }
  el.style.display = '';
  el.innerHTML = items.map(a => `
    <div class="announcement-banner">
      <div class="announcement-body">
        <span class="announcement-icon">📣</span>
        <span class="announcement-text">${sanitize(a.text)}</span>
      </div>
      <div class="announcement-meta">${sanitize(a.author || '')} · ${(a.ts || '').substring(0,10)}</div>
      ${state.isAdmin ? `<button class="announcement-delete" onclick="deleteAnnouncement('${a.id}')" title="מחק הכרזה">✕</button>` : ''}
    </div>
  `).join('');
}

async function sendAnnouncement() {
  if (!state.isAdmin) { notify('🚫 רק מנטורים יכולים לשלוח הכרזות', 'error'); return; }
  const text = (document.getElementById('announce-input')?.value || '').trim().slice(0, 300);
  if (!text) { notify('נדרש טקסט להכרזה', 'error'); return; }
  const msg = { id: String(Date.now()), text, author: state.currentUser?.name || 'מנטור', ts: new Date().toISOString() };

  if (window.db) {
    const docRef = window.db.collection(window.FB_PROJECT).doc('chats');
    const snap = await docRef.get();
    const items = [...((snap.exists ? snap.data().announcements : null) || []), msg].slice(-20);
    await docRef.set({ announcements: items }, { merge: true });
  } else {
    if (!state.announcements) state.announcements = [];
    state.announcements.push(msg);
    saveState();
    _renderAnnouncements(state.announcements);
  }
  if (document.getElementById('announce-input')) document.getElementById('announce-input').value = '';
  closeModal('modal-announce');
  notify('📣 הכרזה נשלחה לכל הקבוצה!', 'success');
}

async function deleteAnnouncement(id) {
  if (!state.isAdmin) return;
  if (!confirm('למחוק הכרזה זו?')) return;
  if (window.db) {
    const docRef = window.db.collection(window.FB_PROJECT).doc('chats');
    const snap = await docRef.get();
    const items = ((snap.exists ? snap.data().announcements : null) || []).filter(a => a.id !== id);
    await docRef.set({ announcements: items }, { merge: true });
  } else {
    state.announcements = (state.announcements || []).filter(a => a.id !== id);
    saveState();
    _renderAnnouncements(state.announcements);
  }
  notify('🗑️ הכרזה נמחקה', 'success');
}

function openPrivateChat(memberId, memberName) {
  const myId = String(state.currentUser?.id || state.currentUser?.email || '');
  if (!myId || myId === String(memberId)) return;
  const key = [myId, String(memberId)].sort().join('___');
  navigate('chat');
  switchChatTab('private', key, memberName);
}
