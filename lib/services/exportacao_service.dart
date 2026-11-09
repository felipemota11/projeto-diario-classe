import 'package:csv/csv.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';

import '../models/turma.dart';
import '../models/bimestre.dart';
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
        'Prova 1',
        'Prova 2',
        'Média das provas',
        'Recuperação',
        'Média final',
        'Situação',
      ],
    ];

    for (int i = 0; i < turma.alunos.length; i++) {
      final aluno = turma.alunos[i];

      final prova1Lancada = bimestre.notasLancadas[i][0];

      final prova2Lancada = bimestre.notasLancadas[i][1];

      final prova1 = prova1Lancada ? bimestre.notas[i][0] : null;

      final prova2 = prova2Lancada ? bimestre.notas[i][1] : null;

      final mediaProvas = CalculoService.calcularMediaProvas(bimestre, i);

      final recuperacao = bimestre.recuperacoes[i];

      final mediaFinal = CalculoService.calcularMedia(bimestre, i);

      final situacao = CalculoService.verificarSituacao(bimestre, i);

      linhas.add([
        nomeProfessor,
        turma.nome,
        turma.curso,
        turma.periodo,
        '${bimestre.numero}º',
        aluno.matricula,
        aluno.nome,
        _formatarNota(prova1),
        _formatarNota(prova2),
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
  }) async {
    final conteudo = gerarCsv(
      nomeProfessor: nomeProfessor,
      turma: turma,
      bimestre: bimestre,
    );

    final nomeTurma = turma.nome.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]'),
      '_',
    );

    final nomeArquivo =
        'diario_classe_${nomeTurma}_bimestre_${bimestre.numero}.csv';

    await FlutterFileSaver().writeFileAsString(
      fileName: nomeArquivo,
      data: conteudo,
    );
  }
}
