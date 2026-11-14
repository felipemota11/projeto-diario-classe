class Aluno {
  String nome;
  String matricula;

  /// Anotações livres do professor sobre o aluno.
  /// Em dados antigos, o campo simplesmente não existe e assume vazio.
  String observacao;

  Aluno({required this.nome, required this.matricula, this.observacao = ''});
}
