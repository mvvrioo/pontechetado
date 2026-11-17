import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'ayuda_screen.dart';
import 'chat_ayuda_screen.dart';
import 'chatbot_screen.dart';

/// Pestaña "Ayuda" del socio: todo junto y a un toque.
///  - Llamar a un entrenador para que venga.
///  - Consulta por chat (pagos, horarios u otras dudas).
///  - Asistente de ejercicios (chatbot).
///  - Sus conversaciones con los entrenadores.
class AyudaTabScreen extends StatefulWidget {
  /// Se avisa cuando el socio abre o crea una solicitud (para que la app vigile la respuesta).
  final VoidCallback? alCambiar;

  const AyudaTabScreen({super.key, this.alCambiar});

  @override
  State<AyudaTabScreen> createState() => _AyudaTabScreenState();
}

class _AyudaTabScreenState extends State<AyudaTabScreen> {
  final _api = ApiService.instance;
  MisSolicitudesAyuda? _datos;
  bool _cargando = true;
  Object? _error;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _cargar();
    _reloj = Timer.periodic(const Duration(seconds: 10), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    try {
      final datos = await _api.misSolicitudesAyuda();
      if (!mounted) return;
      setState(() {
        _datos = datos;
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

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    widget.alCambiar?.call();
    _cargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
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
    final gimnasio = d.gimnasio ?? 'tu gimnasio';
    final anteriores = d.solicitudes.where((s) => !s.pendiente).take(5).toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ---- Solicitud en curso ----
          if (activa != null) ...[
            _TarjetaActiva(solicitud: activa, alTocar: () => _abrir(ChatAyudaScreen(solicitudId: activa.id))),
            const SizedBox(height: 4),
          ],

          // ---- Entrenadores del gimnasio ----
          _Seccion(titulo: 'Entrenadores de $gimnasio'),
          if (!d.puedePedir)
            const _Bloqueado()
          else ...[
            _OpcionGrande(
              icono: Icons.front_hand,
              titulo: 'Llamar a un entrenador',
              descripcion: 'Que se acerque a corregir tu técnica, ayudarte con una máquina o tu rutina.',
              boton: 'Necesito que venga',
              destacado: true,
              deshabilitado: activa != null,
              alTocar: () => _abrir(const AyudaScreen()),
            ),
            _OpcionGrande(
              icono: Icons.chat_bubble_outline,
              titulo: 'Consulta por chat',
              descripcion: 'Pagos, mensualidad, horarios u otra duda. Te responden por chat, sin moverte.',
              boton: 'Escribir consulta',
              deshabilitado: activa != null,
              alTocar: () => _abrir(const AyudaScreen(motivoInicial: 'consulta')),
            ),
            if (activa != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'Tienes una solicitud en curso. Puedes pedir otra cuando la atiendan o la canceles.',
                  style: TextStyle(color: Colores.textoSuave, fontSize: 13),
                ),
              ),
          ],

          // ---- Asistente ----
          const _Seccion(titulo: 'Respuestas al instante'),
          _OpcionGrande(
            icono: Icons.smart_toy_outlined,
            titulo: 'Asistente de ejercicios',
            descripcion: 'Técnica, series y repeticiones, descanso, calentamiento y cómo armar tu entrenamiento.',
            boton: 'Preguntar',
            alTocar: () => _abrir(const ChatbotScreen()),
          ),

          // ---- Historial ----
          if (anteriores.isNotEmpty) ...[
            const _Seccion(titulo: 'Mis conversaciones'),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < anteriores.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    _FilaHistorial(
                      solicitud: anteriores[i],
                      alTocar: () => _abrir(ChatAyudaScreen(solicitudId: anteriores[i].id)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;

  const _Seccion({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Text(
        titulo.toUpperCase(),
        style: const TextStyle(
          color: Colores.textoSuave,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _OpcionGrande extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String boton;
  final bool destacado;
  final bool deshabilitado;
  final VoidCallback alTocar;

  const _OpcionGrande({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.boton,
    required this.alTocar,
    this.destacado = false,
    this.deshabilitado = false,
  });

  @override
  Widget build(BuildContext context) {
    final accion = deshabilitado ? null : alTocar;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: destacado
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colores.marca, width: 1.2),
            )
          : null,
      child: InkWell(
        onTap: accion,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Opacity(
            opacity: deshabilitado ? 0.45 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: destacado ? Colores.degradado : null,
                        color: destacado ? null : Colores.superficieAlta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icono,
                        color: destacado ? Colores.sobreMarca : Colores.marca,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(descripcion, style: const TextStyle(color: Colores.textoSuave, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                destacado
                    ? FilledButton(onPressed: accion, child: Text(boton))
                    : OutlinedButton(onPressed: accion, child: Text(boton)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaActiva extends StatelessWidget {
  final SolicitudAyuda solicitud;
  final VoidCallback alTocar;

  const _TarjetaActiva({required this.solicitud, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final respondio = s.sinLeerSocio > 0;
    return Card(
      color: Colores.marcaTenue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colores.marca, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (respondio)
                    const Icon(Icons.mark_chat_unread, color: Colores.marca)
                  else
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      respondio
                          ? 'El entrenador te respondió'
                          : s.motivo == 'consulta'
                              ? 'Consulta enviada'
                              : 'Un entrenador viene en camino',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [s.motivoTexto, if (s.ejercicio != null) s.ejercicio!].join(' · '),
                style: const TextStyle(color: Colores.textoSuave),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: alTocar,
                icon: Badge(
                  isLabelVisible: respondio,
                  label: Text('${s.sinLeerSocio}'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                label: Text(respondio ? 'Leer respuesta' : 'Abrir chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  final SolicitudAyuda solicitud;
  final VoidCallback alTocar;

  const _FilaHistorial({required this.solicitud, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    return ListTile(
      leading: Icon(
        s.atendida ? Icons.check_circle : Icons.cancel_outlined,
        color: s.atendida ? Colores.marca : Colores.textoSuave,
      ),
      title: Text(s.motivoTexto, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        s.atendida
            ? 'Atendida${s.entrenador == null ? '' : ' por ${s.entrenador}'} · ${formatearFecha(s.creadaEn)}'
            : 'Cancelada · ${formatearFecha(s.creadaEn)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: alTocar,
    );
  }
}

class _Bloqueado extends StatelessWidget {
  const _Bloqueado();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colores.premium.withValues(alpha: 0.10),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.workspace_premium, color: Colores.premium),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Con Premium activo en tu gimnasio puedes llamar a un entrenador o '
                'hacerle consultas por chat. Se activa pagando tu membresía en un gimnasio asociado (Perfil > Gimnasios).',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
