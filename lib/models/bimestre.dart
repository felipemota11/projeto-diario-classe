class Bimestre {
  /// Nomes usados ao criar um bimestre sem configuração personalizada.
  /// Eles mantêm a compatibilidade com os dados antigos, que tinham
  /// exatamente duas provas.
  static const List<String> nomesAvaliacoesPadrao = ['Prova 1', 'Prova 2'];

  /// Limite para manter a tela e os relatórios legíveis.
  static const int limiteAvaliacoes = 10;

  static const int limiteCaracteresNome = 40;

  final int numero;

  /// Nomes das avaliações regulares deste bimestre.
  /// A ordem da lista é a mesma das colunas de notas.
  final List<String> avaliacoes;

  // Cada linha representa um aluno.
  // Cada coluna representa uma avaliação.
  final List<List<double>> notas;

  // Indica se cada avaliação do aluno foi lançada.
  final List<List<bool>> notasLancadas;

  // Lista de recuperações: null significa não lançada.
  final List<double?> recuperacoes;

  Bimestre({
    required this.numero,
    required int quantidadeAlunos,
    List<String>? avaliacoes,
  }) : avaliacoes = _normalizarNomes(avaliacoes),
       notas = [],
       notasLancadas = [],
       recuperacoes = [] {
    if (numero < 1) {
      throw ArgumentError('Número do bimestre inválido.');
    }

    if (quantidadeAlunos < 0) {
      throw ArgumentError('Quantidade de alunos inválida.');
    }

    _inicializarAlunos(quantidadeAlunos);
  }

  int get quantidadeAvaliacoes => avaliacoes.length;

  // Valida e limpa a lista de nomes recebida do armazenamento ou da interface.
  static List<String> _normalizarNomes(List<String>? nomes) {
    final List<String> lista = List<String>.from(
      nomes ?? nomesAvaliacoesPadrao,
    );

    if (lista.isEmpty) {
      throw ArgumentError('O bimestre precisa de pelo menos uma avaliação.');
    }

    if (lista.length > limiteAvaliacoes) {
      throw ArgumentError(
        'O bimestre pode ter no máximo $limiteAvaliacoes avaliações.',
      );
    }

    final List<String> normalizados = [];
    final Set<String> vistos = {};

    for (final nome in lista) {
      final String limpo = nome.trim();

      if (limpo.isEmpty) {
        throw ArgumentError('Informe o nome da avaliação.');
      }

      if (limpo.length > limiteCaracteresNome) {
        throw ArgumentError(
          'O nome da avaliação deve ter no máximo $limiteCaracteresNome '
          'caracteres.',
        );
      }

      if (!vistos.add(limpo.toLowerCase())) {
        throw ArgumentError('Já existe uma avaliação com esse nome.');
      }

      normalizados.add(limpo);
    }

    return normalizados;
  }

  String _validarNome(String nome, {int? ignorarIndice}) {
    final String limpo = nome.trim();

    if (limpo.isEmpty) {
      throw ArgumentError('Informe o nome da avaliação.');
    }

    if (limpo.length > limiteCaracteresNome) {
      throw ArgumentError(
        'O nome da avaliação deve ter no máximo $limiteCaracteresNome '
        'caracteres.',
      );
    }

    final bool existe = avaliacoes.asMap().entries.any(
      (item) =>
          item.key != ignorarIndice &&
          item.value.toLowerCase() == limpo.toLowerCase(),
    );

    if (existe) {
      throw ArgumentError('Já existe uma avaliação com esse nome.');
    }

    return limpo;
  }

  void _inicializarAlunos(int quantidade) {
    while (notas.length < quantidade) {
      notas.add(List<double>.filled(avaliacoes.length, 0.0, growable: true));
      notasLancadas.add(
        List<bool>.filled(avaliacoes.length, false, growable: true),
      );
      recuperacoes.add(null);
    }
  }

  // Garante que todas as listas tenham espaço para os alunos.
  // Evita diferenças entre alunos cadastrados e suas notas.
  void sincronizarQuantidadeAlunos(int quantidade) {
    if (quantidade < 0) {
      throw ArgumentError('Quantidade inválida.');
    }

    _inicializarAlunos(quantidade);
  }

  // Adiciona um aluno às estruturas do bimestre.
  void adicionarAluno() {
    final int atual = [
      notas.length,
      notasLancadas.length,
      recuperacoes.length,
    ].reduce((a, b) => a > b ? a : b);

    sincronizarQuantidadeAlunos(atual + 1);
  }

  // Adiciona uma nova avaliação com nome personalizado.
  void adicionarAvaliacao(String nome) {
    if (avaliacoes.length >= limiteAvaliacoes) {
      throw StateError(
        'O bimestre pode ter no máximo $limiteAvaliacoes avaliações.',
      );
    }

    final String limpo = _validarNome(nome);

    avaliacoes.add(limpo);

    for (final linha in notas) {
      linha.add(0.0);
    }

    for (final linha in notasLancadas) {
      linha.add(false);
    }
  }

  // Renomeia uma avaliação sem mexer nas notas já lançadas.
  void renomearAvaliacao({required int indice, required String nome}) {
    if (indice < 0 || indice >= avaliacoes.length) {
      throw RangeError('Avaliação não encontrada.');
    }

    avaliacoes[indice] = _validarNome(nome, ignorarIndice: indice);
  }

  // Remove uma avaliação e todas as notas lançadas nela.
  void removerAvaliacao(int indice) {
    if (indice < 0 || indice >= avaliacoes.length) {
      throw RangeError('Avaliação não encontrada.');
    }

    if (avaliacoes.length <= 1) {
      throw StateError('O bimestre precisa ter pelo menos uma avaliação.');
    }

    avaliacoes.removeAt(indice);

    for (final linha in notas) {
      linha.removeAt(indice);
    }

    for (final linha in notasLancadas) {
      linha.removeAt(indice);
    }
  }

  // Quantidade de alunos com nota lançada em uma avaliação.
  int quantidadeNotasLancadas(int indiceAvaliacao) {
    if (indiceAvaliacao < 0 || indiceAvaliacao >= avaliacoes.length) {
      throw RangeError('Avaliação não encontrada.');
    }

    return notasLancadas.where((linha) => linha[indiceAvaliacao]).length;
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

  // Registra ou altera uma avaliação regular.
  void registrarNota({
    required int indiceAluno,
    required int avaliacao,
    required double nota,
  }) {
    _validarAluno(indiceAluno);
    _validarNota(nota);

    if (avaliacao < 1 || avaliacao > avaliacoes.length) {
      throw ArgumentError('A avaliação informada não existe.');
    }

    notas[indiceAluno][avaliacao - 1] = nota;
    notasLancadas[indiceAluno][avaliacao - 1] = true;
  }

  // Remove o lançamento de uma avaliação, deixando-a pendente novamente.
  void limparNota({required int indiceAluno, required int avaliacao}) {
    _validarAluno(indiceAluno);

    if (avaliacao < 1 || avaliacao > avaliacoes.length) {
      throw ArgumentError('A avaliação informada não existe.');
    }

    notas[indiceAluno][avaliacao - 1] = 0.0;
    notasLancadas[indiceAluno][avaliacao - 1] = false;
  }

  // Registra ou altera a recuperação.
  void registrarRecuperacao({required int indiceAluno, required double nota}) {
    _validarAluno(indiceAluno);
    _validarNota(nota);

    recuperacoes[indiceAluno] = nota;
  }

  // Remove a recuperação, deixando-a como não lançada.
  void limparRecuperacao(int indiceAluno) {
    _validarAluno(indiceAluno);
    recuperacoes[indiceAluno] = null;
  }

  // Remove as estruturas de um aluno. Usado quando o aluno é excluído.
  void removerAlunoNoIndice(int indiceAluno) {
    _validarAluno(indiceAluno);

    notas.removeAt(indiceAluno);
    notasLancadas.removeAt(indiceAluno);
    recuperacoes.removeAt(indiceAluno);
  }
}
