import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Transição de tela com fade combinado a um leve deslize horizontal.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page})
    : super(
        transitionDuration: AppMotion.page,
        reverseTransitionDuration: AppMotion.fast,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          // Respeita a opção de reduzir animações do sistema.
          if (!AppMotion.enabled(context)) return child;

          final Animation<double> curva = CurvedAnimation(
            parent: animation,
            curve: AppMotion.curve,
            reverseCurve: AppMotion.curve,
          );

          return FadeTransition(
            opacity: curva,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curva),
              child: child,
            ),
          );
        },
      );

  /// Atalho para empurrar uma tela com a transição padrão do app.
  static Route<T> fadeSlide<T>(Widget page) => AppPageRoute<T>(page: page);
}
