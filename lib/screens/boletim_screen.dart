import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import '../services/calculo_service.dart';
import '../services/pdf_service.dart';
import '../widgets/status_chip.dart';

/// Boletim de um aluno com o resultado dos dois bimestres do semestre.
class BoletimScreen extends StatefulWidget {
  final Professor professor;
  final Turma turma;
  final int indiceAluno;

  const BoletimScreen({
    super.key,
    required this.professor,
    required this.turma,
    required this.indiceAluno,
  });

  @override
  State<BoletimScreen> createState() => _BoletimScreenState();
}

class _BoletimScreenState extends State<BoletimScreen> {
  bool _gerandoPdf = false;

  String _formatar(double? nota) =>
      nota == null ? 'Pendente' : nota.toStringAsFixed(2).replaceAll('.', ',');

  Future<void> _exportarPdf() async {
    setState(() => _gerandoPdf = true);
    try {
      await PdfService.exportarBoletim(
        professor: widget.professor,
        turma: widget.turma,
        indiceAluno: widget.indiceAluno,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boletim semestral exportado!')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $erro')),
      );
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  Widget _linha(String nome, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(nome)),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final indice = widget.indiceAluno;
    if (indice < 0 || indice >= widget.turma.alunos.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boletim')),
        body: const Center(child: Text('Aluno não encontrado.')),
      );
    }

    final primeiro = widget.turma.primeiroBimestre;
    final segundo = widget.turma.segundoBimestre;

    final aluno = widget.turma.alunos[indice];
    final media = CalculoService.calcularMediaSemestral(
      primeiro,
      segundo,
      indice,
    );
    final finalNota = media != null && media < widget.professor.mediaMinima
        ? segundo.provasFinais[indice]
        : null;
    final resultado = CalculoService.calcularMediaFinalSemestral(
      primeiro,
      segundo,
      indice,
      mediaMinima: widget.professor.mediaMinima,
    );
    final situacao = CalculoService.verificarSituacaoSemestral(
      primeiro,
      segundo,
      indice,
      mediaMinima: widget.professor.mediaMinima,
    );
    final frequencia = widget.turma.percentualPresenca(indice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletim do aluno'),
        actions: [
          IconButton(
            tooltip: 'Exportar boletim PDF',
            onPressed: _gerandoPdf ? null : _exportarPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(aluno.nome, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Matrícula: ${aluno.matricula}'),
          Text(
            'Curso: ${widget.turma.curso} • Período: ${widget.turma.periodo}º',
          ),
          Text('Turma: ${widget.turma.nome}'),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avaliações do semestre',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _linha(
                    '1º bimestre — ${primeiro.nomeProva}',
                    _formatar(primeiro.obterNota(indice)),
                  ),
                  _linha(
                    '2º bimestre — ${segundo.nomeProva}',
                    _formatar(segundo.obterNota(indice)),
                  ),
                  const Divider(),
                  _linha('Média semestral', _formatar(media)),
                  if (media != null && media < widget.professor.mediaMinima)
                    _linha('Prova final', _formatar(finalNota)),
                  const Divider(),
                  _linha('Média final', _formatar(resultado)),
                  const SizedBox(height: 12),
                  StatusChip(situacao: situacao),
                  const SizedBox(height: 14),
                  Text(
                    'Média mínima: ${_formatar(widget.professor.mediaMinima)}',
                  ),
                  Text(
                    'Frequência: ${frequencia == null ? "Sem aulas registradas" : "${_formatar(frequencia)}%"}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Média semestral = (Prova 1 + Prova 2) ÷ 2. '
                    'Quando necessário, média final = (média semestral + prova final) ÷ 2.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _gerandoPdf ? null : _exportarPdf,
            icon: const Icon(Icons.download_outlined),
            label: Text(
              _gerandoPdf ? 'Gerando PDF...' : 'Exportar boletim em PDF',
            ),
          ),
        ],
      ),
    );
  }
}
