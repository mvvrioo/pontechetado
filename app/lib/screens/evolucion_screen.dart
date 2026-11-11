import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';

/// Evolución de los pesos por ejercicio: el usuario elige un ejercicio que
/// ya entrenó y ve en un gráfico el mayor peso levantado cada día.
class EvolucionScreen extends StatefulWidget {
  const EvolucionScreen({super.key});

  @override
  State<EvolucionScreen> createState() => _EvolucionScreenState();
}

class _EvolucionScreenState extends State<EvolucionScreen> {
  final _api = ApiService.instance;
  EvolucionEjercicio? _datos;
  int? _ejercicioId;
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
      _cargando = _datos == null;
      _error = null;
    });
    try {
      var datos = await _api.evolucionEjercicio(ejercicioId: _ejercicioId);
      // La primera vez se muestra el ejercicio entrenado más recientemente
      if (_ejercicioId == null && datos.ejercicios.isNotEmpty) {
        _ejercicioId = datos.ejercicios.first.id;
        datos = await _api.evolucionEjercicio(ejercicioId: _ejercicioId);
      }
      if (!mounted) return;
      setState(() {
        _datos = datos;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolución')),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null && _datos == null) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final d = _datos!;
    if (d.ejercicios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Todavía no registras entrenamientos.\n'
            'Cuando registres series en "Entrenar", aquí verás cómo suben tus pesos.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final puntos = d.puntos;
    final diferencia = d.diferencia;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _ejercicioId,
            isExpanded: true,
            menuMaxHeight: 420,
            decoration: const InputDecoration(labelText: 'Ejercicio'),
            items: [
              for (final e in d.ejercicios)
                DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.nombre} · ${e.dias} día${e.dias == 1 ? '' : 's'}'),
                ),
            ],
            onChanged: (v) {
              if (v == null || v == _ejercicioId) return;
              setState(() => _ejercicioId = v);
              _cargar();
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Dato(
                valor: d.mejorPeso == null ? '—' : '${formatearKg(d.mejorPeso!)} kg',
                etiqueta: 'mejor peso',
              ),
              const SizedBox(width: 10),
              _Dato(
                valor: d.mejorMarca == null ? '—' : '${formatearKg(d.mejorMarca!)} kg',
                etiqueta: '1RM estimado',
              ),
              const SizedBox(width: 10),
              _Dato(
                valor: puntos.length < 2
                    ? '—'
                    : '${diferencia > 0 ? '+' : ''}${formatearKg(diferencia)} kg',
                etiqueta: 'desde el inicio',
                color: diferencia > 0
                    ? Colores.marca
                    : diferencia < 0
                        ? Colores.peligro
                        : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (puntos.length >= 2)
            SizedBox(height: 240, child: _GraficoEvolucion(puntos: puntos))
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Entrena este ejercicio al menos dos días para ver el gráfico.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 10),
            child: Text(
              'Historial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final p in puntos.reversed)
            Card(
              child: ListTile(
                title: Text(
                  '${formatearKg(p.pesoMax)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${formatearFecha(p.fecha)} · ${p.series} serie${p.series == 1 ? '' : 's'} · '
                  '${formatearMiles(p.volumen)} kg de volumen',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color? color;

  const _Dato({required this.valor, required this.etiqueta, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colores.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colores.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            Text(etiqueta, style: const TextStyle(color: Colores.textoSuave, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Línea con el mayor peso levantado cada día que se entrenó el ejercicio.
class _GraficoEvolucion extends StatelessWidget {
  final List<PuntoEvolucion> puntos;

  const _GraficoEvolucion({required this.puntos});

  @override
  Widget build(BuildContext context) {
    final pesos = puntos.map((p) => p.pesoMax);
    final minimo = pesos.reduce((a, b) => a < b ? a : b);
    final maximo = pesos.reduce((a, b) => a > b ? a : b);
    final margen = ((maximo - minimo) * 0.2).clamp(2.5, 50.0).toDouble();
    final piso = (minimo - margen).floorToDouble();

    const sinTitulos = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 24, 12),
        child: LineChart(
          LineChartData(
            minY: piso < 0 ? 0 : piso,
            maxY: (maximo + margen).ceilToDouble(),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(drawVerticalLine: false),
            titlesData: FlTitlesData(
              topTitles: sinTitulos,
              rightTitles: sinTitulos,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (valor, meta) {
                    final i = valor.round();
                    // Solo el primer y el último día, para no amontonar fechas
                    if (valor != i.toDouble() || (i != 0 && i != puntos.length - 1)) {
                      return const SizedBox();
                    }
                    final f = puntos[i].fecha;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${f.day}/${f.month}',
                        style: const TextStyle(fontSize: 11, color: Colores.textoSuave),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < puntos.length; i++)
                    FlSpot(i.toDouble(), puntos[i].pesoMax),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: Colores.marca,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colores.marca.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
