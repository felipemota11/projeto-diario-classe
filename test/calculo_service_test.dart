import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/bimestre.dart';
import 'package:projeto_diario/services/calculo_service.dart';

void main() {
  group('CalculoService', () {
    late Bimestre bimestre;

    setUp(() {
      bimestre = Bimestre(numero: 1, quantidadeAlunos: 3);
    });

    test('média das provas fica pendente até as duas notas serem lançadas', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);

      expect(CalculoService.calcularMediaProvas(bimestre, 0), isNull);

      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 6);

      expect(CalculoService.calcularMediaProvas(bimestre, 0), 7);
    });

    test('média usa todas as avaliações personalizadas', () {
      final Bimestre comTres = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: const ['Prova', 'Trabalho', 'Teste'],
      );

      comTres.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
      comTres.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 6);

      // A média fica pendente enquanto o teste não for lançado.
      expect(CalculoService.calcularMediaProvas(comTres, 0), isNull);

      comTres.registrarNota(indiceAluno: 0, avaliacao: 3, nota: 10);

      expect(CalculoService.calcularMediaProvas(comTres, 0), 8);
    });

    test('média final usa apenas as provas quando atinge a média mínima', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 8);
      bimestre.registrarRecuperacao(indiceAluno: 0, nota: 10);

      expect(CalculoService.calcularMedia(bimestre, 0), 8);
      expect(CalculoService.recuperacaoAplicada(bimestre, 0), isFalse);
    });

    test('média final aplica a recuperação quando fica abaixo da mínima', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 4);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 5);
      bimestre.registrarRecuperacao(indiceAluno: 0, nota: 9);

      // (4 + 5) / 2 = 4,5 e (4,5 + 9) / 2 = 6,75
      expect(CalculoService.calcularMedia(bimestre, 0), 6.75);
      expect(CalculoService.recuperacaoAplicada(bimestre, 0), isTrue);
    });

    test('média mínima configurável altera a aplicação da recuperação', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 6);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 7);
      bimestre.registrarRecuperacao(indiceAluno: 0, nota: 10);

      // Com média mínima 7,0 a recuperação é aplicada: (6,5 + 10) / 2.
      expect(CalculoService.calcularMedia(bimestre, 0), 8.25);

      // Com média mínima 6,0 a média das provas já basta.
      expect(CalculoService.calcularMedia(bimestre, 0, mediaMinima: 6), 6.5);
    });

    test('situação do aluno considera a média mínima informada', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 6);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 7);

      expect(CalculoService.verificarSituacao(bimestre, 0), 'Abaixo da média');
      expect(
        CalculoService.verificarSituacao(bimestre, 0, mediaMinima: 6),
        'Aprovado',
      );
    });

    test('calcula a nota necessária na recuperação', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 4);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 5);

      expect(CalculoService.notaNecessariaRecuperacao(bimestre, 0), 9.5);
    });

    test('nota necessária é nula quando as provas já atingem a média', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 7);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 8);

      expect(CalculoService.notaNecessariaRecuperacao(bimestre, 0), isNull);
    });

    test('nota necessária pode ultrapassar 10 quando é inalcançável', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 0);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 0);

      expect(CalculoService.notaNecessariaRecuperacao(bimestre, 0), 14);
    });

    test('média geral e percentual de aprovados ignoram pendentes', () {
      // Aluno 0: aprovado, média 8.
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 8);

      // Aluno 1: abaixo da média, média 4.
      bimestre.registrarNota(indiceAluno: 1, avaliacao: 1, nota: 4);
      bimestre.registrarNota(indiceAluno: 1, avaliacao: 2, nota: 4);

      // Aluno 2: pendente.

      expect(CalculoService.calcularMediaGeral(bimestre), 6);
      expect(CalculoService.calcularPercentualAprovados(bimestre), 50);
    });

    test('maior e menor nota consideram recuperações lançadas', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 6);
      bimestre.registrarRecuperacao(indiceAluno: 0, nota: 9);
      bimestre.registrarNota(indiceAluno: 1, avaliacao: 1, nota: 3);

      expect(CalculoService.obterMaiorNotaLancada(bimestre), 9);
      expect(CalculoService.obterMenorNotaLancada(bimestre), 3);
    });

    test('pendências listam avaliações não lançadas', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);

      expect(CalculoService.pendenciasDoAluno(bimestre, 0), ['Prova 2']);
    });

    test('pendências incluem a recuperação necessária', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 4);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 5);

      expect(CalculoService.pendenciasDoAluno(bimestre, 0), ['Recuperação']);
    });

    test('pendências não incluem recuperação já lançada', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 4);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 5);
      bimestre.registrarRecuperacao(indiceAluno: 0, nota: 9);

      expect(CalculoService.pendenciasDoAluno(bimestre, 0), isEmpty);
    });

    test('pendências respeitam a média mínima configurada', () {
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 6);
      bimestre.registrarNota(indiceAluno: 0, avaliacao: 2, nota: 7);

      expect(CalculoService.pendenciasDoAluno(bimestre, 0), ['Recuperação']);
      expect(
        CalculoService.pendenciasDoAluno(bimestre, 0, mediaMinima: 6),
        isEmpty,
      );
    });

    test('pendências usam os nomes personalizados das avaliações', () {
      final Bimestre comTres = Bimestre(
        numero: 1,
        quantidadeAlunos: 1,
        avaliacoes: const ['Prova', 'Trabalho', 'Teste'],
      );

      comTres.registrarNota(indiceAluno: 0, avaliacao: 1, nota: 8);

      expect(CalculoService.pendenciasDoAluno(comTres, 0), [
        'Trabalho',
        'Teste',
      ]);
    });
  });
}
