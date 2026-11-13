import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'ayuda_screen.dart';

/// Asistente de ejercicios: responde dudas de técnica y entrenamiento con
/// respuestas predefinidas (no usa IA). La conversación queda guardada.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _api = ApiService.instance;
  final _textoCtrl = TextEditingController();
  final _scroll = ScrollController();
  final List<MensajeChat> _mensajes = [];
  List<String> _sugerencias = [];
  bool _esPremium = false;
  bool _cargando = true;
  bool _escribiendo = false; // el bot está "escribiendo"
  bool _ofrecerAyuda = false; // el bot no supo responder: ofrecer un entrenador
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final conversacion = await _api.historialChat();
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(conversacion.mensajes);
        _sugerencias = conversacion.sugerencias;
        _esPremium = conversacion.esPremium;
        _cargando = false;
      });
      _bajarAlFinal();
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _enviar([String? texto]) async {
    final mensaje = (texto ?? _textoCtrl.text).trim();
    if (mensaje.isEmpty || _escribiendo) return;
    if (!_esPremium) {
      mostrarDialogoPremium(context, 'El asistente de ejercicios es una función Premium.');
      return;
    }

    // Mostrar la pregunta al tiro mientras llega la respuesta
    final temporal = MensajeChat(id: -1, esBot: false, texto: mensaje, fecha: DateTime.now());
    setState(() {
      _mensajes.add(temporal);
      _escribiendo = true;
      _textoCtrl.clear();
    });
    _bajarAlFinal();

    try {
      final r = await _api.preguntarChatbot(mensaje);
      if (!mounted) return;
      setState(() {
        _mensajes
          ..remove(temporal)
          ..add(r.pregunta)
          ..add(r.respuesta);
        _sugerencias = r.sugerencias;
        _ofrecerAyuda = !r.entendida;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _mensajes.remove(temporal));
      _textoCtrl.text = mensaje; // para no perder lo que escribió
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _escribiendo = false);
      _bajarAlFinal();
    }
  }

  Future<void> _borrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar la conversación?'),
        content: const Text('Se eliminarán todos los mensajes con el asistente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _api.borrarChat();
      if (!mounted) return;
      setState(_mensajes.clear);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
        actions: [
          if (_mensajes.isNotEmpty)
            IconButton(
              tooltip: 'Borrar conversación',
              icon: const Icon(Icons.delete_outline),
              onPressed: _borrar,
            ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    return Column(
      children: [
        if (!_esPremium)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colores.premium.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colores.premium),
                SizedBox(width: 10),
                Expanded(child: Text('El asistente es Premium. Actívalo en tu gimnasio.')),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              const _Burbuja(
                esBot: true,
                texto: '¡Hola! Soy el asistente de PonteChetado.\n'
                    'Pregúntame sobre técnica de ejercicios, series y repeticiones, '
                    'descanso o cómo armar tu entrenamiento.',
              ),
              for (final m in _mensajes) _Burbuja(esBot: m.esBot, texto: m.texto),
              if (_escribiendo) const _Burbuja(esBot: true, texto: 'Escribiendo...', suave: true),
              if (_ofrecerAyuda && !_escribiendo)
                Padding(
                  padding: const EdgeInsets.only(left: 38, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AyudaScreen()),
                      ),
                      icon: const Icon(Icons.support_agent, size: 18),
                      label: const Text('Pedir ayuda a un entrenador'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_sugerencias.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sugerencias.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(
                label: Text(_sugerencias[i]),
                onPressed: _escribiendo ? null : () => _enviar(_sugerencias[i]),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textoCtrl,
                    maxLength: 300,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: _escribiendo ? null : _enviar,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  final bool esBot;
  final String texto;
  final bool suave;

  const _Burbuja({required this.esBot, required this.texto, this.suave = false});

  @override
  Widget build(BuildContext context) {
    final burbuja = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esBot ? Colores.superficieAlta : Colores.marca,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(esBot ? 4 : 18),
          bottomRight: Radius.circular(esBot ? 18 : 4),
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: esBot ? (suave ? Colores.textoSuave : Colores.texto) : Colores.sobreMarca,
          fontStyle: suave ? FontStyle.italic : FontStyle.normal,
          height: 1.35,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: esBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (esBot) ...[
            const CircleAvatar(
              radius: 15,
              backgroundColor: Colores.marca,
              child: Icon(Icons.smart_toy, size: 18, color: Colores.sobreMarca),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: burbuja),
        ],
      ),
    );
  }
}
