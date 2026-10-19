import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import 'rutina_detalle_screen.dart';

/// Rutinas organizadas por día de la semana (lunes: pecho y espalda, etc.).
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
      _cargando = _rutinas.isEmpty;
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

  Future<void> _crear({int? diaInicial}) async {
    final nueva = await showDialog<_NuevaRutina>(
      context: context,
      builder: (_) => _NuevaRutinaDialog(diaInicial: diaInicial),
    );
    if (nueva == null) return;

    try {
      await _api.crearRutina(
        nueva.nombre,
        nueva.descripcion,
        diaSemana: nueva.diaSemana,
      );
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

  Future<void> _cambiarDia(Rutina r) async {
    final dia = await elegirDiaSemana(context, actual: r.diaSemana);
    if (dia == null) return; // canceló
    try {
      final mensaje = await _api.asignarDiaRutina(r.id, dia == 0 ? null : dia);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      _cargar();
    } catch (e) {
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
    _cargar(); // al volver, actualizar el contador de ejercicios y el día
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi semana')),
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
    if (_error != null && _rutinas.isEmpty) {
      return VistaError(error: _error!, alReintentar: _cargar);
    }

    final hoy = DateTime.now().weekday; // 1 = lunes ... 7 = domingo
    final sinDia = _rutinas.where((r) => r.diaSemana == null).toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          if (_limite != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                avatar: const Icon(Icons.info_outline, size: 18),
                label: Text('Plan gratis: ${_rutinas.length} de $_limite rutinas'),
              ),
            ),
          // Lunes a domingo, siempre visibles para armar la semana
          for (var dia = 1; dia <= 7; dia++)
            _SeccionDia(
              dia: dia,
              esHoy: dia == hoy,
              rutinas: _rutinas.where((r) => r.diaSemana == dia).toList(),
              alAgregar: () => _crear(diaInicial: dia),
              construirRutina: _tarjetaRutina,
            ),
          if (sinDia.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                'Sin día asignado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colores.textoSuave,
                ),
              ),
            ),
            for (final r in sinDia) _tarjetaRutina(r),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaRutina(Rutina r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            if (r.descripcion != null && r.descripcion!.isNotEmpty) r.descripcion!,
            '${r.totalEjercicios} ejercicio${r.totalEjercicios == 1 ? '' : 's'}',
          ].join(' · '),
        ),
        onTap: () => _abrir(r),
        trailing: PopupMenuButton<String>(
          onSelected: (accion) {
            if (accion == 'dia') _cambiarDia(r);
            if (accion == 'eliminar') _eliminar(r);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'dia', child: Text('Cambiar día')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}

class _SeccionDia extends StatelessWidget {
  final int dia;
  final bool esHoy;
  final List<Rutina> rutinas;
  final VoidCallback alAgregar;
  final Widget Function(Rutina) construirRutina;

  const _SeccionDia({
    required this.dia,
    required this.esHoy,
    required this.rutinas,
    required this.alAgregar,
    required this.construirRutina,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda con la letra del día
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12, top: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: esHoy ? Colores.marca : Colores.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: esHoy ? Colores.marca : Colores.borde),
            ),
            child: Text(
              letrasDias[dia],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: esHoy ? Colors.black : Colores.texto,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Text(
                    esHoy ? '${nombresDias[dia]} · HOY' : nombresDias[dia],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: esHoy ? Colores.marca : Colores.texto,
                    ),
                  ),
                ),
                if (rutinas.isEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: alAgregar,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colores.borde),
                      ),
                      child: const Text(
                        'Descanso · toca para agregar rutina',
                        style: TextStyle(color: Colores.textoSuave),
                      ),
                    ),
                  ),
                for (final r in rutinas) construirRutina(r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para elegir día. Devuelve 1..7, 0 = "sin día", null = canceló.
Future<int?> elegirDiaSemana(BuildContext context, {int? actual}) {
  return showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('¿Qué día toca esta rutina?'),
      children: [
        for (var d = 1; d <= 7; d++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, d),
            child: Row(
              children: [
                Icon(
                  actual == d ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: actual == d ? Colores.marca : Colores.textoSuave,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(nombresDias[d]),
              ],
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 0),
          child: Row(
            children: [
              Icon(
                actual == null ? Icons.radio_button_checked : Icons.radio_button_off,
                color: actual == null ? Colores.marca : Colores.textoSuave,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Sin día'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NuevaRutina {
  final String nombre;
  final String descripcion;
  final int? diaSemana;

  _NuevaRutina(this.nombre, this.descripcion, this.diaSemana);
}

class _NuevaRutinaDialog extends StatefulWidget {
  final int? diaInicial;

  const _NuevaRutinaDialog({this.diaInicial});

  @override
  State<_NuevaRutinaDialog> createState() => _NuevaRutinaDialogState();
}

class _NuevaRutinaDialogState extends State<_NuevaRutinaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _dia;

  @override
  void initState() {
    super.initState();
    _dia = widget.diaInicial;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _NuevaRutina(_nombreCtrl.text.trim(), _descCtrl.text.trim(), _dia),
    );
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
                hintText: 'Ej: Pecho y espalda',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _dia,
              decoration: const InputDecoration(labelText: 'Día de la semana'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Sin día')),
                for (var d = 1; d <= 7; d++)
                  DropdownMenuItem<int?>(value: d, child: Text(nombresDias[d])),
              ],
              onChanged: (v) => setState(() => _dia = v),
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
