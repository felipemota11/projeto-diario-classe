import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import 'alunos_screen.dart';
import '../services/armazenamento_service.dart';

class TurmasScreen extends StatefulWidget {
  final Professor professor;

  const TurmasScreen({super.key, required this.professor});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  Future<void> _cadastrarTurma() async {
    final formKey = GlobalKey<FormState>();

    String nome = '';
    String curso = '';
    String periodoTexto = '';

    final turmaCriada = await showDialog<Turma>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cadastrar turma'),

          content: Form(
            key: formKey,

            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nome da turma',
                      hintText: 'Ex.: Turma A',
                      border: OutlineInputBorder(),
                    ),

                    onSaved: (value) {
                      nome = value!.trim();
                    },

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da turma.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Curso',
                      hintText: 'Ex.: Ciência da Computação',
                      border: OutlineInputBorder(),
                    ),

                    onSaved: (value) {
                      curso = value!.trim();
                    },

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o curso.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    keyboardType: TextInputType.number,

                    decoration: const InputDecoration(
                      labelText: 'Período',
                      hintText: 'Ex.: 1',
                      border: OutlineInputBorder(),
                    ),

                    onSaved: (value) {
                      periodoTexto = value!.trim();
                    },

                    validator: (value) {
                      final numero = int.tryParse(value?.trim() ?? '');

                      if (numero == null || numero < 1) {
                        return 'Informe um período válido.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
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

                final turma = Turma(
                  nome: nome,
                  curso: curso,
                  periodo: int.parse(periodoTexto),
                );

                Navigator.pop(dialogContext, turma);
              },
              child: const Text('Cadastrar'),
            ),
          ],
        );
      },
    );

    if (!mounted || turmaCriada == null) {
      return;
    }

    final duplicada = widget.professor.turmas.any(
      (turma) =>
          turma.nome.toLowerCase() == turmaCriada.nome.toLowerCase() &&
          turma.curso.toLowerCase() == turmaCriada.curso.toLowerCase() &&
          turma.periodo == turmaCriada.periodo,
    );

    if (duplicada) {
      _mostrarMensagem('Essa turma já está cadastrada.');
      return;
    }

    widget.professor.adicionarTurma(turmaCriada);

    // Salva a nova turma.
    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Turma cadastrada com sucesso!');
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _abrirTurma(Turma turma) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AlunosScreen(turma: turma, professor: widget.professor),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas turmas')),

      body: turmas.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 75, color: Colors.grey),

                  SizedBox(height: 16),

                  Text(
                    'Nenhuma turma cadastrada.',
                    style: TextStyle(fontSize: 18),
                  ),

                  SizedBox(height: 8),

                  Text('Clique no botão abaixo para começar.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: turmas.length,

              itemBuilder: (context, index) {
                final turma = turmas[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.school)),

                    title: Text(
                      turma.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      '${turma.curso}\n'
                      '${turma.periodo}º período'
                      ' • ${turma.alunos.length} alunos',
                    ),

                    isThreeLine: true,

                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                    onTap: () => _abrirTurma(turma),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cadastrarTurma,
        icon: const Icon(Icons.add),
        label: const Text('Nova turma'),
      ),
    );
  }
}
