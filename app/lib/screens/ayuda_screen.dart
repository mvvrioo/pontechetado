import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';

/// El socio pide que un entrenador del gimnasio se acerque a ayudarlo
/// y ve aquí cuando su solicitud fue atendida.
class AyudaScreen extends StatefulWidget {
  /// Ejercicios del catálogo, para indicar con cuál necesita ayuda (opcional).
  final List<Ejercicio> ejercicios;

  const AyudaScreen({super.key, this.ejercicios = const []});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> {
  final _api = ApiService.instance;
  final _mensajeCtrl = TextEditingController();
  MisSolicitudesAyuda? _datos;
  List<Ejercicio> _ejercicios = [];
  String? _motivo;
  int? _ejercicioId;
  bool _cargando = true;
  bool _enviando = false;
  Object? _error;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _ejercicios = widget.ejercicios.where((e) => !e.bloqueado).toList();
    _cargar();
    // Mientras haya una solicitud pendiente se revisa cada 10 segundos
    // para avisar apenas el entrenador la marque como atendida.
    _reloj = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_datos?.activa != null) _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!mounted) return;
    if (!silencioso) {
      setState(() {
        _cargando = _datos == null;
        _error = null;
      });
    }
    try {
      final idActiva = _datos?.activa?.id;
      final datos = await _api.misSolicitudesAyuda();
      if (_ejercicios.isEmpty && datos.puedePedir) {
        _ejercicios = (await _api.listarEjercicios()).where((e) => !e.bloqueado).toList();
      }
      if (!mounted) return;
      setState(() {
        _datos = datos;
        _cargando = false;
      });

      // La que estaba pendiente ya no lo está: ¿la atendieron?
      if (idActiva != null && datos.activa == null) {
        final anterior = datos.solicitudes.where((s) => s.id == idActiva).firstOrNull;
        if (anterior != null && anterior.atendida) {
          mostrarMensaje(
            context,
            anterior.entrenador == null
                ? 'Tu solicitud fue atendida'
                : '${anterior.entrenador} atendió tu solicitud',
          );
        }
      }
    } catch (e) {
      if (!mounted || silencioso) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  Future<void> _enviar() async {
    final motivo = _motivo;
    if (motivo == null) {
      mostrarMensaje(context, 'Elige en qué necesitas ayuda');
      return;
    }
    final mensaje = _mensajeCtrl.text.trim();
    if (motivo == 'otro' && mensaje.isEmpty) {
      mostrarMensaje(context, 'Cuéntale al entrenador en qué te puede ayudar');
      return;
    }

    setState(() => _enviando = true);
    try {
      final confirmacion = await _api.solicitarAyuda(
        motivo: motivo,
        ejercicioId: motivo == 'tecnica' ? _ejercicioId : null,
        mensaje: mensaje,
      );
      if (!mounted) return;
      _mensajeCtrl.clear();
      setState(() {
        _motivo = null;
        _ejercicioId = null;
      });
      FocusScope.of(context).unfocus();
      mostrarMensaje(context, confirmacion);
      await _cargar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cancelar(SolicitudAyuda s) async {
    try {
      await _api.cancelarAyuda(s.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Solicitud cancelada');
      await _cargar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
      _cargar(silencioso: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir ayuda')),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null && _datos == null) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final d = _datos!;
    final activa = d.activa;
    final anteriores = d.solicitudes.where((s) => !s.pendiente).toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (!d.puedePedir)
            const _AyudaBloqueada()
          else if (activa != null)
            _TarjetaEnEspera(solicitud: activa, alCancelar: () => _cancelar(activa))
          else
            _formulario(d),
          if (anteriores.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 12, 4, 10),
              child: Text(
                'Solicitudes anteriores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            for (final s in anteriores) _TarjetaSolicitud(solicitud: s),
          ],
        ],
      ),
    );
  }

  Widget _formulario(MisSolicitudesAyuda d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent, color: Colores.marca),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¿En qué te ayudamos?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Un entrenador de ${d.gimnasio ?? 'tu gimnasio'} recibe tu solicitud y se acerca a ayudarte.',
              style: const TextStyle(color: Colores.textoSuave),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in d.motivos)
                  ChoiceChip(
                    label: Text(m.texto),
                    selected: _motivo == m.codigo,
                    onSelected: (_) => setState(() => _motivo = m.codigo),
                  ),
              ],
            ),
            if (_motivo == 'tecnica' && _ejercicios.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _ejercicioId,
                isExpanded: true,
                menuMaxHeight: 360,
                decoration: const InputDecoration(labelText: 'Ejercicio (opcional)'),
                items: [
                  for (final e in _ejercicios)
                    DropdownMenuItem(value: e.id, child: Text(e.nombre)),
                ],
                onChanged: (v) => setState(() => _ejercicioId = v),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _mensajeCtrl,
              maxLength: 255,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _motivo == 'otro' ? 'Cuéntanos qué necesitas' : 'Detalle (opcional)',
                hintText: 'Ej: estoy en el rack 2, no sé cuánto bajar en la sentadilla',
                alignLabelWithHint: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.front_hand),
              label: Text(_enviando ? 'Enviando...' : 'Pedir ayuda'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}

String _horaDe(DateTime f) =>
    '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

String _detalleDe(SolicitudAyuda s) => [
  s.motivoTexto,
  if (s.ejercicio != null) s.ejercicio!,
].join(' · ');

class _TarjetaEnEspera extends StatelessWidget {
  final SolicitudAyuda solicitud;
  final VoidCallback alCancelar;

  const _TarjetaEnEspera({required this.solicitud, required this.alCancelar});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF232E12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colores.marca),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solicitud enviada',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Los entrenadores ya recibieron tu solicitud. Quédate donde estás entrenando.',
            ),
            const SizedBox(height: 12),
            Text(
              '${_detalleDe(solicitud)} · ${_horaDe(solicitud.creadaEn)}',
              style: const TextStyle(color: Colores.textoSuave),
            ),
            if (solicitud.mensaje != null) ...[
              const SizedBox(height: 4),
              Text('"${solicitud.mensaje}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: alCancelar,
              child: const Text('Ya no necesito ayuda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  final SolicitudAyuda solicitud;

  const _TarjetaSolicitud({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final atendida = s.atendida;
    return Card(
      child: ListTile(
        leading: Icon(
          atendida ? Icons.check_circle : Icons.cancel_outlined,
          color: atendida ? Colores.marca : Colores.textoSuave,
        ),
        title: Text(_detalleDe(s), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          atendida
              ? 'Atendida${s.entrenador == null ? '' : ' por ${s.entrenador}'} · ${formatearFecha(s.creadaEn)}'
              : 'Cancelada · ${formatearFecha(s.creadaEn)}',
        ),
      ),
    );
  }
}

class _AyudaBloqueada extends StatelessWidget {
  const _AyudaBloqueada();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colores.premium.withValues(alpha: 0.12),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: Colores.premium),
                SizedBox(width: 10),
                Text(
                  'Función Premium',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Con Premium activo en tu gimnasio puedes pedir desde la app que un '
              'entrenador se acerque a corregir tu técnica o a orientarte con tu rutina.\n\n'
              'Se activa pagando tu membresía en un gimnasio asociado (pestaña "Gimnasios").',
            ),
          ],
        ),
      ),
    );
  }
}
