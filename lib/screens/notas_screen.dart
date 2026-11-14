import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../services/calculo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_number.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_widgets.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/status_chip.dart';
import 'avaliacoes_screen.dart';
import 'lancamento_lote_screen.dart';

class NotasScreen extends StatefulWidget {
  final Professor professor;

  const NotasScreen({super.key, required this.professor});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  int? _turmaSelecionadaIndex;
  int? _bimestreSelecionadoNumero;
  int? _alunoSelecionadoIndex;

  // Quando ativo, o seletor mostra apenas alunos com algo pendente.
  bool _somentePendentes = false;

  // Exibe mensagens para o usuário.
  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Seletor reutilizável para turma, bimestre e aluno.
  Widget _seletor<T>({
    required String titulo,
    required IconData icone,
    required T valor,
    required List<DropdownMenuItem<T>> itens,
    required ValueChanged<T?> onChanged,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: titulo,
        prefixIcon: Icon(icone, size: 20, color: scheme.primary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: scheme.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: itens,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Formata notas utilizando vírgula.
  String _formatarNota(double nota) {
    return nota.toStringAsFixed(2).replaceAll('.', ',');
  }

  // Verifica se o aluno tem nota de avaliação ou recuperação pendente.
  bool _alunoTemPendencia(Bimestre bimestre, int indiceAluno) {
    return CalculoService.pendenciasDoAluno(
      bimestre,
      indiceAluno,
      mediaMinima: widget.professor.mediaMinima,
    ).isNotEmpty;
  }

  // Índices de todos os alunos com pendências no bimestre.
  List<int> _indicesPendentes(Turma turma, Bimestre bimestre) {
    return [
      for (int i = 0; i < turma.alunos.length; i++)
        if (_alunoTemPendencia(bimestre, i)) i,
    ];
  }

  // Índices exibidos no seletor de aluno, respeitando o filtro.
  List<int> _indicesAlunosVisiveis(Turma turma, Bimestre bimestre) {
    if (_somentePendentes) {
      return _indicesPendentes(turma, bimestre);
    }

    return List<int>.generate(turma.alunos.length, (indice) => indice);
  }

  // Cadastra um novo bimestre.
  Future<void> _adicionarBimestre(Turma turma) async {
    final formKey = GlobalKey<FormState>();

    String numeroTexto = '';

    final numero = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          title: Row(
            children: [
              const IconBadge(icon: Icons.calendar_month_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cadastrar bimestre',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),

          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              keyboardType: TextInputType.number,
              autofocus: true,

              decoration: const InputDecoration(
                labelText: 'Número do bimestre',
                hintText: 'Ex.: 1',
              ),

              onSaved: (value) {
                numeroTexto = value!.trim();
              },

              validator: (value) {
                final numero = int.tryParse(value?.trim() ?? '');

                if (numero == null || numero < 1) {
                  return 'Informe um número válido.';
                }

                final existe = turma.bimestres.any((b) => b.numero == numero);

                if (existe) {
                  return 'Esse bimestre já está cadastrado.';
                }

                return null;
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                formKey.currentState!.save();

                Navigator.pop(dialogContext, int.parse(numeroTexto));
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    if (!mounted || numero == null) return;

    turma.adicionarBimestre(numero);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {
      _bimestreSelecionadoNumero = numero;
      _alunoSelecionadoIndex = null;
      _somentePendentes = false;
    });

    _mostrarMensagem(
      'Bimestre cadastrado! Use "Avaliações" para renomear ou adicionar '
      'provas, trabalhos e testes.',
    );
  }

  // Solicita uma nota ao professor.
  Future<double?> _solicitarNota({
    required String titulo,
    double? notaAtual,
  }) async {
    final formKey = GlobalKey<FormState>();

    double? notaInformada;

    return await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          title: Row(
            children: [
              const IconBadge(icon: Icons.edit_note_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),

          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              initialValue: notaAtual?.toString() ?? '',

              autofocus: true,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Ex.: 8,5',
                helperText: 'Informe uma nota entre 0 e 10.',
                prefixIcon: Icon(Icons.pin_rounded),
              ),

              onSaved: (value) {
                notaInformada = double.parse(
                  value!.trim().replaceAll(',', '.'),
                );
              },

              validator: (value) {
                final texto = value?.trim().replaceAll(',', '.');

                final nota = double.tryParse(texto ?? '');

                if (nota == null || !nota.isFinite) {
                  return 'Informe um número válido.';
                }

                if (nota < 0 || nota > 10) {
                  return 'A nota deve estar entre 0 e 10.';
                }

                return null;
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                formKey.currentState!.save();

                Navigator.pop(dialogContext, notaInformada);
              },
              child: const Text('Salvar nota'),
            ),
          ],
        );
      },
    );
  }

  // Lança ou altera uma avaliação.
  Future<void> _editarAvaliacao({
    required Bimestre bimestre,
    required int indiceAluno,
    required int avaliacao,
  }) async {
    final coluna = avaliacao - 1;

    final nome = bimestre.avaliacoes[coluna];

    final jaLancada = bimestre.notasLancadas[indiceAluno][coluna];

    final notaAtual = jaLancada ? bimestre.notas[indiceAluno][coluna] : null;

    final nota = await _solicitarNota(
      titulo: jaLancada ? 'Alterar $nome' : 'Lançar $nome',
      notaAtual: notaAtual,
    );

    if (!mounted || nota == null) return;

    bimestre.registrarNota(
      indiceAluno: indiceAluno,
      avaliacao: avaliacao,
      nota: nota,
    );

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Nota de $nome salva com sucesso!');
  }

  // Lança ou altera a recuperação.
  Future<void> _editarRecuperacao({
    required Bimestre bimestre,
    required int indiceAluno,
  }) async {
    final podeRecuperar = CalculoService.podeFazerRecuperacao(
      bimestre,
      indiceAluno,
      mediaMinima: widget.professor.mediaMinima,
    );

    final recuperacaoAtual = bimestre.recuperacoes[indiceAluno];

    if (!podeRecuperar && recuperacaoAtual == null) {
      _mostrarMensagem('A recuperação não é necessária para este aluno.');
      return;
    }

    final nota = await _solicitarNota(
      titulo: recuperacaoAtual == null
          ? 'Lançar recuperação'
          : 'Alterar recuperação',
      notaAtual: recuperacaoAtual,
    );

    if (!mounted || nota == null) return;

    bimestre.registrarRecuperacao(indiceAluno: indiceAluno, nota: nota);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Recuperação salva com sucesso!');
  }

  // Remove uma recuperação.
  Future<void> _removerRecuperacao({
    required Bimestre bimestre,
    required int indiceAluno,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover recuperação?'),

          content: const Text(
            'A nota de recuperação será removida. '
            'A média voltará a considerar somente as avaliações regulares.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    bimestre.recuperacoes[indiceAluno] = null;

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Recuperação removida.');
  }

  // Abre a tela de lançamento em lote.
  Future<void> _abrirLancamentoLote(Turma turma, Bimestre bimestre) async {
    final bool? salvou = await Navigator.push<bool>(
      context,
      AppPageRoute.fadeSlide(
        LancamentoLoteScreen(
          professor: widget.professor,
          turma: turma,
          bimestre: bimestre,
        ),
      ),
    );

    if (!mounted) return;

    if (salvou == true) {
      setState(() {});
      _mostrarMensagem('Notas do bimestre salvas com sucesso!');
    }
  }

  // Abre a tela para adicionar, renomear ou remover avaliações.
  Future<void> _abrirAvaliacoes(Turma turma, Bimestre bimestre) async {
    await Navigator.push<void>(
      context,
      AppPageRoute.fadeSlide(
        AvaliacoesScreen(
          professor: widget.professor,
          turma: turma,
          bimestre: bimestre,
        ),
      ),
    );

    if (!mounted) return;

    // As alterações são salvas na própria tela de avaliações. Atualiza a
    // seleção atual para refletir nomes e quantidades novas.
    setState(() {
      if (_alunoSelecionadoIndex != null &&
          _alunoSelecionadoIndex! >= turma.alunos.length) {
        _alunoSelecionadoIndex = null;
      }
    });
  }

  // Exclui o bimestre selecionado, com opção de desfazer.
  Future<void> _excluirBimestre(Turma turma, Bimestre bimestre) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir bimestre?'),
          content: Text(
            'Todas as notas do ${bimestre.numero}º bimestre desta turma '
            'serão removidas.',
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

    turma.removerBimestre(bimestre.numero);
    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {
      _bimestreSelecionadoNumero = null;
      _alunoSelecionadoIndex = null;
      _somentePendentes = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${bimestre.numero}º bimestre excluído.'),
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

              setState(() {});
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas
        .where((turma) => !turma.arquivada)
        .toList();

    // Verifica se existem turmas ativas cadastradas.
    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lançamento de notas')),

        body: const EmptyState(
          icon: Icons.school_rounded,
          titulo: 'Nenhuma turma ativa.',
          mensagem:
              'Cadastre uma turma ou desarquive uma turma antiga antes de '
              'lançar notas.',
        ),
      );
    }

    // Mantém um índice válido para a turma selecionada.
    final indiceTurma =
        _turmaSelecionadaIndex != null &&
            _turmaSelecionadaIndex! >= 0 &&
            _turmaSelecionadaIndex! < turmas.length
        ? _turmaSelecionadaIndex!
        : 0;

    final turma = turmas[indiceTurma];

    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento de notas')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(child: const SectionHeader(titulo: 'Selecionar turma')),

            const SizedBox(height: 8),

            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _seletor<int>(
                titulo: 'Turma',
                icone: Icons.school_rounded,
                valor: indiceTurma,

                itens: List.generate(turmas.length, (index) {
                  final item = turmas[index];

                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      '${item.nome} - ${item.curso}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),

                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    _turmaSelecionadaIndex = valor;
                    _bimestreSelecionadoNumero = null;
                    _alunoSelecionadoIndex = null;
                    _somentePendentes = false;
                  });
                },
              ),
            ),

            const SizedBox(height: 22),

            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  const Expanded(child: SectionHeader(titulo: 'Bimestre')),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _adicionarBimestre(turma),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Novo'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (turma.bimestres.isEmpty)
              const AppCard(
                padding: EdgeInsets.zero,
                child: EmptyState(
                  icon: Icons.calendar_month_rounded,
                  titulo: 'Nenhum bimestre cadastrado.',
                  mensagem:
                      'Utilize o botão "Novo" acima para criar o primeiro '
                      'bimestre.',
                ),
              )
            else
              _construirConteudoBimestre(turma, indiceTurma),
          ],
        ),
      ),
    );
  }

  // Constrói a seleção de bimestre e aluno.
  Widget _construirConteudoBimestre(Turma turma, int indiceTurma) {
    final bimestres = turma.bimestres;

    // Localiza o bimestre selecionado.
    final selecionados = bimestres.where(
      (b) => b.numero == _bimestreSelecionadoNumero,
    );

    final Bimestre bimestre = selecionados.isNotEmpty
        ? selecionados.first
        : bimestres.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seletor<int>(
          titulo: 'Escolha o bimestre',
          icone: Icons.calendar_month_rounded,
          valor: bimestre.numero,

          itens: bimestres.map((item) {
            return DropdownMenuItem<int>(
              value: item.numero,
              child: Text('${item.numero}º Bimestre'),
            );
          }).toList(),

          onChanged: (numero) {
            if (numero == null) return;

            setState(() {
              _bimestreSelecionadoNumero = numero;
              _alunoSelecionadoIndex = null;
              _somentePendentes = false;
            });
          },
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _abrirAvaliacoes(turma, bimestre),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Avaliações'),
            ),
            OutlinedButton.icon(
              onPressed: turma.alunos.isEmpty
                  ? null
                  : () => _abrirLancamentoLote(turma, bimestre),
              icon: const Icon(Icons.grid_on_rounded, size: 18),
              label: const Text('Lançamento em lote'),
            ),
            OutlinedButton.icon(
              onPressed: () => _excluirBimestre(turma, bimestre),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: BorderSide(
                  color: AppTheme.danger.withValues(alpha: 0.35),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Excluir bimestre'),
            ),
          ],
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            const Expanded(child: SectionHeader(titulo: 'Selecionar aluno')),
            if (turma.alunos.isNotEmpty) ...[
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  'Pendentes (${_indicesPendentes(turma, bimestre).length})',
                ),
                selected: _somentePendentes,
                visualDensity: VisualDensity.compact,
                onSelected: (selecionado) {
                  final pendentes = _indicesPendentes(turma, bimestre);

                  setState(() {
                    _somentePendentes = selecionado;

                    if (selecionado) {
                      _alunoSelecionadoIndex = pendentes.isNotEmpty
                          ? pendentes.first
                          : null;
                    } else if (_alunoSelecionadoIndex == null ||
                        _alunoSelecionadoIndex! < 0 ||
                        _alunoSelecionadoIndex! >= turma.alunos.length) {
                      _alunoSelecionadoIndex = 0;
                    }
                  });
                },
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        if (turma.alunos.isEmpty)
          const AppCard(
            padding: EdgeInsets.zero,
            child: EmptyState(
              icon: Icons.people_alt_rounded,
              titulo: 'Esta turma ainda não possui alunos.',
              mensagem: 'Cadastre estudantes na tela de turmas.',
            ),
          )
        else
          _construirNotasDoAluno(turma, bimestre),
      ],
    );
  }

  // Exibe as avaliações e a situação acadêmica.
  Widget _construirNotasDoAluno(Turma turma, Bimestre bimestre) {
    final alunos = turma.alunos;
    final indicesVisiveis = _indicesAlunosVisiveis(turma, bimestre);

    if (indicesVisiveis.isEmpty) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.task_alt_rounded,
          titulo: 'Nenhum aluno pendente.',
          mensagem:
              'Todos os alunos têm as notas e recuperações lançadas neste '
              'bimestre.',
          acao: TextButton.icon(
            onPressed: () => setState(() => _somentePendentes = false),
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('Mostrar todos'),
          ),
        ),
      );
    }

    // Garante que o aluno selecionado esteja visível no filtro atual.
    final indiceAluno = indicesVisiveis.contains(_alunoSelecionadoIndex)
        ? _alunoSelecionadoIndex!
        : indicesVisiveis.first;

    final aluno = alunos[indiceAluno];

    final recuperacao = bimestre.recuperacoes[indiceAluno];

    // Média simples de todas as avaliações regulares.
    final mediaProvas = CalculoService.calcularMediaProvas(
      bimestre,
      indiceAluno,
    );

    final double mediaMinima = widget.professor.mediaMinima;

    // Média final, considerando recuperação.
    final media = CalculoService.calcularMedia(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    // Verifica se a recuperação pode ser aplicada.
    final podeLancarRecuperacao = CalculoService.podeFazerRecuperacao(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    // A recuperação somente é aplicada se a média original
    // ficar abaixo da média mínima configurada.
    final recuperacaoAplicada = CalculoService.recuperacaoAplicada(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    // Nota necessária na recuperação para alcançar a média mínima.
    final notaNecessaria = CalculoService.notaNecessariaRecuperacao(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    final situacao = CalculoService.verificarSituacao(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seletor<int>(
          titulo: 'Aluno',
          icone: Icons.person_rounded,
          valor: indiceAluno,

          itens: indicesVisiveis.map((index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text(alunos[index].nome, overflow: TextOverflow.ellipsis),
            );
          }).toList(),

          onChanged: (valor) {
            if (valor == null) return;

            setState(() {
              _alunoSelecionadoIndex = valor;
            });
          },
        ),

        const SizedBox(height: 16),

        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: AppCard(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identificação do aluno.
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          aluno.nome.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            aluno.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Matrícula: ${aluno.matricula}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Troca suave do chip quando a situação muda.
                    StatusChip(situacao: situacao),
                  ],
                ),

                const SizedBox(height: 18),

                // Avaliações regulares.
                Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Avaliações regulares',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 14.5),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ...List.generate(bimestre.avaliacoes.length, (j) {
                  return Padding(
                    padding: EdgeInsets.only(top: j == 0 ? 0 : 8),
                    child: _linhaAvaliacao(
                      nome: bimestre.avaliacoes[j],
                      indice: j,
                      lancada: bimestre.notasLancadas[indiceAluno][j],
                      nota: bimestre.notas[indiceAluno][j],
                      aoEditar: () {
                        _editarAvaliacao(
                          bimestre: bimestre,
                          indiceAluno: indiceAluno,
                          avaliacao: j + 1,
                        );
                      },
                    ),
                  );
                }),

                const SizedBox(height: 18),

                // Recuperação.
                _blocoRecuperacao(
                  recuperacao: recuperacao,
                  mediaProvas: mediaProvas,
                  mediaMinima: mediaMinima,
                  notaNecessaria: notaNecessaria,
                  podeLancarRecuperacao: podeLancarRecuperacao,
                  aoEditar: () {
                    _editarRecuperacao(
                      bimestre: bimestre,
                      indiceAluno: indiceAluno,
                    );
                  },
                  aoRemover: () {
                    _removerRecuperacao(
                      bimestre: bimestre,
                      indiceAluno: indiceAluno,
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Resultado acadêmico.
                _blocoResultado(
                  mediaProvas: mediaProvas,
                  media: media,
                  mediaMinima: mediaMinima,
                  situacao: situacao,
                  recuperacao: recuperacao,
                  recuperacaoAplicada: recuperacaoAplicada,
                  quantidadeAvaliacoes: bimestre.avaliacoes.length,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Linha de uma avaliação, com toque amplo e tom alternado.
  Widget _linhaAvaliacao({
    required String nome,
    required int indice,
    required bool lancada,
    required double nota,
    required VoidCallback aoEditar,
  }) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;

    // Linhas alternadas para facilitar a leitura.
    final Color fundo = indice.isEven
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.18);

    return Material(
      color: fundo,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lancada ? 'Nota lançada' : 'Nota ainda não lançada',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (lancada)
                AnimatedNumber(
                  value: nota,
                  formatter: (valor) => _formatarNota(valor.toDouble()),
                  style: AppTheme.numerico(
                    TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Lançar ou alterar $nome',
                onPressed: aoEditar,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary.withValues(alpha: 0.10),
                  foregroundColor: scheme.primary,
                ),
                icon: Icon(
                  lancada ? Icons.edit_rounded : Icons.add_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bloco com a nota de recuperação e suas ações.
  Widget _blocoRecuperacao({
    required double? recuperacao,
    required double? mediaProvas,
    required double mediaMinima,
    required double? notaNecessaria,
    required bool podeLancarRecuperacao,
    required VoidCallback aoEditar,
    required VoidCallback aoRemover,
  }) {
    final ThemeData tema = Theme.of(context);
    final Color cor = recuperacao != null
        ? AppTheme.warning
        : tema.colorScheme.primary;

    String subtitulo;

    if (recuperacao != null) {
      subtitulo = 'Nota lançada: ${_formatarNota(recuperacao)}';
    } else if (mediaProvas == null) {
      subtitulo = 'Lance todas as avaliações primeiro.';
    } else if (!podeLancarRecuperacao) {
      subtitulo =
          'Não necessária: média igual ou superior a '
          '${_formatarNota(mediaMinima)}.';
    } else if (notaNecessaria != null && notaNecessaria > 10) {
      subtitulo =
          'Não é possível atingir a média ${_formatarNota(mediaMinima)} '
          'apenas com a recuperação.';
    } else if (notaNecessaria != null) {
      subtitulo =
          'Precisa de ${_formatarNota(notaNecessaria)} para ficar com '
          'média ${_formatarNota(mediaMinima)}.';
    } else {
      subtitulo = 'Recuperação disponível.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restore_rounded, size: 18, color: cor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recuperação',
                  style: tema.textTheme.titleMedium?.copyWith(fontSize: 14.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitulo,
                  style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                ),
              ),
              IconButton(
                tooltip: recuperacao == null
                    ? 'Lançar recuperação'
                    : 'Alterar recuperação',
                onPressed: (podeLancarRecuperacao || recuperacao != null)
                    ? aoEditar
                    : null,
                style: IconButton.styleFrom(
                  foregroundColor: cor,
                  backgroundColor: cor.withValues(alpha: 0.10),
                ),
                icon: const Icon(Icons.edit_rounded, size: 19),
              ),
              if (recuperacao != null)
                IconButton(
                  tooltip: 'Remover recuperação',
                  onPressed: aoRemover,
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Bloco com as médias, a situação e a regra aplicada.
  Widget _blocoResultado({
    required double? mediaProvas,
    required double? media,
    required double mediaMinima,
    required String situacao,
    required double? recuperacao,
    required bool recuperacaoAplicada,
    required int quantidadeAvaliacoes,
  }) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;

    final String mediaAvaliacoes = quantidadeAvaliacoes == 1
        ? 'média da avaliação'
        : 'média simples das $quantidadeAvaliacoes avaliações';

    final String formula = recuperacaoAplicada
        ? '(Média das avaliações + recuperação) ÷ 2'
        : 'Média final = $mediaAvaliacoes';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            scheme.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _resultadoItem(
                  titulo: 'Média das avaliações',
                  valor: mediaProvas,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resultadoItem(
                  titulo: 'Média final',
                  valor: media,
                  destaque: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Text(
                'Situação',
                style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              const Spacer(),
              // A troca do chip usa AnimatedSwitcher suave.
              StatusChip(situacao: situacao),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            formula,
            style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
          ),

          if (recuperacao != null && !recuperacaoAplicada)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'A recuperação não foi aplicada porque a média das avaliações '
                'já atingiu ${_formatarNota(mediaMinima)}.',
                style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
              ),
            ),

          const SizedBox(height: 4),

          Text(
            'Média mínima para aprovação: ${_formatarNota(mediaMinima)}',
            style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _resultadoItem({
    required String titulo,
    required double? valor,
    bool destaque = false,
  }) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        if (valor == null)
          Text(
            'Pendente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          AnimatedNumber(
            value: valor,
            formatter: (numero) => _formatarNota(numero.toDouble()),
            style: AppTheme.numerico(
              TextStyle(
                fontSize: destaque ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: destaque ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}
