import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../tema.dart';

/// Qué eligió el entrenador en la alerta de ayuda.
enum RespuestaAlerta { atender, chat, verTodas, despues }

/// Alerta a pantalla completa para el entrenador: "¡Un socio necesita ayuda!".
/// Muestra quién la pide, el motivo, el ejercicio y su mensaje.
/// [otras] es cuántas solicitudes nuevas más llegaron al mismo tiempo.
Future<RespuestaAlerta> mostrarAlertaAyuda(
  BuildContext context,
  SolicitudAyuda solicitud, {
  int otras = 0,
}) async {
  HapticFeedback.heavyImpact();
  SystemSound.play(SystemSoundType.alert);

  final respuesta = await showGeneralDialog<RespuestaAlerta>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Solicitud de ayuda',
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animacion, _, hijo) => FadeTransition(
      opacity: animacion,
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: animacion, curve: Curves.easeOutBack),
        ),
        child: hijo,
      ),
    ),
    pageBuilder: (context, _, _) => _PantallaAlerta(solicitud: solicitud, otras: otras),
  );
  return respuesta ?? RespuestaAlerta.despues;
}

class _PantallaAlerta extends StatelessWidget {
  final SolicitudAyuda solicitud;
  final int otras;

  const _PantallaAlerta({required this.solicitud, required this.otras});

  @override
  Widget build(BuildContext context) {
    final nombre = solicitud.socio ?? 'Un socio';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colores.marcaProfunda, Colores.fondo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    const _IconoLatiendo(),
                    const SizedBox(height: 28),
                    Text(
                      solicitud.motivo == 'consulta' ? '¡Un socio tiene una consulta!' : '¡Un socio necesita ayuda!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      otras > 0
                          ? 'Y $otras ${otras == 1 ? 'solicitud más' : 'solicitudes más'} esperando'
                          : solicitud.motivo == 'consulta'
                              ? 'Respóndele por el chat'
                              : 'Acércate a ayudarle o respóndele por chat',
                      style: const TextStyle(color: Colores.textoSuave, fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colores.superficie,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colores.marca, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colores.marca,
                                child: Text(
                                  nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colores.sobreMarca,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _Dato(icono: Icons.help_outline, texto: solicitud.motivoTexto),
                          if (solicitud.ejercicio != null)
                            _Dato(icono: Icons.fitness_center, texto: solicitud.ejercicio!),
                          if ((solicitud.mensaje ?? '').isNotEmpty)
                            _Dato(icono: Icons.chat_bubble_outline, texto: '"${solicitud.mensaje!}"'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, RespuestaAlerta.atender),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Ya lo ayudé: marcar como atendida'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, RespuestaAlerta.chat),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Responder por chat'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, RespuestaAlerta.verTodas),
                            icon: const Icon(Icons.list_alt),
                            label: const Text('Ver todas'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, RespuestaAlerta.despues),
                      child: const Text('Más tarde', style: TextStyle(color: Colores.textoSuave)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colores.secundario),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 16, height: 1.3))),
        ],
      ),
    );
  }
}

/// Ícono de ayuda con un anillo que late, para llamar la atención.
class _IconoLatiendo extends StatefulWidget {
  const _IconoLatiendo();

  @override
  State<_IconoLatiendo> createState() => _IconoLatiendoState();
}

class _IconoLatiendoState extends State<_IconoLatiendo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96 + 54 * t,
                height: 96 + 54 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colores.marca.withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Colores.degradado),
                child: const Icon(Icons.support_agent, size: 52, color: Colores.sobreMarca),
              ),
            ],
          );
        },
      ),
    );
  }
}
