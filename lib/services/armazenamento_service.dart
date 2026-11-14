import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/aluno.dart';
import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/registro_presenca.dart';
import '../models/turma.dart';

class ArmazenamentoService {
  static const String _chave = 'diario_classe_dados_v1';
  static const int _versaoAtual = 3;

  // Criado sob demanda para que cada operação use a plataforma atual.
  static SharedPreferencesAsync get _preferences => SharedPreferencesAsync();

  // Salva todos os dados do professor em JSON.
  static Future<void> salvarProfessor(Professor professor) async {
    await _preferences.setString(_chave, exportarJson(professor));
  }

  // Salva e devolve uma mensagem de erro, quando houver.
  // Assim as telas podem avisar o usuário sem interromper o app.
  static Future<String?> tentarSalvarProfessor(Professor professor) async {
    try {
      await salvarProfessor(professor);
      return null;
    } catch (erro) {
      return 'Não foi possível salvar os dados: $erro';
    }
  }

  // Gera o JSON completo, usado tanto no armazenamento quanto no backup.
  static String exportarJson(Professor professor) {
    return jsonEncode(_professorParaJson(professor));
  }

  // Reconstrói um professor a partir de um JSON de backup.
  static Professor importarJson(String json) {
    final dynamic dados = jsonDecode(json);

    if (dados is! Map) {
      throw const FormatException('O arquivo não contém um objeto JSON.');
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(dados);

    if (mapa['turmas'] is! List) {
      throw const FormatException(
        'O arquivo não parece ser um backup do Diário de Classe.',
      );
    }

    return _professorDeJson(mapa);
  }

  // Carrega os dados salvos.
  static Future<Professor> carregarProfessor() async {
    final String? jsonSalvo = await _preferences.getString(_chave);

    // Primeiro acesso: cria um professor vazio.
    if (jsonSalvo == null) {
      return Professor(nome: 'Professor');
    }

    try {
      return importarJson(jsonSalvo);
    } catch (erro) {
      throw FormatException(
        'Não foi possível recuperar os dados salvos: $erro',
      );
    }
  }

  // Converte o professor para uma estrutura JSON.
  static Map<String, dynamic> _professorParaJson(Professor professor) {
    return {
      'versao': _versaoAtual,
      'nome': professor.nome,
      'mediaMinima': professor.mediaMinima,

      'turmas': professor.turmas.map((turma) {
        return {
          'nome': turma.nome,
          'curso': turma.curso,
          'periodo': turma.periodo,
          'arquivada': turma.arquivada,

          'alunos': turma.alunos.map((aluno) {
            return {
              'nome': aluno.nome,
              'matricula': aluno.matricula,
              'observacao': aluno.observacao,
            };
          }).toList(),

          'presencas': turma.presencas.map((registro) {
            return {'data': registro.data, 'presentes': registro.presentes};
          }).toList(),

          'bimestres': turma.bimestres.map((bimestre) {
            return {
              'numero': bimestre.numero,
              'avaliacoes': bimestre.avaliacoes,
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
    final double mediaMinima = _converterMediaMinima(dados['mediaMinima']);

    final professor = Professor(
      nome: dados['nome']?.toString() ?? 'Professor',
      mediaMinima: mediaMinima,
    );

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
        arquivada: turmaDados['arquivada'] == true,
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
              observacao: alunoDados['observacao']?.toString() ?? '',
            ),
          );
        }
      }

      // Recupera as presenças.
      final presencasJson = turmaDados['presencas'];

      if (presencasJson is List) {
        final datasAdicionadas = <String>{};

        for (final presencaItem in presencasJson) {
          if (presencaItem is! Map) continue;

          final dadosPresenca = Map<String, dynamic>.from(presencaItem);
          final data = dadosPresenca['data']?.toString() ?? '';

          if (data.isEmpty || !datasAdicionadas.add(data)) continue;

          final presentesJson = dadosPresenca['presentes'];
          final presentes = List<bool>.generate(turma.alunos.length, (i) {
            if (presentesJson is List && i < presentesJson.length) {
              return presentesJson[i] == true;
            }

            return true;
          });

          turma.presencas.add(
            RegistroPresenca(data: data, presentes: presentes),
          );
        }

        turma.presencas.sort((a, b) => a.data.compareTo(b.data));
      }

      // Recupera os bimestres.
      final bimestresJson = turmaDados['bimestres'];

      if (bimestresJson is List) {
        for (final bimestreItem in bimestresJson) {
          if (bimestreItem is! Map) continue;

          final dadosBimestre = Map<String, dynamic>.from(bimestreItem);

          final numero = _converterInt(dadosBimestre['numero']);

          final List<String>? avaliacoes = _converterAvaliacoes(
            dadosBimestre['avaliacoes'],
            quantidadeNotas: _quantidadeAvaliacoes(dadosBimestre['notas']),
          );

          turma.adicionarBimestre(numero, avaliacoes: avaliacoes);

          final Bimestre bimestre = turma.bimestres.firstWhere(
            (b) => b.numero == numero,
          );

          final notasJson = dadosBimestre['notas'];
          final lancadasJson = dadosBimestre['notasLancadas'];

          final recuperacoesJson = dadosBimestre['recuperacoes'];

          // Recupera as notas de todas as avaliações do bimestre.
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

              for (int j = 0; j < bimestre.avaliacoes.length; j++) {
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

  // Conta quantas colunas de notas um bimestre antigo possui.
  // Isso permite reconstruir avaliações além das duas provas padrão.
  static int _quantidadeAvaliacoes(dynamic notasJson) {
    if (notasJson is List && notasJson.isNotEmpty) {
      final primeiraLinha = notasJson.first;

      if (primeiraLinha is List && primeiraLinha.isNotEmpty) {
        final quantidade = primeiraLinha.length;

        if (quantidade > 0) {
          return quantidade > Bimestre.limiteAvaliacoes
              ? Bimestre.limiteAvaliacoes
              : quantidade;
        }
      }
    }

    return Bimestre.nomesAvaliacoesPadrao.length;
  }

  // Lê os nomes das avaliações com segurança. Backups antigos não possuem
  // esse campo e continuam usando "Prova 1" e "Prova 2".
  static List<String>? _converterAvaliacoes(
    dynamic valor, {
    required int quantidadeNotas,
  }) {
    if (valor is! List) {
      return _avaliacoesPadrao(quantidadeNotas);
    }

    final List<String> nomes = [];
    final Set<String> vistos = {};

    for (final item in valor) {
      final String nome = item?.toString().trim() ?? '';

      if (nome.isEmpty || nome.length > Bimestre.limiteCaracteresNome) {
        continue;
      }

      if (!vistos.add(nome.toLowerCase())) {
        continue;
      }

      nomes.add(nome);

      if (nomes.length >= Bimestre.limiteAvaliacoes) {
        break;
      }
    }

    return nomes.isEmpty ? _avaliacoesPadrao(quantidadeNotas) : nomes;
  }

  static List<String> _avaliacoesPadrao(int quantidade) {
    if (quantidade == Bimestre.nomesAvaliacoesPadrao.length) {
      return List<String>.from(Bimestre.nomesAvaliacoesPadrao);
    }

    final limite = quantidade < 1
        ? 1
        : (quantidade > Bimestre.limiteAvaliacoes
              ? Bimestre.limiteAvaliacoes
              : quantidade);

    return List<String>.generate(limite, (indice) => 'Avaliação ${indice + 1}');
  }

  // Converte valores numéricos para inteiro.
  static int _converterInt(dynamic valor) {
    if (valor is num) {
      return valor.toInt();
    }

    return int.parse(valor.toString());
  }

  // Converte valores numéricos para double, aceitando vírgula decimal.
  static double _converterDouble(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    return double.parse(valor.toString().trim().replaceAll(',', '.'));
  }

  // Lê a média mínima com segurança; dados antigos não possuem o campo.
  static double _converterMediaMinima(dynamic valor) {
    if (valor == null) {
      return 7.0;
    }

    try {
      final double media = _converterDouble(valor);

      if (!media.isFinite || media < 0 || media > 10) {
        return 7.0;
      }

      return media;
    } catch (_) {
      return 7.0;
    }
  }

  // Remove os dados salvos.
  // Utilizar somente quando for necessário limpar o cadastro.
  static Future<void> apagarDados() async {
    await _preferences.remove(_chave);
  }
}
