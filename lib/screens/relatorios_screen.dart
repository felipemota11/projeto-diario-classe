import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import '../models/bimestre.dart';
import '../services/calculo_service.dart';
import '../services/exportacao_service.dart';

class RelatoriosScreen extends StatefulWidget {
  final Professor professor;

  const RelatoriosScreen({super.key, required this.professor});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  Future<void> _exportarCsv(Turma turma, Bimestre bimestre) async {
    try {
      await ExportacaoService.exportarCsv(
        nomeProfessor: widget.professor.nome,
        turma: turma,
        bimestre: bimestre,
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

  int? _turmaSelecionadaIndex;
  int? _bimestreSelecionadoNumero;

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

  // Seletor reutilizável.
  Widget _seletor<T>({
    required String titulo,
    required IconData icone,
    required T valor,
    required List<DropdownMenuItem<T>> itens,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icone),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          items: itens,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Cartão individual de estatística.
  Widget _cartaoEstatistica({
    required String titulo,
    required String valor,
    required IconData icone,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 26, color: Theme.of(context).colorScheme.primary),

            const SizedBox(height: 10),

            Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(titulo, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // Cria a área de estatísticas.
  Widget _construirEstatisticas(Bimestre bimestre) {
    final mediaGeral = CalculoService.calcularMediaGeral(bimestre);

    final maiorNota = CalculoService.obterMaiorNotaLancada(bimestre);

    final menorNota = CalculoService.obterMenorNotaLancada(bimestre);

    final percentual = CalculoService.calcularPercentualAprovados(bimestre);

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,

          children: [
            SizedBox(
              width: largura,
              child: _cartaoEstatistica(
                titulo: 'Média geral',
                valor: _formatar(mediaGeral),
                icone: Icons.calculate_outlined,
              ),
            ),

            SizedBox(
              width: largura,
              child: _cartaoEstatistica(
                titulo: 'Maior nota lançada',
                valor: _formatar(maiorNota),
                icone: Icons.trending_up,
              ),
            ),

            SizedBox(
              width: largura,
              child: _cartaoEstatistica(
                titulo: 'Menor nota lançada',
                valor: _formatar(menorNota),
                icone: Icons.trending_down,
              ),
            ),

            SizedBox(
              width: largura,
              child: _cartaoEstatistica(
                titulo: 'Percentual de aprovados',
                valor: _formatarPercentual(percentual),
                icone: Icons.check_circle_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  // Gráfico de barras das médias dos estudantes.
  Widget _construirGrafico(Turma turma, Bimestre bimestre) {
    final medias = List<double?>.generate(
      turma.alunos.length,
      (index) => CalculoService.calcularMedia(bimestre, index),
    );

    final possuiMedias = medias.any((media) => media != null);

    if (!possuiMedias) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Ainda não existem médias calculadas '
              'para este bimestre.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final larguraGrafico = (turma.alunos.length * 100.0).clamp(400.0, 3000.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: SizedBox(
            width: larguraGrafico,
            height: 260,

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,

              children: List.generate(turma.alunos.length, (index) {
                final aluno = turma.alunos[index];
                final media = medias[index];

                final aprovado =
                    media != null && media >= CalculoService.mediaMinima;

                final cor = media == null
                    ? Colors.grey
                    : aprovado
                    ? Colors.green
                    : Colors.orange;

                final altura = media == null
                    ? 4.0
                    : (media / 10 * 140).clamp(4.0, 140.0);

                return SizedBox(
                  width: 100,

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      Text(
                        media == null ? 'Pendente' : _formatar(media),

                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),

                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 145,

                        child: Align(
                          alignment: Alignment.bottomCenter,

                          child: Container(
                            width: 36,
                            height: altura,
                            decoration: BoxDecoration(
                              color: cor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 40,
                        child: Text(
                          aluno.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // Lista as notas e situações dos estudantes.
  Widget _construirListaAlunos(Turma turma, Bimestre bimestre) {
    return Card(
      child: Column(
        children: List.generate(turma.alunos.length, (index) {
          final aluno = turma.alunos[index];

          final media = CalculoService.calcularMedia(bimestre, index);

          final situacao = CalculoService.verificarSituacao(bimestre, index);

          final cor = situacao == 'Aprovado'
              ? Colors.green
              : situacao == 'Pendente'
              ? Colors.grey
              : Colors.orange;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(child: Text(aluno.nome[0].toUpperCase())),

                title: Text(aluno.nome),

                subtitle: Text(
                  'Matrícula: ${aluno.matricula}\n'
                  'Situação: $situacao',
                ),

                isThreeLine: true,

                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Média', style: TextStyle(fontSize: 11)),

                    Text(
                      media == null ? '—' : _formatar(media),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                iconColor: cor,
              ),

              if (index < turma.alunos.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas;

    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relatórios')),

        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),

            child: Text(
              'Nenhuma turma cadastrada. '
              'Cadastre uma turma para visualizar os relatórios.',
              textAlign: TextAlign.center,
            ),
          ),
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
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar turma',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _seletor<int>(
              titulo: 'Turma',
              icone: Icons.school,
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
                });
              },
            ),

            const SizedBox(height: 24),

            if (bimestre == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Esta turma ainda não possui bimestres cadastrados.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar bimestre',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  _seletor<int>(
                    titulo: 'Bimestre',
                    icone: Icons.calendar_month,
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
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: turma.alunos.isEmpty
                          ? null
                          : () => _exportarCsv(turma, bimestre),

                      icon: const Icon(Icons.download),

                      label: const Text('Exportar resultados para CSV'),

                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Estatísticas da turma',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _construirEstatisticas(bimestre),

                  const SizedBox(height: 24),

                  const Text(
                    'Gráfico de médias',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Cada barra representa a média final de um aluno.',
                  ),

                  const SizedBox(height: 12),

                  turma.alunos.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Esta turma ainda não possui alunos.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _construirGrafico(turma, bimestre),

                  const SizedBox(height: 24),

                  const Text(
                    'Desempenho dos alunos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  turma.alunos.isEmpty
                      ? const SizedBox.shrink()
                      : _construirListaAlunos(turma, bimestre),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
