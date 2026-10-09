import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Si la sesión expira en cualquier pantalla, volvemos al login
  ApiService.instance.alExpirarSesion = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  };

  runApp(const PonteChetadoApp());
}

class PonteChetadoApp extends StatelessWidget {
  const PonteChetadoApp({super.key});

  static const colorMarca = Color(0xFFB6FF3B); // verde "chetado"

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ponte Chetado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorMarca,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const InicioScreen(),
    );
  }
}

/// Pantalla de carga: revisa si ya había sesión guardada.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();
    _revisarSesion();
  }

  Future<void> _revisarSesion() async {
    final api = ApiService.instance;
    await api.cargarSesion();

    var sesionValida = false;
    if (api.haySesion) {
      try {
        await api.perfil(); // confirma que el token sigue sirviendo
        sesionValida = true;
      } on ApiException catch (e) {
        // 401: el token venció y alExpirarSesion ya nos llevó al login.
        if (e.codigo == 401) return;
        // Otro error (ej: XAMPP apagado): entramos igual, la app mostrará el error.
        sesionValida = true;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => sesionValida ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
