import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/registro_presenca.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';

/// Controle de frequência por aula/data, com percentual por aluno.
class FrequenciaScreen extends StatefulWidget {
  final Professor professor;
  final Turma turma;

  const FrequenciaScreen({
    super.key,
    required this.professor,
    required this.turma,
  });

  @override
  State<FrequenciaScreen> createState() => _FrequenciaScreenState();
}

class _FrequenciaScreenState extends State<FrequenciaScreen> {
  static const double _limiteRisco = 75;

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _adicionarAula() async {
    final DateTime agora = DateTime.now();

    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Data da aula',
      cancelText: 'Cancelar',
      confirmText: 'Registrar',
    );

    if (data == null || !mounted) return;

    final String iso = RegistroPresenca.dataParaIso(data);

    try {
      widget.turma.adicionarPresenca(iso);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      setState(() {});
      _mensagem('Aula de ${RegistroPresenca.formatarData(iso)} registrada.');
    } catch (erro) {
      if (!mounted) return;
      _mensagem(erro.toString().replaceFirst('ArgumentError: ', ''));
    }
  }

  Future<void> _alternarPresenca(int registro, int aluno) async {
    widget.turma.alternarPresenca(registro: registro, aluno: aluno);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (mounted) setState(() {});
  }

  Future<void> _excluirAula(int indice) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir aula?'),
          content: const Text(
            'A chamada dessa data será removida. '
            'As demais aulas não serão afetadas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final RegistroPresenca removido = widget.turma.presencas[indice];

    widget.turma.removerPresencaNoIndice(indice);
    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Aula de ${RegistroPresenca.formatarData(removido.data)} excluída.',
          ),
          // Sem isso, o aviso com ação fica preso na tela para sempre.
          persist: false,
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              widget.turma.presencas.insert(indice, removido);
              widget.turma.presencas.sort((a, b) => a.data.compareTo(b.data));

              await ArmazenamentoService.salvarProfessor(widget.professor);

              if (mounted) setState(() {});
            },
          ),
        ),
      );
  }

  double? _mediaPresenca() {
    final List<double> percentuais = [
      for (int i = 0; i < widget.turma.alunos.length; i++)
        if (widget.turma.percentualPresenca(i) != null)
          widget.turma.percentualPresenca(i)!,
    ];

    if (percentuais.isEmpty) return null;

    return percentuais.reduce((a, b) => a + b) / percentuais.length;
  }

  int _quantidadeEmRisco() {
    int total = 0;

    for (int i = 0; i < widget.turma.alunos.length; i++) {
      final double? percentual = widget.turma.percentualPresenca(i);

      if (percentual != null && percentual < _limiteRisco) {
        total++;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    if (widget.turma.alunos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Frequência')),
        body: const EmptyState(
          icon: Icons.people_alt_rounded,
          titulo: 'Nenhum aluno cadastrado.',
          mensagem:
              'Cadastre os alunos da turma antes de registrar a frequência.',
        ),
      );
    }

    final double? media = _mediaPresenca();
    final int emRisco = _quantidadeEmRisco();

    return Scaffold(
      appBar: AppBar(title: Text('Frequência • ${widget.turma.nome}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              gradient: AppTheme.brandGradient,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Resumo da frequência',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ResumoClaro(
                        valor: widget.turma.presencas.length.toString(),
                        titulo: 'Aulas',
                      ),
                      const SizedBox(width: 10),
                      _ResumoClaro(
                        valor: media == null
                            ? '—'
                            : formatarPercentualTexto(media),
                        titulo: 'Presença média',
                      ),
                      const SizedBox(width: 10),
                      _ResumoClaro(
                        valor: emRisco.toString(),
                        titulo: 'Em risco',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(
                  child: SectionHeader(titulo: 'Frequência por aluno'),
                ),
                Text(
                  'Risco: abaixo de ${_limiteRisco.toInt()}%',
                  style: tema.textTheme.bodyMedium?.copyWith(fontSize: 10.5),
                ),
              ],
            ),

            const SizedBox(height: 10),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: List.generate(widget.turma.alunos.length, (index) {
                  final aluno = widget.turma.alunos[index];
                  final double? percentual = widget.turma.percentualPresenca(
                    index,
                  );

                  final bool risco =
                      percentual != null && percentual < _limiteRisco;

                  final Color cor = percentual == null
                      ? tema.colorScheme.outline
                      : risco
                      ? AppTheme.warning
                      : AppTheme.success;

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 1,
                          color: tema.colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: cor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Center(
                                    child: Text(
                                      inicialDoNome(aluno.nome),
                                      style: TextStyle(
                                        color: cor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    aluno.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tema.textTheme.titleMedium?.copyWith(
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                if (risco) ...[
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: AppTheme.warning,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  formatarPercentualTexto(
                                    percentual,
                                    vazio: 'Sem aulas',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: cor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (percentual ?? 0) / 100,
                                minHeight: 6,
                                backgroundColor: cor.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(cor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(
                  child: SectionHeader(titulo: 'Aulas registradas'),
                ),
                FilledButton.icon(
                  onPressed: _adicionarAula,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Registrar aula'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (widget.turma.presencas.isEmpty)
              AppCard(
                padding: EdgeInsets.zero,
                child: EmptyState(
                  icon: Icons.event_available_rounded,
                  titulo: 'Nenhuma aula registrada.',
                  mensagem:
                      'Registre a primeira aula para acompanhar a presença '
                      'dos alunos.',
                  acao: GradientButton(
                    label: 'Registrar primeira aula',
                    icon: Icons.add_rounded,
                    expandido: false,
                    onPressed: _adicionarAula,
                  ),
                ),
              )
            else
              ...List.generate(widget.turma.presencas.length, (indice) {
                final registro = widget.turma.presencas[indice];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartaoAula(
                    data: registro.data,
                    presentes: registro.presentes.length,
                    quantidadePresentes: registro.quantidadePresentes,
                    alunos: widget.turma.alunos.map((a) => a.nome).toList(),
                    presencas: registro.presentes,
                    aoAlternar: (aluno) => _alternarPresenca(indice, aluno),
                    aoExcluir: () => _excluirAula(indice),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ResumoClaro extends StatelessWidget {
  final String valor;
  final String titulo;

  const _ResumoClaro({required this.valor, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoAula extends StatelessWidget {
  final String data;
  final int presentes;
  final int quantidadePresentes;
  final List<String> alunos;
  final List<bool> presencas;
  final ValueChanged<int> aoAlternar;
  final VoidCallback aoExcluir;

  const _CartaoAula({
    required this.data,
    required this.presentes,
    required this.quantidadePresentes,
    required this.alunos,
    required this.presencas,
    required this.aoAlternar,
    required this.aoExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tema.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 19,
                  color: tema.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RegistroPresenca.formatarData(data),
                      style: tema.textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$quantidadePresentes de $presentes presentes',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir aula',
                onPressed: aoExcluir,
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              const double espaco = 8;
              final int colunas = constraints.maxWidth >= 620 ? 3 : 2;
              final double largura =
                  (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

              return Wrap(
                spacing: espaco,
                runSpacing: espaco,
                children: List.generate(alunos.length, (indice) {
                  final bool presente =
                      indice < presencas.length && presencas[indice];

                  return SizedBox(
                    width: largura,
                    child: _ChipPresenca(
                      nome: alunos[indice],
                      presente: presente,
                      onTap: () => aoAlternar(indice),
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 10),

          Text(
            'Toque no nome para alternar presença e falta.',
            style: tema.textTheme.bodyMedium?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ChipPresenca extends StatelessWidget {
  final String nome;
  final bool presente;
  final VoidCallback onTap;

  const _ChipPresenca({
    required this.nome,
    required this.presente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color cor = presente ? AppTheme.success : AppTheme.danger;

    return Material(
      color: cor.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(
                presente ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: cor,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
