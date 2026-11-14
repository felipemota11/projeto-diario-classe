import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/calculo_service.dart';
import '../services/exportacao_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_number.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/status_chip.dart';

enum _FiltroAlunos { todos, pendentes, aprovados, abaixoDaMedia }

class RelatoriosScreen extends StatefulWidget {
  final Professor professor;

  const RelatoriosScreen({super.key, required this.professor});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  int? _turmaSelecionadaIndex;
  int? _bimestreSelecionadoNumero;
  bool _exportandoPdf = false;
  _FiltroAlunos _filtroAlunos = _FiltroAlunos.todos;

  double get _mediaMinima => widget.professor.mediaMinima;

  Future<void> _exportarCsv(Turma turma, Bimestre bimestre) async {
    try {
      await ExportacaoService.exportarCsv(
        nomeProfessor: widget.professor.nome,
        turma: turma,
        bimestre: bimestre,
        mediaMinima: _mediaMinima,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório CSV exportado com sucesso!')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível exportar o arquivo: $erro')),
      );
    }
  }

  Future<void> _exportarPdf(Turma turma, Bimestre bimestre) async {
    setState(() => _exportandoPdf = true);

    try {
      await PdfService.exportarRelatorioTurma(
        professor: widget.professor,
        turma: turma,
        bimestre: bimestre,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório PDF gerado com sucesso!')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $erro')),
      );
    } finally {
      if (mounted) setState(() => _exportandoPdf = false);
    }
  }

  // Formata os valores com duas casas decimais.
  String _formatar(double? valor) {
    if (valor == null) {
      return '—';
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatarPercentual(double? valor) {
    if (valor == null) {
      return '—';
    }

    return '${valor.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  // Pendências de um aluno no bimestre, incluindo a recuperação quando
  // ela é necessária e ainda não foi lançada.
  List<String> _pendenciasDoAluno(Bimestre bimestre, int indiceAluno) {
    return CalculoService.pendenciasDoAluno(
      bimestre,
      indiceAluno,
      mediaMinima: _mediaMinima,
    );
  }

  bool _alunoPendente(Bimestre bimestre, int indiceAluno) {
    return _pendenciasDoAluno(bimestre, indiceAluno).isNotEmpty;
  }

  // Resumo dos filtros do desempenho dos alunos.
  ({int pendentes, int aprovados, int abaixo}) _resumoFiltros(
    Turma turma,
    Bimestre bimestre,
  ) {
    int pendentes = 0;
    int aprovados = 0;
    int abaixo = 0;

    for (int i = 0; i < turma.alunos.length; i++) {
      if (_alunoPendente(bimestre, i)) pendentes++;

      final situacao = CalculoService.verificarSituacao(
        bimestre,
        i,
        mediaMinima: _mediaMinima,
      );

      if (situacao == 'Aprovado') aprovados++;
      if (situacao == 'Abaixo da média') abaixo++;
    }

    return (pendentes: pendentes, aprovados: aprovados, abaixo: abaixo);
  }

  // Seletor reutilizável.
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

  // Estilo padrão dos números grandes dos cartões.
  TextStyle _estiloNumero() {
    final ThemeData tema = Theme.of(context);

    return AppTheme.numerico(
      tema.textTheme.headlineSmall?.copyWith(
        fontSize: 23,
        color: tema.colorScheme.onSurface,
      ),
    );
  }

  Widget _construirEstatisticas(Bimestre bimestre) {
    final mediaGeral = CalculoService.calcularMediaGeral(
      bimestre,
      mediaMinima: _mediaMinima,
    );

    final maiorNota = CalculoService.obterMaiorNotaLancada(bimestre);

    final menorNota = CalculoService.obterMenorNotaLancada(bimestre);

    final percentual = CalculoService.calcularPercentualAprovados(
      bimestre,
      mediaMinima: _mediaMinima,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const double espaco = 12;
        final bool telaLarga = constraints.maxWidth >= 700;
        final int colunas = telaLarga ? 4 : 2;

        final double largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            SizedBox(
              width: largura,
              height: 132,
              child: StatCard(
                titulo: 'Média geral',
                icon: Icons.calculate_rounded,
                cor: AppTheme.primary,
                valor: AnimatedNumber(
                  value: mediaGeral,
                  formatter: (valor) => _formatar(valor.toDouble()),
                  style: _estiloNumero(),
                ),
              ),
            ),
            SizedBox(
              width: largura,
              height: 132,
              child: StatCard(
                titulo: 'Maior nota lançada',
                icon: Icons.trending_up_rounded,
                cor: AppTheme.success,
                valor: AnimatedNumber(
                  value: maiorNota,
                  formatter: (valor) => _formatar(valor.toDouble()),
                  style: _estiloNumero(),
                ),
              ),
            ),
            SizedBox(
              width: largura,
              height: 132,
              child: StatCard(
                titulo: 'Menor nota lançada',
                icon: Icons.trending_down_rounded,
                cor: AppTheme.warning,
                valor: AnimatedNumber(
                  value: menorNota,
                  formatter: (valor) => _formatar(valor.toDouble()),
                  style: _estiloNumero(),
                ),
              ),
            ),
            SizedBox(
              width: largura,
              height: 132,
              child: StatCard(
                titulo: 'Percentual de aprovados',
                icon: Icons.check_circle_rounded,
                cor: AppTheme.info,
                valor: AnimatedNumber(
                  value: percentual,
                  formatter: (valor) => _formatarPercentual(valor.toDouble()),
                  style: _estiloNumero(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legenda(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  // Gráfico de barras das médias dos estudantes.
  Widget _construirGrafico(Turma turma, Bimestre bimestre) {
    final medias = List<double?>.generate(
      turma.alunos.length,
      (index) => CalculoService.calcularMedia(
        bimestre,
        index,
        mediaMinima: _mediaMinima,
      ),
    );

    final possuiMedias = medias.any((media) => media != null);

    if (!possuiMedias) {
      return const AppCard(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          titulo: 'Ainda não existem médias calculadas.',
          mensagem:
              'Lance todas as avaliações de pelo menos um aluno '
              'para visualizar o gráfico.',
        ),
      );
    }

    final double larguraNecessaria = turma.alunos.length * 86.0;

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 18, 18, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double larguraFinal = constraints.maxWidth > larguraNecessaria
                ? constraints.maxWidth
                : larguraNecessaria;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _legenda(AppTheme.success, 'Aprovado'),
                      _legenda(AppTheme.warning, 'Abaixo da média'),
                      _legenda(
                        Theme.of(context).colorScheme.outline,
                        'Pendente',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: larguraFinal,
                    height: 280,
                    child: _GraficoMedias(
                      turma: turma,
                      medias: medias,
                      mediaMinima: _mediaMinima,
                      formatar: _formatar,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Filtros rápidos da lista de desempenho.
  Widget _construirFiltrosAlunos(Turma turma, Bimestre bimestre) {
    final resumo = _resumoFiltros(turma, bimestre);

    Widget chip(_FiltroAlunos filtro, String label, int quantidade) {
      return ChoiceChip(
        label: Text('$label ($quantidade)'),
        selected: _filtroAlunos == filtro,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() => _filtroAlunos = filtro),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(_FiltroAlunos.todos, 'Todos', turma.alunos.length),
        chip(_FiltroAlunos.pendentes, 'Pendentes', resumo.pendentes),
        chip(_FiltroAlunos.aprovados, 'Aprovados', resumo.aprovados),
        chip(_FiltroAlunos.abaixoDaMedia, 'Abaixo da média', resumo.abaixo),
      ],
    );
  }

  // Lista as notas e situações dos estudantes.
  Widget _construirListaAlunos(Turma turma, Bimestre bimestre) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;
    final bool escuro = tema.brightness == Brightness.dark;

    final List<int> indices = [];

    for (int i = 0; i < turma.alunos.length; i++) {
      final situacao = CalculoService.verificarSituacao(
        bimestre,
        i,
        mediaMinima: _mediaMinima,
      );

      final bool incluir = switch (_filtroAlunos) {
        _FiltroAlunos.todos => true,
        _FiltroAlunos.pendentes => _alunoPendente(bimestre, i),
        _FiltroAlunos.aprovados => situacao == 'Aprovado',
        _FiltroAlunos.abaixoDaMedia => situacao == 'Abaixo da média',
      };

      if (incluir) indices.add(i);
    }

    if (indices.isEmpty) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.filter_alt_off_rounded,
          titulo: 'Nenhum aluno neste filtro.',
          mensagem: _filtroAlunos == _FiltroAlunos.pendentes
              ? 'Todos os alunos estão com as notas e recuperações em dia.'
              : 'Ajuste o filtro para visualizar outros alunos.',
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(indices.length, (posicao) {
          final index = indices[posicao];
          final aluno = turma.alunos[index];

          final media = CalculoService.calcularMedia(
            bimestre,
            index,
            mediaMinima: _mediaMinima,
          );

          final situacao = CalculoService.verificarSituacao(
            bimestre,
            index,
            mediaMinima: _mediaMinima,
          );

          final Color fundo = posicao.isEven
              ? scheme.surfaceContainerHighest.withValues(
                  alpha: escuro ? 0.22 : 0.32,
                )
              : Colors.transparent;

          return Container(
            color: fundo,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      inicialDoNome(aluno.nome),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 15,
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
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Matrícula: ${aluno.matricula}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Média',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                    AnimatedNumber(
                      value: media,
                      animated: false,
                      formatter: (valor) => _formatar(valor.toDouble()),
                      style: AppTheme.numerico(
                        TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                StatusChip(situacao: situacao, compacto: true),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Lista alunos com notas ou recuperações pendentes.
  Widget _construirPendencias(Turma turma, Bimestre bimestre) {
    final ThemeData tema = Theme.of(context);

    final List<({String nome, List<String> pendencias})> pendencias = [];

    for (int i = 0; i < turma.alunos.length; i++) {
      final List<String> faltas = _pendenciasDoAluno(bimestre, i);

      if (faltas.isNotEmpty) {
        pendencias.add((nome: turma.alunos[i].nome, pendencias: faltas));
      }
    }

    if (pendencias.isEmpty) {
      return AppCard(
        color: AppTheme.success.withValues(alpha: 0.07),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.20)),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nenhuma pendência neste bimestre. Tudo lançado!',
                style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(pendencias.length, (index) {
          final item = pendencias[index];

          return Column(
            children: [
              if (index > 0)
                Divider(
                  height: 1,
                  color: tema.colorScheme.outlineVariant.withValues(
                    alpha: 0.35,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.pending_actions_rounded,
                      size: 19,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: item.pendencias
                                .map(
                                  (falta) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warning.withValues(
                                        alpha: 0.11,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      falta,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Compara a média geral de todos os bimestres da turma.
  Widget _construirEvolucao(Turma turma) {
    final List<({int numero, double? media})> dados = turma.bimestres
        .map(
          (bimestre) => (
            numero: bimestre.numero,
            media: CalculoService.calcularMediaGeral(
              bimestre,
              mediaMinima: _mediaMinima,
            ),
          ),
        )
        .toList();

    final bool temDados = dados.any((item) => item.media != null);

    if (!temDados) {
      return const AppCard(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.show_chart_rounded,
          titulo: 'Sem médias para comparar.',
          mensagem:
              'Lance as notas dos bimestres para acompanhar a evolução '
              'da turma.',
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 18, 18, 14),
        child: SizedBox(
          height: 220,
          child: _GraficoEvolucao(dados: dados, formatar: _formatar),
        ),
      ),
    );
  }

  // Destaca quem melhorou ou piorou em relação ao bimestre anterior.
  Widget _construirDestaques(Turma turma, Bimestre bimestreAtual) {
    final ThemeData tema = Theme.of(context);

    final int indiceAtual = turma.bimestres.indexWhere(
      (item) => item.numero == bimestreAtual.numero,
    );

    if (indiceAtual <= 0) {
      return AppCard(
        child: Row(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 20,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Selecione um bimestre a partir do segundo para comparar '
                'com o anterior.',
                style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    final Bimestre anterior = turma.bimestres[indiceAtual - 1];

    final List<({String nome, double diferenca})> variacoes = [];

    for (int i = 0; i < turma.alunos.length; i++) {
      final double? mediaAtual = CalculoService.calcularMedia(
        bimestreAtual,
        i,
        mediaMinima: _mediaMinima,
      );
      final double? mediaAnterior = CalculoService.calcularMedia(
        anterior,
        i,
        mediaMinima: _mediaMinima,
      );

      if (mediaAtual == null || mediaAnterior == null) continue;

      variacoes.add((
        nome: turma.alunos[i].nome,
        diferenca: mediaAtual - mediaAnterior,
      ));
    }

    if (variacoes.isEmpty) {
      return AppCard(
        child: Text(
          'Ainda não há médias nos dois bimestres para comparar.',
          style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
        ),
      );
    }

    final List<({String nome, double diferenca})> melhoraram =
        variacoes.where((item) => item.diferenca > 0).toList()
          ..sort((a, b) => b.diferenca.compareTo(a.diferenca));

    final List<({String nome, double diferenca})> pioraram =
        variacoes.where((item) => item.diferenca < 0).toList()
          ..sort((a, b) => a.diferenca.compareTo(b.diferenca));

    Widget coluna(
      String titulo,
      IconData icone,
      Color cor,
      List<({String nome, double diferenca})> itens,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 17, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: tema.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            Text(
              'Nenhum aluno.',
              style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
            )
          else
            ...itens.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    Text(
                      '${item.diferenca > 0 ? '+' : ''}'
                      '${_formatar(item.diferenca)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: cor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    }

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              children: [
                coluna(
                  'Melhoraram (${bimestreAtual.numero}º)',
                  Icons.trending_up_rounded,
                  AppTheme.success,
                  melhoraram,
                ),
                const SizedBox(height: 18),
                coluna(
                  'Pioraram (${bimestreAtual.numero}º)',
                  Icons.trending_down_rounded,
                  AppTheme.danger,
                  pioraram,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: coluna(
                  'Melhoraram (${bimestreAtual.numero}º)',
                  Icons.trending_up_rounded,
                  AppTheme.success,
                  melhoraram,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: coluna(
                  'Pioraram (${bimestreAtual.numero}º)',
                  Icons.trending_down_rounded,
                  AppTheme.danger,
                  pioraram,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas
        .where((turma) => !turma.arquivada)
        .toList();

    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relatórios')),
        body: const EmptyState(
          icon: Icons.bar_chart_rounded,
          titulo: 'Nenhuma turma ativa.',
          mensagem:
              'Cadastre uma turma ou desarquive uma turma antiga para '
              'visualizar os relatórios acadêmicos.',
        ),
      );
    }

    final indiceTurma =
        _turmaSelecionadaIndex != null &&
            _turmaSelecionadaIndex! >= 0 &&
            _turmaSelecionadaIndex! < turmas.length
        ? _turmaSelecionadaIndex!
        : 0;

    final turma = turmas[indiceTurma];

    final bimestres = turma.bimestres;

    final bimestresSelecionados = bimestres.where(
      (b) => b.numero == _bimestreSelecionadoNumero,
    );

    final Bimestre? bimestre = bimestresSelecionados.isNotEmpty
        ? bimestresSelecionados.first
        : bimestres.isNotEmpty
        ? bimestres.first
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios acadêmicos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(child: const SectionHeader(titulo: 'Selecionar turma')),
            const SizedBox(height: 8),
            _seletor<int>(
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
                  _filtroAlunos = _FiltroAlunos.todos;
                });
              },
            ),
            const SizedBox(height: 22),
            if (bimestre == null)
              const AppCard(
                padding: EdgeInsets.zero,
                child: EmptyState(
                  icon: Icons.calendar_month_rounded,
                  titulo: 'Sem bimestres cadastrados.',
                  mensagem:
                      'Esta turma ainda não possui bimestres cadastrados.',
                ),
              )
            else ...[
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: const SectionHeader(titulo: 'Selecionar bimestre'),
              ),
              const SizedBox(height: 8),
              _seletor<int>(
                titulo: 'Bimestre',
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
                    _filtroAlunos = _FiltroAlunos.todos;
                  });
                },
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: _exportandoPdf
                    ? 'Gerando PDF...'
                    : 'Exportar relatório em PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: _exportandoPdf
                    ? null
                    : () => _exportarPdf(turma, bimestre),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: turma.alunos.isEmpty
                    ? null
                    : () => _exportarCsv(turma, bimestre),
                icon: const Icon(Icons.table_view_rounded, size: 19),
                label: const Text('Exportar resultados para CSV'),
              ),
              const SizedBox(height: 26),
              const SectionHeader(titulo: 'Pendências do bimestre'),
              const SizedBox(height: 10),
              _construirPendencias(turma, bimestre),
              const SizedBox(height: 26),
              const SectionHeader(titulo: 'Estatísticas da turma'),
              const SizedBox(height: 12),
              _construirEstatisticas(bimestre),
              const SizedBox(height: 26),
              const SectionHeader(titulo: 'Gráfico de médias'),
              const SizedBox(height: 4),
              Text(
                'Cada barra representa a média final de um aluno.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              turma.alunos.isEmpty
                  ? const AppCard(
                      padding: EdgeInsets.zero,
                      child: EmptyState(
                        icon: Icons.people_alt_rounded,
                        titulo: 'Esta turma ainda não possui alunos.',
                        mensagem: 'Cadastre alunos para visualizar o gráfico.',
                      ),
                    )
                  : _construirGrafico(turma, bimestre),
              const SizedBox(height: 26),
              const SectionHeader(titulo: 'Evolução entre bimestres'),
              const SizedBox(height: 4),
              Text(
                'Média geral da turma em cada bimestre.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              _construirEvolucao(turma),
              const SizedBox(height: 20),
              _construirDestaques(turma, bimestre),
              const SizedBox(height: 26),
              const SectionHeader(titulo: 'Desempenho dos alunos'),
              const SizedBox(height: 8),
              if (turma.alunos.isNotEmpty) ...[
                _construirFiltrosAlunos(turma, bimestre),
                const SizedBox(height: 12),
              ],
              turma.alunos.isEmpty
                  ? const SizedBox.shrink()
                  : _construirListaAlunos(turma, bimestre),
            ],
          ],
        ),
      ),
    );
  }
}

// Gráfico de barras das médias por aluno.
// Usa a animação interna do fl_chart para não reconstruir os dados a cada frame.
class _GraficoMedias extends StatefulWidget {
  final Turma turma;
  final List<double?> medias;
  final double mediaMinima;
  final String Function(double? valor) formatar;

  const _GraficoMedias({
    required this.turma,
    required this.medias,
    required this.mediaMinima,
    required this.formatar,
  });

  @override
  State<_GraficoMedias> createState() => _GraficoMediasState();
}

class _GraficoMediasState extends State<_GraficoMedias> {
  bool _valoresVisiveis = false;
  bool _agendado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_agendado) return;
    _agendado = true;

    if (!AppMotion.enabled(context)) {
      _valoresVisiveis = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _valoresVisiveis = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;
    final Duration duracao = AppMotion.duration(context, AppMotion.slow);

    return RepaintBoundary(
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 10,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (valor) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
                getTitlesWidget: (valor, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      valor.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (valor, meta) {
                  final indice = valor.round();

                  if (indice < 0 || indice >= widget.turma.alunos.length) {
                    return const SizedBox.shrink();
                  }

                  final nome = widget.turma.alunos[indice].nome.trim();

                  final primeiroNome = nome.split(RegExp(r'\s+')).first;

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: SizedBox(
                      width: 74,
                      child: Text(
                        primeiroNome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.15,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.onSurface.withValues(alpha: 0.92),
              getTooltipItem: (grupo, grupoIndex, haste, hasteIndex) {
                final indice = grupo.x;

                if (indice < 0 || indice >= widget.turma.alunos.length) {
                  return null;
                }

                final aluno = widget.turma.alunos[indice];
                final media = widget.medias[indice];

                return BarTooltipItem(
                  '${aluno.nome}\n'
                  'Média: ${media == null ? 'Pendente' : widget.formatar(media)}',
                  TextStyle(
                    color: scheme.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(widget.turma.alunos.length, (index) {
            final media = widget.medias[index];

            final Color cor = media == null
                ? scheme.outline
                : media >= widget.mediaMinima
                ? AppTheme.success
                : AppTheme.warning;

            final double valor = !_valoresVisiveis ? 0 : media ?? 0.35;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: valor,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [cor.withValues(alpha: 0.55), cor],
                  ),
                ),
              ],
            );
          }),
        ),
        duration: duracao,
        curve: AppMotion.curve,
      ),
    );
  }
}

// Gráfico de barras da média geral por bimestre.
class _GraficoEvolucao extends StatefulWidget {
  final List<({int numero, double? media})> dados;
  final String Function(double? valor) formatar;

  const _GraficoEvolucao({required this.dados, required this.formatar});

  @override
  State<_GraficoEvolucao> createState() => _GraficoEvolucaoState();
}

class _GraficoEvolucaoState extends State<_GraficoEvolucao> {
  bool _valoresVisiveis = false;
  bool _agendado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_agendado) return;
    _agendado = true;

    if (!AppMotion.enabled(context)) {
      _valoresVisiveis = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _valoresVisiveis = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;
    final Duration duracao = AppMotion.duration(context, AppMotion.slow);

    return RepaintBoundary(
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 10,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (valor) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
                getTitlesWidget: (valor, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      valor.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (valor, meta) {
                  final indice = valor.round();

                  if (indice < 0 || indice >= widget.dados.length) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      '${widget.dados[indice].numero}º',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.onSurface.withValues(alpha: 0.92),
              getTooltipItem: (grupo, grupoIndex, haste, hasteIndex) {
                final indice = grupo.x;

                if (indice < 0 || indice >= widget.dados.length) {
                  return null;
                }

                final item = widget.dados[indice];

                return BarTooltipItem(
                  '${item.numero}º bimestre\n'
                  'Média: ${item.media == null ? 'Pendente' : widget.formatar(item.media)}',
                  TextStyle(
                    color: scheme.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(widget.dados.length, (index) {
            final item = widget.dados[index];
            final Color cor = item.media == null
                ? scheme.outline
                : AppTheme.info;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: !_valoresVisiveis ? 0 : item.media ?? 0.35,
                  width: 26,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [cor.withValues(alpha: 0.45), cor],
                  ),
                ),
              ],
            );
          }),
        ),
        duration: duracao,
        curve: AppMotion.curve,
      ),
    );
  }
}
