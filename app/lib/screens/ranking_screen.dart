import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../tema.dart';
import '../utils.dart';

/// Top 10 de los más fuertes del gimnasio.
/// El puntaje es la suma de la mejor marca en press banca, sentadilla y peso muerto.
/// Entrenadores y admins lo ven sin posición propia; el superadmin pasa [gimnasioId].
class RankingScreen extends StatefulWidget {
  final int? gimnasioId;

  const RankingScreen({super.key, this.gimnasioId});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _api = ApiService.instance;
  RankingGimnasio? _ranking;
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
      _cargando = _ranking == null;
      _error = null;
    });
    try {
      final ranking = await _api.rankingGimnasio(gimnasioId: widget.gimnasioId);
      if (!mounted) return;
      setState(() {
        _ranking = ranking;
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
      appBar: AppBar(
        title: Text(_ranking == null ? 'Ranking' : 'Top 10 ${_ranking!.gimnasio}'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null && _ranking == null) {
      // Sin gimnasio (409) o sin Premium (403): se explica cómo desbloquearlo
      if (error is ApiException && (error.codigo == 409 || error.codigo == 403)) {
        return _RankingBloqueado(mensaje: error.mensaje);
      }
      return VistaError(error: error, alReintentar: _cargar);
    }

    final r = _ranking!;
    final yo = r.yo;
    final estoyEnTop = r.top.any((f) => f.esYo);

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (yo != null) _TarjetaMiPuesto(yo: yo, participantes: r.participantes),
          if (r.top.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía nadie tiene marcas en este gimnasio.\n'
                  'Registra press banca, sentadilla o peso muerto y sé el primero.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          for (final fila in r.top) _FilaTop(fila: fila),
          if (yo != null && yo.posicion != null && !estoyEnTop) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Icon(Icons.more_vert, color: Colores.textoSuave),
              ),
            ),
            _FilaTop(
              fila: FilaRanking(
                posicion: yo.posicion!,
                nombre: 'Tú',
                puntaje: yo.puntaje,
                banca: yo.banca,
                sentadilla: yo.sentadilla,
                pesoMuerto: yo.pesoMuerto,
                esYo: true,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colores.textoSuave),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${r.criterio} Se actualiza cada vez que alguien registra una marca.',
                      style: const TextStyle(color: Colores.textoSuave, fontSize: 13),
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

class _TarjetaMiPuesto extends StatelessWidget {
  final MiPuestoRanking yo;
  final int participantes;

  const _TarjetaMiPuesto({required this.yo, required this.participantes});

  @override
  Widget build(BuildContext context) {
    final tienePuesto = yo.posicion != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B3A12), Colores.superficie],
        ),
        border: Border.all(color: Colores.marca.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TU PUESTO',
            style: TextStyle(
              color: Colores.marca,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tienePuesto ? '#${yo.posicion}' : 'Sin marcas',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              if (tienePuesto)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    'de $participantes · ${formatearKg(yo.puntaje)} pts',
                    style: const TextStyle(color: Colores.textoSuave),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (tienePuesto)
            Row(
              children: [
                _Marca(nombre: 'Banca', kg: yo.banca),
                _Marca(nombre: 'Sentadilla', kg: yo.sentadilla),
                _Marca(nombre: 'Peso muerto', kg: yo.pesoMuerto),
              ],
            )
          else
            const Text(
              'Registra una serie de press banca, sentadilla o peso muerto '
              '(de 1 a 12 repeticiones) para entrar al ranking.',
              style: TextStyle(color: Colores.textoSuave),
            ),
        ],
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  final String nombre;
  final double kg;

  const _Marca({required this.nombre, required this.kg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kg <= 0 ? '—' : '${formatearKg(kg)} kg',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(nombre, style: const TextStyle(color: Colores.textoSuave, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FilaTop extends StatelessWidget {
  final FilaRanking fila;

  const _FilaTop({required this.fila});

  /// Oro, plata y bronce para el podio.
  Color get _colorPuesto => switch (fila.posicion) {
    1 => Colores.premium,
    2 => const Color(0xFFC9D1D9),
    3 => const Color(0xFFCD8B5A),
    _ => Colores.textoSuave,
  };

  @override
  Widget build(BuildContext context) {
    final podio = fila.posicion <= 3;
    final detalle = [
      if (fila.banca > 0) 'Banca ${formatearKg(fila.banca)}',
      if (fila.sentadilla > 0) 'Sentadilla ${formatearKg(fila.sentadilla)}',
      if (fila.pesoMuerto > 0) 'P. muerto ${formatearKg(fila.pesoMuerto)}',
    ].join(' · ');

    return Card(
      color: fila.esYo ? const Color(0xFF232E12) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: fila.esYo ? Colores.marca : Colores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _colorPuesto.withValues(alpha: podio ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${fila.posicion}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _colorPuesto,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fila.esYo && fila.nombre != 'Tú' ? '${fila.nombre} (tú)' : fila.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                      if (fila.nivel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Nv. ${fila.nivel}',
                          style: const TextStyle(
                            color: Colores.marca,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (detalle.isNotEmpty)
                    Text(
                      detalle,
                      style: const TextStyle(color: Colores.textoSuave, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatearKg(fila.puntaje),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Text('pts', style: TextStyle(color: Colores.textoSuave, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingBloqueado extends StatelessWidget {
  final String mensaje;

  const _RankingBloqueado({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard, size: 56, color: Colores.premium),
            const SizedBox(height: 14),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'El ranking compara tus marcas con los socios de tu mismo gimnasio. '
              'Paga tu membresía en un gimnasio asociado (pestaña "Gimnasios") y '
              'pide que activen Premium con tu correo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
