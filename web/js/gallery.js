// ═══════════════════════════════════════════════════════
// § 12 · GALLERY & IMPROVEMENTS
// ═══════════════════════════════════════════════════════
function openAddImprovement() { openModal('modal-improvement'); }
function saveImprovement() {
  const name = document.getElementById('imp-name').value.trim().slice(0, 200);
  if (!name) { notify('נדרש שם שיפור', 'error'); return; }
  const fileInput = document.getElementById('imp-image');
  const file = fileInput.files[0];
  const imp = {
    id: Date.now(), name, desc: document.getElementById('imp-desc').value,
    mission: document.getElementById('imp-mission').value,
    code: sanitizeUrl(document.getElementById('imp-code').value),
    date: new Date().toISOString().split('T')[0],
    author: state.currentUser?.name || 'אנונימי',
    image: null,
  };
  if (file) {
    const reader = new FileReader();
    reader.onload = e => { imp.image = e.target.result; state.improvements.push(imp); saveState(); renderGallery(); };
    reader.readAsDataURL(file);
  } else {
    state.improvements.push(imp); saveState(); renderGallery();
  }
  closeModal('modal-improvement'); notify('✅ שיפור נשמר', 'success');
}

function handleRobotPhoto(e) {
  const file = e.target.files[0]; if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    state.improvements.push({ id: Date.now(), name: 'צילום מהנייד', image: ev.target.result, date: new Date().toISOString().split('T')[0], author: state.currentUser?.name || 'אנונימי', mission: '' });
    saveState(); renderGallery(); notify('📸 תמונה נשמרה', 'success');
  };
  reader.readAsDataURL(file);
}

function renderGallery() {
  const el = document.getElementById('robot-gallery');
  const filter = document.getElementById('mission-filter').value;
  let items = state.improvements.filter(i => i.image);
  if (filter) items = items.filter(i => i.mission == filter);
  if (!items.length) {
    el.innerHTML = `<div class="gallery-empty"><div style="font-size:36px;margin-bottom:8px">📷</div><div>הוסף תמונות ושיפורים לגלריה</div></div>`;
    return;
  }
  el.innerHTML = items.map(i => `
    <div class="gallery-item" style="position:relative">
      <img src="${i.image && i.image.startsWith('data:image') ? i.image : ''}" alt="${sanitize(i.name)}">
      <div class="gallery-item-info">${sanitize(i.name)}<br><span style="opacity:0.7">${formatDate(i.date)}</span></div>
      ${state.isAdmin ? `<button onclick="deleteImprovement(${i.id})" style="position:absolute;top:6px;left:6px;background:rgba(0,0,0,0.6);border:none;color:#fff;border-radius:50%;width:24px;height:24px;cursor:pointer;font-size:13px;line-height:1;display:flex;align-items:center;justify-content:center" title="מחק">🗑️</button>` : ''}
    </div>
  `).join('');
}

function deleteImprovement(id) {
  if (!confirm('למחוק את התמונה/השיפור?')) return;
  state.improvements = state.improvements.filter(i => i.id !== id);
  saveState(); renderGallery();
  notify('🗑️ נמחק', 'success');
}

// ─── Team Gallery ─────────────────────────────────────
function renderTeamGallery() {
  const el = document.getElementById('team-gallery-grid');
  if (!el) return;
  const items = state.teamGallery || [];
  const countEl = document.getElementById('gallery-count');
  if (countEl) countEl.textContent = items.length + ' תמונות';
  if (!items.length) {
    el.innerHTML = `<div class="team-gallery-empty">
      <div style="font-size:48px;margin-bottom:10px">🖼️</div>
      <div style="font-size:15px;margin-bottom:6px">אין תמונות בגלריה</div>
      <div style="font-size:12px">הוסף תמונות מהאימונים והתחרות</div>
    </div>`;
    return;
  }
  el.innerHTML = items.map(item => {
    const canDelete = state.isAdmin || item.author === (state.currentUser?.name || '');
    return `
      <div class="team-gallery-item" onclick="viewTeamPhoto(${item.id})">
        <img src="${item.image && item.image.startsWith('data:image') ? item.image : ''}" alt="${sanitize(item.caption || '')}">
        ${(item.caption || item.author || item.date) ? `
          <div class="team-gallery-caption">
            ${item.caption ? `<div class="team-gallery-caption-text">${sanitize(item.caption)}</div>` : ''}
            <div class="team-gallery-author">${sanitize(item.author || '')} · ${item.date || ''}</div>
          </div>` : ''}
        ${canDelete ? `<button class="team-gallery-delete" onclick="event.stopPropagation();deleteTeamPhoto(${item.id})" title="מחק">🗑️</button>` : ''}
      </div>
    `;
  }).join('');
}

function addTeamPhoto(event) {
  const file = event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    const caption = prompt('כיתוב לתמונה (אופציונלי):') || '';
    if (!state.teamGallery) state.teamGallery = [];
    state.teamGallery.push({
      id: Date.now(),
      image: e.target.result,
      caption: caption.trim().slice(0, 200),
      date: new Date().toISOString().split('T')[0],
      author: state.currentUser?.name || 'אנונימי',
    });
    saveState(); renderTeamGallery();
    notify('📸 תמונה נוספה לגלריה', 'success');
  };
  reader.readAsDataURL(file);
  event.target.value = '';
}

function deleteTeamPhoto(id) {
  if (!confirm('למחוק תמונה זו מהגלריה?')) return;
  state.teamGallery = (state.teamGallery || []).filter(i => i.id !== id);
  saveState(); renderTeamGallery();
  notify('🗑️ תמונה נמחקה', 'success');
}

function viewTeamPhoto(id) {
  const item = (state.teamGallery || []).find(i => i.id === id);
  if (!item || !item.image) return;
  const win = window.open('', '_blank', 'width=900,height=700');
  if (!win) return;
  win.document.write(`<!DOCTYPE html><html dir="rtl"><head><meta charset="UTF-8">
    <style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;font-family:sans-serif}
    img{max-width:100vw;max-height:85vh;object-fit:contain}
    .info{color:#ccc;padding:10px;text-align:center;font-size:13px}</style></head>
    <body>
      <img src="${item.image}" alt="">
      ${item.caption ? `<div class="info"><strong>${sanitize(item.caption)}</strong></div>` : ''}
      <div class="info">${sanitize(item.author || '')} · ${item.date || ''}</div>
    </body></html>`);
  win.document.close();
}

function openVideoSelect() {
  const imgs = state.improvements.filter(i => i.image);
  if (!imgs.length) { notify('אין תמונות בגלריה', 'error'); return; }
  const el = document.getElementById('video-img-list');
  el.innerHTML = imgs.map(i => `
    <label style="cursor:pointer;border-radius:10px;overflow:hidden;border:2px solid var(--border);display:block" onclick="updateVideoCount()">
      <input type="checkbox" data-id="${i.id}" style="position:absolute;width:1px;height:1px;opacity:0">
      <img src="${i.image}" style="width:100%;height:90px;object-fit:cover;display:block">
      <div style="padding:4px 6px;font-size:11px;background:var(--surface2);display:flex;align-items:center;gap:4px">
        <span id="vcheck-${i.id}" style="color:var(--text3)">○</span>
        <span>${sanitize(i.name)}</span>
      </div>
    </label>
  `).join('');
  // Make labels toggle visually
  el.querySelectorAll('label').forEach(lbl => {
    lbl.addEventListener('click', e => {
      const cb = lbl.querySelector('input');
      cb.checked = !cb.checked;
      const id = cb.dataset.id;
      document.getElementById('vcheck-' + id).textContent = cb.checked ? '✅' : '○';
      lbl.style.borderColor = cb.checked ? 'var(--accent)' : 'var(--border)';
      updateVideoCount();
      e.preventDefault();
    });
  });
  updateVideoCount();
  openModal('modal-video-select');
}

function updateVideoCount() {
  const count = document.querySelectorAll('#video-img-list input:checked').length;
  document.getElementById('video-selected-count').textContent = count + ' נבחרו';
}

function toggleSelectAll() {
  const inputs = [...document.querySelectorAll('#video-img-list input')];
  const allChecked = inputs.every(i => i.checked);
  inputs.forEach(cb => {
    cb.checked = !allChecked;
    const id = cb.dataset.id;
    document.getElementById('vcheck-' + id).textContent = cb.checked ? '✅' : '○';
    cb.closest('label').style.borderColor = cb.checked ? 'var(--accent)' : 'var(--border)';
  });
  updateVideoCount();
}

async function createVideoFromSelected() {
  const selected = [...document.querySelectorAll('#video-img-list input:checked')].map(cb => cb.dataset.id);
  const imgs = state.improvements.filter(i => selected.includes(String(i.id)) && i.image);
  if (!imgs.length) { notify('יש לבחור לפחות תמונה אחת', 'error'); return; }
  closeModal('modal-video-select');
  await makeTimelapse(imgs);
}

async function makeTimelapse(imgs) {
  if (!imgs || !imgs.length) { notify('נדרשת לפחות תמונה אחת', 'error'); return; }

  const loadImg = src => new Promise((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = rej; i.src = src; });
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  const canvas = document.createElement('canvas');
  canvas.width = 800; canvas.height = 600;
  const ctx = canvas.getContext('2d');

  function drawImgOnCanvas(imgEl, alpha, label) {
    ctx.clearRect(0, 0, 800, 600);
    ctx.fillStyle = '#0b0f1a'; ctx.fillRect(0, 0, 800, 600);
    ctx.globalAlpha = alpha;
    const sc = Math.min(780 / imgEl.width, 540 / imgEl.height);
    ctx.drawImage(imgEl, (800 - imgEl.width * sc) / 2, (600 - imgEl.height * sc) / 2, imgEl.width * sc, imgEl.height * sc);
    ctx.globalAlpha = 1;
    ctx.fillStyle = 'rgba(0,0,0,0.65)'; ctx.fillRect(0, 540, 800, 60);
    ctx.fillStyle = '#fff'; ctx.font = 'bold 15px Arial'; ctx.textAlign = 'right';
    ctx.fillText(label, 780, 572);
  }

  // iOS Safari: canvas.captureStream is not available — fall back to HTML slideshow
  const hasCapture = typeof canvas.captureStream === 'function';
  const videoMime = hasCapture && ['video/mp4;codecs=avc1', 'video/webm;codecs=vp9', 'video/webm'].find(
    t => typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported(t)
  );

  if (!hasCapture || !videoMime) {
    notify('🎬 מייצר מצגת (ספארי אינו תומך בייצוא וידאו)...', 'success');
    const slides = imgs.map((img, i) => {
      const label = sanitize(img.name) + ' · ' + formatDate(img.date);
      return `<div class="sl" style="display:${i===0?'flex':'none'};flex-direction:column;align-items:center;justify-content:center;height:100vh;padding:16px;box-sizing:border-box">
        <img src="${sanitize(img.image)}" style="max-width:100%;max-height:78vh;border-radius:12px;object-fit:contain">
        <div style="color:#fff;margin-top:10px;font-size:15px;font-weight:700">${label}</div>
        <div style="color:#aaa;font-size:13px;margin-top:4px">${i+1}/${imgs.length}</div>
      </div>`;
    }).join('');
    const win = window.open('', '_blank');
    if (!win) { notify('אפשר פתיחת חלונות לייצוא', 'error'); return; }
    win.document.write(`<!DOCTYPE html><html dir="rtl"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>FLL Slideshow</title>
    <style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0b0f1a;font-family:sans-serif}
    #ctrl{position:fixed;bottom:0;left:0;right:0;background:rgba(0,0,0,0.7);padding:12px;display:flex;gap:8px;justify-content:center;z-index:9}
    button{padding:10px 22px;border-radius:8px;border:none;background:#3d7fff;color:#fff;font-size:15px;cursor:pointer}
    </style></head><body>${slides}
    <div id="ctrl">
      <button onclick="go(-1)">◀ הקודם</button>
      <button onclick="tog()" id="ab">▶ אוטומטי</button>
      <button onclick="go(1)">הבא ▶</button>
    </div>
    <script>
    var idx=0,timer=null,sl=document.querySelectorAll('.sl');
    function go(d){sl[idx].style.display='none';idx=(idx+d+sl.length)%sl.length;sl[idx].style.display='flex';}
    function tog(){if(timer){clearInterval(timer);timer=null;document.getElementById('ab').textContent='▶ אוטומטי';}
    else{timer=setInterval(()=>go(1),5000);document.getElementById('ab').textContent='⏸ עצור';}}
    <\/script></body></html>`);
    win.document.close();
    notify('✅ המצגת נפתחה!', 'success');
    return;
  }

  notify('🎬 מייצר סרטון... אל תסגור את הדף', 'success');
  const stream = canvas.captureStream(30);
  const recorder = new MediaRecorder(stream, { mimeType: videoMime });
  const chunks = [];
  recorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data); };
  const ext = videoMime.includes('mp4') ? 'mp4' : 'webm';

  recorder.onstop = async () => {
    const blob = new Blob(chunks, { type: videoMime.split(';')[0] });
    const filename = 'fll-video-' + new Date().toISOString().split('T')[0] + '.' + ext;
    if (window.showSaveFilePicker) {
      try {
        const fh = await window.showSaveFilePicker({ suggestedName: filename, types: [{ description: 'Video', accept: { [videoMime.split(';')[0]]: ['.' + ext] } }] });
        const writable = await fh.createWritable(); await writable.write(blob); await writable.close();
        notify('✅ הסרטון נשמר!', 'success'); return;
      } catch(e) {}
    }
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 3000);
    notify('✅ הסרטון הורד!', 'success');
  };

  const imageEls = await Promise.all(imgs.map(i => loadImg(i.image).catch(() => null)));
  recorder.start();

  for (let i = 0; i < imgs.length; i++) {
    const imgEl = imageEls[i];
    if (!imgEl) continue;
    const label = sanitize(imgs[i].name) + ' · ' + formatDate(imgs[i].date) + '  ' + (i + 1) + '/' + imgs.length;

    drawImgOnCanvas(imgEl, 1, label);
    await sleep(4000);

    if (i < imgs.length - 1) {
      const nextEl = imageEls[i + 1];
      if (nextEl) {
        const nextLabel = sanitize(imgs[i + 1].name) + ' · ' + formatDate(imgs[i + 1].date) + '  ' + (i + 2) + '/' + imgs.length;
        const STEPS = 30;
        for (let s = 0; s <= STEPS; s++) {
          const alpha = s / STEPS;
          ctx.clearRect(0, 0, 800, 600);
          ctx.fillStyle = '#0b0f1a'; ctx.fillRect(0, 0, 800, 600);
          ctx.globalAlpha = 1 - alpha;
          const sc1 = Math.min(780 / imgEl.width, 540 / imgEl.height);
          ctx.drawImage(imgEl, (800 - imgEl.width * sc1) / 2, (600 - imgEl.height * sc1) / 2, imgEl.width * sc1, imgEl.height * sc1);
          ctx.globalAlpha = alpha;
          const sc2 = Math.min(780 / nextEl.width, 540 / nextEl.height);
          ctx.drawImage(nextEl, (800 - nextEl.width * sc2) / 2, (600 - nextEl.height * sc2) / 2, nextEl.width * sc2, nextEl.height * sc2);
          ctx.globalAlpha = 1;
          ctx.fillStyle = 'rgba(0,0,0,0.65)'; ctx.fillRect(0, 540, 800, 60);
          ctx.fillStyle = '#fff'; ctx.font = 'bold 15px Arial'; ctx.textAlign = 'right';
          ctx.fillText(alpha < 0.5 ? label : nextLabel, 780, 572);
          await sleep(33);
        }
      }
    }
  }

  recorder.stop();
}
