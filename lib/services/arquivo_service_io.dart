import 'dart:typed_data';

import 'package:flutter_file_saver/flutter_file_saver.dart';

/// Implementação para plataformas nativas (Android, iOS e desktop).
class ArquivoService {
  const ArquivoService._();

  static Future<void> salvarTexto({
    required String nomeArquivo,
    required String conteudo,
  }) async {
    await FlutterFileSaver().writeFileAsString(
      fileName: nomeArquivo,
      data: conteudo,
    );
  }

  static Future<void> salvarBytes({
    required String nomeArquivo,
    required Uint8List bytes,
  }) async {
    await FlutterFileSaver().writeFileAsBytes(
      fileName: nomeArquivo,
      bytes: bytes,
    );
  }
}
