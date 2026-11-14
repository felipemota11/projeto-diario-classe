// Bootstrap do Flutter Web.
//
// O carregamento do service worker é feito pelo arquivo web/sw.js,
// registrado em web/index.html. Assim evitamos que o Flutter registre
// o service worker padrão dele e substitua o nosso cache offline.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
