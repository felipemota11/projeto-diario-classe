import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/models/aluno.dart';
import 'package:projeto_diario/models/professor.dart';
import 'package:projeto_diario/services/armazenamento_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fixtures.dart';

void main() {
  late ArmazenamentoDeTeste plataforma;
  setUp(() async {
    plataforma = ArmazenamentoDeTeste();
    SharedPreferencesAsyncPlatform.instance = plataforma;
    await ArmazenamentoService.carregarProfessor();
  });

  test(
    'salva e carrega nomes das provas, notas, perfil, frequência e arquivo',
    () async {
      final p = criarProfessor(mediaMinima: 6.25);
      final t = p.turmas.single;
      t.primeiroBimestre.renomearProva('Projeto prático');
      t.primeiroBimestre.registrarNota(indiceAluno: 0, nota: 4);
      t.segundoBimestre.registrarNota(indiceAluno: 0, nota: 5);
      t.segundoBimestre.registrarProvaFinal(indiceAluno: 0, nota: 8);
      t.adicionarPresenca('2026-11-10');
      t.alternarPresenca(registro: 0, aluno: 0);
      t.arquivada = true;
      await ArmazenamentoService.salvarProfessor(p);
      final carregado = await ArmazenamentoService.carregarProfessor();
      expect(
        ArmazenamentoService.exportarJson(carregado),
        ArmazenamentoService.exportarJson(p),
      );
      expect(
        carregado.turmas.single.primeiroBimestre.nomeProva,
        'Projeto prático',
      );
      expect(carregado.turmas.single.alunos.single.observacao, 'Participativo');
    },
  );

  test('ignora armazenamento antigo e recusa seus backups', () async {
    final preferencias = SharedPreferencesAsync();
    const antigo = '{"versao":3,"nome":"Antigo","turmas":[]}';
    await preferencias.setString('diario_classe_dados_v1', antigo);
    final p = await ArmazenamentoService.carregarProfessor();
    expect(p.turmas, isEmpty);
    expect(
      () => ArmazenamentoService.importarJson(antigo),
      throwsFormatException,
    );
    await ArmazenamentoService.salvarProfessor(p);
    expect(await preferencias.getString('diario_classe_dados_v1'), antigo);
    final dados = jsonDecode((await ArmazenamentoService.obterJsonSalvo())!);
    expect(dados['sistema'], 'semestral');
    expect(dados['versao'], ArmazenamentoService.versaoAtual);
  });

  test(
    'dados inválidos bloqueiam gravação até recuperação explícita',
    () async {
      final preferencias = SharedPreferencesAsync();
      await preferencias.setString(
        ArmazenamentoService.chaveDados,
        'corrompido',
      );
      await expectLater(
        ArmazenamentoService.carregarProfessor(),
        throwsFormatException,
      );
      final p = Professor(nome: 'Professor');
      await expectLater(
        ArmazenamentoService.salvarProfessor(p),
        throwsStateError,
      );
      await expectLater(
        ArmazenamentoService.alterarProfessor(p, () => p.nome = 'Outro'),
        throwsStateError,
      );
      expect(await ArmazenamentoService.obterJsonSalvo(), 'corrompido');
      final novo = criarProfessor();
      await ArmazenamentoService.substituirProfessor(p, novo);
      expect(
        (await ArmazenamentoService.carregarProfessor()).turmas,
        hasLength(1),
      );
    },
  );

  test('rejeita versões desconhecidas, matrizes antigas e desalinhamentos', () {
    for (final alterar in <void Function(Map<String, dynamic>)>[
      (d) => d['turmas'][0]['alunos'][0]['nome'] = 'Aluno123',
      (d) => d['turmas'][0]['alunos'][0]['matricula'] = 'ABC',
      (d) => d['versao'] = 99,
      (d) => d['turmas'][0]['bimestres'] = [],
      (d) => d['turmas'][0]['bimestres'][0]['notas'] = [
        [8, 9],
      ],
      (d) => d['turmas'][0]['bimestres'][0]['notas'] = [],
      (d) => d['turmas'][0]['bimestres'][0]['avaliacoes'] = ['A', 'B'],
      (d) => d['turmas'][0]['bimestres'][0]['provasFinais'] = [8],
      (d) => d['turmas'][0]['bimestres'][1]['provasFinais'] = [8],
      (d) => d['turmas'][0]['alunos'].add(null),
      (d) => d['turmas'][0]['presencas'] = [
        {
          'data': '2026-02-30',
          'presentes': [true],
        },
      ],
      (d) => d['mediaMinima'] = 20,
    ]) {
      final dados = jsonDecode(
        ArmazenamentoService.exportarJson(criarProfessor()),
      ) as Map<String, dynamic>;
      alterar(dados);
      expect(
        () => ArmazenamentoService.importarJson(jsonEncode(dados)),
        throwsFormatException,
      );
    }
  });

  test(
    'falha de gravação restaura objetos e permite repetir o lançamento',
    () async {
      final p = criarProfessor();
      final t = p.turmas.single;
      final aluno = t.alunos.single;
      final b1 = t.primeiroBimestre;
      final b2 = t.segundoBimestre;
      final aula = t.adicionarPresenca('2026-11-10');
      await ArmazenamentoService.salvarProfessor(p);
      final antes = await ArmazenamentoService.obterJsonSalvo();
      plataforma.falhar = true;
      await expectLater(
        ArmazenamentoService.alterarProfessor(p, () {
          p.editarPerfil(nome: 'Outro', mediaMinima: 6);
          t.editar(nome: 'Outra', curso: 'Outro', periodo: 3);
          t.arquivada = true;
          t.editarAluno(0, nome: 'Novo', matricula: '003', observacao: 'Outra');
          b1.renomearProva('Outra prova');
          b1.registrarNota(indiceAluno: 0, nota: 6);
          b2.registrarNota(indiceAluno: 0, nota: 6);
          t.alternarPresenca(registro: 0, aluno: 0);
          t.adicionarAluno(Aluno(nome: 'Extra', matricula: '002'));
        }),
        throwsStateError,
      );
      expect(identical(p.turmas.single, t), isTrue);
      expect(identical(t.alunos.single, aluno), isTrue);
      expect(identical(t.primeiroBimestre, b1), isTrue);
      expect(identical(t.presencas.single, aula), isTrue);
      expect(ArmazenamentoService.exportarJson(p), antes);
      plataforma.falhar = false;
      await ArmazenamentoService.alterarProfessor(p, () {
        b1.registrarNota(indiceAluno: 0, nota: 6);
        b2.registrarNota(indiceAluno: 0, nota: 6);
        b2.registrarProvaFinal(indiceAluno: 0, nota: 8);
      });
      expect(
        (await ArmazenamentoService.carregarProfessor())
            .turmas
            .single
            .segundoBimestre
            .provasFinais,
        [8],
      );
    },
  );

  test(
    'falha de exclusão devolve aluno, notas e turma nas referências originais',
    () async {
      final p = criarProfessor();
      final t = p.turmas.single;
      final a = t.alunos.single;
      plataforma.falhar = true;
      await expectLater(
        ArmazenamentoService.alterarProfessor(p, () {
          t.removerAlunoNoIndice(0);
          p.turmas.remove(t);
        }),
        throwsStateError,
      );
      expect(identical(p.turmas.single, t), isTrue);
      expect(identical(t.alunos.single, a), isTrue);
      expect(t.primeiroBimestre.notas, [null]);
    },
  );

  test('restauração mal sucedida mantém o cadastro atual', () async {
    final p = criarProfessor();
    final t = p.turmas.single;
    await ArmazenamentoService.salvarProfessor(p);
    plataforma.falhar = true;
    await expectLater(
      ArmazenamentoService.substituirProfessor(p, Professor(nome: 'Novo')),
      throwsStateError,
    );
    expect(identical(p.turmas.single, t), isTrue);
    expect((await ArmazenamentoService.carregarProfessor()).nome, 'Maria');
  });

  test(
    'remover prova ou mudar regra elimina final de aluno dispensado',
    () async {
      final p = criarProfessor();
      final t = p.turmas.single;
      await ArmazenamentoService.alterarProfessor(p, () {
        t.primeiroBimestre.registrarNota(indiceAluno: 0, nota: 6);
        t.segundoBimestre.registrarNota(indiceAluno: 0, nota: 6);
        t.segundoBimestre.registrarProvaFinal(indiceAluno: 0, nota: 8);
      });
      await ArmazenamentoService.alterarProfessor(
        p,
        () => p.editarPerfil(nome: 'Maria', mediaMinima: 6),
      );
      expect(t.segundoBimestre.provasFinais.single, isNull);
      await ArmazenamentoService.alterarProfessor(
        p,
        () => p.editarPerfil(nome: 'Maria', mediaMinima: 7),
      );
      expect(t.segundoBimestre.provasFinais.single, isNull);
      await ArmazenamentoService.alterarProfessor(
        p,
        () => t.segundoBimestre.registrarProvaFinal(indiceAluno: 0, nota: 8),
      );
      await ArmazenamentoService.alterarProfessor(
        p,
        () => t.primeiroBimestre.limparNota(indiceAluno: 0),
      );
      expect(t.segundoBimestre.provasFinais.single, isNull);
    },
  );
}
