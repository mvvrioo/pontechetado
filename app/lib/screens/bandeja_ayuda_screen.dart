import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'chat_ayuda_screen.dart';

/// Bandeja del entrenador: solicitudes de ayuda de los socios del gimnasio.
/// Se actualiza sola cada 8 segundos y avisa cuando llega una nueva.
/// El superadmin entra con [gimnasioId].
class BandejaAyudaScreen extends StatefulWidget {
  final int? gimnasioId;

  const BandejaAyudaScreen({super.key, this.gimnasioId});

  @override
  State<BandejaAyudaScreen> createState() => _BandejaAyudaScreenState();
}

class _BandejaAyudaScreenState extends State<BandejaAyudaScreen> {
  final _api = ApiService.instance;
  BandejaAyuda? _bandeja;
  int _ultimoIdVisto = 0;
  int? _atendiendo; // id de la solicitud que se está marcando
  bool _cargando = true;
  Object? _error;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _cargar();
    _reloj = Timer.periodic(const Duration(seconds: 8), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!mounted) return;
    if (!silencioso) {
      setState(() {
        _cargando = _bandeja == null;
        _error = null;
      });
    }
    try {
      final primeraVez = _bandeja == null;
      final bandeja = await _api.bandejaAyuda(gimnasioId: widget.gimnasioId);
      if (!mounted) return;

      // Aviso de solicitud nueva (no en la primera carga)
      if (!primeraVez && bandeja.ultimoId > _ultimoIdVisto) {
        final nueva = bandeja.pendientes.last;
        mostrarMensaje(context, 'Nueva solicitud: ${nueva.socio ?? 'un socio'} necesita ayuda');
      }

      setState(() {
        _bandeja = bandeja;
        if (bandeja.ultimoId > _ultimoIdVisto) _ultimoIdVisto = bandeja.ultimoId;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silencioso) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  Future<void> _atender(SolicitudAyuda s) async {
    setState(() => _atendiendo = s.id);
    try {
      await _api.atenderAyuda(s.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Listo: ${s.socio ?? 'el socio'} verá que fue atendido');
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _atendiendo = null);
      await _cargar(silencioso: true);
    }
  }

  Future<void> _abrirChat(SolicitudAyuda s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatAyudaScreen(solicitudId: s.id)),
    );
    _cargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_bandeja == null ? 'Solicitudes de ayuda' : 'Ayuda · ${_bandeja!.gimnasio}'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null && _bandeja == null) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final b = _bandeja!;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pendientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${b.pendientes.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: b.pendientes.isEmpty ? Colores.textoSuave : Colores.marca,
                  ),
                ),
              ],
            ),
          ),
          if (b.pendientes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: Colores.textoSuave),
                    SizedBox(height: 10),
                    Text(
                      'No hay solicitudes pendientes.\n'
                      'Esta pantalla se actualiza sola cuando un socio pide ayuda.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          for (final s in b.pendientes)
            _TarjetaPendiente(
              solicitud: s,
              ocupado: _atendiendo == s.id,
              alAtender: () => _atender(s),
              alAbrirChat: () => _abrirChat(s),
            ),
          if (b.atendidasHoy.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 12, 4, 10),
              child: Text(
                'Atendidas hoy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            for (final s in b.atendidasHoy)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colores.marca),
                  title: Text(
                    s.socio ?? 'Socio',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${_detalle(s)}\n'
                    'Atendió ${s.entrenador ?? 'un entrenador'}'
                    '${s.atendidaEn == null ? '' : ' a las ${_hora(s.atendidaEn!)}'}',
                  ),
                  isThreeLine: true,
                  trailing: s.mensajesChat > 0 ? const Icon(Icons.chat_bubble_outline, size: 20) : null,
                  onTap: () => _abrirChat(s),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _hora(DateTime f) =>
    '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

String _detalle(SolicitudAyuda s) => [
  s.motivoTexto,
  if (s.ejercicio != null) s.ejercicio!,
].join(' · ');

/// "hace 3 min", para que el entrenador priorice al que lleva más esperando.
String _espera(DateTime desde) {
  final minutos = DateTime.now().difference(desde).inMinutes;
  if (minutos < 1) return 'recién';
  if (minutos < 60) return 'hace $minutos min';
  return 'hace ${minutos ~/ 60} h';
}

class _TarjetaPendiente extends StatelessWidget {
  final SolicitudAyuda solicitud;
  final bool ocupado;
  final VoidCallback alAtender;
  final VoidCallback alAbrirChat;

  const _TarjetaPendiente({
    required this.solicitud,
    required this.ocupado,
    required this.alAtender,
    required this.alAbrirChat,
  });

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final nombre = s.socio ?? 'Socio';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colores.marca),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colores.marca,
                  child: Text(
                    nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
                    style: const TextStyle(color: Colores.sobreMarca, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(_detalle(s), style: const TextStyle(color: Colores.textoSuave)),
                    ],
                  ),
                ),
                Text(
                  _espera(s.creadaEn),
                  style: const TextStyle(color: Colores.premium, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (s.mensaje != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.superficieAlta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(s.mensaje!),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: alAbrirChat,
                    icon: Badge(
                      isLabelVisible: s.sinLeerEntrenador > 0,
                      label: Text('${s.sinLeerEntrenador}'),
                      child: const Icon(Icons.chat_bubble_outline, size: 20),
                    ),
                    label: Text(s.sinLeerEntrenador > 0 ? 'Mensaje nuevo' : 'Responder'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: ocupado ? null : alAtender,
                    icon: const Icon(Icons.check),
                    label: Text(ocupado ? 'Guardando...' : 'Atendida'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
