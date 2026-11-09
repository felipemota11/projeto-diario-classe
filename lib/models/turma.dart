import 'aluno.dart';
import 'bimestre.dart';

class Turma {
  final String nome;
  final String curso;
  final int periodo;

  final List<Aluno> alunos = [];
  final List<Bimestre> bimestres = [];

  Turma({required this.nome, required this.curso, required this.periodo}) {
    if (periodo < 1) {
      throw ArgumentError('Período inválido.');
    }
  }

  // Adiciona um aluno e sincroniza suas notas.
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

    // Só adiciona o aluno depois da sincronização.
    alunos.add(aluno);
  }

  // Cria um novo bimestre.
  void adicionarBimestre(int numero) {
    final existe = bimestres.any((b) => b.numero == numero);

    if (existe) {
      throw ArgumentError('Esse bimestre já foi cadastrado.');
    }

    bimestres.add(Bimestre(numero: numero, quantidadeAlunos: alunos.length));

    bimestres.sort((a, b) => a.numero.compareTo(b.numero));
  }
}
