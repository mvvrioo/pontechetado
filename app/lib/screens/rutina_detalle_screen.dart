import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';

class RutinaDetalleScreen extends StatefulWidget {
  final int rutinaId;

  const RutinaDetalleScreen({super.key, required this.rutinaId});

  @override
  State<RutinaDetalleScreen> createState() => _RutinaDetalleScreenState();
}

class _RutinaDetalleScreenState extends State<RutinaDetalleScreen> {
  final _api = ApiService.instance;
  RutinaDetalle? _rutina;
  List<Ejercicio>? _catalogo; // se carga la primera vez que agregas un ejercicio
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
      final rutina = await _api.detalleRutina(widget.rutinaId);
      if (!mounted) return;
      setState(() {
        _rutina = rutina;
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

  Future<void> _agregarEjercicio() async {
    // 1. Cargar catálogo (solo una vez)
    try {
      _catalogo ??= await _api.listarEjercicios();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
      return;
    }
    if (!mounted) return;

    // 2. Elegir ejercicio
    final elegido = await showModalBottomSheet<Ejercicio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SelectorEjercicio(ejercicios: _catalogo!),
    );
    if (elegido == null || !mounted) return;

    // Aviso rápido en la app (el servidor igual lo valida)
    if (elegido.bloqueado) {
      mostrarDialogoPremium(context, '"${elegido.nombre}" es un ejercicio Premium.');
      return;
    }

    // 3. Series, repeticiones y peso
    final config = await showDialog<_ConfigSeries>(
      context: context,
      builder: (_) => _SeriesDialog(nombreEjercicio: elegido.nombre),
    );
    if (config == null) return;

    // 4. Guardar
    try {
      await _api.agregarEjercicioARutina(
        rutinaId: widget.rutinaId,
        ejercicioId: elegido.id,
        series: config.series,
        repeticiones: config.repeticiones,
        pesoKg: config.pesoKg,
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e); // ej: límite de ejercicios del plan gratis
    }
  }

  Future<void> _quitar(EjercicioRutina e) async {
    try {
      await _api.quitarEjercicioDeRutina(e.id);
      if (!mounted) return;
      mostrarMensaje(context, '${e.nombre} quitado');
      _cargar();
    } catch (err) {
      if (!mounted) return;
      mostrarError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_rutina?.nombre ?? 'Rutina')),
      floatingActionButton: _rutina == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _agregarEjercicio,
              icon: const Icon(Icons.add),
              label: const Text('Agregar ejercicio'),
            ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    final rutina = _rutina!;
    if (rutina.ejercicios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Esta rutina no tiene ejercicios.\nAgrega el primero 👇',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (rutina.descripcion != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(rutina.descripcion!),
          ),
        for (final (i, e) in rutina.ejercicios.indexed)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(e.nombre),
              subtitle: Text([
                '${e.series} × ${e.repeticiones}',
                if (e.pesoKg != null) '${formatearKg(e.pesoKg!)} kg',
                e.grupoMuscular,
              ].join(' · ')),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Quitar',
                onPressed: () => _quitar(e),
              ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
//  Lista para elegir un ejercicio del catálogo
// ----------------------------------------------------------------------
class _SelectorEjercicio extends StatelessWidget {
  final List<Ejercicio> ejercicios;

  const _SelectorEjercicio({required this.ejercicios});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Elige un ejercicio', style: tema.textTheme.titleLarge),
          ),
          for (final e in ejercicios)
            ListTile(
              title: Text(e.nombre),
              subtitle: Text(e.grupoMuscular),
              trailing: e.esPremium
                  ? Icon(
                      e.bloqueado ? Icons.lock : Icons.workspace_premium,
                      color: tema.colorScheme.tertiary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, e),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
//  Diálogo: series, repeticiones y peso
// ----------------------------------------------------------------------
class _ConfigSeries {
  final int series;
  final int repeticiones;
  final double? pesoKg;

  _ConfigSeries(this.series, this.repeticiones, this.pesoKg);
}

class _SeriesDialog extends StatefulWidget {
  final String nombreEjercicio;

  const _SeriesDialog({required this.nombreEjercicio});

  @override
  State<_SeriesDialog> createState() => _SeriesDialogState();
}

class _SeriesDialogState extends State<_SeriesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _seriesCtrl = TextEditingController(text: '4');
  final _repsCtrl = TextEditingController(text: '10');
  final _pesoCtrl = TextEditingController();

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repsCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final peso = _pesoCtrl.text.trim().isEmpty ? null : leerNumero(_pesoCtrl.text);
    Navigator.pop(
      context,
      _ConfigSeries(int.parse(_seriesCtrl.text), int.parse(_repsCtrl.text), peso),
    );
  }

  String? _validarEntero(String? v, int min, int max) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < min || n > max) return 'Entre $min y $max';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.nombreEjercicio),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _seriesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Series'),
                    validator: (v) => _validarEntero(v, 1, 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repeticiones'),
                    validator: (v) => _validarEntero(v, 1, 300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (opcional)',
                suffixText: 'kg',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = leerNumero(v);
                if (n == null || n < 0 || n > 1000) return 'Peso no válido';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Agregar')),
      ],
    );
  }
}
