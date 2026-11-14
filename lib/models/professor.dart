import 'turma.dart';

class Professor {
  String nome;

  /// Nota mínima configurável para aprovação.
  double mediaMinima;

  final List<Turma> turmas = [];

  Professor({required this.nome, this.mediaMinima = 7.0});

  // Atualiza o perfil e a regra de aprovação.
  void editarPerfil({required String nome, required double mediaMinima}) {
    if (nome.trim().isEmpty) {
      throw ArgumentError('Informe o nome do professor.');
    }

    if (!mediaMinima.isFinite || mediaMinima < 0 || mediaMinima > 10) {
      throw ArgumentError('A média mínima deve estar entre 0 e 10.');
    }

    this.nome = nome.trim();
    this.mediaMinima = mediaMinima;
  }

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

  // Substitui todos os dados pelos de outro professor.
  // Usado ao restaurar um backup ou desfazer uma exclusão.
  void substituirPor(Professor outro) {
    nome = outro.nome;
    mediaMinima = outro.mediaMinima;

    // Mantém a mesma lista para que as telas que já a utilizam
    // continuem enxergando os dados atualizados.
    turmas
      ..clear()
      ..addAll(outro.turmas);
  }
}
