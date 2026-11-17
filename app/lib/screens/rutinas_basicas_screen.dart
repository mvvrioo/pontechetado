import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'rutinas_screen.dart' show elegirDiaSemana;

/// Rutinas básicas listas para usar. Están disponibles en el plan gratis (H003).
class RutinasBasicasScreen extends StatefulWidget {
  const RutinasBasicasScreen({super.key});

  @override
  State<RutinasBasicasScreen> createState() => _RutinasBasicasScreenState();
}

class _RutinasBasicasScreenState extends State<RutinasBasicasScreen> {
  final _api = ApiService.instance;
  List<RutinaBasica> _rutinas = [];
  bool _cargando = true;
  String? _usando; // clave de la rutina que se está copiando
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final rutinas = await _api.rutinasBasicas();
      if (!mounted) return;
      setState(() {
        _rutinas = rutinas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  Future<void> _usar(RutinaBasica r) async {
    final dia = await elegirDiaSemana(context);
    if (dia == null || !mounted) return; // canceló
    setState(() => _usando = r.clave);
    try {
      final mensaje = await _api.usarRutinaBasica(r.clave, diaSemana: dia == 0 ? null : dia);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
    } catch (e) {
      // Si llegó al límite de rutinas del plan gratis, se muestra el aviso Premium.
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _usando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas básicas')),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 14),
          child: Text(
            'Rutinas listas para empezar, incluidas en el plan gratis. '
            'Elige una, asígnale un día y aparecerá en tu semana.',
            style: TextStyle(color: Colores.textoSuave),
          ),
        ),
        for (final r in _rutinas)
          _TarjetaRutinaBasica(
            rutina: r,
            usando: _usando == r.clave,
            alUsar: _usando == null ? () => _usar(r) : null,
          ),
      ],
    );
  }
}

class _TarjetaRutinaBasica extends StatelessWidget {
  final RutinaBasica rutina;
  final bool usando;
  final VoidCallback? alUsar;

  const _TarjetaRutinaBasica({required this.rutina, required this.usando, required this.alUsar});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colores.marca),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rutina.nombre,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colores.marca.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'GRATIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colores.marca,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(rutina.descripcion, style: const TextStyle(color: Colores.textoSuave)),
            const SizedBox(height: 10),
            for (final e in rutina.ejercicios)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${e.series} x ${e.repeticiones}',
                      style: const TextStyle(color: Colores.textoSuave),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: alUsar,
              icon: const Icon(Icons.add),
              label: Text(usando ? 'Agregando...' : 'Usar esta rutina'),
            ),
          ],
        ),
      ),
    );
  }
}
