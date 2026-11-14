import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/bimestre.dart';

void main() {
  group('Bimestre', () {
    test('começa com as duas avaliações padrão e estruturas alinhadas', () {
      final bimestre = Bimestre(numero: 1, quantidadeAlunos: 2);

      expect(bimestre.avaliacoes, ['Prova 1', 'Prova 2']);
      expect(bimestre.quantidadeAvaliacoes, 2);
      expect(bimestre.notas, hasLength(2));
      expect(bimestre.notasLancadas, hasLength(2));
      expect(bimestre.notas[0], hasLength(2));
      expect(bimestre.notasLancadas[0], hasLength(2));
    });

    test('adiciona uma avaliação mantendo as notas existentes', () {
      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 2,
        avaliacoes: const ['Prova', 'Trabalho'],
      );

      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 6);

      bimestre.adicionarAvaliacao('Teste');

      expect(bimestre.avaliacoes, ['Prova', 'Trabalho', 'Teste']);
      expect(bimestre.notas[0], [8.0, 6.0, 0.0]);
      expect(bimestre.notasLancadas[0], [true, true, false]);
      expect(bimestre.notasLancadas[1], [false, false, false]);
    });

    test('renomeia a avaliação sem alterar as notas', () {
      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: const ['Prova', 'Trabalho'],
      );

      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 9);
      bimestre.renomearAvaliacao(indice: 1, nome: 'Atividade');

      expect(bimestre.avaliacoes, ['Prova', 'Atividade']);
      expect(bimestre.notas[0][1], 9);
      expect(bimestre.notasLancadas[0][1], isTrue);
    });

    test('remove a avaliação e as notas dela', () {
      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: const ['Prova', 'Trabalho', 'Teste'],
      );

      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 5);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 8);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 3, nota: 10);

      bimestre.removerAvaliacao(1);

      expect(bimestre.avaliacoes, ['Prova', 'Teste']);
      expect(bimestre.notas[0], [5.0, 10.0]);
      expect(bimestre.notasLancadas[0], [true, true]);
    });

    test('não permite remover a única avaliação', () {
      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: const ['Prova'],
      );

      expect(() => bimestre.removerAvaliacao(0), throwsStateError);
    });

    test('valida nomes vazios, duplicados e acima do limite', () {
      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: const ['Prova'],
      );

      expect(() => bimestre.adicionarAvaliacao('  '), throwsArgumentError);
      expect(() => bimestre.adicionarAvaliacao('prova'), throwsArgumentError);
      expect(() => bimestre.adicionarAvaliacao('a' * 41), throwsArgumentError);
    });

    test('respeita o limite máximo de avaliações', () {
      final nomes = List<String>.generate(
        Bimestre.limiteAvaliacoes,
        (i) => 'Avaliação ${i + 1}',
      );

      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: nomes,
      );

      expect(() => bimestre.adicionarAvaliacao('Extra'), throwsStateError);
    });

    test('conta quantas notas foram lançadas por avaliação', () {
      final bimestre = Bimestre(
        numero: 1,
        quantidadeAlunos: 3,
        avaliacoes: const ['Prova', 'Trabalho'],
      );

      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 7);
      bimestre.registrarNota(indiceAluno: 2, avaliacao: 1, nota: 9);

      expect(bimestre.quantidadeNotasLancadas(0), 2);
      expect(bimestre.quantidadeNotasLancadas(1), 0);
    });
  });
}
