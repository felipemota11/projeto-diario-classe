import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Centraliza cores, tipografia, formas e sombras do aplicativo.
///
/// Todo o visual é definido aqui para que as telas permaneçam apenas com
/// estrutura e conteúdo. Nada neste arquivo altera regras de negócio.
class AppTheme {
  const AppTheme._();

  // Cores de destaque da identidade visual.
  static const Color brandGreen = Color(AppPalette.institutionalGreen);
  static const Color primary = Color(AppPalette.primary);
  static const Color secondary = Color(AppPalette.institutionalRed);
  static const Color success = Color(AppPalette.greenMedium);
  static const Color warning = Color(AppPalette.warning);
  static const Color danger = Color(AppPalette.institutionalRed);
  static const Color info = Color(AppPalette.info);

  // Superfícies de fundo e de cartão.
  static const Color _lightBackground = Color(AppPalette.lightBackground);
  static const Color _lightSurface = Color(AppPalette.lightSurface);
  static const Color _darkBackground = Color(AppPalette.darkBackground);
  static const Color _darkSurface = Color(AppPalette.darkSurface);

  /// Raio padrão de cartões e blocos.
  static const double radius = 20;

  /// Gradiente usado em cabeçalhos e botões principais.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, success],
  );

  /// Mantém cores de texto e ícones legíveis sobre superfícies escuras.
  static Color foreground(BuildContext context, Color color) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, 0.48)!
        : color;
  }

  /// Tema claro.
  static ThemeData get light => _build(Brightness.light);

  /// Tema escuro.
  static ThemeData get dark => _build(Brightness.dark);

  /// Sombra suave e adaptada ao brilho do tema.
  static List<BoxShadow> softShadow(BuildContext context) {
    final bool escuro = Theme.of(context).brightness == Brightness.dark;

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: escuro ? 0.32 : 0.05),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: escuro ? 0.22 : 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Aplica algarismos tabulares para que os números não "pulem" de largura.
  static TextStyle numerico(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static ThemeData _build(Brightness brilho) {
    final bool escuro = brilho == Brightness.dark;

    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: brandGreen,
          brightness: brilho,
        ).copyWith(
          primary: escuro ? const Color(0xFF92DB9F) : primary,
          onPrimary: escuro ? const Color(0xFF073914) : Colors.white,
          primaryContainer: escuro
              ? const Color(0xFF224B2C)
              : const Color(0xFFDFF1DF),
          onPrimaryContainer: escuro
              ? const Color(0xFFDFF1DF)
              : const Color(0xFF103B1C),
          secondary: escuro ? const Color(0xFFFFB4B0) : secondary,
          onSecondary: escuro ? const Color(0xFF690006) : Colors.white,
          secondaryContainer: escuro
              ? const Color(0xFF542526)
              : const Color(0xFFFCE9E8),
          onSecondaryContainer: escuro
              ? const Color(0xFFFFDAD6)
              : const Color(0xFF741216),
          tertiary: escuro ? const Color(0xFFA4CFBA) : info,
          error: escuro ? const Color(0xFFFFB4AB) : danger,
          onError: escuro ? const Color(0xFF690005) : Colors.white,
          surface: escuro ? _darkSurface : _lightSurface,
          onSurface: Color(escuro ? AppPalette.darkText : AppPalette.lightText),
          onSurfaceVariant: Color(
            escuro ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
          ),
          outline: Color(
            escuro ? AppPalette.darkOutline : AppPalette.lightOutline,
          ),
          outlineVariant: Color(
            escuro ? AppPalette.darkBorder : AppPalette.lightBorder,
          ),
          surfaceContainerHighest: escuro
              ? const Color(AppPalette.darkContainer)
              : const Color(AppPalette.lightContainer),
        );

    final Color background = escuro ? _darkBackground : _lightBackground;

    // Fontes locais para funcionar sem conexão em todas as plataformas.
    final TextTheme baseTexto = ThemeData(brightness: brilho).textTheme;

    final TextTheme texto = baseTexto
        .apply(fontFamily: 'DiarioRoboto')
        .copyWith(
          displaySmall: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: scheme.onSurface,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 15,
            height: 1.45,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 14,
            height: 1.45,
            color: scheme.onSurfaceVariant,
          ),
          labelLarge: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        );

    final OutlineInputBorder borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: texto,
      visualDensity: VisualDensity.standard,

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
          fontFamily: 'DiarioRoboto',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorStyle: TextStyle(color: scheme.error),
        border: borda,
        enabledBorder: borda,
        focusedBorder: borda.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: borda.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: borda.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: 'DiarioRoboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        focusElevation: 5,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(
          fontFamily: 'DiarioRoboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: escuro
            ? const Color(AppPalette.darkContainer)
            : const Color(AppPalette.lightText),
        contentTextStyle: TextStyle(
          fontFamily: 'DiarioRoboto',
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          fontFamily: 'DiarioRoboto',
          fontSize: 15,
          color: scheme.onSurface,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}
