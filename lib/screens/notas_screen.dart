import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../services/calculo_service.dart';
import '../widgets/status_chip.dart';
import 'lancamento_lote_screen.dart';
import 'avaliacoes_screen.dart';
import 'relatorio_semestral_screen.dart';

/// Lançamento individual: Prova 1 + Prova 2 e, se necessária, Prova Final.
class NotasScreen extends StatefulWidget {
  final Professor professor;
  const NotasScreen({super.key, required this.professor});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  int _turmaSelecionada = 0;
  int? _alunoSelecionado;
  bool _somentePendentes = false;

  String _nota(double? valor) => valor == null
      ? 'Pendente'
      : valor.toStringAsFixed(2).replaceAll('.', ',');

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _alterar(void Function() acao, String sucesso) async {
    try {
      await ArmazenamentoService.alterarProfessor(widget.professor, acao);
      if (!mounted) return;
      setState(() {});
      _mensagem(sucesso);
    } catch (erro) {
      if (!mounted) return;
      setState(() {});
      _mensagem('Não foi possível salvar: $erro');
    }
  }

  Future<double?> _pedirNota(String titulo, double? atual) async {
    final formKey = GlobalKey<FormState>();
    double? notaInformada;
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: atual == null
                ? ''
                : atual.toString().replaceAll('.', ','),
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nota de 0 a 10',
              hintText: 'Ex.: 8,5',
            ),
            validator: (valor) {
              final numero = double.tryParse(
                (valor ?? '').trim().replaceAll(',', '.'),
              );
              if (numero == null ||
                  !numero.isFinite ||
                  numero < 0 ||
                  numero > 10) {
                return 'Informe uma nota válida entre 0 e 10.';
              }
              return null;
            },
            onSaved: (valor) => notaInformada = double.parse(
              valor!.trim().replaceAll(',', '.'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              formKey.currentState!.save();
              Navigator.pop(dialogContext, notaInformada);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarProva(Bimestre bimestre, int indiceAluno) async {
    final nota = await _pedirNota(
      '${bimestre.numero}º bimestre — ${bimestre.nomeProva}',
      bimestre.obterNota(indiceAluno),
    );
    if (!mounted || nota == null) return;
    await _alterar(() {
      bimestre.registrarNota(indiceAluno: indiceAluno, nota: nota);
    }, 'Nota registrada com sucesso.');
  }

  Future<void> _limparProva(
    Turma turma,
    Bimestre bimestre,
    int indiceAluno,
  ) async {
    await _alterar(() {
      bimestre.limparNota(indiceAluno: indiceAluno);
      final segundo = turma.segundoBimestre;
      segundo.limparProvaFinal(indiceAluno);
    }, 'Nota removida.');
  }

  Future<void> _editarFinal(
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno,
  ) async {
    if (!CalculoService.precisaProvaFinal(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: widget.professor.mediaMinima,
    )) {
      return;
    }
    final nota = await _pedirNota(
      'Prova final',
      segundo.provasFinais[indiceAluno],
    );
    if (!mounted || nota == null) return;
    await _alterar(() {
      CalculoService.registrarProvaFinal(
        primeiro,
        segundo,
        indiceAluno,
        nota,
        mediaMinima: widget.professor.mediaMinima,
      );
    }, 'Prova final registrada.');
  }

  Future<void> _abrirLote(Turma turma) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LancamentoLoteScreen(professor: widget.professor, turma: turma),
      ),
    );
    if (!mounted) return;
    if (salvou == true) setState(() {});
  }

  bool _pendente(Bimestre primeiro, Bimestre segundo, int i) {
    return CalculoService.pendenciasSemestrais(
      primeiro,
      segundo,
      i,
      mediaMinima: widget.professor.mediaMinima,
    ).isNotEmpty;
  }

  Widget _linhaNota({
    required String titulo,
    required double? nota,
    required VoidCallback aoEditar,
    VoidCallback? aoRemover,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo),
      subtitle: Text(_nota(nota)),
      trailing: Wrap(
        spacing: 2,
        children: [
          IconButton(
            tooltip: 'Lançar ou alterar',
            icon: Icon(
              nota == null ? Icons.add_circle_outline : Icons.edit_outlined,
            ),
            onPressed: aoEditar,
          ),
          if (nota != null && aoRemover != null)
            IconButton(
              tooltip: 'Remover nota',
              icon: const Icon(Icons.delete_outline),
              onPressed: aoRemover,
            ),
        ],
      ),
    );
  }

  Widget _notasAluno(
    Turma turma,
    Bimestre primeiro,
    Bimestre segundo,
    int indiceAluno,
  ) {
    final minima = widget.professor.mediaMinima;
    final media = CalculoService.calcularMediaSemestral(
      primeiro,
      segundo,
      indiceAluno,
    );
    final mediaFinal = CalculoService.calcularMediaFinalSemestral(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: minima,
    );
    final situacao = CalculoService.verificarSituacaoSemestral(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: minima,
    );
    final precisaFinal = media != null && media < minima;
    final necessaria = CalculoService.notaNecessariaProvaFinal(
      primeiro,
      segundo,
      indiceAluno,
      mediaMinima: minima,
    );
    final finalNota = segundo.provasFinais[indiceAluno];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turma.alunos[indiceAluno].nome,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Matrícula: ${turma.alunos[indiceAluno].matricula}'),
            const SizedBox(height: 12),
            _linhaNota(
              titulo: '1º bimestre — ${primeiro.nomeProva}',
              nota: primeiro.obterNota(indiceAluno),
              aoEditar: () => _editarProva(primeiro, indiceAluno),
              aoRemover: () => _limparProva(turma, primeiro, indiceAluno),
            ),
            const Divider(),
            _linhaNota(
              titulo: '2º bimestre — ${segundo.nomeProva}',
              nota: segundo.obterNota(indiceAluno),
              aoEditar: () => _editarProva(segundo, indiceAluno),
              aoRemover: () => _limparProva(turma, segundo, indiceAluno),
            ),
            const Divider(),
            Text('Média semestral: ${_nota(media)}'),
            if (precisaFinal) ...[
              const SizedBox(height: 8),
              if (necessaria != null)
                Text(
                  necessaria > 10
                      ? 'Mesmo com 10, não atinge a média mínima.'
                      : 'Nota necessária na prova final: ${_nota(necessaria)}',
                ),
              _linhaNota(
                titulo: 'Prova final',
                nota: finalNota,
                aoEditar: () => _editarFinal(primeiro, segundo, indiceAluno),
                aoRemover: () => _alterar(
                  () => CalculoService.limparProvaFinal(segundo, indiceAluno),
                  'Prova final removida.',
                ),
              ),
            ] else if (media != null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Prova final não necessária.'),
              ),
            const Divider(),
            Text(
              'Média final: ${_nota(mediaFinal)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            StatusChip(situacao: situacao),
            const SizedBox(height: 8),
            Text('Média mínima: ${_nota(minima)}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas.where((t) => !t.arquivada).toList();
    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lançamento de notas')),
        body: const Center(child: Text('Cadastre ou desarquive uma turma.')),
      );
    }
    final indiceTurma = _turmaSelecionada < turmas.length
        ? _turmaSelecionada
        : 0;
    final turma = turmas[indiceTurma];
    final primeiro = turma.primeiroBimestre;
    final segundo = turma.segundoBimestre;

    final todos = List<int>.generate(turma.alunos.length, (i) => i);
    final visiveis = _somentePendentes
        ? todos.where((i) => _pendente(primeiro, segundo, i)).toList()
        : todos;
    final selecionado = visiveis.contains(_alunoSelecionado)
        ? _alunoSelecionado!
        : (visiveis.isEmpty ? null : visiveis.first);
    final quantidadePendentes = todos
        .where((i) => _pendente(primeiro, segundo, i))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamento de notas'),
        actions: [
          IconButton(
            tooltip: 'Lançamento em lote',
            onPressed: () => _abrirLote(turma),
            icon: const Icon(Icons.groups_outlined),
          ),
          IconButton(
            tooltip: 'Relatório semestral',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RelatorioSemestralScreen(professor: widget.professor),
              ),
            ),
            icon: const Icon(Icons.assessment_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey(indiceTurma),
            initialValue: indiceTurma,
            decoration: const InputDecoration(labelText: 'Selecionar turma'),
            items: [
              for (int i = 0; i < turmas.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    '${turmas[i].nome} — ${turmas[i].curso}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (valor) {
              if (valor == null) return;
              setState(() {
                _turmaSelecionada = valor;
                _alunoSelecionado = null;
                _somentePendentes = false;
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Avaliações do semestre',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ...[
            for (final bimestre in turma.bimestres)
              ListTile(
                title: Text(
                  '${bimestre.numero}º bimestre: ${bimestre.nomeProva}',
                ),
                subtitle: const Text('Nota de 0 a 10'),
                trailing: IconButton(
                  tooltip: 'Renomear prova',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AvaliacoesScreen(
                          professor: widget.professor,
                          bimestre: bimestre,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
            const SizedBox(height: 4),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alunos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilterChip(
                  label: Text('Pendentes ($quantidadePendentes)'),
                  selected: _somentePendentes,
                  onSelected: (valor) => setState(() {
                    _somentePendentes = valor;
                    _alunoSelecionado = null;
                  }),
                ),
              ],
            ),
            if (turma.alunos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Cadastre alunos para lançar notas.'),
              )
            else if (selecionado == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum aluno com notas pendentes.'),
              )
            else ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: ValueKey(
                  'aluno-$indiceTurma-$selecionado-$_somentePendentes',
                ),
                initialValue: selecionado,
                decoration: const InputDecoration(labelText: 'Aluno'),
                items: [
                  for (final i in visiveis)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        turma.alunos[i].nome,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (valor) => setState(() => _alunoSelecionado = valor),
              ),
              const SizedBox(height: 14),
              _notasAluno(turma, primeiro, segundo, selecionado),
            ],
          ],
        ],
      ),
    );
  }
}
