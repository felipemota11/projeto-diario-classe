import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/aluno.dart';
import 'package:projeto_diario/models/registro_presenca.dart';
import 'package:projeto_diario/models/turma.dart';

void main() {
  late Turma turma;
  setUp(() => turma = Turma(nome: 'A', curso: 'Computação', periodo: 1));

  test('turma nasce com dois bimestres fixos e sincroniza novos alunos', () {
    expect(turma.bimestres.map((b) => b.numero), [1, 2]);
    expect(() => turma.bimestres.clear(), throwsUnsupportedError);
    turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '1'));
    for (final b in turma.bimestres) {
      expect(b.notas, [null]);
      expect(b.provasFinais, [null]);
    }
  });

  test('edição impede matrícula duplicada', () {
    turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
    turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '2'));
    expect(
      () => turma.adicionarAluno(Aluno(nome: 'Outra', matricula: '001')),
      throwsArgumentError,
    );
    expect(
      () =>
          turma.editarAluno(1, nome: 'Bruno', matricula: '001', observacao: ''),
      throwsArgumentError,
    );
    turma.editarAluno(
      0,
      nome: 'Ana Maria',
      matricula: '001',
      observacao: 'Participativa',
    );
    expect(turma.alunos.first.observacao, 'Participativa');
  });

  test('remoção mantém alinhamento das notas e presenças do outro aluno', () {
    turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '1'));
    turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '2'));
    turma.primeiroBimestre.registrarNota(indiceAluno: 1, nota: 4);
    turma.segundoBimestre.registrarNota(indiceAluno: 1, nota: 5);
    turma.segundoBimestre.registrarProvaFinal(indiceAluno: 1, nota: 9);
    turma.adicionarPresenca('2026-11-10');
    turma.alternarPresenca(registro: 0, aluno: 1);
    turma.removerAlunoNoIndice(0);
    expect(turma.alunos.single.nome, 'Bruno');
    expect(turma.primeiroBimestre.notas, [4]);
    expect(turma.segundoBimestre.notas, [5]);
    expect(turma.segundoBimestre.provasFinais, [9]);
    expect(turma.presencas.single.presentes, [false]);
  });

  test('frequência sem aulas é pendente e calcula faltas por data', () {
    turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '1'));
    expect(turma.percentualPresenca(0), isNull);
    turma.adicionarPresenca('2026-11-10');
    turma.adicionarPresenca('2026-11-11');
    turma.alternarPresenca(registro: 0, aluno: 0);
    expect(turma.percentualPresenca(0), 50);
    expect(() => turma.adicionarPresenca('2026-11-10'), throwsArgumentError);
    turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '2'));
    expect(turma.percentualPresenca(1), 100);
  });

  test('datas são exibidas no padrão brasileiro', () {
    expect(RegistroPresenca.dataParaIso(DateTime(2026, 11, 9)), '2026-11-09');
    expect(RegistroPresenca.formatarData('2026-11-09'), '09/11/2026');
    expect(RegistroPresenca.formatarData('inválida'), 'inválida');
  });
}
