var C = "fll-v5";
self.addEventListener("install", e => { /* wait for SKIP_WAITING message from page */ });
self.addEventListener("message", e => {
  if (e.data?.type === "SKIP_WAITING") self.skipWaiting();
});
self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  e.respondWith(fetch(e.request).catch(() => caches.match(e.request)));
});
self.addEventListener("notificationclick", e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then(cls => {
      for (const c of cls) {
        if ("focus" in c) { c.focus(); c.postMessage({ type: "NAVIGATE", screen: "mytasks" }); return; }
      }
      return clients.openWindow("/");
    })
  );
});
