import 'package:projeto_diario/models/aluno.dart';
import 'package:projeto_diario/models/professor.dart';
import 'package:projeto_diario/models/turma.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/types.dart';

Professor criarProfessor({double mediaMinima = 7}) {
  final professor = Professor(nome: 'Maria', mediaMinima: mediaMinima);
  final turma = Turma(nome: 'Turma A', curso: 'Computação', periodo: 2);
  turma.adicionarAluno(
    Aluno(nome: 'João', matricula: '001', observacao: 'Participativo'),
  );
  professor.adicionarTurma(turma);
  return professor;
}

base class ArmazenamentoDeTeste extends InMemorySharedPreferencesAsync {
  ArmazenamentoDeTeste() : super.empty();
  bool falhar = false;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (falhar) throw StateError('Falha de gravação simulada');
    return super.setString(key, value, options);
  }
}
