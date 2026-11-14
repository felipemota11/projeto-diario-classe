import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_diario/main.dart';
import 'package:projeto_diario/screens/inicio_screen.dart';
import 'package:projeto_diario/services/tema_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fixtures.dart';

void main() {
  late ArmazenamentoDeTeste plataforma;
  setUp(() {
    plataforma = ArmazenamentoDeTeste();
    SharedPreferencesAsyncPlatform.instance = plataforma;
  });

  test('preferência ausente ou desconhecida segue o sistema', () async {
    expect(await TemaService.carregar(), ThemeMode.system);
    await SharedPreferencesAsync().setString(
      TemaService.chaveTema,
      'desconhecido',
    );
    expect(await TemaService.carregar(), ThemeMode.system);
  });

  testWidgets(
    'troca tema, mantém a escolha ao reabrir e permite voltar ao claro',
    (tester) async {
      await tester.pumpWidget(DiarioClasseApp(professor: criarProfessor()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Alterar tema'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Escuro'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(InicioScreen))).brightness,
        Brightness.dark,
      );
      expect(await TemaService.carregar(), ThemeMode.dark);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(DiarioClasseApp(professor: criarProfessor()));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      await tester.tap(find.byTooltip('Alterar tema'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Claro'),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(InicioScreen))).brightness,
        Brightness.light,
      );
      expect(await TemaService.carregar(), ThemeMode.light);
    },
  );

  testWidgets('modo automático acompanha a aparência do aparelho', (
    tester,
  ) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    await TemaService.salvar(ThemeMode.light);
    await tester.pumpWidget(DiarioClasseApp(professor: criarProfessor()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Alterar tema'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Seguir o sistema'),
    );
    await tester.pumpAndSettle();
    expect(await TemaService.carregar(), ThemeMode.system);
    expect(
      Theme.of(tester.element(find.byType(InicioScreen))).brightness,
      Brightness.dark,
    );
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(InicioScreen))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'falha ao salvar mantém o tema anterior e permite nova tentativa',
    (tester) async {
      await TemaService.salvar(ThemeMode.light);
      await tester.pumpWidget(DiarioClasseApp(professor: criarProfessor()));
      await tester.pumpAndSettle();
      plataforma.falhar = true;
      await tester.tap(find.byTooltip('Alterar tema'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Escuro'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível salvar o tema. Tente novamente.'),
        findsOneWidget,
      );
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(await TemaService.carregar(), ThemeMode.light);
      plataforma.falhar = false;
      await tester.tap(find.byTooltip('Alterar tema'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Escuro'),
      );
      await tester.pumpAndSettle();
      expect(await TemaService.carregar(), ThemeMode.dark);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    },
  );
}
