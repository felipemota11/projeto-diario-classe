import 'turma.dart';

class Professor {
  final String nome;
  final List<Turma> turmas = [];

  Professor({required this.nome});

  void adicionarTurma(Turma turma) {
    final existe = turmas.any(
      (t) =>
          t.nome == turma.nome &&
          t.curso == turma.curso &&
          t.periodo == turma.periodo,
    );

    if (existe) {
      throw ArgumentError('Essa turma já está cadastrada.');
    }

    turmas.add(turma);
  }
}
