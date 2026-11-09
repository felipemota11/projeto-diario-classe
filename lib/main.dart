import 'package:flutter/material.dart';

import 'models/professor.dart';
import 'screens/inicio_screen.dart';
import 'services/armazenamento_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Recupera os dados salvos no dispositivo.
  final Professor professor = await ArmazenamentoService.carregarProfessor();

  runApp(DiarioClasseApp(professor: professor));
}

class DiarioClasseApp extends StatelessWidget {
  final Professor professor;

  const DiarioClasseApp({super.key, required this.professor});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diário de Classe',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),

      home: InicioScreen(professor: professor),
    );
  }
}
