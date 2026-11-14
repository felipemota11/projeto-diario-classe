import 'package:flutter/widgets.dart';

/// Durações e curvas usadas em todo o aplicativo.
///
/// Também concentra o respeito à opção "reduzir animações" do sistema.
class AppMotion {
  const AppMotion._();

  /// Microinterações (ripple, escala de toque).
  static const Duration fast = Duration(milliseconds: 200);

  /// Entradas de listas e trocas de estado.
  static const Duration normal = Duration(milliseconds: 320);

  /// Contagem de números e abertura do gráfico.
  static const Duration slow = Duration(milliseconds: 480);

  /// Transição entre telas.
  static const Duration page = Duration(milliseconds: 360);

  /// Curva padrão, suave no final.
  static const Curve curve = Curves.easeOutCubic;

  /// Verdadeiro quando o sistema permite animações.
  static bool enabled(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Retorna [duracao] ou zero quando as animações estão desligadas.
  static Duration duration(BuildContext context, Duration duracao) {
    return enabled(context) ? duracao : Duration.zero;
  }

  /// Atraso escalonado para itens de lista, limitado para não cansar.
  static Duration stagger(
    int indice, {
    Duration passo = const Duration(milliseconds: 55),
    int maximo = 7,
  }) {
    final int posicao = indice > maximo ? maximo : indice;

    return passo * posicao;
  }
}
