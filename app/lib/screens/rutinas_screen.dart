import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';
import 'rutina_detalle_screen.dart';

class RutinasScreen extends StatefulWidget {
  const RutinasScreen({super.key});

  @override
  State<RutinasScreen> createState() => _RutinasScreenState();
}

class _RutinasScreenState extends State<RutinasScreen> {
  final _api = ApiService.instance;
  List<Rutina> _rutinas = [];
  int? _limite; // null = ilimitado (Premium)
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final (rutinas, limite) = await _api.listarRutinas();
      if (!mounted) return;
      setState(() {
        _rutinas = rutinas;
        _limite = limite;
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

  Future<void> _crear() async {
    final nueva = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _NuevaRutinaDialog(),
    );
    if (nueva == null) return;

    try {
      await _api.crearRutina(nueva.$1, nueva.$2);
      if (!mounted) return;
      mostrarMensaje(context, 'Rutina creada');
      _cargar();
    } catch (e) {
      // Si llegó al límite del plan gratis, el servidor responde
      // "requiere_premium" y mostrarError muestra el aviso Premium.
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  Future<void> _eliminar(Rutina r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar rutina?'),
        content: Text('Se eliminará "${r.nombre}" con todos sus ejercicios.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _api.eliminarRutina(r.id);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  Future<void> _abrir(Rutina r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RutinaDetalleScreen(rutinaId: r.id)),
    );
    _cargar(); // al volver, actualizar el contador de ejercicios
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis rutinas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (_limite != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                avatar: const Icon(Icons.info_outline, size: 18),
                label: Text('Plan gratis: ${_rutinas.length} de $_limite rutinas'),
              ),
            ),
          if (_rutinas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Text(
                'Todavía no tienes rutinas.\nCrea la primera con "Nueva rutina".',
                textAlign: TextAlign.center,
              ),
            ),
          for (final r in _rutinas)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                title: Text(r.nombre),
                subtitle: Text(
                  [
                    if (r.descripcion != null) r.descripcion!,
                    '${r.totalEjercicios} ejercicio${r.totalEjercicios == 1 ? '' : 's'}',
                  ].join(' · '),
                ),
                onTap: () => _abrir(r),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar',
                  onPressed: () => _eliminar(r),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NuevaRutinaDialog extends StatefulWidget {
  const _NuevaRutinaDialog();

  @override
  State<_NuevaRutinaDialog> createState() => _NuevaRutinaDialogState();
}

class _NuevaRutinaDialogState extends State<_NuevaRutinaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (_nombreCtrl.text.trim(), _descCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva rutina'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Pecho y tríceps',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Crear')),
      ],
    );
  }
}
