import 'package:flutter/material.dart';

import 'models/professor.dart';
import 'screens/backup_screen.dart';
import 'screens/inicio_screen.dart';
import 'services/armazenamento_service.dart';
import 'services/tema_service.dart';
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
        'Restaure um backup semestral ou inicie um novo diário.\n\n$erro';
  }

  runApp(DiarioClasseApp(professor: professor, erroAoCarregar: erroAoCarregar));
}

class DiarioClasseApp extends StatefulWidget {
  final Professor professor;
  final String? erroAoCarregar;

  const DiarioClasseApp({
    super.key,
    required this.professor,
    this.erroAoCarregar,
  });

  @override
  State<DiarioClasseApp> createState() => _DiarioClasseAppState();
}

class _DiarioClasseAppState extends State<DiarioClasseApp> {
  late String? _erroAoCarregar = widget.erroAoCarregar;
  final _mensageiro = GlobalKey<ScaffoldMessengerState>();
  ThemeMode _tema = ThemeMode.system;
  bool _temaEscolhido = false;
  bool _salvandoTema = false;

  @override
  void initState() {
    super.initState();
    _carregarTema();
  }

  Future<void> _carregarTema() async {
    try {
      final tema = await TemaService.carregar();
      if (mounted && !_temaEscolhido) setState(() => _tema = tema);
    } catch (_) {
      // Uma falha na preferência visual mantém o tema do sistema.
    }
  }

  Future<void> _alterarTema(ThemeMode tema) async {
    if (_salvandoTema) return;
    _temaEscolhido = true;
    setState(() => _salvandoTema = true);
    try {
      await TemaService.salvar(tema);
      if (mounted) setState(() => _tema = tema);
    } catch (_) {
      if (mounted) {
        _mensageiro.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o tema. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoTema = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diário de Classe',
      scaffoldMessengerKey: _mensageiro,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _tema,

      home: _erroAoCarregar == null
          ? InicioScreen(
              professor: widget.professor,
              temaSelecionado: _tema,
              salvandoTema: _salvandoTema,
              aoAlterarTema: _alterarTema,
            )
          : BackupScreen(
              professor: widget.professor,
              erroAoCarregar: _erroAoCarregar,
              aoRecuperar: () => setState(() => _erroAoCarregar = null),
            ),
    );
  }
}
