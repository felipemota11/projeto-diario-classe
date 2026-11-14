import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_widgets.dart';
import '../widgets/fade_slide_in.dart';
import 'alunos_screen.dart';

enum _FiltroTurmas { ativas, arquivadas }

enum _AcaoTurma { editar, arquivar, excluir }

class TurmasScreen extends StatefulWidget {
  final Professor professor;

  const TurmasScreen({super.key, required this.professor});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  _FiltroTurmas _filtro = _FiltroTurmas.ativas;

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Abre o formulário de turma. Retorna null quando o usuário cancela.
  Future<Turma?> _abrirFormulario({Turma? turma}) async {
    final formKey = GlobalKey<FormState>();

    final TextEditingController nomeController = TextEditingController(
      text: turma?.nome ?? '',
    );
    final TextEditingController cursoController = TextEditingController(
      text: turma?.curso ?? '',
    );
    final TextEditingController periodoController = TextEditingController(
      text: turma?.periodo.toString() ?? '',
    );

    final Turma? resultado = await showDialog<Turma>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          title: Row(
            children: [
              IconBadge(
                icon: turma == null ? Icons.school_rounded : Icons.edit_rounded,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  turma == null ? 'Cadastrar turma' : 'Editar turma',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome da turma',
                      hintText: 'Ex.: Turma A',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da turma.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cursoController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Curso',
                      hintText: 'Ex.: Ciência da Computação',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o curso.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: periodoController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Período',
                      hintText: 'Ex.: 1',
                    ),
                    validator: (value) {
                      final numero = int.tryParse(value?.trim() ?? '');

                      if (numero == null || numero < 1) {
                        return 'Informe um período válido.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final nome = nomeController.text.trim();
                final curso = cursoController.text.trim();
                final periodo = int.parse(periodoController.text.trim());

                final bool duplicada = widget.professor.turmas.any(
                  (item) =>
                      item != turma &&
                      item.nome.toLowerCase() == nome.toLowerCase() &&
                      item.curso.toLowerCase() == curso.toLowerCase() &&
                      item.periodo == periodo,
                );

                if (duplicada) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Essa turma já está cadastrada.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  Turma(
                    nome: nome,
                    curso: curso,
                    periodo: periodo,
                    arquivada: turma?.arquivada ?? false,
                  ),
                );
              },
              child: Text(turma == null ? 'Cadastrar' : 'Salvar'),
            ),
          ],
        );
      },
    );

    // Descarta somente depois da animação de saída do diálogo.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      nomeController.dispose();
      cursoController.dispose();
      periodoController.dispose();
    });

    return resultado;
  }

  Future<void> _cadastrarTurma() async {
    final Turma? turma = await _abrirFormulario();

    if (!mounted || turma == null) return;

    try {
      widget.professor.adicionarTurma(turma);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {
        _filtro = _FiltroTurmas.ativas;
      });

      _mostrarMensagem('Turma cadastrada com sucesso!');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem(erro.toString().replaceFirst('ArgumentError: ', ''));
    }
  }

  Future<void> _editarTurma(Turma turma) async {
    final Turma? dados = await _abrirFormulario(turma: turma);

    if (!mounted || dados == null) return;

    turma.editar(nome: dados.nome, curso: dados.curso, periodo: dados.periodo);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});
    _mostrarMensagem('Turma atualizada com sucesso!');
  }

  Future<void> _alternarArquivamento(Turma turma) async {
    turma.arquivada = !turma.arquivada;

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            turma.arquivada
                ? '${turma.nome} foi arquivada.'
                : '${turma.nome} voltou para as turmas ativas.',
          ),
          // Sem isso, o aviso com ação fica preso na tela para sempre.
          persist: false,
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              turma.arquivada = !turma.arquivada;
              await ArmazenamentoService.salvarProfessor(widget.professor);
              if (mounted) setState(() {});
            },
          ),
        ),
      );
  }

  Future<void> _excluirTurma(Turma turma) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir turma?'),
          content: Text(
            'A turma "${turma.nome}" e todos os seus alunos, notas e '
            'frequências serão removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final String backup = ArmazenamentoService.exportarJson(widget.professor);

    widget.professor.turmas.remove(turma);
    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${turma.nome} foi excluída.'),
          // Sem isso, o aviso com ação fica preso na tela para sempre.
          persist: false,
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              final Professor restaurado = ArmazenamentoService.importarJson(
                backup,
              );

              widget.professor.substituirPor(restaurado);
              await ArmazenamentoService.salvarProfessor(widget.professor);

              if (mounted) setState(() {});
            },
          ),
        ),
      );
  }

  Future<void> _abrirTurma(Turma turma) async {
    await Navigator.push<void>(
      context,
      AppPageRoute.fadeSlide(
        AlunosScreen(turma: turma, professor: widget.professor),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Turma> ativas = widget.professor.turmas
        .where((turma) => !turma.arquivada)
        .toList();

    final List<Turma> arquivadas = widget.professor.turmas
        .where((turma) => turma.arquivada)
        .toList();

    final List<Turma> visiveis = _filtro == _FiltroTurmas.ativas
        ? ativas
        : arquivadas;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas turmas')),
      body: widget.professor.turmas.isEmpty
          ? EmptyState(
              icon: Icons.school_rounded,
              titulo: 'Nenhuma turma cadastrada.',
              mensagem:
                  'Crie sua primeira turma para começar a organizar '
                  'alunos e avaliações.',
              acao: GradientButton(
                label: 'Cadastrar primeira turma',
                icon: Icons.add_rounded,
                expandido: false,
                onPressed: _cadastrarTurma,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FiltroChip(
                          label: 'Ativas',
                          quantidade: ativas.length,
                          selecionado: _filtro == _FiltroTurmas.ativas,
                          onTap: () =>
                              setState(() => _filtro = _FiltroTurmas.ativas),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FiltroChip(
                          label: 'Arquivadas',
                          quantidade: arquivadas.length,
                          selecionado: _filtro == _FiltroTurmas.arquivadas,
                          onTap: () => setState(
                            () => _filtro = _FiltroTurmas.arquivadas,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visiveis.isEmpty
                      ? EmptyState(
                          icon: _filtro == _FiltroTurmas.ativas
                              ? Icons.school_rounded
                              : Icons.archive_rounded,
                          titulo: _filtro == _FiltroTurmas.ativas
                              ? 'Nenhuma turma ativa.'
                              : 'Nenhuma turma arquivada.',
                          mensagem: _filtro == _FiltroTurmas.ativas
                              ? 'Cadastre uma turma ou desarquive uma turma '
                                    'antiga.'
                              : 'Turmas arquivadas ficam guardadas aqui e '
                                    'podem ser restauradas a qualquer momento.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          itemCount: visiveis.length,
                          itemBuilder: (context, index) {
                            final Turma turma = visiveis[index];

                            return FadeSlideIn(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Hero(
                                  tag: turmaHeroTag(turma),
                                  flightShuttleBuilder: (_, _, _, _, _) {
                                    return Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.brandGradient,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radius,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.school_rounded,
                                            color: Colors.white,
                                            size: 38,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            turma.nome,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: _CartaoTurma(
                                    turma: turma,
                                    aoClicar: () => _abrirTurma(turma),
                                    aoEditar: () => _editarTurma(turma),
                                    aoArquivar: () =>
                                        _alternarArquivamento(turma),
                                    aoExcluir: () => _excluirTurma(turma),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: AppFab(
        onPressed: _cadastrarTurma,
        icon: Icons.add_rounded,
        label: 'Nova turma',
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final int quantidade;
  final bool selecionado;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.quantidade,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: selecionado
          ? scheme.primary.withValues(alpha: 0.12)
          : scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selecionado ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selecionado
                      ? scheme.primary.withValues(alpha: 0.16)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  quantidade.toString(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selecionado
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoTurma extends StatelessWidget {
  final Turma turma;
  final VoidCallback aoClicar;
  final VoidCallback aoEditar;
  final VoidCallback aoArquivar;
  final VoidCallback aoExcluir;

  const _CartaoTurma({
    required this.turma,
    required this.aoClicar,
    required this.aoEditar,
    required this.aoArquivar,
    required this.aoExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return AppCard(
      onTap: aoClicar,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          const IconBadge(icon: Icons.school_rounded, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  turma.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  turma.curso,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Etiqueta(
                      icone: Icons.calendar_today_rounded,
                      texto: '${turma.periodo}º período',
                    ),
                    _Etiqueta(
                      icone: Icons.people_alt_rounded,
                      texto: '${turma.alunos.length} alunos',
                    ),
                    if (turma.arquivada)
                      const _Etiqueta(
                        icone: Icons.archive_rounded,
                        texto: 'Arquivada',
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_AcaoTurma>(
            tooltip: 'Opções da turma',
            icon: Icon(
              Icons.more_vert_rounded,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            onSelected: (acao) {
              switch (acao) {
                case _AcaoTurma.editar:
                  aoEditar();
                  break;
                case _AcaoTurma.arquivar:
                  aoArquivar();
                  break;
                case _AcaoTurma.excluir:
                  aoExcluir();
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: _AcaoTurma.editar,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: _AcaoTurma.arquivar,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      turma.arquivada
                          ? Icons.unarchive_rounded
                          : Icons.archive_rounded,
                    ),
                    title: Text(turma.arquivada ? 'Desarquivar' : 'Arquivar'),
                  ),
                ),
                const PopupMenuItem(
                  value: _AcaoTurma.excluir,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.danger,
                    ),
                    title: Text(
                      'Excluir',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Etiqueta({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
