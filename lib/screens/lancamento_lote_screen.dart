import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';

/// Tela para lançar as notas de todos os alunos de uma vez.
class LancamentoLoteScreen extends StatefulWidget {
  final Professor professor;
  final Turma turma;
  final Bimestre bimestre;

  const LancamentoLoteScreen({
    super.key,
    required this.professor,
    required this.turma,
    required this.bimestre,
  });

  @override
  State<LancamentoLoteScreen> createState() => _LancamentoLoteScreenState();
}

class _LancamentoLoteScreenState extends State<LancamentoLoteScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<List<TextEditingController>> _notas = [];
  final List<TextEditingController> _rec = [];

  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < widget.turma.alunos.length; i++) {
      _notas.add(
        List<TextEditingController>.generate(
          widget.bimestre.avaliacoes.length,
          (j) => TextEditingController(text: _inicial(i, j)),
        ),
      );
      _rec.add(
        TextEditingController(
          text: i < widget.bimestre.recuperacoes.length
              ? _formatar(widget.bimestre.recuperacoes[i])
              : '',
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final linha in _notas) {
      for (final controller in linha) {
        controller.dispose();
      }
    }

    for (final controller in _rec) {
      controller.dispose();
    }

    super.dispose();
  }

  String _formatar(double? nota) {
    if (nota == null) return '';

    return nota.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _inicial(int indiceAluno, int avaliacao) {
    if (indiceAluno >= widget.bimestre.notas.length) return '';
    if (!widget.bimestre.notasLancadas[indiceAluno][avaliacao]) return '';

    return _formatar(widget.bimestre.notas[indiceAluno][avaliacao]);
  }

  double? _lerNota(String texto) {
    final String limpo = texto.trim().replaceAll(',', '.');

    if (limpo.isEmpty) return null;

    return double.tryParse(limpo);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      for (int i = 0; i < widget.turma.alunos.length; i++) {
        for (int j = 0; j < _notas[i].length; j++) {
          final double? nota = _lerNota(_notas[i][j].text);

          if (nota == null) {
            widget.bimestre.limparNota(indiceAluno: i, avaliacao: j + 1);
          } else {
            widget.bimestre.registrarNota(
              indiceAluno: i,
              avaliacao: j + 1,
              nota: nota,
            );
          }
        }

        final double? rec = _lerNota(_rec[i].text);

        if (rec == null) {
          widget.bimestre.limparRecuperacao(i);
        } else {
          widget.bimestre.registrarRecuperacao(indiceAluno: i, nota: rec);
        }
      }

      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      setState(() => _salvando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar as notas: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento em lote')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          itemCount: widget.turma.alunos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  color: tema.colorScheme.primary.withValues(alpha: 0.06),
                  border: Border.all(
                    color: tema.colorScheme.primary.withValues(alpha: 0.16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.grid_on_rounded,
                        size: 20,
                        color: tema.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Preencha as notas das avaliações do '
                          '${widget.bimestre.numero}º bimestre. Deixe um '
                          'campo vazio para remover a nota. As notas devem '
                          'ficar entre 0 e 10.',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final int i = index - 1;
            final aluno = widget.turma.alunos[i];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: tema.colorScheme.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              inicialDoNome(aluno.nome),
                              style: TextStyle(
                                color: tema.colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aluno.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                'Matrícula: ${aluno.matricula}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _camposDoAluno(i),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: 0.35),
              ),
            ),
          ),
          child: GradientButton(
            label: _salvando ? 'Salvando...' : 'Salvar todas as notas',
            icon: Icons.check_rounded,
            onPressed: _salvando ? null : _salvar,
          ),
        ),
      ),
    );
  }

  // Distribui os campos em uma grade que se adapta ao espaço disponível.
  Widget _camposDoAluno(int indiceAluno) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double espaco = 8;
        final int colunas = constraints.maxWidth >= 620
            ? 4
            : constraints.maxWidth >= 420
            ? 3
            : 2;
        final double largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: 10,
          children: [
            for (int j = 0; j < _notas[indiceAluno].length; j++)
              SizedBox(
                width: largura,
                child: _campoNota(
                  controller: _notas[indiceAluno][j],
                  label: widget.bimestre.avaliacoes[j],
                  acao: TextInputAction.next,
                ),
              ),
            SizedBox(
              width: largura,
              child: _campoNota(
                controller: _rec[indiceAluno],
                label: 'Recuperação',
                acao: TextInputAction.done,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _campoNota({
    required TextEditingController controller,
    required String label,
    required TextInputAction acao,
  }) {
    final ThemeData tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: label,
          child: Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodyMedium?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: acao,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: '—',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          ),
          validator: (valor) {
            final String limpo = (valor ?? '').trim();

            if (limpo.isEmpty) return null;

            final double? nota = double.tryParse(limpo.replaceAll(',', '.'));

            if (nota == null || !nota.isFinite) {
              return 'Inválido';
            }

            if (nota < 0 || nota > 10) {
              return '0 a 10';
            }

            return null;
          },
        ),
      ],
    );
  }
}
