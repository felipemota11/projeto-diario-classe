import '../models/bimestre.dart';

class CalculoService {
  static const double mediaMinima = 7.0;

  // Calcula a média das duas avaliações regulares.
  static double? calcularMediaProvas(Bimestre bimestre, int indiceAluno) {
    if (indiceAluno < 0 || indiceAluno >= bimestre.notas.length) {
      throw RangeError('Aluno não encontrado.');
    }

    final lancamentos = bimestre.notasLancadas[indiceAluno];

    if (!lancamentos[0] || !lancamentos[1]) {
      return null;
    }

    final prova1 = bimestre.notas[indiceAluno][0];
    final prova2 = bimestre.notas[indiceAluno][1];

    return (prova1 + prova2) / 2;
  }

  // Calcula a média final considerando a recuperação.
  static double? calcularMedia(Bimestre bimestre, int indiceAluno) {
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
  static bool podeFazerRecuperacao(Bimestre bimestre, int indiceAluno) {
    final mediaProvas = calcularMediaProvas(bimestre, indiceAluno);

    return mediaProvas != null && mediaProvas < mediaMinima;
  }

  // Identifica a situação acadêmica.
  static String verificarSituacao(Bimestre bimestre, int indiceAluno) {
    final media = calcularMedia(bimestre, indiceAluno);

    if (media == null) {
      return 'Pendente';
    }

    if (media >= mediaMinima) {
      return 'Aprovado';
    }

    return 'Abaixo da média';
  }

  // Calcula a média geral dos alunos com duas provas lançadas.
  static double? calcularMediaGeral(Bimestre bimestre) {
    double soma = 0;
    int quantidade = 0;

    for (int i = 0; i < bimestre.notas.length; i++) {
      final media = calcularMedia(bimestre, i);

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
  // Considera as provas e as recuperações registradas.
  static double? obterMaiorNotaLancada(Bimestre bimestre) {
    double? maior;

    for (int i = 0; i < bimestre.notas.length; i++) {
      for (int j = 0; j < 2; j++) {
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
      for (int j = 0; j < 2; j++) {
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
  static double? calcularPercentualAprovados(Bimestre bimestre) {
    int quantidadeAvaliada = 0;
    int quantidadeAprovada = 0;

    for (int i = 0; i < bimestre.notas.length; i++) {
      final media = calcularMedia(bimestre, i);

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
}
