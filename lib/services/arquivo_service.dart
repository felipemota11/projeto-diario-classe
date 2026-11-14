// Escolhe a implementação de salvamento de arquivos de acordo com a
// plataforma. No navegador usamos um download direto por Blob, que não
// depende da permissão da File System Access API. Em aplicativos nativos
// continuamos usando o seletor de arquivos do sistema.
export 'arquivo_service_stub.dart'
    if (dart.library.io) 'arquivo_service_io.dart'
    if (dart.library.js_interop) 'arquivo_service_web.dart';
