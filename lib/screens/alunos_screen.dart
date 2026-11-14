import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../services/calculo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_widgets.dart';
import '../widgets/fade_slide_in.dart';
import 'boletim_screen.dart';
import 'frequencia_screen.dart';

enum _OrdenacaoAlunos { nomeAz, nomeZa, matricula, media }

enum _AcaoAluno { boletim, editar, excluir }

class AlunosScreen extends StatefulWidget {
  final Turma turma;
  final Professor professor;

  const AlunosScreen({super.key, required this.turma, required this.professor});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  late Turma _turma = widget.turma;
  final TextEditingController _buscaController = TextEditingController();

  _OrdenacaoAlunos _ordenacao = _OrdenacaoAlunos.nomeAz;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Após uma restauração, o objeto antigo sai da lista do professor.
  // Reencontra a turma pelos dados para continuar exibindo a versão atual.
  void _sincronizarTurma() {
    final int porIdentidade = widget.professor.turmas.indexWhere(
      (turma) => identical(turma, _turma),
    );

    if (porIdentidade >= 0) {
      _turma = widget.professor.turmas[porIdentidade];
      return;
    }

    final int porDados = widget.professor.turmas.indexWhere(
      (turma) =>
          turma.nome == _turma.nome &&
          turma.curso == _turma.curso &&
          turma.periodo == _turma.periodo,
    );

    if (porDados >= 0) {
      _turma = widget.professor.turmas[porDados];
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<Aluno?> _abrirFormularioAluno({int? indice}) async {
    final formKey = GlobalKey<FormState>();

    final Aluno? atual = indice == null ? null : _turma.alunos[indice];

    final TextEditingController nomeController = TextEditingController(
      text: atual?.nome ?? '',
    );
    final TextEditingController matriculaController = TextEditingController(
      text: atual?.matricula ?? '',
    );
    final TextEditingController observacaoController = TextEditingController(
      text: atual?.observacao ?? '',
    );

    final Aluno? resultado = await showDialog<Aluno>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          title: Row(
            children: [
              IconBadge(
                icon: indice == null
                    ? Icons.person_add_rounded
                    : Icons.edit_rounded,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  indice == null ? 'Cadastrar aluno' : 'Editar aluno',
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
                      labelText: 'Nome completo',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do aluno.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: matriculaController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Matrícula'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a matrícula.';
                      }

                      final existe = _turma.alunos.asMap().entries.any(
                        (item) =>
                            item.key != indice &&
                            item.value.matricula.toLowerCase() ==
                                value.trim().toLowerCase(),
                      );

                      if (existe) {
                        return 'Essa matrícula já está cadastrada.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: observacaoController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Anotações sobre o desempenho do aluno...',
                      alignLabelWithHint: true,
                    ),
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

                Navigator.pop(
                  dialogContext,
                  Aluno(
                    nome: nomeController.text.trim(),
                    matricula: matriculaController.text.trim(),
                    observacao: observacaoController.text.trim(),
                  ),
                );
              },
              child: Text(indice == null ? 'Cadastrar' : 'Salvar'),
            ),
          ],
        );
      },
    );

    // Descarta somente depois da animação de saída do diálogo.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      nomeController.dispose();
      matriculaController.dispose();
      observacaoController.dispose();
    });

    return resultado;
  }

  Future<void> _cadastrarAluno() async {
    final Aluno? aluno = await _abrirFormularioAluno();

    if (!mounted || aluno == null) return;

    _sincronizarTurma();

    try {
      _turma.adicionarAluno(aluno);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});
      _mostrarMensagem('${aluno.nome} cadastrado com sucesso!');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem(erro.toString().replaceFirst('ArgumentError: ', ''));
    }
  }

  Future<void> _editarAluno(int indice) async {
    final Aluno? aluno = await _abrirFormularioAluno(indice: indice);

    if (!mounted || aluno == null) return;

    _sincronizarTurma();

    if (indice >= _turma.alunos.length) return;

    try {
      _turma.editarAluno(
        indice,
        nome: aluno.nome,
        matricula: aluno.matricula,
        observacao: aluno.observacao,
      );

      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});
      _mostrarMensagem('Dados do aluno atualizados!');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem(erro.toString().replaceFirst('ArgumentError: ', ''));
    }
  }

  Future<void> _excluirAluno(int indice) async {
    if (indice < 0 || indice >= _turma.alunos.length) return;

    final Aluno aluno = _turma.alunos[indice];

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir aluno?'),
          content: Text(
            '${aluno.nome} e todas as suas notas, recuperações e presenças '
            'serão removidos. Essa ação pode ser desfeita na próxima mensagem.',
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

    _sincronizarTurma();

    if (indice >= _turma.alunos.length) return;

    final String backup = ArmazenamentoService.exportarJson(widget.professor);

    _turma.removerAlunoNoIndice(indice);
    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${aluno.nome} foi excluído.'),
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

              if (!mounted) return;

              _sincronizarTurma();
              setState(() {});
            },
          ),
        ),
      );
  }

  Future<void> _abrirBoletim(int indice) async {
    _sincronizarTurma();

    if (indice < 0 || indice >= _turma.alunos.length) return;

    await Navigator.push<void>(
      context,
      AppPageRoute.fadeSlide(
        BoletimScreen(
          professor: widget.professor,
          turma: _turma,
          indiceAluno: indice,
        ),
      ),
    );

    if (!mounted) return;

    _sincronizarTurma();
    setState(() {});
  }

  Future<void> _abrirFrequencia() async {
    _sincronizarTurma();

    await Navigator.push<void>(
      context,
      AppPageRoute.fadeSlide(
        FrequenciaScreen(professor: widget.professor, turma: _turma),
      ),
    );

    if (!mounted) return;

    _sincronizarTurma();
    setState(() {});
  }

  List<int> _indicesVisiveis() {
    final String termo = _buscaController.text.trim().toLowerCase();

    final List<int> indices = [];

    for (int i = 0; i < _turma.alunos.length; i++) {
      final Aluno aluno = _turma.alunos[i];

      final bool combina =
          termo.isEmpty ||
          aluno.nome.toLowerCase().contains(termo) ||
          aluno.matricula.toLowerCase().contains(termo);

      if (combina) indices.add(i);
    }

    final Bimestre? ultimo = _turma.bimestres.isEmpty
        ? null
        : _turma.bimestres.last;

    indices.sort((a, b) {
      final Aluno alunoA = _turma.alunos[a];
      final Aluno alunoB = _turma.alunos[b];

      switch (_ordenacao) {
        case _OrdenacaoAlunos.nomeAz:
          return alunoA.nome.toLowerCase().compareTo(alunoB.nome.toLowerCase());
        case _OrdenacaoAlunos.nomeZa:
          return alunoB.nome.toLowerCase().compareTo(alunoA.nome.toLowerCase());
        case _OrdenacaoAlunos.matricula:
          return alunoA.matricula.toLowerCase().compareTo(
            alunoB.matricula.toLowerCase(),
          );
        case _OrdenacaoAlunos.media:
          final double? mediaA = ultimo == null
              ? null
              : CalculoService.calcularMedia(
                  ultimo,
                  a,
                  mediaMinima: widget.professor.mediaMinima,
                );
          final double? mediaB = ultimo == null
              ? null
              : CalculoService.calcularMedia(
                  ultimo,
                  b,
                  mediaMinima: widget.professor.mediaMinima,
                );

          if (mediaA == null && mediaB == null) {
            return alunoA.nome.toLowerCase().compareTo(
              alunoB.nome.toLowerCase(),
            );
          }

          if (mediaA == null) return 1;
          if (mediaB == null) return -1;

          return mediaB.compareTo(mediaA);
      }
    });

    return indices;
  }

  @override
  Widget build(BuildContext context) {
    _sincronizarTurma();

    final List<int> indices = _indicesVisiveis();
    final bool temAlunos = _turma.alunos.isNotEmpty;
    final Bimestre? ultimo = _turma.bimestres.isEmpty
        ? null
        : _turma.bimestres.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(_turma.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Frequência',
            onPressed: temAlunos ? _abrirFrequencia : null,
            icon: const Icon(Icons.fact_check_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Hero(
              tag: turmaHeroTag(_turma),
              child: AppCard(
                gradient: AppTheme.brandGradient,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _turma.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _turma.curso,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _EtiquetaClara(
                                icone: Icons.calendar_today_rounded,
                                texto: '${_turma.periodo}º período',
                              ),
                              _EtiquetaClara(
                                icone: Icons.people_alt_rounded,
                                texto: '${_turma.alunos.length} alunos',
                              ),
                              if (_turma.arquivada)
                                const _EtiquetaClara(
                                  icone: Icons.archive_rounded,
                                  texto: 'Arquivada',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (temAlunos) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Widget busca = TextField(
                    controller: _buscaController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou matrícula',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _buscaController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _buscaController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                    ),
                  );

                  final Widget ordenar = InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ordenar',
                      prefixIcon: Icon(Icons.sort_rounded, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_OrdenacaoAlunos>(
                        value: _ordenacao,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: const [
                          DropdownMenuItem(
                            value: _OrdenacaoAlunos.nomeAz,
                            child: Text('Nome (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: _OrdenacaoAlunos.nomeZa,
                            child: Text('Nome (Z-A)'),
                          ),
                          DropdownMenuItem(
                            value: _OrdenacaoAlunos.matricula,
                            child: Text('Matrícula'),
                          ),
                          DropdownMenuItem(
                            value: _OrdenacaoAlunos.media,
                            child: Text('Média (maior)'),
                          ),
                        ],
                        onChanged: (valor) {
                          if (valor == null) return;
                          setState(() => _ordenacao = valor);
                        },
                      ),
                    ),
                  );

                  if (constraints.maxWidth < 470) {
                    return Column(
                      children: [busca, const SizedBox(height: 8), ordenar],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: busca),
                      const SizedBox(width: 8),
                      SizedBox(width: 176, child: ordenar),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              titulo: _buscaController.text.trim().isEmpty
                  ? 'Alunos cadastrados'
                  : '${indices.length} resultado(s)',
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: !temAlunos
                ? EmptyState(
                    icon: Icons.people_alt_rounded,
                    titulo: 'Nenhum aluno cadastrado.',
                    mensagem:
                        'Adicione os estudantes desta turma para começar '
                        'a lançar notas.',
                    acao: GradientButton(
                      label: 'Cadastrar aluno',
                      icon: Icons.person_add_rounded,
                      expandido: false,
                      onPressed: _cadastrarAluno,
                    ),
                  )
                : indices.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    titulo: 'Nenhum aluno encontrado.',
                    mensagem:
                        'Tente outro nome ou matrícula, ou limpe a busca.',
                    acao: OutlinedButton.icon(
                      onPressed: () {
                        _buscaController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Limpar busca'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    itemCount: indices.length,
                    itemBuilder: (context, posicao) {
                      final int indice = indices[posicao];
                      final Aluno aluno = _turma.alunos[indice];

                      final double? media = ultimo == null
                          ? null
                          : CalculoService.calcularMedia(
                              ultimo,
                              indice,
                              mediaMinima: widget.professor.mediaMinima,
                            );

                      final double? frequencia = _turma.percentualPresenca(
                        indice,
                      );

                      return FadeSlideIn(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CartaoAluno(
                            aluno: aluno,
                            indice: indice,
                            media: media,
                            frequencia: frequencia,
                            aoAbrir: () => _abrirBoletim(indice),
                            aoEditar: () => _editarAluno(indice),
                            aoExcluir: () => _excluirAluno(indice),
                            aoBoletim: () => _abrirBoletim(indice),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        onPressed: _cadastrarAluno,
        icon: Icons.person_add_rounded,
        label: 'Novo aluno',
      ),
    );
  }
}

class _CartaoAluno extends StatelessWidget {
  final Aluno aluno;
  final int indice;
  final double? media;
  final double? frequencia;
  final VoidCallback aoAbrir;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;
  final VoidCallback aoBoletim;

  const _CartaoAluno({
    required this.aluno,
    required this.indice,
    required this.media,
    required this.frequencia,
    required this.aoAbrir,
    required this.aoEditar,
    required this.aoExcluir,
    required this.aoBoletim,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final bool escuro = tema.brightness == Brightness.dark;

    final Color fundo = indice.isEven
        ? tema.colorScheme.surface
        : tema.colorScheme.surfaceContainerHighest.withValues(
            alpha: escuro ? 0.35 : 0.45,
          );

    return AppCard(
      color: fundo,
      onTap: aoAbrir,
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tema.colorScheme.primary, tema.colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                inicialDoNome(aluno.nome),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  aluno.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Matrícula: ${aluno.matricula}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                ),
                if (aluno.observacao.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_rounded,
                        size: 13,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          aluno.observacao.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (media != null || frequencia != null) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (media != null)
                        _MiniEtiqueta(
                          icone: Icons.calculate_rounded,
                          texto: 'Média: ${formatarNotaTexto(media)}',
                          cor: tema.colorScheme.primary,
                        ),
                      if (frequencia != null)
                        _MiniEtiqueta(
                          icone: Icons.fact_check_rounded,
                          texto: formatarPercentualTexto(frequencia),
                          cor: frequencia! < 75
                              ? AppTheme.warning
                              : AppTheme.success,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_AcaoAluno>(
            tooltip: 'Opções do aluno',
            icon: Icon(
              Icons.more_vert_rounded,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            onSelected: (acao) {
              switch (acao) {
                case _AcaoAluno.boletim:
                  aoBoletim();
                  break;
                case _AcaoAluno.editar:
                  aoEditar();
                  break;
                case _AcaoAluno.excluir:
                  aoExcluir();
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _AcaoAluno.boletim,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.assignment_ind_rounded),
                    title: Text('Boletim'),
                  ),
                ),
                PopupMenuItem(
                  value: _AcaoAluno.editar,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: _AcaoAluno.excluir,
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

class _MiniEtiqueta extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color cor;

  const _MiniEtiqueta({
    required this.icone,
    required this.texto,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 11, color: cor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EtiquetaClara extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _EtiquetaClara({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
