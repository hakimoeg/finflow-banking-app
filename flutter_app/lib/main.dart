// lib/main.dart — Point d'entrée de l'application Flutter FinFlow
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. IMPORT INDISPENSABLE
import 'services/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // 2. S'assurer que les liaisons Flutter sont prêtes pour l'asynchrone
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Charger les fichiers de traduction pour le formatage des dates en français
  await initializeDateFormatting('fr_FR', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const FinFlowApp(),
    ),
  );
}

class FinFlowApp extends StatelessWidget {
  const FinFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC9A84C),
          surface: const Color(0xFF141D2E),
          background: const Color(0xFF0A0F1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        fontFamily: 'DM Sans',
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
    );
  }
}

// Redirige vers Dashboard si session active, sinon Login
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await context.read<AuthProvider>().loadSession();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const DashboardScreen();
    return const LoginScreen();
  }
}