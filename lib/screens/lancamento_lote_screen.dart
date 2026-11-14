import 'package:flutter/material.dart';

import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/turma.dart';
import '../services/armazenamento_service.dart';
import '../services/calculo_service.dart';

/// Lança as duas provas e a prova final de toda a turma em uma única operação.
class LancamentoLoteScreen extends StatefulWidget {
  final Professor professor;
  final Turma turma;

  const LancamentoLoteScreen({
    super.key,
    required this.professor,
    required this.turma,
  });

  @override
  State<LancamentoLoteScreen> createState() => _LancamentoLoteScreenState();
}

class _LancamentoLoteScreenState extends State<LancamentoLoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _prova1 = [];
  final List<TextEditingController> _prova2 = [];
  final List<TextEditingController> _final = [];
  bool _salvando = false;

  Bimestre _buscar(int numero) => widget.turma.bimestres[numero - 1];

  String _texto(double? nota) =>
      nota == null ? '' : nota.toString().replaceAll('.', ',');

  double? _ler(String texto) {
    final nota = double.tryParse(texto.trim().replaceAll(',', '.'));
    return nota != null && nota.isFinite && nota >= 0 && nota <= 10
        ? nota
        : null;
  }

  @override
  void initState() {
    super.initState();
    final primeiro = _buscar(1);
    final segundo = _buscar(2);
    for (int i = 0; i < widget.turma.alunos.length; i++) {
      _prova1.add(TextEditingController(text: _texto(primeiro.obterNota(i))));
      _prova2.add(TextEditingController(text: _texto(segundo.obterNota(i))));
      _final.add(TextEditingController(text: _texto(segundo.provasFinais[i])));
    }
  }

  @override
  void dispose() {
    for (final controller in [..._prova1, ..._prova2, ..._final]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _media(int i) => CalculoService.mediaDasNotas(
    _ler(_prova1[i].text),
    _ler(_prova2[i].text),
  );

  double? _resultado(int i) => CalculoService.resultadoDasNotas(
    _media(i),
    _ler(_final[i].text),
    mediaMinima: widget.professor.mediaMinima,
  );

  String _situacao(int i) => CalculoService.situacaoDasNotas(
    _media(i),
    _ler(_final[i].text),
    mediaMinima: widget.professor.mediaMinima,
  );
  String _mostrar(double? nota) =>
      nota == null ? 'Pendente' : nota.toString().replaceAll('.', ',');

  String? _validar(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null;
    final nota = _ler(texto);
    return nota == null || !nota.isFinite || nota < 0 || nota > 10
        ? 'Nota de 0 a 10'
        : null;
  }

  void _atualizar(int i) {
    final media = _media(i);
    if (media == null || media >= widget.professor.mediaMinima) {
      // Evita guardar provas finais de alunos dispensados ou pendentes.
      _final[i].clear();
    }
    setState(() {});
  }

  Widget _campo(
    TextEditingController controller,
    String titulo, {
    required int indice,
    bool provaFinal = false,
  }) {
    final media = _media(indice);
    final habilitado =
        !provaFinal || (media != null && media < widget.professor.mediaMinima);
    return SizedBox(
      width: 145,
      child: TextFormField(
        controller: controller,
        enabled: habilitado && !_salvando,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: InputDecoration(labelText: titulo, hintText: '0 a 10'),
        validator: _validar,
        onChanged: (_) {
          if (provaFinal) {
            setState(() {});
          } else {
            _atualizar(indice);
          }
        },
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final primeiro = _buscar(1);
    final segundo = _buscar(2);

    // Valida todos os registros antes de alterar os modelos.
    for (int i = 0; i < widget.turma.alunos.length; i++) {
      final media = _media(i);
      final finalNota = _ler(_final[i].text);
      if (finalNota != null &&
          (media == null || media >= widget.professor.mediaMinima)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Revise a prova final de ${widget.turma.alunos[i].nome}.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _salvando = true);
    try {
      await ArmazenamentoService.alterarProfessor(widget.professor, () {
        for (int i = 0; i < widget.turma.alunos.length; i++) {
          final nota1 = _ler(_prova1[i].text);
          final nota2 = _ler(_prova2[i].text);
          final finalNota = _ler(_final[i].text);
          if (nota1 == null) {
            primeiro.limparNota(indiceAluno: i);
          } else {
            primeiro.registrarNota(indiceAluno: i, nota: nota1);
          }
          if (nota2 == null) {
            segundo.limparNota(indiceAluno: i);
          } else {
            segundo.registrarNota(indiceAluno: i, nota: nota2);
          }
          if (finalNota == null) {
            segundo.limparProvaFinal(i);
          } else {
            segundo.registrarProvaFinal(indiceAluno: i, nota: finalNota);
          }
        }
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento em lote')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Lance as duas provas para cada aluno. A prova final '
                  'é habilitada somente quando a média for inferior à mínima. '
                  'Deixar uma prova vazia a mantém pendente.',
                ),
              ),
            ),
            for (int i = 0; i < widget.turma.alunos.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.turma.alunos[i].nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Matrícula: ${widget.turma.alunos[i].matricula}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _campo(_prova1[i], _buscar(1).nomeProva, indice: i),
                          _campo(_prova2[i], _buscar(2).nomeProva, indice: i),
                          _campo(
                            _final[i],
                            'Prova final',
                            indice: i,
                            provaFinal: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Média: ${_mostrar(_media(i))}  •  '
                        'Final: ${_mostrar(_resultado(i))}',
                      ),
                      Text(_situacao(i)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(Icons.save_outlined),
            label: Text(_salvando ? 'Salvando...' : 'Salvar todas as notas'),
          ),
        ),
      ),
    );
  }
}
