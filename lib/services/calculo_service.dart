import '../models/bimestre.dart';

class CalculoService {
  /// Valor usado quando nenhuma configuração foi informada.
  static const double mediaMinimaPadrao = 7.0;

  // Calcula a média simples de todas as avaliações regulares.
  // A média fica pendente enquanto qualquer avaliação não for lançada.
  static double? calcularMediaProvas(Bimestre bimestre, int indiceAluno) {
    if (indiceAluno < 0 || indiceAluno >= bimestre.notas.length) {
      throw RangeError('Aluno não encontrado.');
    }

    final lancamentos = bimestre.notasLancadas[indiceAluno];
    final notas = bimestre.notas[indiceAluno];
    final quantidade = bimestre.avaliacoes.length;

    if (quantidade == 0) {
      return null;
    }

    double soma = 0;

    for (int j = 0; j < quantidade; j++) {
      if (!lancamentos[j]) {
        return null;
      }

      soma += notas[j];
    }

    return soma / quantidade;
  }

  // Calcula a média final considerando a recuperação.
  static double? calcularMedia(
    Bimestre bimestre,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final mediaProvas = calcularMediaProvas(bimestre, indiceAluno);

    if (mediaProvas == null) {
      return null;
    }

    final recuperacao = bimestre.recuperacoes[indiceAluno];

    if (mediaProvas >= mediaMinima || recuperacao == null) {
      return mediaProvas;
    }

    return (mediaProvas + recuperacao) / 2;
  }

  // Verifica se o aluno pode fazer recuperação.
  static bool podeFazerRecuperacao(
    Bimestre bimestre,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final mediaProvas = calcularMediaProvas(bimestre, indiceAluno);

    return mediaProvas != null && mediaProvas < mediaMinima;
  }

  /// Lista as pendências do aluno no bimestre.
  ///
  /// Inclui as avaliações ainda não lançadas e a recuperação quando ela é
  /// necessária e também está pendente.
  static List<String> pendenciasDoAluno(
    Bimestre bimestre,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    if (indiceAluno < 0 || indiceAluno >= bimestre.notas.length) {
      throw RangeError('Aluno não encontrado.');
    }

    final List<String> pendencias = [];
    final lancamentos = bimestre.notasLancadas[indiceAluno];

    for (int j = 0; j < bimestre.avaliacoes.length; j++) {
      if (!lancamentos[j]) {
        pendencias.add(bimestre.avaliacoes[j]);
      }
    }

    final podeRecuperar = podeFazerRecuperacao(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    if (podeRecuperar && bimestre.recuperacoes[indiceAluno] == null) {
      pendencias.add('Recuperação');
    }

    return pendencias;
  }

  // Identifica a situação acadêmica.
  static String verificarSituacao(
    Bimestre bimestre,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final media = calcularMedia(
      bimestre,
      indiceAluno,
      mediaMinima: mediaMinima,
    );

    if (media == null) {
      return 'Pendente';
    }

    if (media >= mediaMinima) {
      return 'Aprovado';
    }

    return 'Abaixo da média';
  }

  // Calcula a média geral dos alunos com todas as avaliações lançadas.
  static double? calcularMediaGeral(
    Bimestre bimestre, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    double soma = 0;
    int quantidade = 0;

    for (int i = 0; i < bimestre.notas.length; i++) {
      final media = calcularMedia(bimestre, i, mediaMinima: mediaMinima);

      if (media != null) {
        soma += media;
        quantidade++;
      }
    }

    if (quantidade == 0) {
      return null;
    }

    return soma / quantidade;
  }

  // Encontra a maior nota individual lançada.
  // Considera as avaliações e as recuperações registradas.
  static double? obterMaiorNotaLancada(Bimestre bimestre) {
    double? maior;

    for (int i = 0; i < bimestre.notas.length; i++) {
      for (int j = 0; j < bimestre.avaliacoes.length; j++) {
        if (bimestre.notasLancadas[i][j]) {
          final nota = bimestre.notas[i][j];

          if (maior == null || nota > maior) {
            maior = nota;
          }
        }
      }

      final recuperacao = bimestre.recuperacoes[i];

      if (recuperacao != null && (maior == null || recuperacao > maior)) {
        maior = recuperacao;
      }
    }

    return maior;
  }

  // Encontra a menor nota individual lançada.
  static double? obterMenorNotaLancada(Bimestre bimestre) {
    double? menor;

    for (int i = 0; i < bimestre.notas.length; i++) {
      for (int j = 0; j < bimestre.avaliacoes.length; j++) {
        if (bimestre.notasLancadas[i][j]) {
          final nota = bimestre.notas[i][j];

          if (menor == null || nota < menor) {
            menor = nota;
          }
        }
      }

      final recuperacao = bimestre.recuperacoes[i];

      if (recuperacao != null && (menor == null || recuperacao < menor)) {
        menor = recuperacao;
      }
    }

    return menor;
  }

  // Calcula o percentual de alunos aprovados.
  // Alunos com notas pendentes não entram no cálculo.
  static double? calcularPercentualAprovados(
    Bimestre bimestre, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    int quantidadeAvaliada = 0;
    int quantidadeAprovada = 0;

    for (int i = 0; i < bimestre.notas.length; i++) {
      final media = calcularMedia(bimestre, i, mediaMinima: mediaMinima);

      if (media == null) {
        continue;
      }

      quantidadeAvaliada++;

      if (media >= mediaMinima) {
        quantidadeAprovada++;
      }
    }

    if (quantidadeAvaliada == 0) {
      return null;
    }

    return (quantidadeAprovada / quantidadeAvaliada) * 100;
  }

  /// Calcula a nota mínima que o aluno precisa tirar na recuperação.
  ///
  /// Retorna null quando as avaliações ainda estão pendentes ou quando a
  /// média já é suficiente. O valor pode ser maior que 10, indicando
  /// que a média não é alcançável apenas com a recuperação.
  static double? notaNecessariaRecuperacao(
    Bimestre bimestre,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final mediaProvas = calcularMediaProvas(bimestre, indiceAluno);

    if (mediaProvas == null || mediaProvas >= mediaMinima) {
      return null;
    }

    // (média das avaliações + recuperação) / 2 >= média mínima
    return (mediaMinima * 2) - mediaProvas;
  }

  /// Indica se a recuperação lançada está sendo aplicada na média final.
  static bool recuperacaoAplicada(
    Bimestre bimestre,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final mediaProvas = calcularMediaProvas(bimestre, indiceAluno);

    return mediaProvas != null &&
        mediaProvas < mediaMinima &&
        bimestre.recuperacoes[indiceAluno] != null;
  }
}
