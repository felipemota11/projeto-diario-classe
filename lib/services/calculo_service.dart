import '../models/bimestre.dart';

/// Regra única de aprovação do semestre, usada também pelas prévias.
class CalculoService {
  static const double mediaMinimaPadrao = 7.0;

  static void _validarMediaMinima(double mediaMinima) {
    if (!mediaMinima.isFinite || mediaMinima < 0 || mediaMinima > 10) {
      throw ArgumentError('A média mínima deve estar entre 0 e 10.');
    }
  }

  static void _validarSemestre(Bimestre primeiro, Bimestre segundo) {
    if (primeiro.numero != 1 ||
        segundo.numero != 2 ||
        primeiro.notas.length != segundo.notas.length) {
      throw ArgumentError('Informe os dois bimestres do mesmo semestre.');
    }
  }

  static double? mediaDasNotas(double? prova1, double? prova2) {
    if (prova1 != null) Bimestre.validarNota(prova1);
    if (prova2 != null) Bimestre.validarNota(prova2);
    if (prova1 == null || prova2 == null) return null;
    return (prova1 + prova2) / 2;
  }

  static double? resultadoDasNotas(
    double? media,
    double? provaFinal, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    _validarMediaMinima(mediaMinima);
    if (media == null) return null;
    Bimestre.validarNota(media);
    if (media >= mediaMinima) return media;
    if (provaFinal == null) return null;
    Bimestre.validarNota(provaFinal);
    return (media + provaFinal) / 2;
  }

  static String situacaoDasNotas(
    double? media,
    double? provaFinal, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final resultado = resultadoDasNotas(
      media,
      provaFinal,
      mediaMinima: mediaMinima,
    );
    if (media == null) return 'Pendente';
    if (media >= mediaMinima) return 'Aprovado';
    if (provaFinal == null) return 'Prova final pendente';
    return resultado! >= mediaMinima ? 'Aprovado após final' : 'Reprovado';
  }

  static double? calcularMediaSemestral(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno,
  ) {
    _validarSemestre(primeiro, segundo);
    return mediaDasNotas(
      primeiro.obterNota(indiceAluno),
      segundo.obterNota(indiceAluno),
    );
  }

  static bool precisaProvaFinal(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    _validarMediaMinima(mediaMinima);
    final media = calcularMediaSemestral(primeiro, segundo, indiceAluno);
    return media != null && media < mediaMinima;
  }

  static void registrarProvaFinal(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno,
    double nota, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    if (!precisaProvaFinal(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: mediaMinima,
    )) {
      throw StateError('A prova final não é necessária ou há notas pendentes.');
    }
    segundo.registrarProvaFinal(indiceAluno: indiceAluno, nota: nota);
  }

  static void limparProvaFinal(Bimestre segundo, int indiceAluno) {
    segundo.limparProvaFinal(indiceAluno);
  }

  static double? calcularMediaFinalSemestral(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final media = calcularMediaSemestral(primeiro, segundo, indiceAluno);
    return resultadoDasNotas(
      media,
      segundo.provasFinais[indiceAluno],
      mediaMinima: mediaMinima,
    );
  }

  static String verificarSituacaoSemestral(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    final media = calcularMediaSemestral(primeiro, segundo, indiceAluno);
    return situacaoDasNotas(
      media,
      segundo.provasFinais[indiceAluno],
      mediaMinima: mediaMinima,
    );
  }

  static double? notaNecessariaProvaFinal(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    if (!precisaProvaFinal(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: mediaMinima,
    )) {
      return null;
    }
    final media = calcularMediaSemestral(primeiro, segundo, indiceAluno)!;
    return (mediaMinima * 2) - media;
  }

  static List<String> pendenciasSemestrais(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno, {
    double mediaMinima = mediaMinimaPadrao,
  }) {
    _validarSemestre(primeiro, segundo);
    _validarMediaMinima(mediaMinima);
    final resultado = <String>[];
    if (primeiro.obterNota(indiceAluno) == null) {
      resultado.add(primeiro.nomeProva);
    }
    if (segundo.obterNota(indiceAluno) == null) {
      resultado.add(segundo.nomeProva);
    }
    if (resultado.isNotEmpty) return resultado;
    if (precisaProvaFinal(
          primeiro,
          segundo,
          indiceAluno,
          mediaMinima: mediaMinima,
        ) &&
        segundo.provasFinais[indiceAluno] == null) {
      resultado.add('Prova final');
    }
    return resultado;
  }
}
