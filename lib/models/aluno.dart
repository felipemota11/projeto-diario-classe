class Aluno {
  static final RegExp _nomeValido = RegExp(
    r'^\p{L}[\p{L}\p{M}]*(?: +\p{L}[\p{L}\p{M}]*)*$',
    unicode: true,
  );
  static final RegExp _matriculaValida = RegExp(r'^[0-9]+$');

  String _nome;
  String _matricula;

  /// Anotações livres do professor sobre o aluno.
  String observacao;

  Aluno({required String nome, required String matricula, this.observacao = ''})
    : _nome = nome.trim(),
      _matricula = matricula.trim() {
    validarCadastro(nome: nome, matricula: matricula);
  }

  String get nome => _nome;
  set nome(String valor) {
    final erro = validarNome(valor);
    if (erro != null) throw ArgumentError(erro);
    _nome = valor.trim();
  }

  String get matricula => _matricula;
  set matricula(String valor) {
    final erro = validarMatricula(valor);
    if (erro != null) throw ArgumentError(erro);
    _matricula = valor.trim();
  }

  static String? validarNome(String? valor) {
    final nome = valor?.trim() ?? '';
    if (nome.isEmpty) return 'Informe o nome do aluno.';
    if (!_nomeValido.hasMatch(nome)) {
      return 'O nome deve conter apenas letras e espaços.';
    }
    return null;
  }

  static String? validarMatricula(String? valor) {
    final matricula = valor?.trim() ?? '';
    if (matricula.isEmpty) return 'Informe a matrícula.';
    if (!_matriculaValida.hasMatch(matricula)) {
      return 'A matrícula deve conter apenas números.';
    }
    return null;
  }

  static void validarCadastro({
    required String nome,
    required String matricula,
  }) {
    final erro = validarNome(nome) ?? validarMatricula(matricula);
    if (erro != null) throw ArgumentError(erro);
  }
}
