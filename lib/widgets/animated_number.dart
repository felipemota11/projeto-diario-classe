import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Número que conta de zero até o valor final quando aparece na tela.
///
/// Usa algarismos tabulares para evitar que a largura do texto mude
/// durante a contagem. Em listas longas, use [animated] como `false`
/// para evitar várias animações simultâneas e manter a rolagem fluida.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = AppMotion.slow,
    this.textAlign,
    this.animated = true,
  });

  /// Valor a ser exibido. Quando nulo, mostra um travessão.
  final num? value;

  /// Função de formatação (por exemplo, duas casas decimais).
  final String Function(num valor) formatter;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final TextStyle estilo = AppTheme.numerico(
      style ?? Theme.of(context).textTheme.titleLarge,
    );

    if (value == null) {
      return Text('—', style: estilo, textAlign: textAlign);
    }

    final Duration duracao = AppMotion.duration(context, duration);

    // Números estáticos são usados em listas para reduzir o custo de pintura.
    if (!animated || duracao == Duration.zero) {
      return Text(
        formatter(value!),
        style: estilo,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value!.toDouble()),
        duration: duracao,
        curve: AppMotion.curve,
        builder: (context, valorAtual, _) {
          return Text(
            formatter(valorAtual),
            style: estilo,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}
