import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/bimestre.dart';

void main() {
  test('cada bimestre possui uma prova e notas pendentes', () {
    final b = Bimestre(numero: 2, quantidadeAlunos: 2);
    expect(b.nomeProva, 'Prova 2');
    expect(b.notas, [null, null]);
    expect(b.provasFinais, [null, null]);
  });

  test('zero é nota lançada e limpar volta a pendente', () {
    final b = Bimestre(numero: 1, quantidadeAlunos: 1);
    b.registrarNota(indiceAluno: 0, nota: 0);
    expect(b.obterNota(0), 0);
    b.limparNota(indiceAluno: 0);
    expect(b.obterNota(0), isNull);
  });

  test('renomeia a prova preservando notas', () {
    final b = Bimestre(numero: 1, quantidadeAlunos: 1);
    b.registrarNota(indiceAluno: 0, nota: 8.75);
    b.renomearProva('  Trabalho prático  ');
    expect(b.nomeProva, 'Trabalho prático');
    expect(b.obterNota(0), 8.75);
    expect(() => b.renomearProva(' '), throwsArgumentError);
    expect(() => b.renomearProva('a' * 41), throwsArgumentError);
  });

  test('rejeita notas inválidas, índices inválidos e terceiro bimestre', () {
    final b = Bimestre(numero: 1, quantidadeAlunos: 1);
    for (final nota in [-1.0, 10.01, double.nan, double.infinity]) {
      expect(
        () => b.registrarNota(indiceAluno: 0, nota: nota),
        throwsArgumentError,
      );
    }
    expect(() => b.obterNota(1), throwsRangeError);
    expect(() => Bimestre(numero: 3, quantidadeAlunos: 0), throwsArgumentError);
    expect(
      () => Bimestre(numero: 1, quantidadeAlunos: -1),
      throwsArgumentError,
    );
  });

  test('a prova final pertence exclusivamente ao segundo bimestre', () {
    final b1 = Bimestre(numero: 1, quantidadeAlunos: 1);
    final b2 = Bimestre(numero: 2, quantidadeAlunos: 1);
    expect(
      () => b1.registrarProvaFinal(indiceAluno: 0, nota: 8),
      throwsStateError,
    );
    expect(() => b1.limparProvaFinal(0), throwsStateError);
    b2.registrarProvaFinal(indiceAluno: 0, nota: 8);
    expect(b2.provasFinais.single, 8);
    b2.limparProvaFinal(0);
    expect(b2.provasFinais.single, isNull);
  });
}
