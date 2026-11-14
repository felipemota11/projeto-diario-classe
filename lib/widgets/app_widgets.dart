import 'package:flutter/material.dart';

import '../models/turma.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Tag de Hero compartilhada entre a lista de turmas e a tela de alunos.
String turmaHeroTag(Turma turma) {
  return 'turma-${turma.nome}-${turma.curso}-${turma.periodo}';
}

/// Retorna a inicial do nome com segurança, mesmo para dados antigos vazios.
String inicialDoNome(String nome) {
  final String limpo = nome.trim();

  if (limpo.isEmpty) {
    return '?';
  }

  return limpo.substring(0, 1).toUpperCase();
}

/// Formata uma nota com vírgula decimal e travessão para valores pendentes.
String formatarNotaTexto(double? nota, {String vazio = '—'}) {
  if (nota == null) {
    return vazio;
  }

  return nota.toStringAsFixed(2).replaceAll('.', ',');
}

/// Formata um percentual com uma casa decimal.
String formatarPercentualTexto(double? valor, {String vazio = '—'}) {
  if (valor == null) {
    return vazio;
  }

  return '${valor.toStringAsFixed(1).replaceAll('.', ',')}%';
}

/// Título de seção com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.titulo, this.acao});

  final String titulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final TextTheme texto = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: texto.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?acao,
      ],
    );
  }
}

/// Ícone dentro de um quadrado com gradiente da marca.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 46,
    this.color,
    this.iconSize,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color cor = color ?? scheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cor, cor.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize ?? size * 0.52),
    );
  }
}

/// Estado vazio reutilizável, com ícone, título e descrição.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    required this.mensagem,
    this.acao,
  });

  final IconData icon;
  final String titulo;
  final String mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: tema.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 40, color: tema.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              style: tema.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (acao != null) ...[const SizedBox(height: 22), acao!],
          ],
        ),
      ),
    );
  }
}

/// Botão principal com gradiente e leve escala ao pressionar.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expandido = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expandido;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final bool ativo = widget.onPressed != null;
    final bool animar = AppMotion.enabled(context);
    final BorderRadius forma = BorderRadius.circular(16);

    final Widget conteudo = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: ativo ? AppTheme.brandGradient : null,
          color: ativo ? null : Theme.of(context).disabledColor,
          borderRadius: forma,
        ),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: ativo
              ? (valor) => setState(() => _pressionado = valor)
              : null,
          borderRadius: forma,
          splashColor: Colors.white.withValues(alpha: 0.16),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: widget.expandido
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressionado ? 0.98 : 1,
      duration: animar ? AppMotion.fast : Duration.zero,
      curve: AppMotion.curve,
      child: ClipRRect(borderRadius: forma, child: conteudo),
    );
  }
}

/// Botão flutuante com animação de entrada (escala + fade).
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Duration duracao = AppMotion.duration(context, AppMotion.normal);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duracao,
      curve: AppMotion.curve,
      builder: (context, valor, filho) {
        return Opacity(
          opacity: valor,
          child: Transform.scale(
            scale: 0.86 + (0.14 * valor),
            alignment: Alignment.bottomRight,
            child: filho,
          ),
        );
      },
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// Cartão de estatística usado no painel e nos relatórios.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icon,
    this.cor,
    this.compacto = false,
  });

  final String titulo;
  final Widget valor;
  final IconData icon;
  final Color? cor;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final Color destaque = cor ?? tema.colorScheme.primary;

    return AppCard(
      padding: EdgeInsets.all(compacto ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: compacto ? 22 : 26, color: destaque),
          const SizedBox(height: 10),
          valor,
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontSize: compacto ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
