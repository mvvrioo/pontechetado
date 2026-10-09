import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';

class EntrenarScreen extends StatefulWidget {
  const EntrenarScreen({super.key});

  @override
  State<EntrenarScreen> createState() => _EntrenarScreenState();
}

class _EntrenarScreenState extends State<EntrenarScreen> {
  final _api = ApiService.instance;
  DateTime _fecha = DateTime.now();
  EntrenoDelDia? _entreno;
  List<VolumenDia> _volumenUltimos14 = [];
  List<Ejercicio> _ejercicios = [];
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        _api.entrenoDelDia(_fecha),
        _api.resumenVolumen(14),
        _api.listarEjercicios(),
      ]);

      if (!mounted) return;
      setState(() {
        _entreno = resultados[0] as EntrenoDelDia;
        _volumenUltimos14 = resultados[1] as List<VolumenDia>;
        _ejercicios = resultados[2] as List<Ejercicio>;
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

  DateTime get _hoy =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: _hoy,
    );
    if (elegida == null) return;
    if (elegida.isAfter(_hoy)) return;
    setState(() => _fecha = elegida);
    await _cargarTodo();
  }

  Future<void> _fechaAnterior() async {
    final nueva = _fecha.subtract(const Duration(days: 1));
    if (nueva.isAfter(_hoy)) return;
    setState(() => _fecha = nueva);
    await _cargarTodo();
  }

  Future<void> _fechaSiguiente() async {
    final nueva = _fecha.add(const Duration(days: 1));
    if (nueva.isAfter(_hoy)) return;
    setState(() => _fecha = nueva);
    await _cargarTodo();
  }

  int get _totalSeries => (_entreno?.ejercicios ?? []).fold<int>(
    0,
    (total, ejercicio) => total + ejercicio.series.length,
  );

  Future<void> _abrirAgregarEjercicio() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        String filtro = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtrados = _ejercicios.where((e) {
              final texto = filtro.trim().toLowerCase();
              if (texto.isEmpty) return true;
              return e.nombre.toLowerCase().contains(texto);
            }).toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Agregar ejercicio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Buscar ejercicio',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valor) => setModalState(() => filtro = valor),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final ejercicio in filtrados)
                            ListTile(
                              leading: ejercicio.bloqueado
                                  ? const Icon(
                                      Icons.lock_outline,
                                      color: Colors.orange,
                                    )
                                  : const Icon(Icons.fitness_center_outlined),
                              title: Text(ejercicio.nombre),
                              subtitle: Text(ejercicio.grupoMuscular),
                              trailing: ejercicio.personalizado
                                  ? const Icon(Icons.person_outline, size: 18)
                                  : null,
                              onTap: () {
                                if (ejercicio.bloqueado) {
                                  Navigator.pop(context);
                                  mostrarError(
                                    context,
                                    ApiException(
                                      'Este ejercicio requiere Premium',
                                      requierePremium: true,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _abrirDialogoSerie(
                                  ejercicio: ejercicio,
                                  pesoInicial: _ultimoPesoPara(ejercicio.id),
                                  repeticionesInicial: _ultimasRepeticionesPara(
                                    ejercicio.id,
                                  ),
                                );
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline),
                            title: const Text('Crear ejercicio personalizado'),
                            onTap: () {
                              Navigator.pop(context);
                              _crearEjercicioPersonalizado();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _crearEjercicioPersonalizado() async {
    final resultado = await showDialog<_EjercicioNuevo>(
      context: context,
      builder: (_) => const _DialogoCrearEjercicio(),
    );
    if (resultado == null) return;

    try {
      final creado = await _api.crearEjercicio(
        resultado.nombre,
        resultado.grupoMuscular,
      );
      if (!mounted) return;
      await _cargarTodo();
      if (!mounted) return;
      _abrirDialogoSerie(
        ejercicio: creado,
        pesoInicial: 0,
        repeticionesInicial: 10,
      );
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  double _ultimoPesoPara(int ejercicioId) {
    final grupo = _entreno?.ejercicios.firstWhere(
      (e) => e.ejercicioId == ejercicioId,
      orElse: () => EjercicioDelDia(
        ejercicioId: ejercicioId,
        nombre: '',
        volumen: 0,
        series: const [],
      ),
    );
    if (grupo == null || grupo.series.isEmpty) return 0;
    return grupo.series.last.pesoKg;
  }

  int _ultimasRepeticionesPara(int ejercicioId) {
    final grupo = _entreno?.ejercicios.firstWhere(
      (e) => e.ejercicioId == ejercicioId,
      orElse: () => EjercicioDelDia(
        ejercicioId: ejercicioId,
        nombre: '',
        volumen: 0,
        series: const [],
      ),
    );
    if (grupo == null || grupo.series.isEmpty) return 10;
    return grupo.series.last.repeticiones;
  }

  Future<void> _abrirDialogoSerie({
    required Ejercicio ejercicio,
    required double pesoInicial,
    required int repeticionesInicial,
  }) async {
    final resultado = await showDialog<_NuevaSerie>(
      context: context,
      builder: (context) => _DialogoNuevaSerie(
        ejercicioNombre: ejercicio.nombre,
        pesoInicial: pesoInicial,
        repeticionesInicial: repeticionesInicial,
      ),
    );
    if (resultado == null) return;

    try {
      await _api.registrarSerie(
        ejercicioId: ejercicio.id,
        fecha: _fecha,
        pesoKg: resultado.pesoKg,
        repeticiones: resultado.repeticiones,
      );
      if (!mounted) return;
      mostrarMensaje(context, 'Serie registrada ✅');
      await _cargarTodo();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  Future<void> _eliminarSerie(SerieEntreno serie) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar serie'),
        content: Text(
          '¿Quieres eliminar la serie ${serie.numeroSerie} de ${formatearKg(serie.pesoKg)} kg × ${serie.repeticiones}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _api.eliminarSerie(serie.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Serie eliminada');
      await _cargarTodo();
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entrenar')),
        body: VistaError(error: _error!, alReintentar: _cargarTodo),
      );
    }

    final totalVolumen = _entreno?.volumenTotal ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAgregarEjercicio,
        icon: const Icon(Icons.add),
        label: const Text('Agregar ejercicio'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _selectorFecha(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Volumen total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${formatearKg(totalVolumen)} kg',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Series',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_totalSeries',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_volumenUltimos14.isNotEmpty) ...[
              Text(
                'Últimos 14 días',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: _GraficoVolumen(volumen: _volumenUltimos14),
              ),
              const SizedBox(height: 16),
            ],
            if ((_entreno?.ejercicios ?? []).isEmpty) ...[
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Todavía no hay series registradas para este día.',
                    ),
                  ),
                ),
              ),
            ] else ...[
              for (final ejercicio in _entreno!.ejercicios)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ejercicio.nombre,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${formatearKg(ejercicio.volumen)} kg',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final serie in ejercicio.series)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Serie ${serie.numeroSerie} · ${formatearKg(serie.pesoKg)} kg × ${serie.repeticiones} = ${formatearKg(serie.volumen)} kg',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar serie',
                                  onPressed: () => _eliminarSerie(serie),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _abrirDialogoSerie(
                              ejercicio: _ejercicios.firstWhere(
                                (e) => e.id == ejercicio.ejercicioId,
                                orElse: () => Ejercicio(
                                  id: ejercicio.ejercicioId,
                                  nombre: ejercicio.nombre,
                                  grupoMuscular: 'General',
                                  esPremium: false,
                                  personalizado: false,
                                  bloqueado: false,
                                ),
                              ),
                              pesoInicial: ejercicio.series.isNotEmpty
                                  ? ejercicio.series.last.pesoKg
                                  : 0,
                              repeticionesInicial: ejercicio.series.isNotEmpty
                                  ? ejercicio.series.last.repeticiones
                                  : 10,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('+ Serie'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selectorFecha() {
    final hoy = _hoy;
    final esHoy =
        _fecha.year == hoy.year &&
        _fecha.month == hoy.month &&
        _fecha.day == hoy.day;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: _fechaAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatearFecha(_fecha)),
              ),
            ),
            IconButton(
              onPressed: esHoy ? null : _fechaSiguiente,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficoVolumen extends StatelessWidget {
  final List<VolumenDia> volumen;

  const _GraficoVolumen({required this.volumen});

  @override
  Widget build(BuildContext context) {
    final maxY =
        (volumen.map((e) => e.volumen).reduce((a, b) => a > b ? a : b) * 1.2)
            .ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
        child: BarChart(
          BarChartData(
            maxY: maxY == 0 ? 10 : maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= volumen.length)
                      return const SizedBox();
                    final dia = volumen[value.toInt()].fecha;
                    return Text('${dia.day}');
                  },
                ),
              ),
            ),
            barGroups: List.generate(volumen.length, (index) {
              final item = volumen[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.volumen,
                    width: 16,
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _EjercicioNuevo {
  final String nombre;
  final String grupoMuscular;

  _EjercicioNuevo(this.nombre, this.grupoMuscular);
}

class _NuevaSerie {
  final double pesoKg;
  final int repeticiones;

  _NuevaSerie(this.pesoKg, this.repeticiones);
}

class _DialogoCrearEjercicio extends StatefulWidget {
  const _DialogoCrearEjercicio();

  @override
  State<_DialogoCrearEjercicio> createState() => _DialogoCrearEjercicioState();
}

class _DialogoCrearEjercicioState extends State<_DialogoCrearEjercicio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _grupoCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _grupoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EjercicioNuevo(_nombreCtrl.text.trim(), _grupoCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo ejercicio'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Ingresa un nombre';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grupoCtrl,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Ingresa el grupo muscular';
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
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

class _DialogoNuevaSerie extends StatefulWidget {
  final String ejercicioNombre;
  final double pesoInicial;
  final int repeticionesInicial;

  const _DialogoNuevaSerie({
    required this.ejercicioNombre,
    required this.pesoInicial,
    required this.repeticionesInicial,
  });

  @override
  State<_DialogoNuevaSerie> createState() => _DialogoNuevaSerieState();
}

class _DialogoNuevaSerieState extends State<_DialogoNuevaSerie> {
  final _formKey = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pesoCtrl.text = widget.pesoInicial == 0
        ? ''
        : widget.pesoInicial.toStringAsFixed(
            widget.pesoInicial % 1 == 0 ? 0 : 2,
          );
    _repsCtrl.text = widget.repeticionesInicial.toString();
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final peso = leerNumero(_pesoCtrl.text);
    final repeticiones = int.tryParse(_repsCtrl.text.trim());
    if (peso == null || repeticiones == null) return;
    Navigator.pop(context, _NuevaSerie(peso, repeticiones));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar serie · ${widget.ejercicioNombre}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _pesoCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso',
                suffixText: 'kg',
              ),
              validator: (v) {
                final value = leerNumero(v ?? '');
                if (value == null || value < 0 || value > 1000) {
                  return 'Peso entre 0 y 1000 kg';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Repeticiones'),
              validator: (v) {
                final repeticiones = int.tryParse(v ?? '');
                if (repeticiones == null ||
                    repeticiones < 1 ||
                    repeticiones > 300) {
                  return 'Entre 1 y 300';
                }
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
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
