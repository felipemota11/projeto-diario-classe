import 'package:flutter/material.dart';

import 'models/professor.dart';
import 'screens/inicio_screen.dart';
import 'services/armazenamento_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Professor professor;
  String? erroAoCarregar;

  // Recupera os dados salvos no dispositivo.
  try {
    professor = await ArmazenamentoService.carregarProfessor();
  } catch (erro) {
    professor = Professor(nome: 'Professor');
    erroAoCarregar =
        'Os dados salvos não puderam ser carregados. '
        'O aplicativo foi iniciado vazio.\n\n$erro';
  }

  runApp(DiarioClasseApp(professor: professor, erroAoCarregar: erroAoCarregar));
}

class DiarioClasseApp extends StatelessWidget {
  final Professor professor;
  final String? erroAoCarregar;

  const DiarioClasseApp({
    super.key,
    required this.professor,
    this.erroAoCarregar,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diário de Classe',

      // O aplicativo acompanha o tema claro/escuro do sistema.
      // Nenhuma tela de configurações é criada: apenas seguimos o aparelho.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      home: InicioScreen(professor: professor, erroAoCarregar: erroAoCarregar),
    );
  }
}
