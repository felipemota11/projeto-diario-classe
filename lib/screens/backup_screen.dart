import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../services/arquivo_service.dart';
import '../services/armazenamento_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';

/// Exporta e restaura todos os dados em um arquivo JSON.
class BackupScreen extends StatefulWidget {
  final Professor professor;

  const BackupScreen({super.key, required this.professor});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _ocupado = false;

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _nomeArquivoBackup() {
    final DateTime agora = DateTime.now();
    final String mes = agora.month.toString().padLeft(2, '0');
    final String dia = agora.day.toString().padLeft(2, '0');

    return 'diario_classe_backup_${agora.year}-$mes-$dia.json';
  }

  Future<void> _exportar() async {
    setState(() => _ocupado = true);

    try {
      final String json = ArmazenamentoService.exportarJson(widget.professor);

      await ArquivoService.salvarTexto(
        nomeArquivo: _nomeArquivoBackup(),
        conteudo: json,
      );

      if (!mounted) return;

      _mensagem('Backup exportado com sucesso!');
    } catch (erro) {
      if (!mounted) return;

      _mensagem('Não foi possível exportar o backup: $erro');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _apagarTodosOsDados() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar todos os dados?'),
          content: const Text(
            'Todas as turmas, alunos, notas, observações e frequências '
            'serão removidos deste aparelho. Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() => _ocupado = true);

    try {
      await ArmazenamentoService.apagarDados();

      // Mantém o nome e a média mínima configurados no perfil.
      widget.professor.substituirPor(
        Professor(
          nome: widget.professor.nome,
          mediaMinima: widget.professor.mediaMinima,
        ),
      );

      if (!mounted) return;

      setState(() {});
      _mensagem('Todos os dados foram apagados.');
    } catch (erro) {
      if (!mounted) return;

      _mensagem('Não foi possível apagar os dados: $erro');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _restaurar() async {
    setState(() => _ocupado = true);

    try {
      final PlatformFile? arquivo = await FilePicker.pickFile(
        dialogTitle: 'Selecione o arquivo de backup',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (arquivo == null) {
        if (mounted) setState(() => _ocupado = false);
        return;
      }

      final String conteudo = utf8
          .decode(await arquivo.readAsBytes(), allowMalformed: true)
          .replaceFirst('\uFEFF', '');

      final Professor importado = ArmazenamentoService.importarJson(conteudo);

      if (!mounted) return;

      final int quantidadeAlunos = importado.turmas.fold<int>(
        0,
        (total, turma) => total + turma.alunos.length,
      );

      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Restaurar backup?'),
            content: Text(
              'O arquivo contém ${importado.turmas.length} turma(s) e '
              '$quantidadeAlunos aluno(s).\n\n'
              'A restauração substituirá todos os dados atuais. '
              'Essa ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Restaurar'),
              ),
            ],
          );
        },
      );

      if (confirmar != true) {
        if (mounted) setState(() => _ocupado = false);
        return;
      }

      widget.professor.substituirPor(importado);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});

      _mensagem('Backup restaurado com sucesso!');
    } catch (erro) {
      if (!mounted) return;

      _mensagem(
        'Arquivo inválido ou não foi possível restaurar o backup: $erro',
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final int turmas = widget.professor.turmas.length;
    final int alunos = widget.professor.turmas.fold<int>(
      0,
      (total, turma) => total + turma.alunos.length,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Backup e restauração')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_ocupado) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 14),
            ],

            const SectionHeader(titulo: 'Seus dados'),

            const SizedBox(height: 10),

            AppCard(
              gradient: AppTheme.brandGradient,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Tudo salvo no aparelho',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Seus dados ficam armazenados localmente. '
                    'Gere um arquivo de backup para guardar em outro lugar '
                    'ou levar para outro aparelho.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ContadorClaro(
                        valor: turmas,
                        label: turmas == 1 ? 'turma' : 'turmas',
                      ),
                      const SizedBox(width: 12),
                      _ContadorClaro(
                        valor: alunos,
                        label: alunos == 1 ? 'aluno' : 'alunos',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SectionHeader(titulo: 'Exportar backup'),

            const SizedBox(height: 10),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: Icons.download_rounded,
                        size: 44,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Gerar arquivo .json',
                          style: tema.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Inclui turmas, alunos, notas, observações e frequência.',
                    style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Exportar backup',
                    icon: Icons.file_download_rounded,
                    onPressed: _ocupado ? null : _exportar,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SectionHeader(titulo: 'Restaurar backup'),

            const SizedBox(height: 10),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(
                        icon: Icons.upload_file_rounded,
                        size: 44,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Importar arquivo .json',
                          style: tema.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Escolha um backup gerado pelo Diário de Classe. '
                    'Os dados atuais serão substituídos.',
                    style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : _restaurar,
                    icon: const Icon(Icons.folder_open_rounded, size: 19),
                    label: const Text('Selecionar arquivo'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SectionHeader(titulo: 'Exclusão de dados'),

            const SizedBox(height: 10),

            AppCard(
              color: AppTheme.danger.withValues(alpha: 0.06),
              border: Border.all(
                color: AppTheme.danger.withValues(alpha: 0.20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(
                        icon: Icons.delete_forever_rounded,
                        size: 44,
                        color: AppTheme.danger,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Apagar todos os dados',
                          style: tema.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Remove turmas, alunos, notas e frequências deste '
                    'aparelho. Gere um backup antes, se quiser guardar uma '
                    'cópia.',
                    style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : _apagarTodosOsDados,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    label: const Text('Apagar todos os dados'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: BorderSide(
                        color: AppTheme.danger.withValues(alpha: 0.40),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            AppCard(
              color: AppTheme.info.withValues(alpha: 0.08),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.20)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dica: guarde o arquivo de backup em um local seguro, '
                      'como seu e-mail ou armazenamento em nuvem pessoal. '
                      'Ele contém os dados de todos os seus alunos.',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContadorClaro extends StatelessWidget {
  final int valor;
  final String label;

  const _ContadorClaro({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$valor $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
