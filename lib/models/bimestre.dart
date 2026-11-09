class Bimestre {
  final int numero;

  // Cada linha representa um aluno.
  // Cada coluna representa uma avaliação.
  final List<List<double>> notas;

  // Indica se as duas avaliações foram lançadas.
  final List<List<bool>> notasLancadas;

  // Lista de recuperações: null significa não lançada.
  final List<double?> recuperacoes;

  Bimestre({required this.numero, required int quantidadeAlunos})
    : notas = List.generate(
        quantidadeAlunos,
        (_) => List<double>.filled(2, 0.0),
        growable: true,
      ),
      notasLancadas = List.generate(
        quantidadeAlunos,
        (_) => List<bool>.filled(2, false),
        growable: true,
      ),
      recuperacoes = List<double?>.filled(
        quantidadeAlunos,
        null,
        growable: true,
      ) {
    if (numero < 1) {
      throw ArgumentError('Número do bimestre inválido.');
    }

    if (quantidadeAlunos < 0) {
      throw ArgumentError('Quantidade de alunos inválida.');
    }
  }

  // Garante que todas as listas tenham espaço para os alunos.
  // Evita diferenças entre alunos cadastrados e suas notas.
  void sincronizarQuantidadeAlunos(int quantidade) {
    if (quantidade < 0) {
      throw ArgumentError('Quantidade inválida.');
    }

    while (notas.length < quantidade) {
      notas.add(List<double>.filled(2, 0.0));
    }

    while (notasLancadas.length < quantidade) {
      notasLancadas.add(List<bool>.filled(2, false));
    }

    while (recuperacoes.length < quantidade) {
      recuperacoes.add(null);
    }
  }

  // Adiciona um aluno às estruturas do bimestre.
  void adicionarAluno() {
    final atual = [
      notas.length,
      notasLancadas.length,
      recuperacoes.length,
    ].reduce((a, b) => a > b ? a : b);

    sincronizarQuantidadeAlunos(atual + 1);
  }

  // Verifica se o índice do aluno é válido.
  void _validarAluno(int indiceAluno) {
    if (indiceAluno < 0 ||
        indiceAluno >= notas.length ||
        indiceAluno >= notasLancadas.length ||
        indiceAluno >= recuperacoes.length) {
      throw RangeError('Aluno não encontrado no bimestre.');
    }
  }

  // Valida notas entre 0 e 10.
  void _validarNota(double nota) {
    if (!nota.isFinite || nota < 0 || nota > 10) {
      throw ArgumentError('A nota deve estar entre 0 e 10.');
    }
  }

  // Registra ou altera uma das duas provas.
  void registrarNota({
    required int indiceAluno,
    required int avaliacao,
    required double nota,
  }) {
    _validarAluno(indiceAluno);
    _validarNota(nota);

    if (avaliacao < 1 || avaliacao > 2) {
      throw ArgumentError('A avaliação deve ser 1 ou 2.');
    }

    notas[indiceAluno][avaliacao - 1] = nota;
    notasLancadas[indiceAluno][avaliacao - 1] = true;
  }

  // Registra ou altera a recuperação.
  void registrarRecuperacao({required int indiceAluno, required double nota}) {
    _validarAluno(indiceAluno);
    _validarNota(nota);

    recuperacoes[indiceAluno] = nota;
  }
}
