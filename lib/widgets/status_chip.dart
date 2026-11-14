import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Chip que representa a situação acadêmica do aluno.
///
/// A cor nunca é o único indicador: o texto da situação sempre aparece.
/// A troca de situação é animada com [AnimatedSwitcher].
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.situacao,
    this.compacto = false,
    this.animated = true,
  });

  final String situacao;
  final bool compacto;
  final bool animated;

  /// Cor base de cada situação conhecida pelo aplicativo.
  static Color corPara(String situacao, Brightness brilho) {
    final Color base = switch (situacao) {
      'Aprovado' => AppTheme.success,
      'Abaixo da média' || 'Final' => AppTheme.warning,
      'Reprovado' => AppTheme.danger,
      _ => AppTheme.info,
    };

    // No tema escuro clareia o tom para manter o contraste.
    return brilho == Brightness.dark
        ? Color.lerp(base, Colors.white, 0.32) ?? base
        : base;
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brilho = Theme.of(context).brightness;
    final Color cor = corPara(situacao, brilho);
    final bool animar = animated && AppMotion.enabled(context);

    final Widget chip = Container(
      key: ValueKey<String>(situacao),
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 10 : 12,
        vertical: compacto ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            situacao,
            style: TextStyle(
              color: cor,
              fontSize: compacto ? 11 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (!animar) return chip;

    // AnimatedSize evita o "pulo" de largura quando o texto da situação muda.
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.curve,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        transitionBuilder: (filho, animacao) {
          return FadeTransition(
            opacity: animacao,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(animacao),
              child: filho,
            ),
          );
        },
        child: chip,
      ),
    );
  }
}
