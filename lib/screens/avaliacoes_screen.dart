import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../services/armazenamento_service.dart';

/// Apenas renomeia a prova única; a quantidade de provas é fixa.
class AvaliacoesScreen extends StatefulWidget {
  final Professor professor;
  final Bimestre bimestre;

  const AvaliacoesScreen({
    super.key,
    required this.professor,
    required this.bimestre,
  });

  @override
  State<AvaliacoesScreen> createState() => _AvaliacoesScreenState();
}

class _AvaliacoesScreenState extends State<AvaliacoesScreen> {
  Future<void> _renomear() async {
    final controller = TextEditingController(text: widget.bimestre.nomeProva);
    try {
      final nome = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Renomear a prova'),
          content: TextField(
            controller: controller,
            maxLength: Bimestre.limiteCaracteresNome,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome da prova'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
      if (!mounted || nome == null) return;
      try {
        await ArmazenamentoService.alterarProfessor(
          widget.professor,
          () => widget.bimestre.renomearProva(nome),
        );
        if (!mounted) return;
        setState(() {});
      } catch (erro) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$erro')));
      }
    } finally {
      Future<void>.delayed(
        const Duration(milliseconds: 400),
        controller.dispose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação do bimestre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('${widget.bimestre.numero}º bimestre'),
              subtitle: const Text(
                'Uma prova por bimestre. Não é possível adicionar outras avaliações.',
              ),
            ),
          ),
          ListTile(
            title: Text(widget.bimestre.nomeProva),
            subtitle: Text(
              '${widget.bimestre.notas.where((nota) => nota != null).length} nota(s) lançada(s)',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Renomear prova',
              onPressed: _renomear,
            ),
          ),
        ],
      ),
    );
  }
}
