import 'package:flutter/material.dart';

/// Identificação visual do Diário de Classe a partir da imagem fornecida.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/images/icone_diario.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
