import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/turma.dart';
import '../models/professor.dart';
import '../services/armazenamento_service.dart';

class AlunosScreen extends StatefulWidget {
  final Turma turma;
  final Professor professor;

  const AlunosScreen({super.key, required this.turma, required this.professor});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  Future<void> _cadastrarAluno() async {
    final formKey = GlobalKey<FormState>();

    String nome = '';
    String matricula = '';

    final alunoCriado = await showDialog<Aluno>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cadastrar aluno'),

          content: Form(
            key: formKey,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                  ),

                  onSaved: (value) {
                    nome = value!.trim();
                  },

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do aluno.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    border: OutlineInputBorder(),
                  ),

                  onSaved: (value) {
                    matricula = value!.trim();
                  },

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a matrícula.';
                    }

                    final existe = widget.turma.alunos.any(
                      (aluno) =>
                          aluno.matricula.toLowerCase() ==
                          value.trim().toLowerCase(),
                    );

                    if (existe) {
                      return 'Essa matrícula já está cadastrada.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                formKey.currentState!.save();

                final aluno = Aluno(nome: nome, matricula: matricula);

                Navigator.pop(dialogContext, aluno);
              },
              child: const Text('Cadastrar'),
            ),
          ],
        );
      },
    );

    if (!mounted || alunoCriado == null) {
      return;
    }

    widget.turma.adicionarAluno(alunoCriado);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${alunoCriado.nome} cadastrado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alunos = widget.turma.alunos;

    return Scaffold(
      appBar: AppBar(title: Text(widget.turma.nome)),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),

            child: Card(
              child: ListTile(
                leading: const Icon(Icons.school, size: 35),

                title: Text(widget.turma.curso),

                subtitle: Text(
                  '${widget.turma.periodo}º período'
                  ' • ${alunos.length} alunos',
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),

            child: Text(
              'Alunos cadastrados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: alunos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 70,
                          color: Colors.grey,
                        ),

                        SizedBox(height: 12),

                        Text(
                          'Nenhum aluno cadastrado.',
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alunos.length,

                    itemBuilder: (context, index) {
                      final aluno = alunos[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(aluno.nome[0].toUpperCase()),
                          ),

                          title: Text(aluno.nome),

                          subtitle: Text('Matrícula: ${aluno.matricula}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cadastrarAluno,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo aluno'),
      ),
    );
  }
}
