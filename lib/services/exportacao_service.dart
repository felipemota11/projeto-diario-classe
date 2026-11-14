import 'package:csv/csv.dart';

import '../models/turma.dart';
import '../models/bimestre.dart';
import 'arquivo_service.dart';
import 'calculo_service.dart';

class ExportacaoService {
  // Formata notas usando vírgula como separador decimal.
  static String _formatarNota(double? nota) {
    if (nota == null) {
      return '';
    }

    return nota.toStringAsFixed(2).replaceAll('.', ',');
  }

  // Cria o conteúdo CSV de uma turma e de um bimestre.
  static String gerarCsv({
    required String nomeProfessor,
    required Turma turma,
    required Bimestre bimestre,
    double mediaMinima = CalculoService.mediaMinimaPadrao,
  }) {
    final linhas = <List<dynamic>>[
      [
        'Professor',
        'Turma',
        'Curso',
        'Período',
        'Bimestre',
        'Matrícula',
        'Aluno',
        ...bimestre.avaliacoes,
        'Média das avaliações',
        'Recuperação',
        'Média final',
        'Situação',
      ],
    ];

    for (int i = 0; i < turma.alunos.length; i++) {
      final aluno = turma.alunos[i];

      final notas = List<String>.generate(bimestre.avaliacoes.length, (j) {
        final lancada = bimestre.notasLancadas[i][j];

        return _formatarNota(lancada ? bimestre.notas[i][j] : null);
      });

      final mediaProvas = CalculoService.calcularMediaProvas(bimestre, i);

      final recuperacao = bimestre.recuperacoes[i];

      final mediaFinal = CalculoService.calcularMedia(
        bimestre,
        i,
        mediaMinima: mediaMinima,
      );

      final situacao = CalculoService.verificarSituacao(
        bimestre,
        i,
        mediaMinima: mediaMinima,
      );

      linhas.add([
        nomeProfessor,
        turma.nome,
        turma.curso,
        turma.periodo,
        '${bimestre.numero}º',
        aluno.matricula,
        aluno.nome,
        ...notas,
        _formatarNota(mediaProvas),
        _formatarNota(recuperacao),
        _formatarNota(mediaFinal),
        situacao,
      ]);
    }

    // Configuração pronta para abrir no Excel.
    return excel.encode(linhas);
  }

  // Gera e disponibiliza o arquivo para download.
  static Future<void> exportarCsv({
    required String nomeProfessor,
    required Turma turma,
    required Bimestre bimestre,
    double mediaMinima = CalculoService.mediaMinimaPadrao,
  }) async {
    final conteudo = gerarCsv(
      nomeProfessor: nomeProfessor,
      turma: turma,
      bimestre: bimestre,
      mediaMinima: mediaMinima,
    );

    final nomeTurma = turma.nome.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]'),
      '_',
    );

    final nomeArquivo =
        'diario_classe_${nomeTurma}_bimestre_${bimestre.numero}.csv';

    await ArquivoService.salvarTexto(
      nomeArquivo: nomeArquivo,
      conteudo: conteudo,
    );
  }
}
