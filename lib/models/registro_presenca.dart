/// Registro de presença de uma aula (uma data) para toda a turma.
///
/// A lista [presentes] está alinhada pelo índice dos alunos da turma.
/// A data é guardada no formato ISO (aaaa-mm-dd) para facilitar a ordenação
/// e a serialização em JSON.
class RegistroPresenca {
  final String data;
  final List<bool> presentes;

  RegistroPresenca({required this.data, required List<bool> presentes})
    : presentes = List<bool>.from(presentes);

  /// Converte uma data para o formato interno `aaaa-mm-dd`.
  static String dataParaIso(DateTime data) {
    final String mes = data.month.toString().padLeft(2, '0');
    final String dia = data.day.toString().padLeft(2, '0');

    return '${data.year}-$mes-$dia';
  }

  /// Tenta converter uma data ISO em [DateTime].
  static DateTime? dataDeIso(String valor) {
    return DateTime.tryParse(valor);
  }

  /// Exibe a data no padrão brasileiro (dd/mm/aaaa).
  static String formatarData(String valor) {
    final DateTime? data = dataDeIso(valor);

    if (data == null) {
      return valor;
    }

    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  /// Quantidade de alunos presentes nesta aula.
  int get quantidadePresentes {
    return presentes.where((presente) => presente).length;
  }
}
