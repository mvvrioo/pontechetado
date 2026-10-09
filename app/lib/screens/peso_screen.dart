import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';

class PesoScreen extends StatefulWidget {
  const PesoScreen({super.key});

  @override
  State<PesoScreen> createState() => _PesoScreenState();
}

class _PesoScreenState extends State<PesoScreen> {
  final _api = ApiService.instance;
  List<RegistroPeso> _registros = [];
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
      final registros = await _api.listarPesos();
      if (!mounted) return;
      setState(() {
        _registros = registros;
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

  Future<void> _agregar() async {
    final nuevo = await showDialog<_NuevoPeso>(
      context: context,
      builder: (_) => const _NuevoPesoDialog(),
    );
    if (nuevo == null) return;

    try {
      await _api.agregarPeso(nuevo.pesoKg, nuevo.fecha, nuevo.nota);
      if (!mounted) return;
      mostrarMensaje(context, 'Peso registrado 💪');
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  Future<void> _eliminar(RegistroPeso r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text('${formatearKg(r.pesoKg)} kg del ${formatearFecha(r.fecha)}'),
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
      await _api.eliminarPeso(r.id);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi peso')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add),
        label: const Text('Registrar peso'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    if (_registros.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no registras tu peso.\nToca "Registrar peso" para empezar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final tema = Theme.of(context);
    final ultimo = _registros.last;
    final diferencia = ultimo.pesoKg - _registros.first.pesoKg;
    final signo = diferencia > 0 ? '+' : '';

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ---- Resumen ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Peso actual', style: tema.textTheme.labelLarge),
                        Text('${formatearKg(ultimo.pesoKg)} kg',
                            style: tema.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (_registros.length > 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Desde el inicio', style: tema.textTheme.labelLarge),
                        Text('$signo${formatearKg(diferencia)} kg',
                            style: tema.textTheme.titleLarge),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Gráfico ----
          if (_registros.length >= 2) ...[
            SizedBox(height: 220, child: _GraficoPeso(registros: _registros)),
            const SizedBox(height: 16),
          ],

          // ---- Historial (más reciente primero) ----
          Text('Historial', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in _registros.reversed)
            Card(
              child: ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text('${formatearKg(r.pesoKg)} kg'),
                subtitle: Text(
                  r.nota == null
                      ? formatearFecha(r.fecha)
                      : '${formatearFecha(r.fecha)} · ${r.nota}',
                ),
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

class _GraficoPeso extends StatelessWidget {
  final List<RegistroPeso> registros;

  const _GraficoPeso({required this.registros});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final pesos = registros.map((r) => r.pesoKg);
    final minimo = pesos.reduce((a, b) => a < b ? a : b);
    final maximo = pesos.reduce((a, b) => a > b ? a : b);

    final puntos = [
      for (var i = 0; i < registros.length; i++)
        FlSpot(i.toDouble(), registros[i].pesoKg),
    ];

    const sinTitulos = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 24, 16),
        child: LineChart(
          LineChartData(
            minY: (minimo - 2).floorToDouble(),
            maxY: (maximo + 2).ceilToDouble(),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: sinTitulos,
              rightTitles: sinTitulos,
              bottomTitles: sinTitulos,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: puntos,
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
//  Diálogo para registrar un peso nuevo
// ----------------------------------------------------------------------
class _NuevoPeso {
  final double pesoKg;
  final DateTime fecha;
  final String nota;

  _NuevoPeso(this.pesoKg, this.fecha, this.nota);
}

class _NuevoPesoDialog extends StatefulWidget {
  const _NuevoPesoDialog();

  @override
  State<_NuevoPesoDialog> createState() => _NuevoPesoDialogState();
}

class _NuevoPesoDialogState extends State<_NuevoPesoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _NuevoPeso(leerNumero(_pesoCtrl.text)!, _fecha, _notaCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar peso'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _pesoCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso',
                suffixText: 'kg',
              ),
              validator: (v) {
                final n = leerNumero(v ?? '');
                if (n == null || n < 20 || n > 400) return 'Peso entre 20 y 400 kg';
                return null;
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(formatearFecha(_fecha)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              maxLength: 100,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
