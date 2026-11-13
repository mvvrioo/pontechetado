import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';

/// El usuario elige su objetivo (fuerza, hipertrofia, híbrido o salud) y los
/// días que va a entrenar, y el sistema le arma una rutina para cada día.
/// Devuelve `true` al cerrar si se crearon rutinas (para recargar la lista).
class RutinaPersonalizadaScreen extends StatefulWidget {
  const RutinaPersonalizadaScreen({super.key});

  @override
  State<RutinaPersonalizadaScreen> createState() => _RutinaPersonalizadaScreenState();
}

class _RutinaPersonalizadaScreenState extends State<RutinaPersonalizadaScreen> {
  final _api = ApiService.instance;
  OpcionesRutinaPersonalizada? _opciones;
  String? _objetivo;
  final Set<int> _dias = {};
  bool _cargando = true;
  bool _generando = false;
  Object? _error;

  static const _iconos = {
    'fuerza': Icons.fitness_center,
    'hipertrofia': Icons.accessibility_new,
    'hibrido': Icons.bolt,
    'salud': Icons.favorite_border,
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final opciones = await _api.opcionesRutinaPersonalizada();
      if (!mounted) return;
      setState(() {
        _opciones = opciones;
        // Si ya había elegido antes, partimos desde ahí
        _objetivo = opciones.objetivoActual;
        _dias
          ..clear()
          ..addAll(opciones.diasActuales);
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

  ObjetivoEntrenamiento? get _objetivoElegido {
    for (final o in _opciones?.objetivos ?? <ObjetivoEntrenamiento>[]) {
      if (o.codigo == _objetivo) return o;
    }
    return null;
  }

  bool get _listo {
    final o = _opciones;
    return o != null &&
        _objetivo != null &&
        _dias.length >= o.diasMin &&
        _dias.length <= o.diasMax;
  }

  void _alternarDia(int dia) {
    final max = _opciones!.diasMax;
    if (!_dias.contains(dia) && _dias.length >= max) {
      mostrarMensaje(context, 'Puedes elegir hasta $max días: deja al menos uno de descanso');
      return;
    }
    setState(() {
      if (!_dias.remove(dia)) _dias.add(dia);
    });
  }

  Future<void> _generar() async {
    final opciones = _opciones!;
    if (!opciones.esPremium) {
      mostrarDialogoPremium(context, 'Las rutinas personalizadas son una función Premium.');
      return;
    }
    if (!_listo) return;

    // Si ya tenía una, avisar que se reemplaza
    if (opciones.objetivoActual != null) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Actualizar tu rutina?'),
          content: const Text(
            'Tus rutinas personalizadas anteriores se reemplazarán por las nuevas. '
            'Las rutinas que creaste tú no se tocan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
      if (seguir != true) return;
    }

    setState(() => _generando = true);
    try {
      final dias = _dias.toList()..sort();
      final mensaje = await _api.generarRutinaPersonalizada(_objetivo!, dias);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutina personalizada')),
      body: _construirCuerpo(),
      bottomNavigationBar: _opciones == null ? null : _botonInferior(),
    );
  }

  Widget _botonInferior() {
    final opciones = _opciones!;
    final texto = !opciones.esPremium
        ? 'Función Premium'
        : _generando
            ? 'Creando tu rutina...'
            : opciones.objetivoActual == null
                ? 'Crear mi rutina'
                : 'Actualizar mi rutina';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: (_generando || (!_listo && opciones.esPremium)) ? null : _generar,
          icon: Icon(opciones.esPremium ? Icons.auto_awesome : Icons.lock),
          label: Text(texto),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    final opciones = _opciones!;
    final objetivo = _objetivoElegido;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (!opciones.esPremium)
          Card(
            color: Colores.premium.withValues(alpha: 0.12),
            child: const ListTile(
              leading: Icon(Icons.workspace_premium, color: Colores.premium),
              title: Text(
                'Función Premium',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Puedes ver cómo funciona, pero para crear tu rutina necesitas Premium. '
                'Se activa en tu gimnasio (pestaña "Gimnasios").',
              ),
            ),
          ),

        // ---- 1. Objetivo ----
        const _Paso(numero: 1, titulo: '¿Cuál es tu objetivo?'),
        for (final o in opciones.objetivos)
          _TarjetaObjetivo(
            objetivo: o,
            icono: _iconos[o.codigo] ?? Icons.fitness_center,
            elegido: o.codigo == _objetivo,
            alTocar: () => setState(() => _objetivo = o.codigo),
          ),

        // ---- 2. Días ----
        const SizedBox(height: 8),
        const _Paso(numero: 2, titulo: '¿Qué días vas a entrenar?'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      _BotonDia(
                        letra: letrasDias[d],
                        elegido: _dias.contains(d),
                        alTocar: () => _alternarDia(d),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _dias.isEmpty
                      ? 'Elige entre ${opciones.diasMin} y ${opciones.diasMax} días'
                      : '${_dias.length} día${_dias.length == 1 ? '' : 's'} por semana'
                          '${_dias.length < opciones.diasMin ? ' · elige al menos ${opciones.diasMin}' : ''}',
                  style: const TextStyle(color: Colores.textoSuave),
                ),
              ],
            ),
          ),
        ),

        // ---- 3. Vista previa ----
        if (objetivo != null && _listo) ...[
          const SizedBox(height: 8),
          const _Paso(numero: 3, titulo: 'Así queda tu semana'),
          _VistaPrevia(objetivo: objetivo, dias: _dias.toList()..sort()),
        ],
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final int numero;
  final String titulo;

  const _Paso({required this.numero, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Colores.marca,
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Colores.sobreMarca,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TarjetaObjetivo extends StatelessWidget {
  final ObjetivoEntrenamiento objetivo;
  final IconData icono;
  final bool elegido;
  final VoidCallback alTocar;

  const _TarjetaObjetivo({
    required this.objetivo,
    required this.icono,
    required this.elegido,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: elegido ? Colores.marca : Colores.borde,
          width: elegido ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: elegido ? Colores.marca : Colores.superficieAlta,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: elegido ? Colores.sobreMarca : Colores.marca),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objetivo.nombre,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      objetivo.descripcion,
                      style: const TextStyle(color: Colores.textoSuave, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                elegido ? Icons.check_circle : Icons.radio_button_unchecked,
                color: elegido ? Colores.marca : Colores.textoSuave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonDia extends StatelessWidget {
  final String letra;
  final bool elegido;
  final VoidCallback alTocar;

  const _BotonDia({required this.letra, required this.elegido, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: alTocar,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: elegido ? Colores.marca : Colors.transparent,
          border: Border.all(color: elegido ? Colores.marca : Colores.borde, width: 2),
        ),
        child: Text(
          letra,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: elegido ? Colores.sobreMarca : Colores.texto,
          ),
        ),
      ),
    );
  }
}

/// "Lunes → Empuje, Miércoles → Tirón..." antes de crear la rutina.
class _VistaPrevia extends StatelessWidget {
  final ObjetivoEntrenamiento objetivo;
  final List<int> dias;

  const _VistaPrevia({required this.objetivo, required this.dias});

  @override
  Widget build(BuildContext context) {
    final sesiones = objetivo.divisiones[dias.length] ?? const <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < dias.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        nombresDias[dias[i]],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colores.marca,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(i < sesiones.length ? sesiones[i] : 'Entrenamiento'),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colores.textoSuave),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    objetivo.indicaciones,
                    style: const TextStyle(color: Colores.textoSuave, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Los días que no elijas quedan de descanso. Tus rutinas creadas a mano no se tocan.',
              style: TextStyle(color: Colores.textoSuave, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
