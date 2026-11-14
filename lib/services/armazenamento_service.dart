import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/aluno.dart';
import '../models/bimestre.dart';
import '../models/professor.dart';
import '../models/registro_presenca.dart';
import '../models/turma.dart';
import 'calculo_service.dart';

/// Armazenamento exclusivo do sistema semestral.
class ArmazenamentoService {
  static const String chaveDados = 'diario_classe_semestral_v1';
  static const int versaoAtual = 5;
  static bool _cargaFalhou = false;
  static bool _emAlteracao = false;

  static SharedPreferencesAsync get _preferences => SharedPreferencesAsync();

  static Future<String?> obterJsonSalvo() => _preferences.getString(chaveDados);

  static Future<void> salvarProfessor(Professor professor) async {
    if (_cargaFalhou) {
      throw StateError(
        'Recupere os dados ou inicie um novo diário antes de salvar.',
      );
    }
    await _gravar(professor);
  }

  static Future<void> _gravar(Professor professor) async {
    final json = exportarJson(professor);
    // Valida também alterações feitas diretamente nos modelos antes de persistir.
    importarJson(json);
    await _preferences.setString(chaveDados, json);
  }

  /// Restaura os valores e as mesmas referências se a alteração ou a gravação falhar.
  static Future<void> alterarProfessor(
    Professor professor,
    void Function() alterar,
  ) async {
    if (_emAlteracao) throw StateError('Aguarde o salvamento em andamento.');
    if (_cargaFalhou) {
      throw StateError('Os dados precisam ser recuperados antes de editar.');
    }
    _emAlteracao = true;
    final reverter = _capturarProfessor(professor);
    try {
      alterar();
      for (final turma in professor.turmas) {
        for (int i = 0; i < turma.alunos.length; i++) {
          if (!CalculoService.precisaProvaFinal(
            turma.primeiroBimestre,
            turma.segundoBimestre,
            i,
            mediaMinima: professor.mediaMinima,
          )) {
            turma.segundoBimestre.limparProvaFinal(i);
          }
        }
      }
      await salvarProfessor(professor);
    } catch (_) {
      reverter();
      rethrow;
    } finally {
      _emAlteracao = false;
    }
  }

  /// Uma restauração só troca os objetos em memória depois que a gravação termina.
  static Future<void> substituirProfessor(
    Professor atual,
    Professor novo,
  ) async {
    if (_emAlteracao) throw StateError('Aguarde o salvamento em andamento.');
    _emAlteracao = true;
    try {
      await _gravar(novo);
      atual.substituirPor(novo);
      _cargaFalhou = false;
    } finally {
      _emAlteracao = false;
    }
  }

  static Future<Professor> carregarProfessor() async {
    try {
      final salvo = await obterJsonSalvo();
      final professor = salvo == null
          ? Professor(nome: 'Professor')
          : importarJson(salvo);
      _cargaFalhou = false;
      return professor;
    } catch (erro) {
      _cargaFalhou = true;
      throw FormatException(
        'Não foi possível recuperar o diário semestral: $erro',
      );
    }
  }

  static String exportarJson(Professor professor) => jsonEncode({
    'sistema': 'semestral',
    'versao': versaoAtual,
    'nome': professor.nome,
    'mediaMinima': professor.mediaMinima,
    'turmas': professor.turmas
        .map(
          (turma) => {
            'nome': turma.nome,
            'curso': turma.curso,
            'periodo': turma.periodo,
            'arquivada': turma.arquivada,
            'alunos': turma.alunos
                .map(
                  (aluno) => {
                    'nome': aluno.nome,
                    'matricula': aluno.matricula,
                    'observacao': aluno.observacao,
                  },
                )
                .toList(),
            'presencas': turma.presencas
                .map(
                  (registro) => {
                    'data': registro.data,
                    'presentes': registro.presentes,
                  },
                )
                .toList(),
            'bimestres': turma.bimestres
                .map(
                  (bimestre) => {
                    'numero': bimestre.numero,
                    'nomeProva': bimestre.nomeProva,
                    'notas': bimestre.notas,
                    if (bimestre.numero == 2)
                      'provasFinais': bimestre.provasFinais,
                  },
                )
                .toList(),
          },
        )
        .toList(),
  });

  static Professor importarJson(String json) {
    try {
      final dados = _mapa(jsonDecode(json));
      if (dados['sistema'] != 'semestral' || dados['versao'] != versaoAtual) {
        throw const FormatException(
          'Use um backup do sistema semestral atual. Backups antigos não são aceitos.',
        );
      }
      final professor = Professor(
        nome: _texto(dados['nome']),
        mediaMinima: _nota(dados['mediaMinima']),
      );
      for (final item in _lista(dados['turmas'])) {
        final dadosTurma = _mapa(item);
        final periodo = dadosTurma['periodo'];
        if (periodo is! int) throw const FormatException('Período inválido.');
        final turma = Turma(
          nome: _texto(dadosTurma['nome']),
          curso: _texto(dadosTurma['curso']),
          periodo: periodo,
          arquivada: _booleano(dadosTurma['arquivada']),
        );
        for (final itemAluno in _lista(dadosTurma['alunos'])) {
          final aluno = _mapa(itemAluno);
          turma.adicionarAluno(
            Aluno(
              nome: _texto(aluno['nome']),
              matricula: _texto(aluno['matricula']),
              observacao: _texto(aluno['observacao'], permitirVazio: true),
            ),
          );
        }
        final bimestres = _lista(dadosTurma['bimestres']);
        if (bimestres.length != 2) {
          throw const FormatException(
            'O semestre deve ter exatamente dois bimestres.',
          );
        }
        final numeros = <int>{};
        for (final itemBimestre in bimestres) {
          final dadosBimestre = _mapa(itemBimestre);
          final numero = dadosBimestre['numero'];
          if ((numero != 1 && numero != 2) || !numeros.add(numero as int)) {
            throw const FormatException('Bimestres inválidos ou repetidos.');
          }
          if (dadosBimestre.containsKey('avaliacoes') ||
              dadosBimestre.containsKey('recuperacoes') ||
              dadosBimestre.containsKey('notasLancadas')) {
            throw const FormatException(
              'O formato de avaliações por bimestre foi descontinuado.',
            );
          }
          final bimestre = turma.bimestres[numero - 1];
          bimestre.renomearProva(_texto(dadosBimestre['nomeProva']));
          final notas = _lista(dadosBimestre['notas']);
          if (notas.length != turma.alunos.length) {
            throw const FormatException('Notas desalinhadas com os alunos.');
          }
          for (int i = 0; i < notas.length; i++) {
            if (notas[i] != null) {
              bimestre.registrarNota(indiceAluno: i, nota: _nota(notas[i]));
            }
          }
          if (numero == 1 && dadosBimestre.containsKey('provasFinais')) {
            throw const FormatException(
              'A prova final pertence somente ao segundo bimestre.',
            );
          }
          if (numero == 2) {
            final finais = _lista(dadosBimestre['provasFinais']);
            if (finais.length != turma.alunos.length) {
              throw const FormatException('Provas finais desalinhadas.');
            }
            for (int i = 0; i < finais.length; i++) {
              if (finais[i] != null) {
                bimestre.registrarProvaFinal(
                  indiceAluno: i,
                  nota: _nota(finais[i]),
                );
              }
            }
          }
        }
        for (int i = 0; i < turma.alunos.length; i++) {
          if (turma.segundoBimestre.provasFinais[i] != null &&
              !CalculoService.precisaProvaFinal(
                turma.primeiroBimestre,
                turma.segundoBimestre,
                i,
                mediaMinima: professor.mediaMinima,
              )) {
            throw const FormatException(
              'Prova final registrada para aluno dispensado ou com provas pendentes.',
            );
          }
        }
        final datas = <String>{};
        for (final itemPresenca in _lista(dadosTurma['presencas'])) {
          final presenca = _mapa(itemPresenca);
          final data = _texto(presenca['data']);
          final dataConvertida = DateTime.tryParse(data);
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data) ||
              dataConvertida == null ||
              RegistroPresenca.dataParaIso(dataConvertida) != data ||
              !datas.add(data)) {
            throw const FormatException('Data de aula inválida ou repetida.');
          }
          final presentes = _lista(presenca['presentes']);
          if (presentes.length != turma.alunos.length) {
            throw const FormatException('Presenças desalinhadas.');
          }
          turma.presencas.add(
            RegistroPresenca(
              data: data,
              presentes: presentes.map(_booleano).toList(),
            ),
          );
        }
        turma.presencas.sort((a, b) => a.data.compareTo(b.data));
        professor.adicionarTurma(turma);
      }
      return professor;
    } on FormatException {
      rethrow;
    } catch (erro) {
      throw FormatException('Backup semestral inválido: $erro');
    }
  }

  static Map<String, dynamic> _mapa(dynamic valor) {
    if (valor is! Map) throw const FormatException('Objeto JSON inválido.');
    return Map<String, dynamic>.from(valor);
  }

  static List<dynamic> _lista(dynamic valor) {
    if (valor is! List) {
      throw const FormatException('Lista ausente ou inválida.');
    }
    return valor;
  }

  static String _texto(dynamic valor, {bool permitirVazio = false}) {
    if (valor is! String || (!permitirVazio && valor.trim().isEmpty)) {
      throw const FormatException('Texto ausente ou inválido.');
    }
    return valor;
  }

  static bool _booleano(dynamic valor) {
    if (valor is! bool) {
      throw const FormatException('Presença ou arquivamento inválido.');
    }
    return valor;
  }

  static double _nota(dynamic valor) {
    if (valor is! num) throw const FormatException('Nota ausente ou inválida.');
    final nota = valor.toDouble();
    Bimestre.validarNota(nota);
    return nota;
  }

  static void Function() _capturarProfessor(Professor professor) {
    final nome = professor.nome;
    final minima = professor.mediaMinima;
    final turmas = List<Turma>.from(professor.turmas);
    final restaurarTurmas = turmas.map(_capturarTurma).toList();
    return () {
      professor.nome = nome;
      professor.mediaMinima = minima;
      professor.turmas
        ..clear()
        ..addAll(turmas);
      for (final restaurar in restaurarTurmas) {
        restaurar();
      }
    };
  }

  static void Function() _capturarTurma(Turma turma) {
    final nome = turma.nome;
    final curso = turma.curso;
    final periodo = turma.periodo;
    final arquivada = turma.arquivada;
    final alunos = List<Aluno>.from(turma.alunos);
    final dadosAlunos = alunos
        .map(
          (a) =>
              (nome: a.nome, matricula: a.matricula, observacao: a.observacao),
        )
        .toList();
    final dadosBimestres = turma.bimestres
        .map(
          (b) => (
            nome: b.nomeProva,
            notas: List<double?>.from(b.notas),
            finais: List<double?>.from(b.provasFinais),
          ),
        )
        .toList();
    final presencas = List<RegistroPresenca>.from(turma.presencas);
    final dadosPresencas = presencas
        .map((p) => List<bool>.from(p.presentes))
        .toList();
    return () {
      turma
        ..nome = nome
        ..curso = curso
        ..periodo = periodo
        ..arquivada = arquivada;
      turma.alunos
        ..clear()
        ..addAll(alunos);
      for (int i = 0; i < alunos.length; i++) {
        alunos[i]
          ..nome = dadosAlunos[i].nome
          ..matricula = dadosAlunos[i].matricula
          ..observacao = dadosAlunos[i].observacao;
      }
      for (int i = 0; i < turma.bimestres.length; i++) {
        final bimestre = turma.bimestres[i];
        bimestre.renomearProva(dadosBimestres[i].nome);
        bimestre.notas
          ..clear()
          ..addAll(dadosBimestres[i].notas);
        bimestre.provasFinais
          ..clear()
          ..addAll(dadosBimestres[i].finais);
      }
      turma.presencas
        ..clear()
        ..addAll(presencas);
      for (int i = 0; i < presencas.length; i++) {
        presencas[i].presentes
          ..clear()
          ..addAll(dadosPresencas[i]);
      }
    };
  }
}
