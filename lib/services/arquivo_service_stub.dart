import 'dart:typed_data';

/// Implementação de segurança para plataformas sem suporte a arquivos.
class ArquivoService {
  const ArquivoService._();

  static Future<void> salvarTexto({
    required String nomeArquivo,
    required String conteudo,
  }) {
    throw UnsupportedError(
      'O salvamento de arquivos não é suportado nesta plataforma.',
    );
  }

  static Future<void> salvarBytes({
    required String nomeArquivo,
    required Uint8List bytes,
  }) {
    throw UnsupportedError(
      'O salvamento de arquivos não é suportado nesta plataforma.',
    );
  }
}
