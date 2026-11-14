import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../services/armazenamento_service.dart';

/// Mostra a falha e permite tentar novamente com os modelos restaurados.
Future<bool> salvarAlteracao(
  BuildContext context,
  Professor professor,
  void Function() alterar,
) async {
  try {
    await ArmazenamentoService.alterarProfessor(professor, alterar);
    return true;
  } catch (erro) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    }
    return false;
  }
}
