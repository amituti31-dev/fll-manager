# FLL Manager

Team-management app for a FIRST LEGO League team. Three clients share one Firebase backend:

- `web/` — vanilla JS PWA, no framework/bundler. This is also the source Electron wraps.
- **Electron desktop app** — `main.js` serves `web/` via a local HTTP server; packaged into a Windows EXE via `package.json`'s `build` (electron-builder) config.
- `Android/` — native Flutter/Dart app, a separate codebase kept at feature parity with `web/` by hand (no shared code).
- `ios/` (gitignored, untracked) — a near-duplicate Flutter copy of `Android/`, only touched when explicitly asked to port a change there.
- `fll_manager/` (gitignored) — a stray/duplicate Flutter build directory, not the real app. `Android/` is the one real, tracked Flutter app.

## Commands

- **Web**: no build step — `web/index.html` is served as-is (statically, or via Electron/Firebase Hosting).
- **Electron**: `npm start` (`electron .`), `npm run build` (`electron-builder --win`) → `dist/*.exe`.
- **Android**: from `Android/`, `flutter analyze` (or `flutter analyze <file>` for a quick syntax check), `flutter build apk --release`.
- **Full release**: `./Update-All.ps1` from the repo root — bumps the version, builds the Windows EXE *and* the Android APK, commits + pushes to `main`, deploys Firebase Hosting, and creates a GitHub Release with both binaries attached. Requires a `.github-token` file (gitignored PAT) in the repo root.
- No automated test suite exists on any client — verification is `node --check` (web JS), `flutter analyze` (Android), and manually exercising the app.

## Architecture

**Backend**: Firebase (Firestore + Auth + Storage). No Cloud Functions, no Blaze plan — all logic is client-side; JSON/data imports are prepared externally and just consumed by the app.

**Firestore layout**, per team under `/{teamId}/`:
- `settings` — team name/logo/join codes. Mentor-only write.
- `data` — anything **any** team member (student or mentor) can write: logs, `missionChecks`, `missionExtra`, links, stickies, memberTasks, interviews, innovation fields, etc.
- `admin-data` — **mentor-only** write: members (raw PINs stripped before sync), scores, rubrics, checklist, seasons, `customMissions`/`missions`, judgingDoc.
- `archives` — mentor-only.
- `gallery`, `improvements` — small anchor docs whose only real content is a `photos` subcollection (`/{teamId}/gallery/photos/{id}`, `/{teamId}/improvements/photos/{id}`), one document per photo. Member-writable (not mentor-only). See "Images" below.
- `fll-teams-registry` (top-level collection) — sanitized-email → `{teamId, role}`, the source of truth Firestore rules read to authorize.

Enforcement is entirely server-side in **`Android/firestore.rules`** (a single rules file, shared by web and Android, deployed via Firebase — there's no per-client copy) via `isMember`/`isMentor` helpers that read the *caller's own* registry doc. **Never trust a client-side `state.isAdmin` / `prov.isAdmin` flag for real authorization** — it's UI-only convenience (hides buttons); the only real gate is `firestore.rules`. When adding a new piece of state, decide up front which tier it belongs in (writable-by-anyone → `data`, mentor-only → `admin-data`) and wire it into the load/save functions on **both** clients.

**Web state** — a single global `state` object (`web/js/state.js`), persisted to `localStorage` and debounced (1s) into the three Firestore tiers above (`saveState()`/`loadState()`). `web/js/defaults.js` holds fixed reference data (`DEFAULT_CHECKLIST`, `MISSIONS_2026`, `OFFICIAL_RUBRICS`) — these are the offline/first-run fallback and must never be deleted, only added to.

**Web events / CSP** — the CSP has no `unsafe-inline`. Every interactive element uses `data-action` / `data-onchange` / `data-oninput` attributes resolved through one allowlisted `ACTIONS` table + delegated listeners in `web/js/actions.js`. **Never add a raw `onclick="..."` attribute** — add a new `ACTIONS` entry and a `data-action` instead (the two exceptions are a handful of handlers inside a separate `document.write()`'d popup window in `gallery.js`, which the page's CSP doesn't cover anyway).

**Android state** — `AppProvider` (`ChangeNotifier`, `Android/lib/providers/app_provider.dart`) mirrors the same three-tier split: `_saveSettings()` / `_saveData()` / the `admin-data` write inside `_saveData()` (wrapped in try/catch since a non-mentor's write is rejected server-side and that's expected/normal, not an error to surface).

**Missions are dynamic on both clients**: web's `getMissions()` (`web/js/utils.js`) returns `state.customMissions` when populated, else the built-in `MISSIONS_2026`; Android's `AppProvider.missions` defaults to `missions2026` and is overridden by `admin-data.missions` when present. Both fallback arrays are load-bearing for offline / brand-new teams — don't remove them when changing mission-related features.

**Images**: since there's no Firebase Storage (no Blaze plan), every image is embedded as a base64 data URL inside a Firestore document — the 1MB-per-document cap is a real constraint, addressed two ways:
1. **Compression before it ever reaches `state`.** Web: any upload path must go through `compressImage(file, {maxDim, quality})` (`web/js/utils.js`) first, which downscales via `<canvas>` and re-encodes as JPEG; used by gallery photos, improvement/log photos, the team logo, and the strategy-board background (`gallery.js`, `logs.js`, `auth.js`, `strategy.js`). Android already downscales on capture (`pickImageWithSource(maxWidth/maxHeight/quality)`) so it doesn't need this. `judging.js`'s judging-PDF upload is intentionally excluded (a PDF can't be canvas-compressed).
2. **One Firestore document per photo**, not one big array field. `state.teamGallery` and `state.improvements` (web) / `gallery` and `improvements` (Android's `AppProvider`) are no longer written into `data`/the old single `gallery` doc — each item is its own doc in a `photos` subcollection (see Firestore layout above), written/deleted individually: `saveGalleryPhoto`/`deleteGalleryPhotoDoc`/`saveImprovementPhoto`/`deleteImprovementPhotoDoc` on web (`state.js`), `saveGalleryPhoto`/`deleteGalleryPhoto`/`saveImprovementPhoto`/`deleteImprovementPhoto` on Android (`FirebaseService`). This is also what made web's team gallery genuinely shared for the first time — it previously lived only in `localStorage`, never synced to Firestore at all, while Android's did (as a single `gallery` doc); both clients now read/write the same per-photo subcollection.
   - **Legacy formats are auto-migrated on load, not deleted:** the old embedded array (`data.improvements`, or the pre-split `gallery` doc's `items` field) is merged with the subcollection docs, lazily written into per-photo docs, and the legacy field is cleared *only after* that write succeeds — so an offline/failed migration just retries next load instead of losing photos. See `mergeAndMigratePhotos()` in `web/js/state.js` / `_mergeAndMigratePhotos()` in `Android/lib/providers/app_provider.dart`.
   - **Bulk-reset flows must clear the subcollection too**, not just the local array — a `{merge:true}` write to the old array field no longer removes anything, since the images aren't there anymore. See `deleteAllImprovementPhotos()`/`clearAllGalleryPhotos()` and their call sites (season archive/reset in `archive.js`/`members.js`, `resetAllData()` in `app_provider.dart`) before adding another feature that wipes these lists.

## Conventions

- All user-facing strings are Hebrew; RTL layout throughout both web and Android.
- Web: always run user-supplied or imported text through `sanitize()` before inserting into `innerHTML`.
- Any new state that's keyed by an id belonging to a replaceable list (e.g. per-mission notes keyed by mission id) should be reset when that list is fully replaced, to avoid stale entries silently pointing at the wrong item after the swap.

## Gotchas

- `.github-token` (repo root, gitignored) is a GitHub PAT `Update-All.ps1` needs to create releases — never commit it.
- Firebase web/app config (apiKey etc., in `web/js/auth.js` and `Android/lib/firebase_options.dart`) is not itself a secret — that's normal for Firebase client apps, real security is entirely in `firestore.rules` — but don't let anything more sensitive get embedded alongside it.
- Git line endings: repo blobs are LF. A script doing raw Node `fs.readFileSync`/`writeFileSync` on Windows can silently flip a file to CRLF; if `git diff` on a small edit shows the whole file changed, that's the tell — re-normalize to LF before committing.
- This is a git repository; check `git status` before assuming a file isn't tracked.
