import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';

/// Gerencia as avaliações de um bimestre de uma turma.
///
/// Cada turma pode ter uma lista própria de provas, trabalhos ou testes.
class AvaliacoesScreen extends StatefulWidget {
  final Professor professor;
  final Turma turma;
  final Bimestre bimestre;

  const AvaliacoesScreen({
    super.key,
    required this.professor,
    required this.turma,
    required this.bimestre,
  });

  @override
  State<AvaliacoesScreen> createState() => _AvaliacoesScreenState();
}

class _AvaliacoesScreenState extends State<AvaliacoesScreen> {
  bool _salvando = false;

  Bimestre get _bimestre => widget.bimestre;

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _limparErro(Object erro) {
    return erro
        .toString()
        .replaceFirst('ArgumentError: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }

  // Abre um diálogo para informar o nome de uma avaliação.
  Future<String?> _solicitarNome({
    required String titulo,
    String? nomeAtual,
    int? indiceAtual,
  }) {
    final formKey = GlobalKey<FormState>();
    String nomeInformado = nomeAtual ?? '';

    // Usa uma cópia para que a validação não mude enquanto o diálogo fecha.
    final List<String> nomesExistentes = List<String>.of(_bimestre.avaliacoes);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          title: Row(
            children: [
              const IconBadge(icon: Icons.event_note_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              initialValue: nomeAtual,
              autofocus: true,
              maxLength: Bimestre.limiteCaracteresNome,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nome da avaliação',
                hintText: 'Ex.: Prova, Trabalho, Teste',
                helperText: 'Use um nome que identifique a atividade.',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              onSaved: (valor) {
                nomeInformado = valor?.trim() ?? '';
              },
              validator: (valor) {
                final nome = valor?.trim() ?? '';

                if (nome.isEmpty) {
                  return 'Informe o nome da avaliação.';
                }

                if (nome.length > Bimestre.limiteCaracteresNome) {
                  return 'Use no máximo ${Bimestre.limiteCaracteresNome} '
                      'caracteres.';
                }

                final existe = nomesExistentes.asMap().entries.any(
                  (item) =>
                      item.key != indiceAtual &&
                      item.value.toLowerCase() == nome.toLowerCase(),
                );

                if (existe) {
                  return 'Já existe uma avaliação com esse nome.';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(dialogContext, nomeInformado);
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                formKey.currentState!.save();
                Navigator.pop(dialogContext, nomeInformado);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionar() async {
    if (_salvando) return;

    if (_bimestre.avaliacoes.length >= Bimestre.limiteAvaliacoes) {
      _mostrarMensagem(
        'Este bimestre já tem o limite de '
        '${Bimestre.limiteAvaliacoes} avaliações.',
      );
      return;
    }

    final nome = await _solicitarNome(titulo: 'Adicionar avaliação');

    if (!mounted || nome == null) return;

    setState(() => _salvando = true);

    try {
      _bimestre.adicionarAvaliacao(nome);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});
      _mostrarMensagem(
        'Avaliação "${nome.trim()}" adicionada. '
        'Lance as notas dela para os alunos.',
      );
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível adicionar: ${_limparErro(erro)}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _renomear(int indice) async {
    if (_salvando) return;

    final nomeAtual = _bimestre.avaliacoes[indice];

    final nome = await _solicitarNome(
      titulo: 'Renomear avaliação',
      nomeAtual: nomeAtual,
      indiceAtual: indice,
    );

    if (!mounted || nome == null || nome.trim() == nomeAtual) return;

    setState(() => _salvando = true);

    try {
      _bimestre.renomearAvaliacao(indice: indice, nome: nome);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});
      _mostrarMensagem('Avaliação renomeada para "${nome.trim()}".');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível renomear: ${_limparErro(erro)}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover(int indice) async {
    if (_salvando) return;

    if (_bimestre.avaliacoes.length <= 1) {
      _mostrarMensagem('O bimestre precisa ter pelo menos uma avaliação.');
      return;
    }

    final nome = _bimestre.avaliacoes[indice];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover avaliação?'),
          content: Text(
            'A avaliação "$nome" e todas as notas lançadas nela serão '
            'removidas deste bimestre. Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() => _salvando = true);

    try {
      _bimestre.removerAvaliacao(indice);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});
      _mostrarMensagem('Avaliação "$nome" removida.');
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível remover: ${_limparErro(erro)}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _linhaAvaliacao(int indice) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;
    final String nome = _bimestre.avaliacoes[indice];
    final int lancadas = _bimestre.quantidadeNotasLancadas(indice);
    final int totalAlunos = widget.turma.alunos.length;
    final bool podeRemover = _bimestre.avaliacoes.length > 1 && !_salvando;

    final String subtitulo = totalAlunos == 0
        ? 'Nenhum aluno cadastrado nesta turma.'
        : '$lancadas de $totalAlunos notas lançadas';

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '${indice + 1}',
            style: TextStyle(
              color: scheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        nome,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: tema.textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        subtitulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Renomear avaliação',
            onPressed: _salvando ? null : () => _renomear(indice),
            icon: const Icon(Icons.edit_rounded, size: 20),
          ),
          IconButton(
            tooltip: podeRemover
                ? 'Remover avaliação'
                : 'O bimestre precisa de pelo menos uma avaliação',
            onPressed: podeRemover ? () => _remover(indice) : null,
            style: IconButton.styleFrom(
              foregroundColor: podeRemover
                  ? AppTheme.danger
                  : scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;
    final int quantidade = _bimestre.avaliacoes.length;
    final bool noLimite = quantidade >= Bimestre.limiteAvaliacoes;

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            color: scheme.primary.withValues(alpha: 0.06),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calculate_rounded, size: 21, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A média do bimestre é a média simples de todas as '
                    'avaliações. O aluno fica pendente até todas elas terem '
                    'nota lançada. A recuperação continua valendo quando a '
                    'média fica abaixo de '
                    '${formatarNotaTexto(widget.professor.mediaMinima)}.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SectionHeader(
            titulo: 'Avaliações do ${_bimestre.numero}º bimestre',
            acao: Text(
              '$quantidade de ${Bimestre.limiteAvaliacoes}',
              style: tema.textTheme.bodyMedium?.copyWith(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 10),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < quantidade; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 62,
                      endIndent: 12,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  _linhaAvaliacao(i),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: _salvando || noLimite ? null : _adicionar,
            icon: Icon(
              noLimite ? Icons.lock_rounded : Icons.add_rounded,
              size: 18,
            ),
            label: Text(
              noLimite
                  ? 'Limite de ${Bimestre.limiteAvaliacoes} avaliações'
                  : 'Adicionar avaliação',
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Você pode usar nomes como "Prova", "Trabalho", "Teste" ou '
            '"Atividade". Cada turma e bimestre tem sua própria lista de '
            'avaliações. Remover uma avaliação também remove as notas dela.',
            style: tema.textTheme.bodyMedium?.copyWith(
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
