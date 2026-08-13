// 遊戲中心的 Service Worker（自動版本管理版）
// 每次新增/移除/更新遊戲時，只需更新 CACHE 版本號，使用者自動取得最新版。
// 策略：網路優先（stale-while-revalidate），快取名稱含版本號，版本不同即全部換新。
const CACHE = 'gamehub-v' + Date.now();

// 快取首頁與必要資源（不預快取各遊戲，採用力需即載策略）
const CORE = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// 網路優先：每次都先向伺服器取得最新版；失敗才退回快取（離線仍可玩）
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request).then((res) => {
      // 只快取成功且為同源/靜態的回應
      if (res && res.status === 200) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(e.request, copy));
      }
      return res;
    }).catch(() =>
      caches.match(e.request).then((hit) => hit || caches.match('./'))
    )
  );
});
