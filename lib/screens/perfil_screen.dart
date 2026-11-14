import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../services/armazenamento_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_widgets.dart';

/// Edição do perfil do professor e da regra de aprovação.
class PerfilScreen extends StatefulWidget {
  final Professor professor;

  const PerfilScreen({super.key, required this.professor});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController = TextEditingController(
    text: widget.professor.nome,
  );

  late final TextEditingController _mediaController = TextEditingController(
    text: widget.professor.mediaMinima.toStringAsFixed(1).replaceAll('.', ','),
  );

  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final String nome = _nomeController.text.trim();

    final double media = double.parse(
      _mediaController.text.trim().replaceAll(',', '.'),
    );

    setState(() => _salvando = true);

    try {
      widget.professor.editarPerfil(nome: nome, mediaMinima: media);
      await ArmazenamentoService.salvarProfessor(widget.professor);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil e regras atualizados!')),
      );

      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      setState(() => _salvando = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil e regras')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(titulo: 'Seu perfil'),

              const SizedBox(height: 10),

              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome do professor',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe o seu nome.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _mediaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Média mínima para aprovação',
                        prefixIcon: Icon(Icons.rule_rounded),
                        helperText: 'Use um valor entre 0 e 10.',
                      ),
                      validator: (valor) {
                        final double? media = double.tryParse(
                          (valor ?? '').trim().replaceAll(',', '.'),
                        );

                        if (media == null || !media.isFinite) {
                          return 'Informe um número válido.';
                        }

                        if (media < 0 || media > 10) {
                          return 'A média deve estar entre 0 e 10.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const SectionHeader(titulo: 'Como as notas são calculadas'),

              const SizedBox(height: 10),

              AppCard(
                color: tema.colorScheme.primary.withValues(alpha: 0.06),
                border: Border.all(
                  color: tema.colorScheme.primary.withValues(alpha: 0.16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RegraItem(
                      icone: Icons.calculate_rounded,
                      titulo: 'Média das avaliações',
                      descricao:
                          'Média simples de todas as avaliações do bimestre. '
                          'A média fica pendente até todas serem lançadas.',
                    ),
                    const SizedBox(height: 14),
                    _RegraItem(
                      icone: Icons.tune_rounded,
                      titulo: 'Avaliações personalizadas',
                      descricao:
                          'Cada turma e bimestre pode ter provas, trabalhos e '
                          'testes com nomes próprios.',
                    ),
                    const SizedBox(height: 14),
                    _RegraItem(
                      icone: Icons.restore_rounded,
                      titulo: 'Com recuperação',
                      descricao:
                          'Se a média das avaliações ficar abaixo de '
                          '${formatarNotaTexto(widget.professor.mediaMinima)}, '
                          'a recuperação entra na média: '
                          '(média das avaliações + recuperação) ÷ 2.',
                    ),
                    const SizedBox(height: 14),
                    _RegraItem(
                      icone: Icons.verified_rounded,
                      titulo: 'Situação do aluno',
                      descricao:
                          'Aprovado quando a média final for maior ou igual '
                          'à média mínima configurada.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GradientButton(
                label: _salvando ? 'Salvando...' : 'Salvar alterações',
                icon: Icons.check_rounded,
                onPressed: _salvando ? null : _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegraItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;

  const _RegraItem({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 20, color: tema.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: tema.textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                descricao,
                style: tema.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
