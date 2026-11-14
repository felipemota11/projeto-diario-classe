import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import '../services/calculo_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';
import '../widgets/status_chip.dart';

/// Boletim individual com o desempenho em todos os bimestres.
class BoletimScreen extends StatefulWidget {
  final Professor professor;
  final Turma turma;
  final int indiceAluno;

  const BoletimScreen({
    super.key,
    required this.professor,
    required this.turma,
    required this.indiceAluno,
  });

  @override
  State<BoletimScreen> createState() => _BoletimScreenState();
}

class _BoletimScreenState extends State<BoletimScreen> {
  bool _gerandoPdf = false;

  Future<void> _exportarPdf() async {
    setState(() => _gerandoPdf = true);

    try {
      await PdfService.exportarBoletim(
        professor: widget.professor,
        turma: widget.turma,
        indiceAluno: widget.indiceAluno,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boletim em PDF gerado com sucesso!')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $erro')),
      );
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  double? _mediaGeral() {
    final List<double> medias = [];

    for (final bimestre in widget.turma.bimestres) {
      final double? media = CalculoService.calcularMedia(
        bimestre,
        widget.indiceAluno,
        mediaMinima: widget.professor.mediaMinima,
      );

      if (media != null) medias.add(media);
    }

    if (medias.isEmpty) return null;

    return medias.reduce((a, b) => a + b) / medias.length;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    if (widget.indiceAluno < 0 ||
        widget.indiceAluno >= widget.turma.alunos.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boletim')),
        body: const EmptyState(
          icon: Icons.person_off_rounded,
          titulo: 'Aluno não encontrado.',
          mensagem: 'Volte para a lista de alunos e tente novamente.',
        ),
      );
    }

    final aluno = widget.turma.alunos[widget.indiceAluno];
    final double? mediaGeral = _mediaGeral();
    final double? frequencia = widget.turma.percentualPresenca(
      widget.indiceAluno,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Boletim do aluno')),
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
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            inicialDoNome(aluno.nome),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              aluno.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Matrícula: ${aluno.matricula}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ResumoBoletim(
                          titulo: 'Média geral',
                          valor: formatarNotaTexto(mediaGeral, vazio: '—'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResumoBoletim(
                          titulo: 'Frequência',
                          valor: formatarPercentualTexto(
                            frequencia,
                            vazio: '—',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResumoBoletim(
                          titulo: 'Bimestres',
                          valor: widget.turma.bimestres.length.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                const Expanded(
                  child: SectionHeader(titulo: 'Desempenho por bimestre'),
                ),
                Text(
                  'Mínima: ${formatarNotaTexto(widget.professor.mediaMinima)}',
                  style: tema.textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (widget.turma.bimestres.isEmpty)
              const AppCard(
                padding: EdgeInsets.zero,
                child: EmptyState(
                  icon: Icons.calendar_month_rounded,
                  titulo: 'Nenhum bimestre cadastrado.',
                  mensagem:
                      'Cadastre bimestres na tela de notas para gerar o '
                      'boletim.',
                ),
              )
            else
              ...widget.turma.bimestres.map((bimestre) {
                final double? recuperacao =
                    bimestre.recuperacoes[widget.indiceAluno];

                final double? media = CalculoService.calcularMedia(
                  bimestre,
                  widget.indiceAluno,
                  mediaMinima: widget.professor.mediaMinima,
                );

                final String situacao = CalculoService.verificarSituacao(
                  bimestre,
                  widget.indiceAluno,
                  mediaMinima: widget.professor.mediaMinima,
                );

                final bool recuperacaoAplicada =
                    CalculoService.recuperacaoAplicada(
                      bimestre,
                      widget.indiceAluno,
                      mediaMinima: widget.professor.mediaMinima,
                    );

                final String formula = recuperacaoAplicada
                    ? 'Média final = (média das avaliações + recuperação) ÷ 2'
                    : bimestre.avaliacoes.length == 1
                    ? 'Média final = nota da avaliação'
                    : 'Média final = média simples das '
                          '${bimestre.avaliacoes.length} avaliações';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${bimestre.numero}º Bimestre',
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            StatusChip(situacao: situacao),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double espaco = 8;
                            final int colunas = constraints.maxWidth >= 520
                                ? 4
                                : 2;
                            final double largura =
                                (constraints.maxWidth -
                                    espaco * (colunas - 1)) /
                                colunas;

                            return Wrap(
                              spacing: espaco,
                              runSpacing: espaco,
                              children: [
                                for (
                                  int j = 0;
                                  j < bimestre.avaliacoes.length;
                                  j++
                                )
                                  SizedBox(
                                    width: largura,
                                    child: _ValorBimestre(
                                      titulo: bimestre.avaliacoes[j],
                                      valor: formatarNotaTexto(
                                        bimestre.notasLancadas[widget
                                                .indiceAluno][j]
                                            ? bimestre.notas[widget
                                                  .indiceAluno][j]
                                            : null,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  width: largura,
                                  child: _ValorBimestre(
                                    titulo: 'Recuperação',
                                    valor: formatarNotaTexto(recuperacao),
                                  ),
                                ),
                                SizedBox(
                                  width: largura,
                                  child: _ValorBimestre(
                                    titulo: 'Média final',
                                    valor: formatarNotaTexto(
                                      media,
                                      vazio: 'Pendente',
                                    ),
                                    destaque: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formula,
                          style: tema.textTheme.bodyMedium?.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            if (aluno.observacao.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionHeader(titulo: 'Observações'),
              const SizedBox(height: 10),
              AppCard(
                color: AppTheme.warning.withValues(alpha: 0.07),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_rounded,
                      size: 20,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        aluno.observacao.trim(),
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            GradientButton(
              label: _gerandoPdf ? 'Gerando PDF...' : 'Salvar boletim em PDF',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: _gerandoPdf ? null : _exportarPdf,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoBoletim extends StatelessWidget {
  final String titulo;
  final String valor;

  const _ResumoBoletim({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              fontSize: 17,
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
    );
  }
}

class _ValorBimestre extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool destaque;

  const _ValorBimestre({
    required this.titulo,
    required this.valor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme scheme = tema.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: destaque
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: destaque
            ? Border.all(color: scheme.primary.withValues(alpha: 0.18))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodyMedium?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.numerico(
              TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: destaque ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
