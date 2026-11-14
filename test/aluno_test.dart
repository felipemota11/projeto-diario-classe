import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/aluno.dart';

import 'support/fixtures.dart';

void main() {
  test('aceita letras acentuadas e preserva zeros iniciais da matrícula', () {
    for (final nome in [
      'Ana Cláudia',
      'João da Conceição',
      'Joa\u0303o Silva',
    ]) {
      final aluno = Aluno(nome: ' $nome ', matricula: '001023');
      expect(aluno.nome, nome);
      expect(aluno.matricula, '001023');
    }
  });

  test('recusa nomes vazios, números, pontuação e símbolos', () {
    for (final nome in [
      '',
      '   ',
      'Ana123',
      'Ana-Maria',
      'Ana @ Silva',
      '123',
      '👩',
    ]) {
      expect(() => Aluno(nome: nome, matricula: '001'), throwsArgumentError);
    }
  });

  test('recusa matrículas com letras, espaços internos e sinais', () {
    for (final matricula in [
      '',
      ' ',
      'ABC',
      '12A3',
      '12 34',
      '12.34',
      '-123',
      '1,5',
    ]) {
      expect(
        () => Aluno(nome: 'Ana Silva', matricula: matricula),
        throwsArgumentError,
      );
    }
    final aluno = Aluno(nome: 'Ana Silva', matricula: '001');
    expect(() => aluno.nome = 'Ana2', throwsArgumentError);
    expect(() => aluno.matricula = 'ABC', throwsArgumentError);
    expect(aluno.nome, 'Ana Silva');
    expect(aluno.matricula, '001');
  });

  test('edição inválida preserva nome, matrícula e observações anteriores', () {
    final turma = criarProfessor().turmas.single;
    final aluno = turma.alunos.single;
    expect(
      () => turma.editarAluno(
        0,
        nome: 'Ana Silva',
        matricula: 'ABC',
        observacao: 'Nova',
      ),
      throwsArgumentError,
    );
    expect(aluno.nome, 'João');
    expect(aluno.matricula, '001');
    expect(aluno.observacao, 'Participativo');
    expect(
      () => turma.editarAluno(
        0,
        nome: 'Ana2',
        matricula: '002',
        observacao: 'Nova',
      ),
      throwsArgumentError,
    );
    expect(aluno.nome, 'João');
    expect(aluno.matricula, '001');
  });
}
