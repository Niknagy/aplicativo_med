import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/medicamento.dart';
import 'screens/historico_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/medicamento_form_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await AuthService.restaurarSessao();
  await DatabaseService.instance.inicializarNotificacoes();
  runApp(const MedicamentosApp());
}

class MedicamentosApp extends StatelessWidget {
  const MedicamentosApp({super.key});

  Route<dynamic> _gerarRota(RouteSettings settings) {
    var nome = settings.name ?? '/home';

    // Proteção de rota: somente o Admin logado acessa o formulário de criar/editar receita.
    if (nome == '/medicamento' && !AuthService.ehAdminLogado) {
      nome = '/login';
    }

    final Widget tela;
    switch (nome) {
      case '/login':
        tela = const LoginScreen();
      case '/cadastro':
        tela = const RegisterScreen();
      case '/medicamento':
        tela = MedicamentoFormScreen(
            medicamento: settings.arguments as Medicamento?);
      case '/historico':
        tela = const HistoricoScreen();
      case '/home':
      default:
        tela = const HomeScreen();
    }
    return MaterialPageRoute(builder: (_) => tela, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Já tomei?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      initialRoute: '/home',
      onGenerateRoute: _gerarRota,
    );
  }
}