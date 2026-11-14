import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Cartão base do aplicativo: cantos arredondados, sombra suave e,
/// quando tocável, leve efeito de escala com ripple.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.color,
    this.border,
    this.radius = AppTheme.radius,
    this.elevated = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Quando informado, o cartão usa este gradiente como fundo.
  final Gradient? gradient;

  /// Cor de fundo usada quando não há gradiente.
  final Color? color;
  final BoxBorder? border;
  final double radius;
  final bool elevated;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;
    final bool animar = AppMotion.enabled(context);

    final BorderRadius forma = BorderRadius.circular(widget.radius);

    // No tema escuro, uma borda sutil ajuda a separar o cartão do fundo.
    final BoxBorder? borda =
        widget.border ??
        (tema.brightness == Brightness.dark && widget.gradient == null
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.18))
            : null);

    final Widget cartao = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (widget.color ?? scheme.surface)
              : null,
          gradient: widget.gradient,
          borderRadius: forma,
          border: borda,
        ),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: widget.onTap == null
              ? null
              : (valor) => setState(() => _pressionado = valor),
          borderRadius: forma,
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    final Widget comSombra = widget.elevated
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: forma,
              boxShadow: AppTheme.softShadow(context),
            ),
            child: ClipRRect(borderRadius: forma, child: cartao),
          )
        : ClipRRect(borderRadius: forma, child: cartao);

    // Escala apenas durante o toque, sem atrasar a leitura.
    // O RepaintBoundary evita repintar o conteúdo durante a animação.
    return AnimatedScale(
      scale: _pressionado ? 0.985 : 1,
      duration: animar ? AppMotion.fast : Duration.zero,
      curve: AppMotion.curve,
      child: RepaintBoundary(child: comSombra),
    );
  }
}
