import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/aluno.dart';
import 'package:projeto_diario/models/registro_presenca.dart';
import 'package:projeto_diario/models/turma.dart';

void main() {
  group('Turma', () {
    late Turma turma;

    setUp(() {
      turma = Turma(nome: 'Turma A', curso: 'Computação', periodo: 1);
    });

    test('adiciona alunos e sincroniza os bimestres existentes', () {
      turma.adicionarBimestre(1);
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
      turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '002'));

      expect(turma.alunos, hasLength(2));
      expect(turma.bimestres.single.notas, hasLength(2));
      expect(turma.bimestres.single.notasLancadas, hasLength(2));
      expect(turma.bimestres.single.recuperacoes, hasLength(2));
    });

    test('impede matrícula duplicada', () {
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));

      expect(
        () => turma.adicionarAluno(Aluno(nome: 'Outra Ana', matricula: '001')),
        throwsArgumentError,
      );
    });

    test('edita aluno sem permitir matrícula de outro estudante', () {
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
      turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '002'));

      turma.editarAluno(
        0,
        nome: 'Ana Maria',
        matricula: '001',
        observacao: 'Participativa',
      );

      expect(turma.alunos[0].nome, 'Ana Maria');
      expect(turma.alunos[0].observacao, 'Participativa');

      expect(
        () => turma.editarAluno(
          0,
          nome: 'Ana Maria',
          matricula: '002',
          observacao: '',
        ),
        throwsArgumentError,
      );
    });

    test('remove aluno de todas as estruturas', () {
      turma.adicionarBimestre(1);
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
      turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '002'));

      turma.bimestres.single.registrarNota(
        indiceAluno: 1,
        avaliacao: 1,
        nota: 9,
      );
      turma.adicionarPresenca('2026-11-10');
      turma.alternarPresenca(registro: 0, aluno: 1);

      turma.removerAlunoNoIndice(0);

      expect(turma.alunos, hasLength(1));
      expect(turma.alunos.single.nome, 'Bruno');
      expect(turma.bimestres.single.notas, hasLength(1));
      expect(turma.bimestres.single.notasLancadas, hasLength(1));
      expect(turma.bimestres.single.recuperacoes, hasLength(1));
      expect(turma.presencas.single.presentes, hasLength(1));
      expect(turma.presencas.single.presentes.single, isFalse);
    });

    test('exclui um bimestre específico', () {
      turma.adicionarBimestre(1);
      turma.adicionarBimestre(2);

      turma.removerBimestre(1);

      expect(turma.bimestres, hasLength(1));
      expect(turma.bimestres.single.numero, 2);
    });

    test('registra aulas e calcula percentual de presença', () {
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
      turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '002'));

      turma.adicionarPresenca('2026-11-10');
      turma.adicionarPresenca('2026-11-11');

      turma.alternarPresenca(registro: 0, aluno: 0);
      turma.alternarPresenca(registro: 1, aluno: 0);

      expect(turma.percentualPresenca(0), 0);
      expect(turma.percentualPresenca(1), 100);
      expect(turma.presencas.first.quantidadePresentes, 1);
    });

    test('novos alunos entram presentes nas aulas já registradas', () {
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
      turma.adicionarPresenca('2026-11-10');

      turma.adicionarAluno(Aluno(nome: 'Bruno', matricula: '002'));

      expect(turma.presencas.single.presentes, [true, true]);
    });

    test('impede duas aulas na mesma data', () {
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));
      turma.adicionarPresenca('2026-11-10');

      expect(() => turma.adicionarPresenca('2026-11-10'), throwsArgumentError);
    });

    test('percentual de presença é nulo sem aulas registradas', () {
      turma.adicionarAluno(Aluno(nome: 'Ana', matricula: '001'));

      expect(turma.percentualPresenca(0), isNull);
    });
  });

  group('RegistroPresenca', () {
    test('converte e exibe a data no padrão brasileiro', () {
      final String iso = RegistroPresenca.dataParaIso(DateTime(2026, 11, 9));

      expect(iso, '2026-11-09');
      expect(RegistroPresenca.formatarData(iso), '09/11/2026');
    });

    test('mantém o valor original quando a data é inválida', () {
      expect(RegistroPresenca.formatarData('data-invalida'), 'data-invalida');
    });
  });
}
