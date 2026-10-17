const { app, BrowserWindow, shell, dialog } = require('electron');
const path = require('path');
const http = require('http');
const https = require('https');
const fs = require('fs');
const urlModule = require('url');

const MIME = {
  '.html': 'text/html',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif':  'image/gif',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
  '.webp': 'image/webp',
  '.webmanifest': 'application/manifest+json',
};

const WEB_DIR = path.join(__dirname, 'web');

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const parsed = urlModule.parse(req.url);
      let filePath = path.join(WEB_DIR, parsed.pathname);

      // Security: prevent path traversal outside web dir
      if (!filePath.startsWith(WEB_DIR)) {
        res.writeHead(403); res.end(); return;
      }

      fs.readFile(filePath, (err, data) => {
        if (err) {
          // SPA fallback → index.html
          fs.readFile(path.join(WEB_DIR, 'index.html'), (e2, d2) => {
            if (e2) { res.writeHead(404); res.end('Not found'); return; }
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(d2);
          });
          return;
        }
        const ext = path.extname(filePath).toLowerCase();
        res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
        res.end(data);
      });
    });

    // Port 0 = OS picks a free port automatically
    server.listen(0, '127.0.0.1', () => resolve(server.address().port));
  });
}

async function createWindow(port) {
  const win = new BrowserWindow({ // eslint-disable-line
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
    },
    icon: path.join(__dirname, 'web', 'icon-512.png'),
    title: 'FLL Manager',
    autoHideMenuBar: true,
  });

  win.loadURL(`http://127.0.0.1:${port}`);

  win.webContents.setWindowOpenHandler(({ url }) => {
    // Allow Firebase auth handler + Google OAuth inside Electron
    const isAuthUrl =
      url.includes('.firebaseapp.com') ||
      url.includes('firebaseauth.app') ||
      url.startsWith('https://accounts.google.com') ||
      url.startsWith('https://www.googleapis.com') ||
      url.startsWith('https://apis.google.com') ||
      url === 'about:blank';

    if (isAuthUrl) {
      return {
        action: 'allow',
        overrideBrowserWindowOptions: {
          width: 600,
          height: 700,
          autoHideMenuBar: true,
        },
      };
    }
    shell.openExternal(url);
    return { action: 'deny' };
  });

  return win;
}

function isNewerVersion(remote, current) {
  const r = remote.split('.').map(Number);
  const c = current.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if ((r[i] || 0) > (c[i] || 0)) return true;
    if ((r[i] || 0) < (c[i] || 0)) return false;
  }
  return false;
}

// Downloads url → dest, following GitHub's release redirects; reports 0..1 progress.
function downloadFile(url, dest, onProgress, redirectsLeft = 5) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'FLL-Manager-Updater' } }, res => {
      if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
        res.resume();
        if (redirectsLeft <= 0) return reject(new Error('Too many redirects'));
        return resolve(downloadFile(new URL(res.headers.location, url).toString(), dest, onProgress, redirectsLeft - 1));
      }
      if (res.statusCode !== 200) { res.resume(); return reject(new Error(`HTTP ${res.statusCode}`)); }
      const total = Number(res.headers['content-length']) || 0;
      let got = 0;
      const file = fs.createWriteStream(dest);
      res.on('data', chunk => { got += chunk.length; if (total) onProgress(got / total); });
      res.pipe(file);
      file.on('finish', () => file.close(() => resolve()));
      file.on('error', reject);
      res.on('error', reject);
    }).on('error', reject);
  });
}

// "עדכן עכשיו": download the installer inside the app (progress on the taskbar
// and in the title), then quit and run it silently — the NSIS installer can't
// replace files while the app is running, which is why updating used to require
// closing the app by hand. /S installs into the existing install location
// without questions; --force-run reopens the updated app when it's done.
async function downloadAndInstall(win, version) {
  const downloadUrl = `https://github.com/amituti31-dev/fll-manager/releases/download/v${version}/FLL.Manager.Setup.exe`;
  const dest = path.join(app.getPath('temp'), `FLL-Manager-Setup-${version}.exe`);
  const baseTitle = win.getTitle();
  try {
    win.setProgressBar(0);
    win.setTitle('מוריד עדכון… 0%');
    await downloadFile(downloadUrl, dest, p => {
      win.setProgressBar(p);
      win.setTitle(`מוריד עדכון… ${Math.round(p * 100)}%`);
    });
    win.setProgressBar(-1);
    win.setTitle('מתקין עדכון…');
    const { spawn } = require('child_process');
    spawn(dest, ['/S', '--force-run'], { detached: true, stdio: 'ignore' }).unref();
    // Give the renderer's debounced Firestore save (≈1s) a moment, then quit so
    // the installer can overwrite the app's files.
    setTimeout(() => app.quit(), 1500);
  } catch (e) {
    win.setProgressBar(-1);
    win.setTitle(baseTitle);
    const { response } = await dialog.showMessageBox(win, {
      type: 'error',
      title: 'העדכון נכשל',
      message: 'לא הצלחנו להוריד את העדכון',
      detail: `${e.message}\nאפשר להוריד אותו בדפדפן ולהתקין ידנית (אחרי שסוגרים את האפליקציה).`,
      buttons: ['הורד בדפדפן', 'סגור'],
      defaultId: 0,
    });
    if (response === 0) shell.openExternal(downloadUrl);
  }
}

function checkForUpdates(win) {
  const req = https.request(
    { hostname: 'fll-manager-site.web.app', path: '/version.json', method: 'GET', timeout: 6000 },
    res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const { version } = JSON.parse(data);
          if (version && isNewerVersion(version, app.getVersion())) {
            dialog.showMessageBox(win, {
              type: 'info',
              title: 'עדכון זמין — FLL Manager',
              message: `גרסה ${version} זמינה!`,
              detail: `הגרסה המותקנת שלך היא ${app.getVersion()}.\nלחיצה על "עדכן עכשיו" תוריד את העדכון, תסגור את האפליקציה, תתקין ותפתח אותה מחדש — אוטומטית.`,
              buttons: ['עדכן עכשיו', 'אחר כך'],
              defaultId: 0,
            }).then(({ response }) => {
              if (response === 0) downloadAndInstall(win, version);
            });
          }
        } catch (e) {}
      });
    }
  );
  req.on('error', () => {});
  req.on('timeout', () => req.destroy());
  req.end();
}

app.whenReady().then(async () => {
  const port = await startServer();
  const win = await createWindow(port);

  // Check for updates 5 seconds after launch (give app time to load)
  setTimeout(() => checkForUpdates(win), 5000);

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow(port);
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
