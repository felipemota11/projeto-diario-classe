import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/aluno.dart';
import 'package:projeto_diario/models/bimestre.dart';
import 'package:projeto_diario/models/professor.dart';
import 'package:projeto_diario/models/turma.dart';
import 'package:projeto_diario/services/armazenamento_service.dart';
import 'package:projeto_diario/services/exportacao_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  const chave = 'diario_classe_dados_v1';

  group('Compatibilidade do armazenamento', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test(
      'salva e carrega turmas, avaliações dinâmicas e recuperações',
      () async {
        final professor = Professor(nome: 'Ana');

        final turma = Turma(
          nome: 'Turma A',
          curso: 'Ciência da Computação',
          periodo: 1,
        );

        turma.adicionarAluno(Aluno(nome: 'Aluno 1', matricula: '2026001'));
        turma.adicionarBimestre(1);

        final bimestre = turma.bimestres.first;

        bimestre.adicionarAvaliacao('Trabalho');
        bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
        bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 9);
        bimestre.registrarNota(indiceAluno: 0, avaliacao: 3, nota: 10);
        bimestre.registrarRecuperacao(indiceAluno: 0, nota: 7.5);

        professor.adicionarTurma(turma);

        await ArmazenamentoService.salvarProfessor(professor);

        final carregado = await ArmazenamentoService.carregarProfessor();

        expect(carregado.nome, 'Ana');
        expect(carregado.turmas.length, 1);
        expect(carregado.turmas.first.alunos.first.observacao, isEmpty);

        final bimestreCarregado = carregado.turmas.first.bimestres.first;

        expect(bimestreCarregado.avaliacoes, [
          'Prova 1',
          'Prova 2',
          'Trabalho',
        ]);
        expect(bimestreCarregado.notas[0], [8, 9, 10]);
        expect(bimestreCarregado.notasLancadas[0], [true, true, true]);
        expect(bimestreCarregado.recuperacoes[0], 7.5);
      },
    );

    test('inclui a versão do schema no JSON exportado', () {
      final professor = Professor(nome: 'Ana');

      final dados = jsonDecode(
        ArmazenamentoService.exportarJson(professor),
      ) as Map<String, dynamic>;

      expect(dados['versao'], 3);
      expect(dados['mediaMinima'], 7.0);
    });

    test('migra dados antigos sem o campo de avaliações', () async {
      final preferences = SharedPreferencesAsync();

      await preferences.setString(
        chave,
        jsonEncode({
          'nome': 'Professor',
          'turmas': [
            {
              'nome': 'Turma Antiga',
              'curso': 'Curso',
              'periodo': 1,
              'alunos': [
                {'nome': 'Aluno', 'matricula': '1'},
              ],
              'bimestres': [
                {
                  'numero': 1,
                  'notas': [
                    [8, 9],
                  ],
                  'notasLancadas': [
                    [true, true],
                  ],
                  'recuperacoes': [null],
                },
              ],
            },
          ],
        }),
      );

      final professor = await ArmazenamentoService.carregarProfessor();

      expect(professor.turmas.first.bimestres.first.avaliacoes, [
        'Prova 1',
        'Prova 2',
      ]);
      expect(professor.turmas.first.bimestres.first.notas[0], [8, 9]);
    });

    test('reconstrói colunas extras de dados antigos', () async {
      final preferences = SharedPreferencesAsync();

      await preferences.setString(
        chave,
        jsonEncode({
          'nome': 'Professor',
          'turmas': [
            {
              'nome': 'Turma Antiga',
              'curso': 'Curso',
              'periodo': 1,
              'alunos': [
                {'nome': 'Aluno', 'matricula': '1'},
              ],
              'bimestres': [
                {
                  'numero': 1,
                  'notas': [
                    [8, 9, 10],
                  ],
                  'notasLancadas': [
                    [true, true, true],
                  ],
                  'recuperacoes': [null],
                },
              ],
            },
          ],
        }),
      );

      final professor = await ArmazenamentoService.carregarProfessor();
      final bimestre = professor.turmas.first.bimestres.first;

      expect(bimestre.avaliacoes, [
        'Avaliação 1',
        'Avaliação 2',
        'Avaliação 3',
      ]);
      expect(bimestre.notas[0], [8, 9, 10]);
    });

    test('aceita notas antigas com vírgula decimal', () async {
      final preferences = SharedPreferencesAsync();

      await preferences.setString(
        chave,
        jsonEncode({
          'nome': 'Professor',
          'turmas': [
            {
              'nome': 'Turma Antiga',
              'curso': 'Curso',
              'periodo': 1,
              'alunos': [
                {'nome': 'Aluno', 'matricula': '1'},
              ],
              'bimestres': [
                {
                  'numero': 1,
                  'notas': [
                    ['8,5', '9,0'],
                  ],
                  'notasLancadas': [
                    [true, true],
                  ],
                  'recuperacoes': [null],
                },
              ],
            },
          ],
        }),
      );

      final professor = await ArmazenamentoService.carregarProfessor();

      expect(professor.turmas.first.bimestres.first.notas[0], [8.5, 9.0]);
    });

    test('dados corrompidos geram FormatException', () async {
      final preferences = SharedPreferencesAsync();

      await preferences.setString(chave, 'isto não é um JSON válido');

      await expectLater(
        ArmazenamentoService.carregarProfessor(),
        throwsA(isA<FormatException>()),
      );
    });

    test('apaga os dados salvos', () async {
      final professor = Professor(nome: 'Ana');

      await ArmazenamentoService.salvarProfessor(professor);
      await ArmazenamentoService.apagarDados();

      final carregado = await ArmazenamentoService.carregarProfessor();

      expect(carregado.nome, 'Professor');
      expect(carregado.turmas, isEmpty);
    });

    test('tentarSalvarProfessor devolve nulo em caso de sucesso', () async {
      final erro = await ArmazenamentoService.tentarSalvarProfessor(
        Professor(nome: 'Ana'),
      );

      expect(erro, isNull);
    });
  });

  test('gera CSV com colunas dinâmicas de avaliações', () {
    final turma = Turma(nome: 'Turma A', curso: 'Computação', periodo: 1);

    turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '1'));

    final bimestre = Bimestre(
      numero: 1,
      quantidadeAlunos: 1,
      avaliacoes: ['Prova 1', 'Prova 2', 'Trabalho'],
    );

    bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
    bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 9);
    bimestre.registrarNota(indiceAluno: 0, avaliacao: 3, nota: 10);

    final csv = ExportacaoService.gerarCsv(
      nomeProfessor: 'Ana',
      turma: turma,
      bimestre: bimestre,
    );

    expect(csv, contains('Prova 1;Prova 2;Trabalho'));
    expect(csv, contains('Ana;Turma A;Computação;1;1º;1;Ana'));
    expect(csv, contains('8,00;9,00;10,00;9,00;;9,00;Aprovado'));
  });
}
