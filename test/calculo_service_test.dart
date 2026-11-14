import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/bimestre.dart';
import 'package:projeto_diario/services/calculo_service.dart';

import 'support/fixtures.dart';

void main() {
  test('média semestral aguarda ambas as provas, inclusive nota zero', () {
    final t = criarProfessor().turmas.single;
    t.primeiroBimestre.registrarNota(indiceAluno: 0, nota: 0);
    expect(
      CalculoService.calcularMediaSemestral(
        t.primeiroBimestre,
        t.segundoBimestre,
        0,
      ),
      isNull,
    );
    t.segundoBimestre.registrarNota(indiceAluno: 0, nota: 10);
    expect(
      CalculoService.calcularMediaSemestral(
        t.primeiroBimestre,
        t.segundoBimestre,
        0,
      ),
      5,
    );
  });

  test('fronteira de aprovação e dispensa de prova final', () {
    expect(CalculoService.situacaoDasNotas(7, null), 'Aprovado');
    expect(CalculoService.resultadoDasNotas(7, 0), 7);
    expect(CalculoService.situacaoDasNotas(6.99, null), 'Prova final pendente');
    expect(CalculoService.situacaoDasNotas(null, null), 'Pendente');
  });

  test('resultado após final respeita média configurada', () {
    expect(CalculoService.resultadoDasNotas(6, 8), 7);
    expect(CalculoService.situacaoDasNotas(6, 8), 'Aprovado após final');
    expect(CalculoService.situacaoDasNotas(6, 7), 'Reprovado');
    expect(
      CalculoService.situacaoDasNotas(6, null, mediaMinima: 6),
      'Aprovado',
    );
    expect(CalculoService.resultadoDasNotas(0, null, mediaMinima: 0), 0);
    expect(CalculoService.resultadoDasNotas(9, 10, mediaMinima: 10), 9.5);
  });

  test(
    'prova final só pode ser registrada com duas provas abaixo da mínima',
    () {
      final t = criarProfessor().turmas.single;
      final b1 = t.primeiroBimestre;
      final b2 = t.segundoBimestre;
      expect(
        () => CalculoService.registrarProvaFinal(b1, b2, 0, 10),
        throwsStateError,
      );
      b1.registrarNota(indiceAluno: 0, nota: 8);
      b2.registrarNota(indiceAluno: 0, nota: 8);
      expect(
        () => CalculoService.registrarProvaFinal(b1, b2, 0, 10),
        throwsStateError,
      );
      b1.registrarNota(indiceAluno: 0, nota: 4);
      b2.registrarNota(indiceAluno: 0, nota: 5);
      expect(CalculoService.notaNecessariaProvaFinal(b1, b2, 0), 9.5);
      CalculoService.registrarProvaFinal(b1, b2, 0, 9.5);
      expect(CalculoService.calcularMediaFinalSemestral(b1, b2, 0), 7);
      expect(
        CalculoService.verificarSituacaoSemestral(b1, b2, 0),
        'Aprovado após final',
      );
      CalculoService.limparProvaFinal(b2, 0);
      expect(
        CalculoService.verificarSituacaoSemestral(b1, b2, 0),
        'Prova final pendente',
      );
    },
  );

  test(
    'nota necessária pode superar dez e pendências usam nomes personalizados',
    () {
      final t = criarProfessor().turmas.single;
      final b1 = t.primeiroBimestre;
      final b2 = t.segundoBimestre;
      b1.renomearProva('Projeto');
      expect(CalculoService.pendenciasSemestrais(b1, b2, 0), [
        'Projeto',
        'Prova 2',
      ]);
      b1.registrarNota(indiceAluno: 0, nota: 0);
      b2.registrarNota(indiceAluno: 0, nota: 0);
      expect(CalculoService.notaNecessariaProvaFinal(b1, b2, 0), 14);
      expect(CalculoService.pendenciasSemestrais(b1, b2, 0), ['Prova final']);
    },
  );

  test(
    'rejeita semestre invertido, alunos inválidos e média mínima inválida',
    () {
      final t = criarProfessor().turmas.single;
      expect(
        () => CalculoService.calcularMediaSemestral(
          t.segundoBimestre,
          t.primeiroBimestre,
          0,
        ),
        throwsArgumentError,
      );
      expect(
        () => CalculoService.calcularMediaSemestral(
          t.primeiroBimestre,
          t.segundoBimestre,
          1,
        ),
        throwsRangeError,
      );
      for (final minima in [-1.0, 11.0, double.nan]) {
        expect(
          () => CalculoService.resultadoDasNotas(7, null, mediaMinima: minima),
          throwsArgumentError,
        );
      }
      expect(
        () => CalculoService.mediaDasNotas(double.infinity, 7),
        throwsArgumentError,
      );
      final outro = Bimestre(numero: 2, quantidadeAlunos: 0);
      expect(
        () =>
            CalculoService.calcularMediaSemestral(t.primeiroBimestre, outro, 0),
        throwsArgumentError,
      );
    },
  );
}
