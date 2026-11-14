import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/professor.dart';
import '../models/turma.dart';
import '../theme/app_palette.dart';
import 'arquivo_service.dart';
import 'calculo_service.dart';

/// Gera boletins e relatórios em PDF usando as mesmas regras da aplicação.
class PdfService {
  static pw.ThemeData? _tema;
  static pw.MemoryImage? _icone;

  static Future<pw.ThemeData> _carregarTema() async {
    if (_tema != null) return _tema!;
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final negrito = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final icone = await rootBundle.load('assets/images/icone_diario.png');
    _icone = pw.MemoryImage(
      icone.buffer.asUint8List(icone.offsetInBytes, icone.lengthInBytes),
    );
    return _tema = pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(negrito),
    );
  }

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
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(_icone!, width: 34, height: 34, fit: pw.BoxFit.cover),
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
                    color: PdfColor.fromInt(AppPalette.lightText),
                  ),
                ),
                pw.Text(
                  subtitulo,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(AppPalette.lightTextMuted),
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
              color: PdfColor.fromInt(AppPalette.lightTextMuted),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(AppPalette.lightTextMuted),
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
          color: PdfColor.fromInt(AppPalette.lightText),
        ),
      ),
    );
  }

  // Boletim individual com a regra semestral, sem recuperação por bimestre.
  static Future<Uint8List> gerarBoletimSemestral({
    required Professor professor,
    required Turma turma,
    required int indiceAluno,
  }) async {
    final semestre = (
      primeiro: turma.primeiroBimestre,
      segundo: turma.segundoBimestre,
    );
    if (indiceAluno < 0 || indiceAluno >= turma.alunos.length) {
      throw RangeError('Aluno não encontrado.');
    }

    final aluno = turma.alunos[indiceAluno];
    final primeiro = semestre.primeiro;
    final segundo = semestre.segundo;
    final nota1 = primeiro.obterNota(indiceAluno);
    final nota2 = segundo.obterNota(indiceAluno);
    final media = CalculoService.calcularMediaSemestral(
      primeiro,
      segundo,
      indiceAluno,
    );
    final precisaFinal = media != null && media < professor.mediaMinima;
    final provaFinal = precisaFinal ? segundo.provasFinais[indiceAluno] : null;
    final resultado = CalculoService.calcularMediaFinalSemestral(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: professor.mediaMinima,
    );
    final situacao = CalculoService.verificarSituacaoSemestral(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: professor.mediaMinima,
    );
    final frequencia = turma.percentualPresenca(indiceAluno);

    final documento = pw.Document(
      title: 'Boletim semestral - ${aluno.nome}',
      theme: await _carregarTema(),
    );
    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _cabecalho(
          titulo: 'Boletim semestral',
          subtitulo:
              '${turma.nome} • ${turma.curso} • ${turma.periodo}º período',
        ),
        footer: (context) => _rodape(context, professor.nome),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(AppPalette.lightBackground),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  aluno.nome,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Matrícula: ${aluno.matricula}'),
                pw.Text('Frequência: ${_percentual(frequencia)}'),
                pw.Text('Média mínima: ${_formatar(professor.mediaMinima)}'),
              ],
            ),
          ),
          _tituloSecao('Avaliações do semestre'),
          pw.TableHelper.fromTextArray(
            border: null,
            headers: [
              primeiro.nomeProva,
              segundo.nomeProva,
              'Média semestral',
              'Prova final',
              'Média final',
            ],
            data: [
              [
                _formatar(nota1),
                _formatar(nota2),
                _formatar(media),
                _formatar(provaFinal),
                _formatar(resultado),
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(AppPalette.lightContainer),
            ),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.all(7),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Situação acadêmica: $situacao',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Média semestral = (nota do 1º bimestre + nota do 2º bimestre) / 2.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if (precisaFinal)
            pw.Text(
              'Média após prova final = (média semestral + prova final) / 2.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          if (aluno.observacao.trim().isNotEmpty) ...[
            _tituloSecao('Observações'),
            pw.Text(
              aluno.observacao.trim(),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Gerado em ${_dataAtual()} pelo Diário de Classe.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return documento.save();
  }

  // Relatório completo com uma prova em cada bimestre e prova final única.
  static Future<Uint8List> gerarRelatorioSemestral({
    required Professor professor,
    required Turma turma,
  }) async {
    final semestre = (
      primeiro: turma.primeiroBimestre,
      segundo: turma.segundoBimestre,
    );
    final primeiro = semestre.primeiro;
    final segundo = semestre.segundo;
    final minima = professor.mediaMinima;
    final linhas = <List<String>>[];
    int aprovados = 0;
    int reprovados = 0;
    int pendentes = 0;
    int concluidos = 0;
    double somaMedias = 0;

    for (int i = 0; i < turma.alunos.length; i++) {
      final aluno = turma.alunos[i];
      final media = CalculoService.calcularMediaSemestral(primeiro, segundo, i);
      final mediaFinal = CalculoService.calcularMediaFinalSemestral(
        primeiro,
        segundo,
        i,
        mediaMinima: minima,
      );
      final situacao = CalculoService.verificarSituacaoSemestral(
        primeiro,
        segundo,
        i,
        mediaMinima: minima,
      );
      final provaFinal = media != null && media < minima
          ? segundo.provasFinais[i]
          : null;

      if (situacao.startsWith('Aprovado')) {
        aprovados++;
      } else if (situacao == 'Reprovado') {
        reprovados++;
      } else {
        pendentes++;
      }
      if (mediaFinal != null) {
        somaMedias += mediaFinal;
        concluidos++;
      }

      linhas.add([
        aluno.matricula,
        aluno.nome,
        _formatar(primeiro.obterNota(i)),
        _formatar(segundo.obterNota(i)),
        _formatar(media),
        _formatar(provaFinal),
        _formatar(mediaFinal),
        situacao,
        _percentual(turma.percentualPresenca(i)),
      ]);
    }

    final documento = pw.Document(
      title: 'Relatório semestral - ${turma.nome}',
      theme: await _carregarTema(),
    );
    final mediaGeral = concluidos == 0 ? null : somaMedias / concluidos;
    final percentual = concluidos == 0 ? null : (aprovados / concluidos) * 100;
    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(27),
        header: (context) => _cabecalho(
          titulo: 'Relatório semestral da turma',
          subtitulo:
              '${turma.nome} • ${turma.curso} • ${turma.periodo}º período',
        ),
        footer: (context) => _rodape(context, professor.nome),
        build: (context) => [
          pw.Row(
            children: [
              _resumo('Média final geral', _formatar(mediaGeral)),
              pw.SizedBox(width: 10),
              _resumo('Aprovados', aprovados.toString()),
              pw.SizedBox(width: 10),
              _resumo('Pendentes', pendentes.toString()),
              pw.SizedBox(width: 10),
              _resumo('Reprovados', reprovados.toString()),
            ],
          ),
          pw.SizedBox(height: 9),
          pw.Text(
            'Aprovação entre alunos com resultado concluído: '
            '${_percentual(percentual)} • Média mínima: ${_formatar(minima)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          _tituloSecao('Notas e situação acadêmica'),
          if (linhas.isEmpty)
            pw.Text('Nenhum aluno cadastrado.')
          else
            pw.TableHelper.fromTextArray(
              border: null,
              headers: [
                'Matrícula',
                'Aluno',
                'B1',
                'B2',
                'Média',
                'Prova final',
                'Média final',
                'Situação',
                'Frequência',
              ],
              data: linhas,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.15),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(.6),
                3: const pw.FlexColumnWidth(.6),
                4: const pw.FlexColumnWidth(.7),
                5: const pw.FlexColumnWidth(.85),
                6: const pw.FlexColumnWidth(.8),
                7: const pw.FlexColumnWidth(1.65),
                8: const pw.FlexColumnWidth(.85),
              },
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(AppPalette.lightContainer),
              ),
              headerAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 7,
              ),
            ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Gerado em ${_dataAtual()} pelo Diário de Classe. '
            'Semestre composto por dois bimestres e uma única prova final, se necessária.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return documento.save();
  }

  static Future<void> exportarRelatorioSemestral({
    required Professor professor,
    required Turma turma,
  }) async {
    final bytes = await gerarRelatorioSemestral(
      professor: professor,
      turma: turma,
    );
    await ArquivoService.salvarBytes(
      nomeArquivo: 'relatorio_semestral_${_slug(turma.nome)}.pdf',
      bytes: bytes,
    );
  }

  static pw.Widget _resumo(String titulo, String valor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(AppPalette.lightBackground),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(AppPalette.lightTextMuted),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(AppPalette.lightText),
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
    final bytes = await gerarBoletimSemestral(
      professor: professor,
      turma: turma,
      indiceAluno: indiceAluno,
    );

    final aluno = turma.alunos[indiceAluno];
    final nomeArquivo = 'boletim_${_slug(aluno.nome)}.pdf';

    await ArquivoService.salvarBytes(nomeArquivo: nomeArquivo, bytes: bytes);
  }
}
