import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/aluno.dart';
import 'package:projeto_diario/models/professor.dart';
import 'package:projeto_diario/models/turma.dart';
import 'package:projeto_diario/services/armazenamento_service.dart';

void main() {
  group('ArmazenamentoService', () {
    test('exporta e importa todos os dados preservando o conteúdo', () {
      final professor = Professor(nome: 'Maria', mediaMinima: 6.5);
      final turma = Turma(nome: 'Turma A', curso: 'Computação', periodo: 2);

      turma.adicionarAluno(
        Aluno(nome: 'Ana', matricula: '001', observacao: 'Bom desempenho'),
      );
      turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '002'));
      turma.adicionarBimestre(
        1,
        avaliacoes: const ['Prova', 'Trabalho', 'Teste'],
      );
      turma.bimestres.single.registrarNota(
        indiceAluno: 0,
        avaliacao: 1,
        nota: 8,
      );
      turma.bimestres.single.registrarNota(
        indiceAluno: 0,
        avaliacao: 2,
        nota: 6,
      );
      turma.bimestres.single.registrarNota(
        indiceAluno: 0,
        avaliacao: 3,
        nota: 9,
      );
      turma.bimestres.single.registrarRecuperacao(indiceAluno: 0, nota: 9);
      turma.adicionarPresenca('2026-11-10');
      turma.alternarPresenca(registro: 0, aluno: 0);
      turma.arquivada = true;

      professor.adicionarTurma(turma);

      final String json = ArmazenamentoService.exportarJson(professor);
      final Professor restaurado = ArmazenamentoService.importarJson(json);

      expect(restaurado.nome, 'Maria');
      expect(restaurado.mediaMinima, 6.5);
      expect(restaurado.turmas, hasLength(1));

      final Turma turmaRestaurada = restaurado.turmas.single;

      expect(turmaRestaurada.nome, 'Turma A');
      expect(turmaRestaurada.curso, 'Computação');
      expect(turmaRestaurada.periodo, 2);
      expect(turmaRestaurada.arquivada, isTrue);
      expect(turmaRestaurada.alunos, hasLength(2));
      expect(turmaRestaurada.alunos.first.observacao, 'Bom desempenho');
      expect(turmaRestaurada.bimestres, hasLength(1));
      expect(turmaRestaurada.bimestres.single.avaliacoes, [
        'Prova',
        'Trabalho',
        'Teste',
      ]);
      expect(turmaRestaurada.bimestres.single.notas[0][0], 8);
      expect(turmaRestaurada.bimestres.single.notas[0][1], 6);
      expect(turmaRestaurada.bimestres.single.notas[0][2], 9);
      expect(turmaRestaurada.bimestres.single.recuperacoes[0], 9);
      expect(turmaRestaurada.presencas, hasLength(1));
      expect(turmaRestaurada.presencas.single.data, '2026-11-10');
      expect(turmaRestaurada.presencas.single.presentes, [false, true]);
    });

    test('carrega dados antigos aplicando os novos campos padrão', () {
      final String jsonAntigo = jsonEncode({
        'nome': 'Professor Antigo',
        'turmas': [
          {
            'nome': 'Turma Antiga',
            'curso': 'Curso',
            'periodo': 1,
            'alunos': [
              {'nome': 'Aluno', 'matricula': '123'},
            ],
            'bimestres': [
              {
                'numero': 1,
                'notas': [
                  [7.0, 8.0],
                ],
                'notasLancadas': [
                  [true, true],
                ],
                'recuperacoes': [null],
              },
            ],
          },
        ],
      });

      final Professor professor = ArmazenamentoService.importarJson(jsonAntigo);

      expect(professor.mediaMinima, 7.0);
      expect(professor.turmas.single.arquivada, isFalse);
      expect(professor.turmas.single.alunos.single.observacao, '');
      expect(professor.turmas.single.presencas, isEmpty);
      expect(professor.turmas.single.bimestres.single.avaliacoes, [
        'Prova 1',
        'Prova 2',
      ]);
      expect(professor.turmas.single.bimestres.single.notas[0][1], 8);
    });

    test('rejeita conteúdo que não seja um objeto JSON', () {
      expect(
        () => ArmazenamentoService.importarJson('[]'),
        throwsFormatException,
      );
    });

    test('rejeita JSON sem a lista de turmas', () {
      expect(
        () => ArmazenamentoService.importarJson('{"nome":"Professor"}'),
        throwsFormatException,
      );
    });

    test('rejeita média mínima inválida e assume o padrão', () {
      final String json = jsonEncode({
        'nome': 'Professor',
        'mediaMinima': 20,
        'turmas': <dynamic>[],
      });

      final Professor professor = ArmazenamentoService.importarJson(json);

      expect(professor.mediaMinima, 7.0);
    });
  });
}
