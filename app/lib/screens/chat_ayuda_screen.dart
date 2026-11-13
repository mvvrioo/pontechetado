import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';

/// Chat de una solicitud de ayuda entre el socio y los entrenadores de su
/// gimnasio. Sirve para resolver dudas sin que el entrenador tenga que ir
/// (ej: "¿hasta qué día pago la mensualidad?") o para coordinar ("voy en 2 min").
/// Se actualiza solo cada 4 segundos mientras está abierto.
class ChatAyudaScreen extends StatefulWidget {
  final int solicitudId;

  const ChatAyudaScreen({super.key, required this.solicitudId});

  @override
  State<ChatAyudaScreen> createState() => _ChatAyudaScreenState();
}

class _ChatAyudaScreenState extends State<ChatAyudaScreen> {
  final _api = ApiService.instance;
  final _textoCtrl = TextEditingController();
  final _scroll = ScrollController();
  ChatAyuda? _chat;
  bool _cargando = true;
  bool _enviando = false;
  bool _atendiendo = false;
  Object? _error;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _cargar();
    _reloj = Timer.periodic(const Duration(seconds: 4), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _textoCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    try {
      final antes = _chat?.mensajes.length ?? -1;
      final chat = await _api.chatAyuda(widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        _cargando = false;
        _error = null;
      });
      if (chat.mensajes.length != antes) _bajarAlFinal();
    } catch (e) {
      if (!mounted || silencioso) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  void _bajarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await _api.enviarMensajeAyuda(widget.solicitudId, texto);
      if (!mounted) return;
      _textoCtrl.clear();
      setState(() => _chat?.mensajes.add(mensaje));
      _bajarAlFinal();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
      _cargar(silencioso: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _marcarAtendida() async {
    setState(() => _atendiendo = true);
    try {
      await _api.atenderAyuda(widget.solicitudId);
      if (!mounted) return;
      mostrarMensaje(context, 'Solicitud marcada como atendida');
      await _cargar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _atendiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    final s = chat?.solicitud;
    final titulo = chat == null
        ? 'Chat'
        : chat.soyElSocio
            ? 'Chat con tu entrenador'
            : (s?.socio ?? 'Socio');

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 20),
        title: Text(titulo),
        actions: [
          if (chat != null && !chat.soyElSocio && s!.pendiente)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _atendiendo ? null : _marcarAtendida,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Atendida'),
              ),
            ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null && _chat == null) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final chat = _chat!;
    final s = chat.solicitud;

    return Column(
      children: [
        _Encabezado(solicitud: s),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              // El detalle que escribió al pedir ayuda es el primer mensaje
              if ((s.mensaje ?? '').isNotEmpty)
                _Burbuja(
                  texto: s.mensaje!,
                  autor: s.socio ?? 'Socio',
                  hora: s.creadaEn,
                  esMio: chat.soyElSocio,
                ),
              if (chat.mensajes.isEmpty && (s.mensaje ?? '').isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    chat.soyElSocio
                        ? 'Escríbele al entrenador si quieres agregar algo.\nTe responderá aquí mismo.'
                        : 'Escríbele al socio, por ejemplo: "Voy en 2 minutos".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colores.textoSuave),
                  ),
                ),
              for (final m in chat.mensajes)
                _Burbuja(texto: m.texto, autor: m.autor, hora: m.creadoEn, esMio: m.esMio),
            ],
          ),
        ),
        if (chat.puedeEscribir)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              decoration: const BoxDecoration(
                color: Colores.superficie,
                border: Border(top: BorderSide(color: Colores.borde)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoCtrl,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _enviando ? null : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          )
        else
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colores.superficie,
              child: Text(
                s.atendida
                    ? 'Solicitud atendida${s.entrenador == null ? '' : ' por ${s.entrenador}'}. La conversación quedó cerrada.'
                    : 'Solicitud cancelada. La conversación quedó cerrada.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.textoSuave),
              ),
            ),
          ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  final SolicitudAyuda solicitud;

  const _Encabezado({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final (color, estado) = switch (s.estado) {
      'pendiente' => (Colores.marca, 'Pendiente'),
      'atendida' => (Colores.textoSuave, 'Atendida'),
      _ => (Colores.textoSuave, 'Cancelada'),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colores.superficie,
        border: Border(bottom: BorderSide(color: Colores.borde)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Colores.marca),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              [s.motivoTexto, if (s.ejercicio != null) s.ejercicio!].join(' · '),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              estado,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final String texto;
  final String autor;
  final DateTime hora;
  final bool esMio;

  const _Burbuja({
    required this.texto,
    required this.autor,
    required this.hora,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    final h = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: esMio ? Colores.marca : Colores.superficieAlta,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(esMio ? 18 : 4),
                  bottomRight: Radius.circular(esMio ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!esMio)
                    Text(
                      autor,
                      style: const TextStyle(
                        color: Colores.marca,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    texto,
                    style: TextStyle(
                      color: esMio ? Colores.sobreMarca : Colores.texto,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      h,
                      style: TextStyle(
                        fontSize: 11,
                        color: esMio ? Colores.sobreMarcaSuave : Colores.textoSuave,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
