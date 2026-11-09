import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/professor.dart';
import '../models/turma.dart';
import '../models/aluno.dart';

class ArmazenamentoService {
  static const String _chave = 'diario_classe_dados_v1';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  // Salva todos os dados do professor em JSON.
  static Future<void> salvarProfessor(Professor professor) async {
    final dados = _professorParaJson(professor);

    final json = jsonEncode(dados);

    await _preferences.setString(_chave, json);
  }

  // Carrega os dados salvos.
  static Future<Professor> carregarProfessor() async {
    final jsonSalvo = await _preferences.getString(_chave);

    // Primeiro acesso: cria um professor vazio.
    if (jsonSalvo == null) {
      return Professor(nome: 'Professor');
    }

    try {
      final dados = jsonDecode(jsonSalvo);

      if (dados is! Map) {
        throw const FormatException('Formato de dados inválido.');
      }

      return _professorDeJson(Map<String, dynamic>.from(dados));
    } catch (erro) {
      throw FormatException(
        'Não foi possível recuperar os dados salvos: $erro',
      );
    }
  }

  // Converte o professor para uma estrutura JSON.
  static Map<String, dynamic> _professorParaJson(Professor professor) {
    return {
      'nome': professor.nome,

      'turmas': professor.turmas.map((turma) {
        return {
          'nome': turma.nome,
          'curso': turma.curso,
          'periodo': turma.periodo,

          'alunos': turma.alunos.map((aluno) {
            return {'nome': aluno.nome, 'matricula': aluno.matricula};
          }).toList(),

          'bimestres': turma.bimestres.map((bimestre) {
            return {
              'numero': bimestre.numero,

              'notas': bimestre.notas,

              'notasLancadas': bimestre.notasLancadas,

              'recuperacoes': bimestre.recuperacoes,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  // Reconstrói o professor e todos os seus dados.
  static Professor _professorDeJson(Map<String, dynamic> dados) {
    final professor = Professor(nome: dados['nome']?.toString() ?? 'Professor');

    final turmasJson = dados['turmas'];

    if (turmasJson is! List) {
      return professor;
    }

    for (final turmaItem in turmasJson) {
      if (turmaItem is! Map) continue;

      final turmaDados = Map<String, dynamic>.from(turmaItem);

      final turma = Turma(
        nome: turmaDados['nome']?.toString() ?? '',
        curso: turmaDados['curso']?.toString() ?? '',
        periodo: _converterInt(turmaDados['periodo']),
      );

      // Recupera os alunos antes dos bimestres.
      // Isso mantém as linhas da matriz alinhadas.
      final alunosJson = turmaDados['alunos'];

      if (alunosJson is List) {
        for (final alunoItem in alunosJson) {
          if (alunoItem is! Map) continue;

          final alunoDados = Map<String, dynamic>.from(alunoItem);

          turma.adicionarAluno(
            Aluno(
              nome: alunoDados['nome']?.toString() ?? '',
              matricula: alunoDados['matricula']?.toString() ?? '',
            ),
          );
        }
      }

      // Recupera os bimestres.
      final bimestresJson = turmaDados['bimestres'];

      if (bimestresJson is List) {
        for (final bimestreItem in bimestresJson) {
          if (bimestreItem is! Map) continue;

          final dadosBimestre = Map<String, dynamic>.from(bimestreItem);

          final numero = _converterInt(dadosBimestre['numero']);

          turma.adicionarBimestre(numero);

          final bimestre = turma.bimestres.firstWhere(
            (b) => b.numero == numero,
          );

          final notasJson = dadosBimestre['notas'];
          final lancadasJson = dadosBimestre['notasLancadas'];

          final recuperacoesJson = dadosBimestre['recuperacoes'];

          // Recupera as notas das duas provas.
          if (notasJson is List && lancadasJson is List) {
            for (int i = 0; i < turma.alunos.length; i++) {
              if (i >= notasJson.length || i >= lancadasJson.length) {
                continue;
              }

              final linhaNotas = notasJson[i];
              final linhaLancamentos = lancadasJson[i];

              if (linhaNotas is! List || linhaLancamentos is! List) {
                continue;
              }

              for (int j = 0; j < 2; j++) {
                if (j >= linhaNotas.length || j >= linhaLancamentos.length) {
                  continue;
                }

                final foiLancada = linhaLancamentos[j] == true;

                if (!foiLancada) continue;

                final nota = _converterDouble(linhaNotas[j]);

                bimestre.registrarNota(
                  indiceAluno: i,
                  avaliacao: j + 1,
                  nota: nota,
                );
              }
            }
          }

          // Recupera as notas de recuperação.
          if (recuperacoesJson is List) {
            for (
              int i = 0;
              i < turma.alunos.length && i < recuperacoesJson.length;
              i++
            ) {
              final valor = recuperacoesJson[i];

              if (valor == null) continue;

              bimestre.registrarRecuperacao(
                indiceAluno: i,
                nota: _converterDouble(valor),
              );
            }
          }
        }
      }

      professor.adicionarTurma(turma);
    }

    return professor;
  }

  // Converte valores numéricos para inteiro.
  static int _converterInt(dynamic valor) {
    if (valor is num) {
      return valor.toInt();
    }

    return int.parse(valor.toString());
  }

  // Converte valores numéricos para double.
  static double _converterDouble(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    return double.parse(valor.toString());
  }

  // Remove os dados salvos.
  // Utilizar somente quando for necessário limpar o cadastro.
  static Future<void> apagarDados() async {
    await _preferences.remove(_chave);
  }
}
