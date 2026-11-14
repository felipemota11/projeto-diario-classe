import 'package:csv/csv.dart';

import '../models/turma.dart';
import 'arquivo_service.dart';
import 'calculo_service.dart';

/// CSV semestral: prova de cada bimestre, prova final e frequência.
class ExportacaoService {
  static String _formatar(double? valor) =>
      valor == null ? '' : valor.toStringAsFixed(2).replaceAll('.', ',');

  static String gerarCsvSemestral({
    required String nomeProfessor,
    required Turma turma,
    double mediaMinima = CalculoService.mediaMinimaPadrao,
  }) {
    final semestre = (
      primeiro: turma.primeiroBimestre,
      segundo: turma.segundoBimestre,
    );
    final primeiro = semestre.primeiro;
    final segundo = semestre.segundo;
    final linhas = <List<dynamic>>[
      [
        'Professor',
        'Curso',
        'Turma',
        'Período',
        'Matrícula',
        'Aluno',
        primeiro.nomeProva,
        segundo.nomeProva,
        'Média semestral',
        'Prova final',
        'Média final',
        'Situação',
        'Frequência (%)',
      ],
    ];
    for (int i = 0; i < turma.alunos.length; i++) {
      final aluno = turma.alunos[i];
      final media = CalculoService.calcularMediaSemestral(primeiro, segundo, i);
      final resultado = CalculoService.calcularMediaFinalSemestral(
        primeiro,
        segundo,
        i,
        mediaMinima: mediaMinima,
      );
      final finalNota = media != null && media < mediaMinima
          ? segundo.provasFinais[i]
          : null;
      linhas.add([
        nomeProfessor,
        turma.curso,
        turma.nome,
        turma.periodo,
        aluno.matricula,
        aluno.nome,
        _formatar(primeiro.obterNota(i)),
        _formatar(segundo.obterNota(i)),
        _formatar(media),
        _formatar(finalNota),
        _formatar(resultado),
        CalculoService.verificarSituacaoSemestral(
          primeiro,
          segundo,
          i,
          mediaMinima: mediaMinima,
        ),
        _formatar(turma.percentualPresenca(i)),
      ]);
    }
    return excel.encode(linhas);
  }

  static Future<void> exportarCsvSemestral({
    required String nomeProfessor,
    required Turma turma,
    double mediaMinima = CalculoService.mediaMinimaPadrao,
  }) async {
    final conteudo = gerarCsvSemestral(
      nomeProfessor: nomeProfessor,
      turma: turma,
      mediaMinima: mediaMinima,
    );
    final nome = turma.nome.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]'),
      '_',
    );
    await ArquivoService.salvarTexto(
      nomeArquivo: 'relatorio_semestral_$nome.csv',
      conteudo: conteudo,
    );
  }
}
