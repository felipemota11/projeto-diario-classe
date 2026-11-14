import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/exportacao_service.dart';
import '../services/calculo_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

/// Relatório que consolida uma prova por bimestre e uma prova final por semestre.
class RelatorioSemestralScreen extends StatefulWidget {
  final Professor professor;

  const RelatorioSemestralScreen({super.key, required this.professor});

  @override
  State<RelatorioSemestralScreen> createState() =>
      _RelatorioSemestralScreenState();
}

class _RelatorioSemestralScreenState extends State<RelatorioSemestralScreen> {
  int _indiceTurma = 0;
  bool _exportando = false;

  String _formatar(double? valor) =>
      valor == null ? '—' : valor.toStringAsFixed(2).replaceAll('.', ',');

  String _situacao(Bimestre primeiro, Bimestre segundo, int indiceAluno) {
    return CalculoService.verificarSituacaoSemestral(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: widget.professor.mediaMinima,
    );
  }

  Future<void> _exportarCsv(Turma turma) async {
    setState(() => _exportando = true);
    try {
      await ExportacaoService.exportarCsvSemestral(
        nomeProfessor: widget.professor.nome,
        turma: turma,
        mediaMinima: widget.professor.mediaMinima,
      );
      if (!mounted) return;
      _mensagem('Relatório CSV exportado!');
    } catch (erro) {
      if (!mounted) return;
      _mensagem('Não foi possível exportar CSV: $erro');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarPdf(Turma turma) async {
    setState(() => _exportando = true);
    try {
      await PdfService.exportarRelatorioSemestral(
        professor: widget.professor,
        turma: turma,
      );
      if (!mounted) return;
      _mensagem('Relatório semestral em PDF exportado!');
    } catch (erro) {
      if (!mounted) return;
      _mensagem('Não foi possível exportar PDF: $erro');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _cartaoResumo(String titulo, String valor, IconData icone) {
    return Card(
      child: SizedBox(
        width: 145,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone),
              const SizedBox(height: 8),
              Text(valor, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(titulo, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conteudo(Turma turma, Bimestre primeiro, Bimestre segundo) {
    int aprovados = 0;
    int reprovados = 0;
    int pendentes = 0;
    int concluidos = 0;
    double soma = 0;
    final minima = widget.professor.mediaMinima;

    for (int i = 0; i < turma.alunos.length; i++) {
      final situacao = _situacao(primeiro, segundo, i);
      if (situacao.startsWith('Aprovado')) {
        aprovados++;
      } else if (situacao == 'Reprovado') {
        reprovados++;
      } else {
        pendentes++;
      }
      final finalAluno = CalculoService.calcularMediaFinalSemestral(
        primeiro,
        segundo,
        i,
        mediaMinima: minima,
      );
      if (finalAluno != null) {
        soma += finalAluno;
        concluidos++;
      }
    }
    final mediaGeral = concluidos == 0 ? null : soma / concluidos;
    final percentual = concluidos == 0 ? null : aprovados * 100 / concluidos;
    final percentualTexto = percentual == null
        ? '—'
        : '${_formatar(percentual)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo do semestre',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _cartaoResumo(
              'Média final geral',
              _formatar(mediaGeral),
              Icons.calculate_outlined,
            ),
            _cartaoResumo(
              'Aprovados',
              '$aprovados',
              Icons.check_circle_outline,
            ),
            _cartaoResumo('Pendentes', '$pendentes', Icons.pending_outlined),
            _cartaoResumo('Reprovados', '$reprovados', Icons.cancel_outlined),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Aprovação entre alunos com resultado concluído: $percentualTexto',
        ),
        const SizedBox(height: 12),
        if (percentual != null)
          LinearProgressIndicator(value: percentual / 100, minHeight: 9),
        if (turma.alunos.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Distribuição de resultados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: aprovados.toDouble(),
                        color: AppTheme.foreground(context, AppTheme.success),
                        width: 38,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: pendentes.toDouble(),
                        color: AppTheme.foreground(context, AppTheme.warning),
                        width: 38,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: reprovados.toDouble(),
                        color: AppTheme.foreground(context, AppTheme.danger),
                        width: 38,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 18,
            children: [
              Text('Aprovados: $aprovados'),
              Text('Pendentes: $pendentes'),
              Text('Reprovados: $reprovados'),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Notas dos alunos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _exportando ? null : () => _exportarCsv(turma),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('CSV'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _exportando ? null : () => _exportarPdf(turma),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_exportando) const LinearProgressIndicator(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Aluno')),
              DataColumn(label: Text('B1')),
              DataColumn(label: Text('B2')),
              DataColumn(label: Text('Média')),
              DataColumn(label: Text('Prova final')),
              DataColumn(label: Text('Resultado')),
              DataColumn(label: Text('Situação')),
            ],
            rows: [
              for (int i = 0; i < turma.alunos.length; i++)
                _linhaAluno(turma, primeiro, segundo, i),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Média mínima de aprovação: ${_formatar(minima)}'),
      ],
    );
  }

  DataRow _linhaAluno(Turma turma, Bimestre primeiro, Bimestre segundo, int i) {
    final media = CalculoService.calcularMediaSemestral(primeiro, segundo, i);
    final resultado = CalculoService.calcularMediaFinalSemestral(
      primeiro,
      segundo,
      i,
      mediaMinima: widget.professor.mediaMinima,
    );
    final provaFinal = media != null && media < widget.professor.mediaMinima
        ? segundo.provasFinais[i]
        : null;
    return DataRow(
      cells: [
        DataCell(Text(turma.alunos[i].nome)),
        DataCell(Text(_formatar(primeiro.obterNota(i)))),
        DataCell(Text(_formatar(segundo.obterNota(i)))),
        DataCell(Text(_formatar(media))),
        DataCell(Text(_formatar(provaFinal))),
        DataCell(Text(_formatar(resultado))),
        DataCell(Text(_situacao(primeiro, segundo, i))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas
        .where((turma) => !turma.arquivada)
        .toList();
    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relatório semestral')),
        body: const Center(child: Text('Nenhuma turma ativa cadastrada.')),
      );
    }
    final indice = _indiceTurma < turmas.length ? _indiceTurma : 0;
    final turma = turmas[indice];
    final primeiro = turma.primeiroBimestre;
    final segundo = turma.segundoBimestre;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório semestral')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Selecionar turma',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: indice,
                isExpanded: true,
                items: [
                  for (int i = 0; i < turmas.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        turmas[i].nome,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;
                  setState(() => _indiceTurma = valor);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Curso: ${turma.curso}'),
          Text('Período: ${turma.periodo}º'),
          Text('Alunos: ${turma.alunos.length}'),
          const SizedBox(height: 24),
          _conteudo(turma, primeiro, segundo),
        ],
      ),
    );
  }
}
