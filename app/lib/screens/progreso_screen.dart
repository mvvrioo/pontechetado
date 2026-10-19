import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';
import '../widgets/nivel.dart';

/// Gamificación: nivel, XP, semana actual e historial de días entrenados.
class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  final _api = ApiService.instance;
  Progreso? _progreso;
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
      final progreso = await _api.progreso();
      if (!mounted) return;
      setState(() {
        _progreso = progreso;
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
      appBar: AppBar(title: const Text('Progreso')),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return VistaError(error: _error!, alReintentar: _cargar);

    final p = _progreso!;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: p.bloqueado
            ? [_TarjetaBloqueada(progreso: p), _ComoGanarXp(progreso: p)]
            : [
                _TarjetaNivel(nivel: p.nivel),
                _FilaEstadisticas(progreso: p),
                _TarjetaSemana(progreso: p),
                const SizedBox(height: 8),
                const _Titulo('Historial de entrenos'),
                if (p.historial.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no registras entrenos.\n'
                        'Ve a "Entrenar", agrega tus series y empieza a sumar XP 💪',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                for (final dia in p.historial) _TarjetaDiaEntrenado(dia: dia),
                const SizedBox(height: 8),
                _ComoGanarXp(progreso: p),
              ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TarjetaNivel extends StatelessWidget {
  final InfoNivel nivel;

  const _TarjetaNivel({required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26330F), Colores.superficie],
        ),
        border: Border.all(color: Colores.marca.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InsigniaNivel(nivel: nivel),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nivel.titulo.toUpperCase(),
                      style: const TextStyle(
                        color: Colores.marca,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatearMiles(nivel.xpTotal)} XP',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'acumulados en total',
                      style: TextStyle(color: Colores.textoSuave),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          BarraXp(nivel: nivel),
        ],
      ),
    );
  }
}

class _FilaEstadisticas extends StatelessWidget {
  final Progreso progreso;

  const _FilaEstadisticas({required this.progreso});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Dato(
            valor: '${progreso.diasEntrenados}',
            etiqueta: 'días\nentrenados',
          ),
          const SizedBox(width: 10),
          _Dato(
            valor: '${progreso.entrenosSemana}/7',
            etiqueta: 'entrenos\nesta semana',
          ),
          const SizedBox(width: 10),
          _Dato(
            valor: '+${progreso.xpSemana}',
            etiqueta: 'XP\nesta semana',
            resaltado: true,
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final bool resaltado;

  const _Dato({
    required this.valor,
    required this.etiqueta,
    this.resaltado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: resaltado ? Colores.marca : Colores.texto,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lunes a domingo: qué días entrenó, cuánta XP ganó y qué rutina toca.
class _TarjetaSemana extends StatelessWidget {
  final Progreso progreso;

  const _TarjetaSemana({required this.progreso});

  @override
  Widget build(BuildContext context) {
    final hoy = progreso.hoy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu semana',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in progreso.semana) _CirculoDia(dia: d),
              ],
            ),
            if (hoy != null) ...[
              const Divider(height: 28),
              Row(
                children: [
                  const Icon(Icons.today, color: Colores.marca, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hoy ${hoy.nombre.toLowerCase()}: ',
                            style: const TextStyle(color: Colores.textoSuave),
                          ),
                          TextSpan(
                            text: hoy.rutina ?? 'sin rutina asignada',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CirculoDia extends StatelessWidget {
  final DiaSemana dia;

  const _CirculoDia({required this.dia});

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color borde;
    final Widget contenido;

    if (dia.entreno) {
      fondo = Colores.marca;
      borde = Colores.marca;
      contenido = const Icon(Icons.check, color: Colors.black, size: 20);
    } else {
      fondo = Colors.transparent;
      borde = dia.esHoy ? Colores.marca : Colores.borde;
      contenido = Text(
        letrasDias[dia.diaSemana],
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: dia.esHoy ? Colores.marca : Colores.textoSuave,
        ),
      );
    }

    return Tooltip(
      message: [
        dia.nombre,
        if (dia.rutina != null) dia.rutina!,
        if (dia.entreno) '+${dia.xp} XP',
      ].join(' · '),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fondo,
              shape: BoxShape.circle,
              border: Border.all(color: borde, width: 2),
            ),
            child: contenido,
          ),
          const SizedBox(height: 6),
          Text(
            dia.entreno ? '+${dia.xp}' : (dia.rutina != null ? '•' : ' '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dia.entreno ? Colores.marca : Colores.textoSuave,
            ),
          ),
        ],
      ),
    );
  }
}

/// "DÍA 12 · Lunes 19/10 · Pecho y espalda · 4.800 kg · +46 XP"
class _TarjetaDiaEntrenado extends StatelessWidget {
  final DiaEntrenado dia;

  const _TarjetaDiaEntrenado({required this.dia});

  @override
  Widget build(BuildContext context) {
    final titulo = dia.rutina ??
        (dia.grupos.isEmpty ? 'Entrenamiento' : dia.grupos.join(' y '));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colores.superficieAlta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'DÍA',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: Colores.textoSuave,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${dia.diaNumero}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dia.nombreDia} ${dia.fecha.day.toString().padLeft(2, '0')}/${dia.fecha.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colores.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${dia.series} series',
                      '${formatearMiles(dia.volumen)} kg',
                      if (dia.rutina != null && dia.grupos.isNotEmpty)
                        dia.grupos.join(' · '),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colores.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ChipXp(dia.xp),
          ],
        ),
      ),
    );
  }
}

/// Plan gratis: se muestra la XP acumulada como gancho para hacerse Premium.
class _TarjetaBloqueada extends StatelessWidget {
  final Progreso progreso;

  const _TarjetaBloqueada({required this.progreso});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.25,
                  child: InsigniaNivel(nivel: progreso.nivel, tamano: 120),
                ),
                const Icon(Icons.lock, size: 44, color: Colores.premium),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Llevas ${formatearMiles(progreso.nivel.xpTotal)} XP guardados',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Niveles, tu semana de entrenamiento y el historial de días '
              'son parte de Premium. Tu XP se sigue sumando igual: al activar '
              'Premium la desbloqueas toda de una.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colores.textoSuave),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colores.premium.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colores.premium),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paga tu membresía en un gimnasio asociado (pestaña '
                      '"Gimnasios") y pide que te activen Premium con tu correo.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComoGanarXp extends StatelessWidget {
  final Progreso progreso;

  const _ComoGanarXp({required this.progreso});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.bolt, color: Colores.marca),
          title: const Text(
            '¿Cómo gano XP?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${progreso.xpPorSerie} XP por cada serie registrada.'),
            Text(
              '• 1 XP extra por cada ${progreso.kgPorXp} kg de volumen '
              '(peso × repeticiones).',
            ),
            const Text('• Ejemplo: 15 series y 4.000 kg en el día = 46 XP.'),
            const SizedBox(height: 8),
            const Text(
              'Cada nivel pide un poco más que el anterior: el nivel 2 son '
              '100 XP, el 3 son 150 más, el 4 son 200 más...',
              style: TextStyle(color: Colores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
