import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/main.dart';
import 'package:projeto_diario/screens/alunos_screen.dart';
import 'package:projeto_diario/screens/lancamento_lote_screen.dart';
import 'package:projeto_diario/services/armazenamento_service.dart';
import 'package:projeto_diario/services/exportacao_service.dart';
import 'package:projeto_diario/services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ArmazenamentoDeTeste plataforma;
  setUp(() async {
    plataforma = ArmazenamentoDeTeste();
    SharedPreferencesAsyncPlatform.instance = plataforma;
    await ArmazenamentoService.carregarProfessor();
  });

  test(
    'CSV semestral contém nomes personalizados, zero, pendência e frequência',
    () {
      final p = criarProfessor();
      final t = p.turmas.single;
      t.primeiroBimestre.renomearProva('Projeto; prático');
      t.primeiroBimestre.registrarNota(indiceAluno: 0, nota: 0);
      t.adicionarPresenca('2026-11-10');
      final csv = ExportacaoService.gerarCsvSemestral(
        nomeProfessor: p.nome,
        turma: t,
      );
      expect(csv, contains('"Projeto; prático"'));
      expect(csv, contains('0,00'));
      expect(csv, contains('Pendente'));
      expect(csv, contains('100,00'));
      expect(csv, isNot(contains('Recuperação')));
    },
  );

  test('PDFs usam fontes locais sem avisos de caracteres ausentes', () async {
    final p = criarProfessor();
    final mensagens = <String>[];
    await runZoned(
      () async {
        final boletim = await PdfService.gerarBoletimSemestral(
          professor: p,
          turma: p.turmas.single,
          indiceAluno: 0,
        );
        final relatorio = await PdfService.gerarRelatorioSemestral(
          professor: p,
          turma: p.turmas.single,
        );
        expect(ascii.decode(boletim.take(4).toList()), '%PDF');
        expect(ascii.decode(relatorio.take(4).toList()), '%PDF');
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, linha) => mensagens.add(linha),
      ),
    );
    expect(
      mensagens.where(
        (linha) =>
            linha.contains('Unable to find a font') ||
            linha.contains('no Unicode'),
      ),
      isEmpty,
    );
  });

  testWidgets('cadastro valida o nome e permite apenas dígitos na matrícula', (
    tester,
  ) async {
    final professor = criarProfessor();
    final turma = professor.turmas.single;
    await tester.pumpWidget(
      MaterialApp(
        home: AlunosScreen(professor: professor, turma: turma),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo aluno'));
    await tester.pumpAndSettle();
    final campos = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(campos.at(0), 'Ana123');
    await tester.enterText(campos.at(1), '00A2-3');
    await tester.pump();
    expect(tester.widget<TextFormField>(campos.at(1)).controller!.text, '0023');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(
      find.text('O nome deve conter apenas letras e espaços.'),
      findsOneWidget,
    );
    expect(turma.alunos, hasLength(1));
    await tester.enterText(campos.at(0), 'Ana Cláudia');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(turma.alunos, hasLength(2));
    expect(turma.alunos.last.nome, 'Ana Cláudia');
    expect(turma.alunos.last.matricula, '0023');
    expect(
      (await ArmazenamentoService.carregarProfessor())
          .turmas
          .single
          .alunos
          .last
          .matricula,
      '0023',
    );
  });

  testWidgets('lote permite repetir após falha e persiste a mesma turma', (
    tester,
  ) async {
    final p = criarProfessor();
    final t = p.turmas.single;
    await ArmazenamentoService.salvarProfessor(p);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => LancamentoLoteScreen(professor: p, turma: t),
                ),
              ),
              child: const Text('Abrir lote'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir lote'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '6');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '6');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), '8');
    await tester.pump();
    plataforma.falhar = true;
    await tester.tap(find.text('Salvar todas as notas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível salvar:'), findsOneWidget);
    expect(identical(p.turmas.single, t), isTrue);
    expect(t.primeiroBimestre.obterNota(0), isNull);
    plataforma.falhar = false;
    await tester.tap(find.text('Salvar todas as notas'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir lote'), findsOneWidget);
    final salvo = await ArmazenamentoService.carregarProfessor();
    expect(salvo.turmas.single.primeiroBimestre.obterNota(0), 6);
    expect(salvo.turmas.single.segundoBimestre.provasFinais.single, 8);
    expect(t.segundoBimestre.provasFinais.single, 8);
  });

  testWidgets(
    'falha inicial abre recuperação sem permitir navegar para edição',
    (tester) async {
      await SharedPreferencesAsync().setString(
        ArmazenamentoService.chaveDados,
        'inválido',
      );
      await expectLater(
        ArmazenamentoService.carregarProfessor(),
        throwsFormatException,
      );
      await tester.pumpWidget(
        DiarioClasseApp(
          professor: criarProfessor(),
          erroAoCarregar: 'Falha de leitura',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Backup e restauração'), findsOneWidget);
      expect(
        find.textContaining('Os dados originais estão protegidos'),
        findsOneWidget,
      );
      expect(find.byType(Drawer), findsNothing);
      expect(await ArmazenamentoService.obterJsonSalvo(), 'inválido');
      final apagar = find.text('Apagar todos os dados').last;
      await tester.ensureVisible(apagar);
      await tester.pumpAndSettle();
      await tester.tap(apagar);
      await tester.pumpAndSettle();
      expect(await ArmazenamentoService.obterJsonSalvo(), 'inválido');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await ArmazenamentoService.obterJsonSalvo(), 'inválido');
      await tester.tap(apagar);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();
      expect(find.text('Olá, Maria!'), findsOneWidget);
      final novo = await ArmazenamentoService.carregarProfessor();
      expect(novo.nome, 'Maria');
      expect(novo.turmas, isEmpty);
    },
  );
}
