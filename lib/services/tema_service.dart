import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência visual do aparelho, independente dos dados do diário.
class TemaService {
  static const String chaveTema = 'diario_classe_tema';

  static Future<ThemeMode> carregar() async {
    final valor = await SharedPreferencesAsync().getString(chaveTema);
    return switch (valor) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> salvar(ThemeMode modo) async {
    await SharedPreferencesAsync().setString(chaveTema, modo.name);
  }
}
