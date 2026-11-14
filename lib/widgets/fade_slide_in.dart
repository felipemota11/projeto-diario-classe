import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Entrada suave (fade + deslize) usada por itens de lista e blocos.
///
/// O atraso [delay] cria o efeito escalonado entre itens. Para listas longas,
/// prefira atraso zero: itens criados ao rolar a tela não devem esperar.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.06),
    this.duration = AppMotion.normal,
  });

  final Widget child;
  final Duration delay;

  /// Deslocamento inicial, em fração do tamanho do filho.
  final Offset offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _curva = CurvedAnimation(
    parent: _controle,
    curve: AppMotion.curve,
  );

  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_iniciado) return;
    _iniciado = true;

    if (!AppMotion.enabled(context)) {
      _controle.value = 1;
      return;
    }

    if (widget.delay == Duration.zero) {
      _controle.forward();
      return;
    }

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controle.forward();
    });
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curva,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(_curva),
        // Isola o conteúdo animado para que a rolagem não repinte o cartão.
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
