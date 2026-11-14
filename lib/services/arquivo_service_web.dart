import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Implementação web usando um link temporário com `download`.
///
/// Essa abordagem funciona em todos os navegadores modernos e não depende da
/// permissão extra exigida pela File System Access API (`showSaveFilePicker`).
class ArquivoService {
  const ArquivoService._();

  static Future<void> salvarTexto({
    required String nomeArquivo,
    required String conteudo,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(conteudo));

    await salvarBytes(nomeArquivo: nomeArquivo, bytes: bytes);
  }

  static Future<void> salvarBytes({
    required String nomeArquivo,
    required Uint8List bytes,
  }) async {
    final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: _tipoArquivo(nomeArquivo)),
    );

    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = nomeArquivo
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();

    // Dá tempo para o navegador iniciar o download antes de liberar a URL.
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 5),
        () => web.URL.revokeObjectURL(url),
      ),
    );
  }

  static String _tipoArquivo(String nomeArquivo) {
    final nome = nomeArquivo.toLowerCase();

    if (nome.endsWith('.pdf')) return 'application/pdf';
    if (nome.endsWith('.csv')) return 'text/csv;charset=utf-8';
    if (nome.endsWith('.json')) return 'application/json;charset=utf-8';
    if (nome.endsWith('.txt')) return 'text/plain;charset=utf-8';

    return 'application/octet-stream';
  }
}
