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
    title: 'FLL Manager – Unearthed 2026',
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

function downloadAndInstall(win, version) {
  const downloadUrl = `https://github.com/amituti31-dev/fll-manager/releases/latest/download/FLL.Manager.Setup.exe`;
  shell.openExternal(downloadUrl);
  dialog.showMessageBox(win, {
    type: 'info',
    title: 'הורדה התחילה',
    message: 'הקובץ מורד בדפדפן שלך',
    detail: 'לאחר סיום ההורדה — פתח את הקובץ והתקן אותו.',
    buttons: ['אישור'],
  });
}

function checkForUpdates(win) {
  const req = https.request(
    { hostname: 'fll-manger.web.app', path: '/version.json', method: 'GET', timeout: 6000 },
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
              detail: `הגרסה המותקנת שלך היא ${app.getVersion()}.\nלחץ "עדכן עכשיו" להורדה והתקנה אוטומטית.`,
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
