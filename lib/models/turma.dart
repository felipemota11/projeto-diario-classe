import 'aluno.dart';
import 'bimestre.dart';
import 'registro_presenca.dart';

class Turma {
  String nome;
  String curso;
  int periodo;

  /// Turmas antigas podem ser arquivadas sem serem excluídas.
  bool arquivada;

  final List<Aluno> alunos = [];
  final List<Bimestre> bimestres = [];

  /// Aulas registradas, com a presença de cada aluno.
  final List<RegistroPresenca> presencas = [];

  Turma({
    required this.nome,
    required this.curso,
    required this.periodo,
    this.arquivada = false,
  }) {
    if (periodo < 1) {
      throw ArgumentError('Período inválido.');
    }
  }

  // Edita os dados básicos da turma.
  void editar({
    required String nome,
    required String curso,
    required int periodo,
  }) {
    if (periodo < 1) {
      throw ArgumentError('Período inválido.');
    }

    this.nome = nome;
    this.curso = curso;
    this.periodo = periodo;
  }

  // Adiciona um aluno e sincroniza suas notas e presenças.
  void adicionarAluno(Aluno aluno) {
    final existe = alunos.any(
      (a) => a.matricula.toLowerCase() == aluno.matricula.toLowerCase(),
    );

    if (existe) {
      throw ArgumentError('Já existe um aluno com essa matrícula na turma.');
    }

    final novaQuantidade = alunos.length + 1;

    // Primeiro prepara todas as estruturas dos bimestres.
    for (final bimestre in bimestres) {
      bimestre.sincronizarQuantidadeAlunos(novaQuantidade);
    }

    // Novos alunos passam a contar como presentes nas aulas já registradas.
    // O professor pode ajustar cada data depois, se necessário.
    for (final registro in presencas) {
      registro.presentes.add(true);
    }

    // Só adiciona o aluno depois da sincronização.
    alunos.add(aluno);
  }

  // Edita um aluno existente, validando a matrícula duplicada.
  void editarAluno(
    int indice, {
    required String nome,
    required String matricula,
    required String observacao,
  }) {
    _validarAluno(indice);

    final existe = alunos.asMap().entries.any(
      (item) =>
          item.key != indice &&
          item.value.matricula.toLowerCase() == matricula.toLowerCase(),
    );

    if (existe) {
      throw ArgumentError('Já existe um aluno com essa matrícula na turma.');
    }

    final aluno = alunos[indice];
    aluno
      ..nome = nome
      ..matricula = matricula
      ..observacao = observacao;
  }

  // Remove um aluno e todas as suas notas e presenças.
  void removerAlunoNoIndice(int indice) {
    _validarAluno(indice);

    for (final bimestre in bimestres) {
      bimestre.removerAlunoNoIndice(indice);
    }

    for (final registro in presencas) {
      if (indice < registro.presentes.length) {
        registro.presentes.removeAt(indice);
      }
    }

    alunos.removeAt(indice);
  }

  // Cria um novo bimestre. Os nomes das avaliações são opcionais para
  // preservar os dados antigos e permitir a configuração por turma.
  void adicionarBimestre(int numero, {List<String>? avaliacoes}) {
    final existe = bimestres.any((b) => b.numero == numero);

    if (existe) {
      throw ArgumentError('Esse bimestre já foi cadastrado.');
    }

    bimestres.add(
      Bimestre(
        numero: numero,
        quantidadeAlunos: alunos.length,
        avaliacoes: avaliacoes,
      ),
    );

    bimestres.sort((a, b) => a.numero.compareTo(b.numero));
  }

  // Exclui um bimestre e todas as notas lançadas nele.
  void removerBimestre(int numero) {
    bimestres.removeWhere((bimestre) => bimestre.numero == numero);
  }

  // Registra uma nova aula com todos os alunos presentes por padrão.
  RegistroPresenca adicionarPresenca(String dataIso) {
    final jaExiste = presencas.any((registro) => registro.data == dataIso);

    if (jaExiste) {
      throw ArgumentError('Já existe uma aula registrada nessa data.');
    }

    final registro = RegistroPresenca(
      data: dataIso,
      presentes: List<bool>.filled(alunos.length, true),
    );

    presencas.add(registro);
    presencas.sort((a, b) => a.data.compareTo(b.data));

    return registro;
  }

  // Remove uma aula registrada.
  void removerPresencaNoIndice(int indice) {
    if (indice < 0 || indice >= presencas.length) {
      throw RangeError('Aula não encontrada.');
    }

    presencas.removeAt(indice);
  }

  // Alterna presença/ausência de um aluno em uma aula.
  void alternarPresenca({required int registro, required int aluno}) {
    if (registro < 0 || registro >= presencas.length) {
      throw RangeError('Aula não encontrada.');
    }

    final presentes = presencas[registro].presentes;

    if (aluno < 0 || aluno >= presentes.length) {
      throw RangeError('Aluno não encontrado na aula.');
    }

    presentes[aluno] = !presentes[aluno];
  }

  // Calcula o percentual de presença de um aluno.
  // Retorna null quando a turma ainda não tem aulas registradas.
  double? percentualPresenca(int indiceAluno) {
    if (presencas.isEmpty) {
      return null;
    }

    int total = 0;
    int presentes = 0;

    for (final registro in presencas) {
      if (indiceAluno < 0 || indiceAluno >= registro.presentes.length) {
        continue;
      }

      total++;

      if (registro.presentes[indiceAluno]) {
        presentes++;
      }
    }

    if (total == 0) {
      return null;
    }

    return (presentes / total) * 100;
  }

  void _validarAluno(int indice) {
    if (indice < 0 || indice >= alunos.length) {
      throw RangeError('Aluno não encontrado.');
    }
  }
}
