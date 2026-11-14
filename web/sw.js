/* Service worker do Diário de Classe.
 *
 * Estratégia:
 * - Sempre tenta a rede primeiro para receber atualizações.
 * - Em caso de falha (offline), usa a cópia em cache.
 * - Navegações caem no index.html em cache.
 */

const CACHE = 'diario-classe-v5';

const ARQUIVOS_BASE = [
  './',
  './index.html',
  './manifest.json',
  './flutter_bootstrap.js',
  './main.dart.js',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
  // Fontes, manifests e shaders usados pelo Flutter.
  './assets/AssetManifest.bin',
  './assets/AssetManifest.bin.json',
  './assets/FontManifest.json',
  './assets/fonts/MaterialIcons-Regular.otf',
  './assets/fonts/fallback/Roboto-Regular.ttf',
  './assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  './assets/shaders/ink_sparkle.frag',
  './assets/shaders/stretch_effect.frag',
  // CanvasKit local. O Chromium usa a variante em canvaskit/chromium;
  // os demais navegadores usam a versão principal.
  './canvaskit/canvaskit.js',
  './canvaskit/canvaskit.wasm',
  './canvaskit/chromium/canvaskit.js',
  './canvaskit/chromium/canvaskit.wasm',
];

self.addEventListener('install', (evento) => {
  evento.waitUntil(
    caches
      .open(CACHE)
      .then((cache) =>
        Promise.all(
          ARQUIVOS_BASE.map((url) =>
            cache.add(url).catch(() => {
              // Um arquivo ausente não deve impedir a instalação.
            }),
          ),
        ),
      )
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (evento) => {
  evento.waitUntil(
    caches
      .keys()
      .then((chaves) =>
        Promise.all(
          chaves
            .filter((chave) => chave !== CACHE)
            .map((chave) => caches.delete(chave)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

// Procura a melhor cópia em cache disponível para a requisição.
// Navegações usam o index.html como reserva (aplicativo de página única).
function respostaDoCache(requisicao) {
  return caches.match(requisicao).then((emCache) => {
    if (emCache) return emCache;
    if (requisicao.mode === 'navigate') return caches.match('./index.html');
    return null;
  });
}

self.addEventListener('fetch', (evento) => {
  const requisicao = evento.request;

  if (requisicao.method !== 'GET') return;

  // Rede primeiro para manter o aplicativo atualizado. Quando a rede falha
  // ou um proxy responde com erro (por exemplo, offline), usa o cache.
  evento.respondWith(
    fetch(requisicao)
      .then((resposta) => {
        if (resposta && (resposta.ok || resposta.type === 'opaque')) {
          const copia = resposta.clone();

          caches
            .open(CACHE)
            .then((cache) => cache.put(requisicao, copia))
            .catch(() => {
              // Cache cheio ou resposta não armazenável: segue normalmente.
            });

          return resposta;
        }

        return respostaDoCache(requisicao).then((emCache) => {
          if (emCache) return emCache;
          // Em navegações, devolve a resposta de erro do servidor.
          // Para arquivos, devolve erro de rede para o Flutter.
          return requisicao.mode === 'navigate' ? resposta : Response.error();
        });
      })
      .catch(() =>
        respostaDoCache(requisicao).then(
          (emCache) => emCache || Response.error(),
        ),
      ),
  );
});
