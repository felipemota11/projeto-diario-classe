import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../services/armazenamento_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_number.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_widgets.dart';
import '../widgets/fade_slide_in.dart';
import 'backup_screen.dart';
import 'notas_screen.dart';
import 'perfil_screen.dart';
import 'relatorios_screen.dart';
import 'turmas_screen.dart';

class InicioScreen extends StatefulWidget {
  final Professor professor;
  final String? erroAoCarregar;

  const InicioScreen({super.key, required this.professor, this.erroAoCarregar});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.erroAoCarregar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _mostrarErroCarregamento(widget.erroAoCarregar!);
      });
    }
  }

  // Avisa sobre dados corrompidos e permite limpar o armazenamento.
  Future<void> _mostrarErroCarregamento(String mensagem) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dados não puderam ser carregados'),
          content: SingleChildScrollView(child: Text(mensagem)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ArmazenamentoService.apagarDados();
                } catch (erro) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Não foi possível limpar os dados: $erro'),
                    ),
                  );

                  return;
                }

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados inválidos removidos.')),
                );
              },
              child: const Text('Limpar dados inválidos'),
            ),
          ],
        );
      },
    );
  }

  // Abre outra tela e atualiza o painel quando retornar.
  Future<void> _abrirTela(Widget tela) async {
    await Navigator.push<void>(context, AppPageRoute.fadeSlide(tela));

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final turmasAtivas = widget.professor.turmas
        .where((turma) => !turma.arquivada)
        .toList();

    final quantidadeTurmas = turmasAtivas.length;

    final quantidadeAlunos = turmasAtivas.fold<int>(
      0,
      (total, turma) => total + turma.alunos.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Diário de Classe',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      drawer: _construirMenu(context),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho em gradiente com o nome do professor.
            FadeSlideIn(child: _Cabecalho(nome: widget.professor.nome)),

            const SizedBox(height: 26),

            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: const SectionHeader(titulo: 'Resumo geral'),
            ),

            const SizedBox(height: 12),

            // Blocos de resumo lado a lado.
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _BentoResumo(
                quantidadeTurmas: quantidadeTurmas,
                quantidadeAlunos: quantidadeAlunos,
              ),
            ),

            const SizedBox(height: 26),

            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: const SectionHeader(titulo: 'Acessos rápidos'),
            ),

            const SizedBox(height: 12),

            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: _AtalhoCard(
                titulo: 'Minhas turmas',
                descricao: 'Cadastrar e consultar turmas e alunos.',
                icone: Icons.groups_rounded,
                cor: AppTheme.primary,
                aoClicar: () {
                  _abrirTela(TurmasScreen(professor: widget.professor));
                },
              ),
            ),

            FadeSlideIn(
              delay: const Duration(milliseconds: 270),
              child: _AtalhoCard(
                titulo: 'Lançamento de notas',
                descricao: 'Registrar avaliações e recuperações.',
                icone: Icons.edit_note_rounded,
                cor: AppTheme.secondary,
                aoClicar: () {
                  _abrirTela(NotasScreen(professor: widget.professor));
                },
              ),
            ),

            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: _AtalhoCard(
                titulo: 'Relatórios',
                descricao: 'Consultar médias e estatísticas.',
                icone: Icons.bar_chart_rounded,
                cor: AppTheme.info,
                aoClicar: () {
                  _abrirTela(RelatoriosScreen(professor: widget.professor));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menu lateral com o mesmo comportamento de navegação do projeto original.
  Widget _construirMenu(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final int quantidadeArquivadas = widget.professor.turmas
        .where((turma) => turma.arquivada)
        .length;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.professor.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Diário de Classe',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            _itemMenu(
              context,
              icone: Icons.home_rounded,
              titulo: 'Início',
              selecionado: true,
              aoClicar: () => Navigator.pop(context),
            ),

            _itemMenu(
              context,
              icone: Icons.groups_rounded,
              titulo: 'Turmas',
              aoClicar: () async {
                Navigator.pop(context);

                await _abrirTela(TurmasScreen(professor: widget.professor));
              },
            ),

            _itemMenu(
              context,
              icone: Icons.edit_note_rounded,
              titulo: 'Lançamento de notas',
              aoClicar: () async {
                Navigator.pop(context);

                await _abrirTela(NotasScreen(professor: widget.professor));
              },
            ),

            _itemMenu(
              context,
              icone: Icons.bar_chart_rounded,
              titulo: 'Relatórios',
              aoClicar: () async {
                Navigator.pop(context);

                await _abrirTela(RelatoriosScreen(professor: widget.professor));
              },
            ),

            _itemMenu(
              context,
              icone: Icons.manage_accounts_rounded,
              titulo: 'Perfil e regras',
              aoClicar: () async {
                Navigator.pop(context);

                await _abrirTela(PerfilScreen(professor: widget.professor));
              },
            ),

            _itemMenu(
              context,
              icone: Icons.cloud_sync_rounded,
              titulo: 'Backup e restauração',
              aoClicar: () async {
                Navigator.pop(context);

                await _abrirTela(BackupScreen(professor: widget.professor));
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Média mínima para aprovação: '
                    '${formatarNotaTexto(widget.professor.mediaMinima)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  if (quantidadeArquivadas > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$quantidadeArquivadas turma(s) arquivada(s)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required VoidCallback aoClicar,
    bool selecionado = false,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selected: selecionado,
        selectedTileColor: scheme.primary.withValues(alpha: 0.10),
        leading: Icon(
          icone,
          color: selecionado ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: selecionado ? FontWeight.w700 : FontWeight.w600,
            color: selecionado ? scheme.primary : scheme.onSurface,
          ),
        ),
        onTap: aoClicar,
      ),
    );
  }
}

// Cabeçalho com gradiente e pequenos círculos decorativos.
class _Cabecalho extends StatelessWidget {
  final String nome;

  const _Cabecalho({required this.nome});

  @override
  Widget build(BuildContext context) {
    // Usa apenas o primeiro nome para evitar textos muito longos.
    final primeiroNome = nome.trim().split(RegExp(r'\s+')).first;

    return AppCard(
      gradient: AppTheme.brandGradient,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(right: -26, top: -34, child: _circulo(132, 0.12)),
          Positioned(right: 74, bottom: -52, child: _circulo(104, 0.08)),
          // O SizedBox garante que o gradiente ocupe toda a largura do cartão.
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PAINEL DO PROFESSOR',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Olá, $primeiroNome!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Organize suas turmas, notas e relatórios em um só lugar.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circulo(double tamanho, double opacidade) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacidade),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Blocos de resumo lado a lado.
class _BentoResumo extends StatelessWidget {
  final int quantidadeTurmas;
  final int quantidadeAlunos;

  const _BentoResumo({
    required this.quantidadeTurmas,
    required this.quantidadeAlunos,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double espaco = 12;
        final int colunas = constraints.maxWidth < 360 ? 1 : 2;

        final double largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            SizedBox(
              width: largura,
              height: 136,
              child: _BlocoResumo(
                destaque: true,
                titulo: 'Turmas ativas',
                valor: quantidadeTurmas,
                icone: Icons.groups_rounded,
              ),
            ),
            SizedBox(
              width: largura,
              height: 136,
              child: _BlocoResumo(
                titulo: 'Alunos',
                valor: quantidadeAlunos,
                icone: Icons.people_alt_rounded,
                cor: AppTheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlocoResumo extends StatelessWidget {
  final String titulo;
  final int valor;
  final IconData icone;
  final Color? cor;
  final bool destaque;

  const _BlocoResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
    this.cor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final Color destaqueCor = cor ?? AppTheme.primary;

    return AppCard(
      gradient: destaque ? AppTheme.brandGradient : null,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: destaque
                  ? Colors.white.withValues(alpha: 0.18)
                  : destaqueCor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icone,
              size: 20,
              color: destaque ? Colors.white : destaqueCor,
            ),
          ),
          const Spacer(),
          AnimatedNumber(
            value: valor,
            formatter: (numero) => numero.round().toString(),
            style: tema.textTheme.headlineSmall?.copyWith(
              fontSize: 27,
              color: destaque ? Colors.white : tema.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: destaque
                  ? Colors.white.withValues(alpha: 0.85)
                  : tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão de acesso rápido.
class _AtalhoCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final VoidCallback aoClicar;

  const _AtalhoCard({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: aoClicar,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(icon: icone, color: cor, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
