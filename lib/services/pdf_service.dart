import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import 'arquivo_service.dart';
import 'calculo_service.dart';

/// Gera boletins e relatórios em PDF usando as mesmas regras da aplicação.
class PdfService {
  static String _formatar(double? valor) {
    if (valor == null) {
      return '—';
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _percentual(double? valor) {
    if (valor == null) {
      return '—';
    }

    return '${valor.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  static String _dataAtual() {
    final DateTime agora = DateTime.now();
    final String dia = agora.day.toString().padLeft(2, '0');
    final String mes = agora.month.toString().padLeft(2, '0');

    return '$dia/$mes/${agora.year}';
  }

  static String _slug(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  // Cabeçalho comum dos PDFs.
  static pw.Widget _cabecalho({
    required String titulo,
    required String subtitulo,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E5EF), width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 34,
            height: 34,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#5B4BFF'),
              borderRadius: pw.BorderRadius.circular(9),
            ),
            child: pw.Text(
              'DC',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1F2430'),
                  ),
                ),
                pw.Text(
                  subtitulo,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rodape(pw.Context context, String nomeProfessor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Diário de Classe • $nomeProfessor',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF9CA3AF),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tituloSecao(String titulo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1F2430'),
        ),
      ),
    );
  }

  // Gera o PDF do boletim individual do aluno.
  static Future<Uint8List> gerarBoletim({
    required Professor professor,
    required Turma turma,
    required int indiceAluno,
  }) async {
    final aluno = turma.alunos[indiceAluno];
    final documento = pw.Document(title: 'Boletim - ${aluno.nome}');

    final linhas = <List<String>>[];

    for (final bimestre in turma.bimestres) {
      final avaliacoes = <String>[];

      for (int j = 0; j < bimestre.avaliacoes.length; j++) {
        final lancada = bimestre.notasLancadas[indiceAluno][j];
        final nota = lancada ? bimestre.notas[indiceAluno][j] : null;

        avaliacoes.add('${bimestre.avaliacoes[j]}: ${_formatar(nota)}');
      }

      linhas.add([
        '${bimestre.numero}º',
        avaliacoes.join('\n'),
        _formatar(bimestre.recuperacoes[indiceAluno]),
        _formatar(
          CalculoService.calcularMedia(
            bimestre,
            indiceAluno,
            mediaMinima: professor.mediaMinima,
          ),
        ),
        CalculoService.verificarSituacao(
          bimestre,
          indiceAluno,
          mediaMinima: professor.mediaMinima,
        ),
      ]);
    }

    final frequencia = turma.percentualPresenca(indiceAluno);

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _cabecalho(
          titulo: 'Boletim do aluno',
          subtitulo:
              '${turma.nome} • ${turma.curso} • ${turma.periodo}º período',
        ),
        footer: (context) => _rodape(context, professor.nome),
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F6FB'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    aluno.nome,
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1F2430'),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Matrícula: ${aluno.matricula}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF6B7280),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Frequência: ${_percentual(frequencia)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#5B4BFF'),
                        ),
                      ),
                      pw.SizedBox(width: 18),
                      pw.Text(
                        'Média mínima: ${_formatar(professor.mediaMinima)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _tituloSecao('Desempenho por bimestre'),
            if (linhas.isEmpty)
              pw.Text(
                'Nenhum bimestre cadastrado.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF6B7280),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Bimestre',
                  'Avaliações',
                  'Recuperação',
                  'Média final',
                  'Situação',
                ],
                data: linhas,
                columnWidths: {
                  0: pw.FlexColumnWidth(0.8),
                  1: pw.FlexColumnWidth(3.2),
                  2: pw.FlexColumnWidth(1.1),
                  3: pw.FlexColumnWidth(1.0),
                  4: pw.FlexColumnWidth(1.4),
                },
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1F2430'),
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EEF0F8'),
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF374151),
                ),
                cellAlignment: pw.Alignment.center,
                cellAlignments: const {1: pw.Alignment.centerLeft},
                headerAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 7,
                ),
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE5E7EB),
                    width: 1,
                  ),
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
              ),
            if (aluno.observacao.trim().isNotEmpty) ...[
              _tituloSecao('Observações'),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF8E7'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  aluno.observacao.trim(),
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColor.fromInt(0xFF4B5563),
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 18),
            pw.Text(
              'Gerado em ${_dataAtual()} pelo Diário de Classe.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF9CA3AF),
              ),
            ),
          ];
        },
      ),
    );

    return documento.save();
  }

  // Gera o relatório completo de uma turma em um bimestre.
  static Future<Uint8List> gerarRelatorioTurma({
    required Professor professor,
    required Turma turma,
    required Bimestre bimestre,
  }) async {
    final documento = pw.Document(
      title: 'Relatório - ${turma.nome} - ${bimestre.numero}º bimestre',
    );

    final linhas = <List<String>>[];

    for (int i = 0; i < turma.alunos.length; i++) {
      final aluno = turma.alunos[i];

      final notas = List<String>.generate(bimestre.avaliacoes.length, (j) {
        final lancada = bimestre.notasLancadas[i][j];

        return _formatar(lancada ? bimestre.notas[i][j] : null);
      });

      linhas.add([
        aluno.matricula,
        aluno.nome,
        ...notas,
        _formatar(bimestre.recuperacoes[i]),
        _formatar(
          CalculoService.calcularMedia(
            bimestre,
            i,
            mediaMinima: professor.mediaMinima,
          ),
        ),
        CalculoService.verificarSituacao(
          bimestre,
          i,
          mediaMinima: professor.mediaMinima,
        ),
        _percentual(turma.percentualPresenca(i)),
      ]);
    }

    final mediaGeral = CalculoService.calcularMediaGeral(
      bimestre,
      mediaMinima: professor.mediaMinima,
    );

    final aprovados = CalculoService.calcularPercentualAprovados(
      bimestre,
      mediaMinima: professor.mediaMinima,
    );

    final double tamanhoFonte = bimestre.avaliacoes.length > 6 ? 7.5 : 8.5;

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _cabecalho(
          titulo: 'Relatório da turma',
          subtitulo:
              '${turma.nome} • ${turma.curso} • '
              '${bimestre.numero}º bimestre',
        ),
        footer: (context) => _rodape(context, professor.nome),
        build: (context) {
          return [
            pw.Row(
              children: [
                _resumo('Média geral', _formatar(mediaGeral)),
                pw.SizedBox(width: 14),
                _resumo(
                  'Aprovados',
                  aprovados == null ? '—' : _percentual(aprovados),
                ),
                pw.SizedBox(width: 14),
                _resumo('Alunos', turma.alunos.length.toString()),
                pw.SizedBox(width: 14),
                _resumo('Média mínima', _formatar(professor.mediaMinima)),
              ],
            ),
            _tituloSecao('Notas e situação'),
            if (linhas.isEmpty)
              pw.Text(
                'Nenhum aluno cadastrado.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF6B7280),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  'Matrícula',
                  'Aluno',
                  ...bimestre.avaliacoes,
                  'Recuperação',
                  'Média final',
                  'Situação',
                  'Frequência',
                ],
                data: linhas,
                columnWidths: {
                  0: pw.FlexColumnWidth(1.1),
                  1: pw.FlexColumnWidth(2.6),
                  for (int j = 0; j < bimestre.avaliacoes.length; j++)
                    (j + 2): pw.FlexColumnWidth(0.8),
                  (bimestre.avaliacoes.length + 2): pw.FlexColumnWidth(1.0),
                  (bimestre.avaliacoes.length + 3): pw.FlexColumnWidth(0.9),
                  (bimestre.avaliacoes.length + 4): pw.FlexColumnWidth(1.3),
                },
                headerStyle: pw.TextStyle(
                  fontSize: tamanhoFonte,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1F2430'),
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EEF0F8'),
                ),
                cellStyle: pw.TextStyle(
                  fontSize: tamanhoFonte,
                  color: const PdfColor.fromInt(0xFF374151),
                ),
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                },
                headerAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE5E7EB),
                    width: 1,
                  ),
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
              ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Gerado em ${_dataAtual()} pelo Diário de Classe.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF9CA3AF),
              ),
            ),
          ];
        },
      ),
    );

    return documento.save();
  }

  static pw.Widget _resumo(String titulo, String valor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F5F6FB'),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF6B7280),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1F2430'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Salva o boletim para download/compartilhamento.
  static Future<void> exportarBoletim({
    required Professor professor,
    required Turma turma,
    required int indiceAluno,
  }) async {
    final bytes = await gerarBoletim(
      professor: professor,
      turma: turma,
      indiceAluno: indiceAluno,
    );

    final aluno = turma.alunos[indiceAluno];
    final nomeArquivo = 'boletim_${_slug(aluno.nome)}.pdf';

    await ArquivoService.salvarBytes(nomeArquivo: nomeArquivo, bytes: bytes);
  }

  // Salva o relatório da turma para download/compartilhamento.
  static Future<void> exportarRelatorioTurma({
    required Professor professor,
    required Turma turma,
    required Bimestre bimestre,
  }) async {
    final bytes = await gerarRelatorioTurma(
      professor: professor,
      turma: turma,
      bimestre: bimestre,
    );

    final nomeArquivo =
        'relatorio_${_slug(turma.nome)}_bimestre_${bimestre.numero}.pdf';

    await ArquivoService.salvarBytes(nomeArquivo: nomeArquivo, bytes: bytes);
  }
}
