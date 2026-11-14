/// Uma prova por bimestre e uma prova final no segundo bimestre.
class Bimestre {
  static const int limiteCaracteresNome = 40;
  final int numero;
  String _nomeProva;
  final List<double?> notas = [];
  final List<double?> provasFinais = [];

  Bimestre({
    required this.numero,
    required int quantidadeAlunos,
    String? nomeProva,
  }) : _nomeProva = nomeProva ?? 'Prova $numero' {
    if (numero != 1 && numero != 2) {
      throw ArgumentError('Um semestre possui somente os bimestres 1 e 2.');
    }
    renomearProva(_nomeProva);
    sincronizarQuantidadeAlunos(quantidadeAlunos);
  }

  String get nomeProva => _nomeProva;

  void renomearProva(String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty || limpo.length > limiteCaracteresNome) {
      throw ArgumentError('O nome da prova deve ter entre 1 e 40 caracteres.');
    }
    _nomeProva = limpo;
  }

  void sincronizarQuantidadeAlunos(int quantidade) {
    if (quantidade < 0) throw ArgumentError('Quantidade de alunos inválida.');
    while (notas.length < quantidade) {
      notas.add(null);
      provasFinais.add(null);
    }
    if (notas.length > quantidade) {
      notas.removeRange(quantidade, notas.length);
      provasFinais.removeRange(quantidade, provasFinais.length);
    }
  }

  void _validarAluno(int indice) {
    if (indice < 0 || indice >= notas.length) {
      throw RangeError('Aluno não encontrado no bimestre.');
    }
  }

  static void validarNota(double nota) {
    if (!nota.isFinite || nota < 0 || nota > 10) {
      throw ArgumentError('A nota deve estar entre 0 e 10.');
    }
  }

  void registrarNota({required int indiceAluno, required double nota}) {
    _validarAluno(indiceAluno);
    validarNota(nota);
    notas[indiceAluno] = nota;
  }

  void limparNota({required int indiceAluno}) {
    _validarAluno(indiceAluno);
    notas[indiceAluno] = null;
  }

  double? obterNota(int indiceAluno) {
    _validarAluno(indiceAluno);
    return notas[indiceAluno];
  }

  void registrarProvaFinal({required int indiceAluno, required double nota}) {
    _validarAluno(indiceAluno);
    if (numero != 2) throw StateError('A prova final pertence ao 2º bimestre.');
    validarNota(nota);
    provasFinais[indiceAluno] = nota;
  }

  void limparProvaFinal(int indiceAluno) {
    _validarAluno(indiceAluno);
    if (numero != 2) throw StateError('A prova final pertence ao 2º bimestre.');
    provasFinais[indiceAluno] = null;
  }

  void removerAlunoNoIndice(int indiceAluno) {
    _validarAluno(indiceAluno);
    notas.removeAt(indiceAluno);
    provasFinais.removeAt(indiceAluno);
  }
}
