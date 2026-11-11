import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import 'ayuda_screen.dart';
import 'bandeja_ayuda_screen.dart';
import 'entrenar_screen.dart';
import 'gimnasios_screen.dart';
import 'perfil_screen.dart';
import 'progreso_screen.dart';
import 'rutinas_screen.dart';

/// Pantalla principal con las pestañas de abajo.
///
/// También hace de "centro de avisos" mientras la app está abierta
/// (Historias 014 y 015):
///  - Entrenadores y admins: cada 15 segundos revisa si llegó una solicitud
///    de ayuda nueva, la avisa y muestra el número pendiente en "Perfil".
///  - Socios con una solicitud pendiente: avisa cuando un entrenador la atiende.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _intervalo = Duration(seconds: 15);

  final _api = ApiService.instance;
  int _pestana = 0;
  Usuario? _usuario;
  Timer? _reloj;
  bool _revisando = false;

  // Personal del gimnasio
  int _pendientes = 0;
  int? _ultimoIdVisto; // null = todavía no hace la primera revisión

  // Socio
  int? _solicitudEsperando; // id de la solicitud pendiente del socio

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      final (usuario, _) = await _api.perfil();
      if (!mounted) return;
      setState(() => _usuario = usuario);
      await _revisar();
      _reloj = Timer.periodic(_intervalo, (_) => _revisar());
    } catch (_) {
      // Sin conexión: la app sigue funcionando, solo sin avisos
    }
  }

  Future<void> _revisar() async {
    final u = _usuario;
    if (u == null || _revisando || !mounted) return;
    _revisando = true;
    try {
      if (u.esPersonalGimnasio) {
        await _revisarBandeja();
      } else if (!u.esSuperadmin) {
        await _revisarMiSolicitud();
      }
    } catch (_) {
      // Un error de red puntual no debe molestar al usuario
    } finally {
      _revisando = false;
    }
  }

  Future<void> _revisarBandeja() async {
    final bandeja = await _api.bandejaAyuda();
    if (!mounted) return;
    final nuevas = _ultimoIdVisto == null
        ? <SolicitudAyuda>[]
        : bandeja.pendientes.where((s) => s.id > _ultimoIdVisto!).toList();
    setState(() {
      _pendientes = bandeja.pendientes.length;
      _ultimoIdVisto = bandeja.ultimoId > (_ultimoIdVisto ?? 0)
          ? bandeja.ultimoId
          : (_ultimoIdVisto ?? 0);
    });
    if (nuevas.isNotEmpty) {
      final s = nuevas.last;
      final detalle = s.ejercicio == null ? s.motivoTexto : '${s.motivoTexto} (${s.ejercicio})';
      _avisar(
        icono: Icons.support_agent,
        texto: nuevas.length == 1
            ? '${s.socio ?? 'Un socio'} pide ayuda: $detalle'
            : '${nuevas.length} socios nuevos piden ayuda',
        accion: 'Ver',
        alTocar: () => _abrirPantalla(const BandejaAyudaScreen()),
      );
    }
  }

  Future<void> _revisarMiSolicitud() async {
    final mis = await _api.misSolicitudesAyuda();
    if (!mounted) return;
    final esperando = _solicitudEsperando;
    if (esperando != null && mis.activa?.id != esperando) {
      // La que esperaba ya no está pendiente: ¿la atendieron?
      final s = mis.solicitudes.where((x) => x.id == esperando).firstOrNull;
      if (s != null && s.atendida) {
        _avisar(
          icono: Icons.check_circle,
          texto: '${s.entrenador ?? 'Un entrenador'} atendió tu solicitud de ayuda',
          accion: 'Ver',
          alTocar: () => _abrirPantalla(const AyudaScreen()),
        );
      }
    }
    _solicitudEsperando = mis.activa?.id;
  }

  void _avisar({
    required IconData icono,
    required String texto,
    required String accion,
    required VoidCallback alTocar,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Row(
            children: [
              Icon(icono, color: Colores.marca),
              const SizedBox(width: 12),
              Expanded(child: Text(texto)),
            ],
          ),
          action: SnackBarAction(label: accion, textColor: Colores.marca, onPressed: alTocar),
        ),
      );
  }

  Future<void> _abrirPantalla(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    _revisar();
  }

  @override
  Widget build(BuildContext context) {
    // Cada vez que cambias de pestaña la pantalla se vuelve a crear
    // y recarga sus datos (así el estado Premium y la XP siempre están al día).
    final pantallas = [
      EntrenarScreen(
        esSocio: _usuario == null || (!_usuario!.esPersonalGimnasio && !_usuario!.esSuperadmin),
        alPedirAyuda: () => _revisar(),
      ),
      const RutinasScreen(),
      const ProgresoScreen(),
      const GimnasiosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: pantallas[_pestana],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) {
          setState(() => _pestana = i);
          _revisar();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Entrenar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Rutinas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Progreso',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Gimnasios',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendientes > 0,
              label: Text('$_pendientes'),
              child: const Icon(Icons.person_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: _pendientes > 0,
              label: Text('$_pendientes'),
              child: const Icon(Icons.person),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
