import 'package:flutter/material.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import '../models/bimestre.dart';
import '../services/calculo_service.dart';
import '../services/armazenamento_service.dart';

class NotasScreen extends StatefulWidget {
  final Professor professor;

  const NotasScreen({super.key, required this.professor});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  int? _turmaSelecionadaIndex;
  int? _bimestreSelecionadoNumero;
  int? _alunoSelecionadoIndex;

  // Exibe mensagens para o usuário.
  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Seletor reutilizável para turma, bimestre e aluno.
  Widget _seletor<T>({
    required String titulo,
    required IconData icone,
    required T valor,
    required List<DropdownMenuItem<T>> itens,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icone),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          items: itens,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Formata notas utilizando vírgula.
  String _formatarNota(double nota) {
    return nota.toStringAsFixed(2).replaceAll('.', ',');
  }

  // Cadastra um novo bimestre.
  Future<void> _adicionarBimestre(Turma turma) async {
    final formKey = GlobalKey<FormState>();

    String numeroTexto = '';

    final numero = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cadastrar bimestre'),

          content: Form(
            key: formKey,
            child: TextFormField(
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Número do bimestre',
                hintText: 'Ex.: 1',
                border: OutlineInputBorder(),
              ),

              onSaved: (value) {
                numeroTexto = value!.trim();
              },

              validator: (value) {
                final numero = int.tryParse(value?.trim() ?? '');

                if (numero == null || numero < 1) {
                  return 'Informe um número válido.';
                }

                final existe = turma.bimestres.any((b) => b.numero == numero);

                if (existe) {
                  return 'Esse bimestre já está cadastrado.';
                }

                return null;
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                formKey.currentState!.save();

                Navigator.pop(dialogContext, int.parse(numeroTexto));
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    if (!mounted || numero == null) return;

    turma.adicionarBimestre(numero);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {
      _bimestreSelecionadoNumero = numero;
      _alunoSelecionadoIndex = null;
    });

    _mostrarMensagem('Bimestre cadastrado com sucesso!');
  }

  // Solicita uma nota ao professor.
  Future<double?> _solicitarNota({
    required String titulo,
    double? notaAtual,
  }) async {
    final formKey = GlobalKey<FormState>();

    double? notaInformada;

    return await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),

          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: notaAtual?.toString() ?? '',

              autofocus: true,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Ex.: 8,5',
                helperText: 'Informe uma nota entre 0 e 10.',
                border: OutlineInputBorder(),
              ),

              onSaved: (value) {
                notaInformada = double.parse(
                  value!.trim().replaceAll(',', '.'),
                );
              },

              validator: (value) {
                final texto = value?.trim().replaceAll(',', '.');

                final nota = double.tryParse(texto ?? '');

                if (nota == null || !nota.isFinite) {
                  return 'Informe um número válido.';
                }

                if (nota < 0 || nota > 10) {
                  return 'A nota deve estar entre 0 e 10.';
                }

                return null;
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
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
              child: const Text('Salvar nota'),
            ),
          ],
        );
      },
    );
  }

  // Lança ou altera uma avaliação.
  Future<void> _editarAvaliacao({
    required Bimestre bimestre,
    required int indiceAluno,
    required int avaliacao,
  }) async {
    final coluna = avaliacao - 1;

    final jaLancada = bimestre.notasLancadas[indiceAluno][coluna];

    final notaAtual = jaLancada ? bimestre.notas[indiceAluno][coluna] : null;

    final nota = await _solicitarNota(
      titulo: jaLancada
          ? 'Alterar Prova $avaliacao'
          : 'Lançar Prova $avaliacao',
      notaAtual: notaAtual,
    );

    if (!mounted || nota == null) return;

    bimestre.registrarNota(
      indiceAluno: indiceAluno,
      avaliacao: avaliacao,
      nota: nota,
    );

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Prova $avaliacao salva com sucesso!');
  }

  // Lança ou altera a recuperação.
  Future<void> _editarRecuperacao({
    required Bimestre bimestre,
    required int indiceAluno,
  }) async {
    final podeRecuperar = CalculoService.podeFazerRecuperacao(
      bimestre,
      indiceAluno,
    );

    final recuperacaoAtual = bimestre.recuperacoes[indiceAluno];

    if (!podeRecuperar && recuperacaoAtual == null) {
      _mostrarMensagem('A recuperação não é necessária para este aluno.');
      return;
    }

    final nota = await _solicitarNota(
      titulo: recuperacaoAtual == null
          ? 'Lançar recuperação'
          : 'Alterar recuperação',
      notaAtual: recuperacaoAtual,
    );

    if (!mounted || nota == null) return;

    bimestre.registrarRecuperacao(indiceAluno: indiceAluno, nota: nota);

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Recuperação salva com sucesso!');
  }

  // Remove uma recuperação.
  Future<void> _removerRecuperacao({
    required Bimestre bimestre,
    required int indiceAluno,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover recuperação?'),

          content: const Text(
            'A nota de recuperação será removida. '
            'A média voltará a considerar somente as duas provas.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    bimestre.recuperacoes[indiceAluno] = null;

    await ArmazenamentoService.salvarProfessor(widget.professor);

    if (!mounted) return;

    setState(() {});

    _mostrarMensagem('Recuperação removida.');
  }

  @override
  Widget build(BuildContext context) {
    final turmas = widget.professor.turmas;

    // Verifica se existem turmas cadastradas.
    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lançamento de notas')),

        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 70, color: Colors.grey),

                SizedBox(height: 16),

                Text(
                  'Nenhuma turma cadastrada.',
                  style: TextStyle(fontSize: 18),
                ),

                SizedBox(height: 8),

                Text(
                  'Cadastre uma turma antes de lançar notas.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mantém um índice válido para a turma selecionada.
    final indiceTurma =
        _turmaSelecionadaIndex != null &&
            _turmaSelecionadaIndex! >= 0 &&
            _turmaSelecionadaIndex! < turmas.length
        ? _turmaSelecionadaIndex!
        : 0;

    final turma = turmas[indiceTurma];

    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento de notas')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar turma',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _seletor<int>(
              titulo: 'Turma',
              icone: Icons.school,
              valor: indiceTurma,

              itens: List.generate(turmas.length, (index) {
                final item = turmas[index];

                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    '${item.nome} - ${item.curso}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),

              onChanged: (valor) {
                if (valor == null) return;

                setState(() {
                  _turmaSelecionadaIndex = valor;
                  _bimestreSelecionadoNumero = null;
                  _alunoSelecionadoIndex = null;
                });
              },
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bimestre',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                OutlinedButton.icon(
                  onPressed: () => _adicionarBimestre(turma),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo bimestre'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (turma.bimestres.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhum bimestre cadastrado. '
                    'Utilize o botão acima para criar o primeiro.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              _construirConteudoBimestre(turma, indiceTurma),
          ],
        ),
      ),
    );
  }

  // Constrói a seleção de bimestre e aluno.
  Widget _construirConteudoBimestre(Turma turma, int indiceTurma) {
    final bimestres = turma.bimestres;

    // Localiza o bimestre selecionado.
    final selecionados = bimestres.where(
      (b) => b.numero == _bimestreSelecionadoNumero,
    );

    final Bimestre bimestre = selecionados.isNotEmpty
        ? selecionados.first
        : bimestres.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seletor<int>(
          titulo: 'Escolha o bimestre',
          icone: Icons.calendar_month,
          valor: bimestre.numero,

          itens: bimestres.map((item) {
            return DropdownMenuItem<int>(
              value: item.numero,
              child: Text('${item.numero}º Bimestre'),
            );
          }).toList(),

          onChanged: (numero) {
            if (numero == null) return;

            setState(() {
              _bimestreSelecionadoNumero = numero;
              _alunoSelecionadoIndex = null;
            });
          },
        ),

        const SizedBox(height: 24),

        const Text(
          'Selecionar aluno',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        if (turma.alunos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Esta turma ainda não possui alunos. '
                'Cadastre estudantes na tela de turmas.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          _construirNotasDoAluno(turma, bimestre),
      ],
    );
  }

  // Exibe as avaliações e a situação acadêmica.
  Widget _construirNotasDoAluno(Turma turma, Bimestre bimestre) {
    final alunos = turma.alunos;

    // Garante que o índice do aluno seja válido.
    final indiceAluno =
        _alunoSelecionadoIndex != null &&
            _alunoSelecionadoIndex! >= 0 &&
            _alunoSelecionadoIndex! < alunos.length
        ? _alunoSelecionadoIndex!
        : 0;

    final aluno = alunos[indiceAluno];

    final prova1Lancada = bimestre.notasLancadas[indiceAluno][0];

    final prova2Lancada = bimestre.notasLancadas[indiceAluno][1];

    final nota1 = bimestre.notas[indiceAluno][0];
    final nota2 = bimestre.notas[indiceAluno][1];

    final recuperacao = bimestre.recuperacoes[indiceAluno];

    // Média das duas provas.
    final mediaProvas = CalculoService.calcularMediaProvas(
      bimestre,
      indiceAluno,
    );

    // Média final, considerando recuperação.
    final media = CalculoService.calcularMedia(bimestre, indiceAluno);

    // Verifica se a recuperação pode ser aplicada.
    final podeLancarRecuperacao = CalculoService.podeFazerRecuperacao(
      bimestre,
      indiceAluno,
    );

    // A recuperação somente é aplicada se a média original
    // for menor que 7,0.
    final recuperacaoAplicada = recuperacao != null && podeLancarRecuperacao;

    final situacao = CalculoService.verificarSituacao(bimestre, indiceAluno);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seletor<int>(
          titulo: 'Selecionar aluno',
          icone: Icons.person,
          valor: indiceAluno,

          itens: List.generate(alunos.length, (index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text(alunos[index].nome, overflow: TextOverflow.ellipsis),
            );
          }),

          onChanged: (valor) {
            if (valor == null) return;

            setState(() {
              _alunoSelecionadoIndex = valor;
            });
          },
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text('Matrícula: ${aluno.matricula}'),

                const Divider(height: 24),

                // Avaliações regulares.
                const Text(
                  'Avaliações regulares',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,

                  title: const Text('Prova 1'),

                  subtitle: Text(
                    prova1Lancada
                        ? 'Nota: ${_formatarNota(nota1)}'
                        : 'Nota ainda não lançada',
                  ),

                  trailing: IconButton(
                    tooltip: 'Lançar ou alterar Prova 1',
                    icon: const Icon(Icons.edit),

                    onPressed: () {
                      _editarAvaliacao(
                        bimestre: bimestre,
                        indiceAluno: indiceAluno,
                        avaliacao: 1,
                      );
                    },
                  ),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,

                  title: const Text('Prova 2'),

                  subtitle: Text(
                    prova2Lancada
                        ? 'Nota: ${_formatarNota(nota2)}'
                        : 'Nota ainda não lançada',
                  ),

                  trailing: IconButton(
                    tooltip: 'Lançar ou alterar Prova 2',
                    icon: const Icon(Icons.edit),

                    onPressed: () {
                      _editarAvaliacao(
                        bimestre: bimestre,
                        indiceAluno: indiceAluno,
                        avaliacao: 2,
                      );
                    },
                  ),
                ),

                const Divider(height: 24),

                // Recuperação.
                const Text(
                  'Recuperação',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,

                  title: const Text('Nota de recuperação'),

                  subtitle: Text(
                    recuperacao != null
                        ? 'Nota: ${_formatarNota(recuperacao)}'
                        : mediaProvas == null
                        ? 'Lance as duas provas primeiro.'
                        : podeLancarRecuperacao
                        ? 'Recuperação disponível.'
                        : 'Não necessária: média igual ou superior a 7,0.',
                  ),

                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: recuperacao == null
                            ? 'Lançar recuperação'
                            : 'Alterar recuperação',

                        icon: const Icon(Icons.edit),

                        onPressed:
                            (podeLancarRecuperacao || recuperacao != null)
                            ? () {
                                _editarRecuperacao(
                                  bimestre: bimestre,
                                  indiceAluno: indiceAluno,
                                );
                              }
                            : null,
                      ),

                      if (recuperacao != null)
                        IconButton(
                          tooltip: 'Remover recuperação',

                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),

                          onPressed: () {
                            _removerRecuperacao(
                              bimestre: bimestre,
                              indiceAluno: indiceAluno,
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // Resultado acadêmico.
                const Text(
                  'Resultado acadêmico',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Text(
                  mediaProvas == null
                      ? 'Média das provas: Pendente'
                      : 'Média das provas: ${_formatarNota(mediaProvas)}',
                ),

                const SizedBox(height: 8),

                Text(
                  media == null
                      ? 'Média final: Pendente'
                      : 'Média final: ${_formatarNota(media)}',

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text('Situação: $situacao'),

                const SizedBox(height: 8),

                Text(
                  recuperacaoAplicada
                      ? '(Média das provas + recuperação) ÷ 2'
                      : '(Prova 1 + Prova 2) ÷ 2',
                ),

                if (recuperacao != null && !recuperacaoAplicada)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'A recuperação não foi aplicada porque '
                      'a média das provas já atingiu 7,0.',
                    ),
                  ),

                const SizedBox(height: 8),

                const Text('Média mínima para aprovação: 7,0'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
