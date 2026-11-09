import 'package:flutter/material.dart';

import '../models/professor.dart';
import 'turmas_screen.dart';
import 'notas_screen.dart';
import 'relatorios_screen.dart';

class InicioScreen extends StatefulWidget {
  final Professor professor;

  const InicioScreen({super.key, required this.professor});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // Abre outra tela e atualiza o painel quando retornar.
  Future<void> _abrirTela(Widget tela) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => tela),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final quantidadeTurmas = widget.professor.turmas.length;

    final quantidadeAlunos = widget.professor.turmas.fold<int>(
      0,
      (total, turma) => total + turma.alunos.length,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Diário de Classe'), centerTitle: true),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.school, color: Colors.white, size: 42),

                  SizedBox(height: 10),

                  Text(
                    'Diário de Classe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Início'),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Turmas'),
              onTap: () async {
                Navigator.pop(context);

                await _abrirTela(TurmasScreen(professor: widget.professor));
              },
            ),

            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Lançamento de notas'),
              onTap: () async {
                Navigator.pop(context);

                await _abrirTela(NotasScreen(professor: widget.professor));
              },
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Relatórios'),
              onTap: () async {
                Navigator.pop(context);

                await _abrirTela(RelatoriosScreen(professor: widget.professor));
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boas-vindas.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bem-vindo ao sistema!',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text('Professor: ${widget.professor.nome}'),

                    const SizedBox(height: 5),

                    const Text('Gerencie suas turmas, alunos e avaliações.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Resumo geral',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ResumoCard(
                    titulo: 'Turmas',
                    quantidade: quantidadeTurmas,
                    icone: Icons.groups,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _ResumoCard(
                    titulo: 'Alunos',
                    quantidade: quantidadeAlunos,
                    icone: Icons.people,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Acessos rápidos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _MenuCard(
              titulo: 'Minhas turmas',
              descricao: 'Cadastrar e consultar turmas e alunos.',
              icone: Icons.groups_outlined,

              aoClicar: () {
                _abrirTela(TurmasScreen(professor: widget.professor));
              },
            ),

            _MenuCard(
              titulo: 'Lançamento de notas',
              descricao: 'Registrar avaliações e recuperações.',
              icone: Icons.edit_note,

              aoClicar: () {
                _abrirTela(NotasScreen(professor: widget.professor));
              },
            ),

            _MenuCard(
              titulo: 'Relatórios',
              descricao: 'Consultar médias e estatísticas.',
              icone: Icons.bar_chart,

              aoClicar: () {
                _abrirTela(RelatoriosScreen(professor: widget.professor));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Cartão de resumo.
class _ResumoCard extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final IconData icone;

  const _ResumoCard({
    required this.titulo,
    required this.quantidade,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Icon(icone, size: 32),

            const SizedBox(height: 8),

            Text(
              quantidade.toString(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            Text(titulo),
          ],
        ),
      ),
    );
  }
}

// Cartão de acesso rápido.
class _MenuCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final VoidCallback aoClicar;

  const _MenuCard({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icone, size: 32),

        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text(descricao),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: aoClicar,
      ),
    );
  }
}
