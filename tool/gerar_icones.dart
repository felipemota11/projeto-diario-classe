import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Gera os formatos de instalação preservando a imagem original do projeto.
/// Execute na raiz: dart run tool/gerar_icones.dart
void main() {
  final original = img.decodeImage(
    File('assets/images/icone_diario_original.jpeg').readAsBytesSync(),
  );
  if (original == null || original.width != original.height) {
    throw StateError('O ícone original deve ser uma imagem quadrada válida.');
  }

  img.Image redimensionar(int tamanho, {double escala = 1}) {
    final lado = (tamanho * escala).round();
    final imagem = img.copyResize(
      original,
      width: lado,
      height: lado,
      interpolation: lado < original.width
          ? img.Interpolation.average
          : img.Interpolation.cubic,
    );
    if (escala == 1) return imagem;
    final fundo = original.getPixel(0, 0);
    final tela = img.Image(width: tamanho, height: tamanho);
    img.fill(
      tela,
      color: img.ColorRgb8(fundo.r.toInt(), fundo.g.toInt(), fundo.b.toInt()),
    );
    return img.compositeImage(
      tela,
      imagem,
      dstX: (tamanho - lado) ~/ 2,
      dstY: (tamanho - lado) ~/ 2,
    );
  }

  void png(String caminho, int tamanho, {double escala = 1}) {
    final arquivo = File(caminho);
    arquivo.parent.createSync(recursive: true);
    arquivo.writeAsBytesSync(
      img.encodePng(redimensionar(tamanho, escala: escala)),
    );
    stdout.writeln('$caminho ($tamanho x $tamanho)');
  }

  png('assets/images/icone_diario.png', original.width);
  png('web/favicon.png', 32);
  for (final tamanho in [192, 512]) {
    png('web/icons/Icon-$tamanho.png', tamanho);
    png('web/icons/Icon-maskable-$tamanho.png', tamanho, escala: 0.80);
  }

  const densidades = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  };
  for (final densidade in densidades.entries) {
    final pasta = 'android/app/src/main/res/mipmap-${densidade.key}';
    png('$pasta/ic_launcher.png', (48 * densidade.value).round());
    png(
      '$pasta/ic_launcher_foreground.png',
      (108 * densidade.value).round(),
      escala: 0.78,
    );
  }

  for (final pasta in [
    'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    'macos/Runner/Assets.xcassets/AppIcon.appiconset',
  ]) {
    final catalogo = jsonDecode(
      File('$pasta/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final gerados = <String>{};
    for (final entrada in catalogo['images'] as List<dynamic>) {
      final dados = entrada as Map<String, dynamic>;
      final nome = dados['filename'] as String;
      if (!gerados.add(nome)) continue;
      final tamanho = double.parse((dados['size'] as String).split('x').first);
      final escala = double.parse(
        (dados['scale'] as String).replaceAll('x', ''),
      );
      png('$pasta/$nome', (tamanho * escala).round());
    }
  }

  final tamanhosWindows = [16, 20, 24, 32, 40, 48, 64, 128, 256];
  File('windows/runner/resources/app_icon.ico').writeAsBytesSync(
    img.IcoEncoder().encodeImages(tamanhosWindows.map(redimensionar).toList()),
  );
  stdout.writeln('Ícone Windows: ${tamanhosWindows.join(", ")} px.');
}
