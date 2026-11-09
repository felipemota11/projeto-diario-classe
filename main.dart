
import 'package:flutter/material.dart';

import 'lib/models/professor.dart';
import 'lib/screens/inicio_screen.dart';

void main() {
  // Cria o professor que utilizará o sistema.
  final professor = Professor(
    nome: 'Professor',
  );

  runApp(
    DiarioClasseApp(professor: professor),
  );
}

class DiarioClasseApp extends StatelessWidget {
  final Professor professor;

  const DiarioClasseApp({
    super.key,
    required this.professor,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diário de Classe',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
      ),

      home: InicioScreen(
        professor: professor,
      ),
    );
  }
}
