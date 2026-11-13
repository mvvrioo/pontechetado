import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

/// Colores que puede elegir el usuario (mismo orden que guarda la base de datos).
const pielesAvatar = [
  Color(0xFFF2D3B1),
  Color(0xFFE0AC69),
  Color(0xFFC68642),
  Color(0xFF8D5524),
  Color(0xFF5C3A21),
];
const pelosAvatar = [
  Color(0xFF1B1B1B),
  Color(0xFF4E342E),
  Color(0xFF8D6E63),
  Color(0xFFD7A65A),
  Color(0xFFB23A2E),
  Color(0xFFE8E8E8),
];
const ropasAvatar = [
  Color(0xFFD4A84B),
  Color(0xFF2E2E2E),
  Color(0xFFB6FF3B),
  Color(0xFFC8463A),
  Color(0xFF8E44AD),
  Color(0xFFFFC145),
];
const peinadosAvatar = ['Corto', 'Rapado', 'Largo', 'Moño'];

/// Tramo de evolución del avatar según el nivel (0 a 5).
/// Coincide con los títulos: Novato, En progreso, Intermedio, Avanzado, Élite, Chetado.
int tramoAvatar(int nivel) {
  if (nivel >= 40) return 5;
  if (nivel >= 30) return 4;
  if (nivel >= 20) return 3;
  if (nivel >= 10) return 2;
  if (nivel >= 5) return 1;
  return 0;
}

/// Nivel mínimo de cada tramo (para mostrar "se desbloquea en nivel X").
const nivelesTramo = [1, 5, 10, 20, 30, 40];
const nombresTramo = ['Novato', 'En progreso', 'Intermedio', 'Avanzado', 'Élite', 'Chetado'];

/// Qué gana el avatar en cada tramo.
const premiosTramo = [
  'Tu avatar inicial',
  'Muñequeras y más brazo',
  'Hombros más anchos',
  'Cintillo y pecho marcado',
  'Medalla de oro',
  'Corona y aura chetada',
];

/// Dibuja el avatar. Proporción ancho:alto = 100:130.
class AvatarDibujo extends StatelessWidget {
  final AvatarConfig config;
  final int tramo;
  final double ancho;

  const AvatarDibujo({
    super.key,
    required this.config,
    required this.tramo,
    this.ancho = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: ancho * 1.3,
      child: CustomPaint(painter: _PintorAvatar(config, tramo.clamp(0, 5))),
    );
  }
}

class _PintorAvatar extends CustomPainter {
  final AvatarConfig c;
  final int tramo;

  _PintorAvatar(this.c, this.tramo);

  late double _k;

  Offset _p(double x, double y) => Offset(x * _k, y * _k);

  Paint _relleno(Color color) => Paint()
    ..color = color
    ..isAntiAlias = true;

  void _circ(Canvas canvas, double x, double y, double r, Color color) {
    canvas.drawCircle(_p(x, y), r * _k, _relleno(color));
  }

  void _linea(Canvas canvas, double x1, double y1, double x2, double y2, double grosor, Color color) {
    canvas.drawLine(
      _p(x1, y1),
      _p(x2, y2),
      Paint()
        ..color = color
        ..strokeWidth = grosor * _k
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  void _poli(Canvas canvas, List<List<double>> puntos, Color color) {
    final path = Path()..moveTo(puntos.first[0] * _k, puntos.first[1] * _k);
    for (final pt in puntos.skip(1)) {
      path.lineTo(pt[0] * _k, pt[1] * _k);
    }
    path.close();
    canvas.drawPath(path, _relleno(color));
  }

  Rect _rect(double x0, double y0, double x1, double y1) =>
      Rect.fromPoints(_p(x0, y0), _p(x1, y1));

  double _rad(double grados) => grados * math.pi / 180;

  /// Relleno entre un arco y su cuerda (ángulos en grados, sentido horario).
  void _cuerda(Canvas canvas, Rect r, double desde, double hasta, Color color) {
    canvas.drawArc(r, _rad(desde), _rad(hasta - desde), false, _relleno(color));
  }

  void _arco(Canvas canvas, Rect r, double desde, double hasta, double grosor, Color color) {
    canvas.drawArc(
      r,
      _rad(desde),
      _rad(hasta - desde),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor * _k
        ..isAntiAlias = true,
    );
  }

  Color _oscurecer(Color color, double f) => Color.fromARGB(
        255,
        ((color.r * 255) * f).round(),
        ((color.g * 255) * f).round(),
        ((color.b * 255) * f).round(),
      );

  @override
  void paint(Canvas canvas, Size size) {
    _k = size.width / 100;
    final m = tramo / 5;
    final fem = c.genero == 'femenino';
    final piel = pielesAvatar[c.piel.clamp(0, pielesAvatar.length - 1)];
    final pielOscura = _oscurecer(piel, 0.85);
    final pelo = pelosAvatar[c.colorPelo.clamp(0, pelosAvatar.length - 1)];
    final ropa = ropasAvatar[c.colorRopa.clamp(0, ropasAvatar.length - 1)];
    const short = Color(0xFF282C24);
    const blanco = Color(0xFFF0F0F0);
    const lima = Color(0xFFE8C46A); // detalles (muñequeras, cintillo) en dorado
    const oro = Color(0xFFFFC145);

    // ---- Aura (Chetado) ----
    if (tramo >= 5) {
      canvas.drawOval(
        _rect(14, 18, 86, 122),
        Paint()
          ..color = lima.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * _k),
      );
    }

    final hombro = 16 + m * 9 - (fem ? 2.5 : 0);
    final cintura = 11.5 + m * 2 - (fem ? 1.5 : 0);
    final cadera = cintura + (fem ? 4 : 1.5);
    final brazo = 6 + m * 4.5 - (fem ? 0.8 : 0);
    final pierna = 8 + m * 2.5;

    // ---- Pelo largo (por detrás) ----
    if (c.peinado == 2) {
      _poli(canvas, [[37, 26], [63, 26], [66, 56], [34, 56]], pelo);
    }

    // ---- Piernas y zapatillas ----
    for (final s in [-1, 1]) {
      _linea(canvas, 50 + s * (cadera / 2 + 1), 102, 50 + s * (cadera / 2 + 0.5), 124, pierna, piel);
      final x = 50 + s * (cadera / 2 + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          _rect(x - pierna / 2 - 1, 123, x + pierna / 2 + (s > 0 ? 2 : 0), 129),
          Radius.circular(2 * _k),
        ),
        _relleno(blanco),
      );
    }

    // ---- Short ----
    _poli(canvas, [
      [50 - cintura, 88],
      [50 + cintura, 88],
      [50 + cadera + 4, 108],
      [51.5, 108],
      [50, 100],
      [48.5, 108],
      [50 - cadera - 4, 108],
    ], short);

    // ---- Brazos (detrás del torso) ----
    for (final s in [-1, 1]) {
      final x0 = 50 + s * (hombro - brazo / 2 + 1);
      final x1 = 50 + s * (hombro + 3 + m * 2);
      _linea(canvas, x0, 54, x1, 88, brazo, piel);
      if (m >= 0.4) {
        _circ(canvas, x0 + s * (1 + m), 63, brazo * 0.62, piel); // bíceps
      }
      _circ(canvas, x1, 90, brazo * 0.55, pielOscura); // mano
      if (tramo >= 1) {
        final bx = x0 + (x1 - x0) * 0.78;
        _linea(canvas, bx, 54 + 34 * 0.76, bx + (x1 - x0) * 0.04, 54 + 34 * 0.8, brazo * 0.9, Colors.white);
      }
    }

    // ---- Torso (polera sin mangas) ----
    _poli(canvas, [
      [50 - hombro, 50],
      [50 + hombro, 50],
      [50 + cintura, 90],
      [50 - cintura, 90],
    ], ropa);
    for (final s in [-1, 1]) {
      _circ(canvas, 50 + s * (hombro - brazo / 2 + 1), 54, brazo / 2 + 0.6, piel);
    }
    if (m >= 0.6 && !fem) {
      final sombra = _oscurecer(ropa, 0.82);
      _arco(canvas, _rect(41, 56, 50, 66), 20, 160, 0.8, sombra);
      _arco(canvas, _rect(50, 56, 59, 66), 20, 160, 0.8, sombra);
    }
    _cuerda(canvas, _rect(44, 44, 56, 56), 0, 180, piel); // escote

    // ---- Medalla (Élite) ----
    if (tramo >= 4) {
      final cinta = Paint()
        ..color = const Color(0xFFC8463A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * _k
        ..isAntiAlias = true;
      canvas.drawPath(
        Path()
          ..moveTo(45 * _k, 50 * _k)
          ..lineTo(50 * _k, 64 * _k)
          ..lineTo(55 * _k, 50 * _k),
        cinta,
      );
      _circ(canvas, 50, 66, 3.2, oro);
      _circ(canvas, 50, 66, 1.6, const Color(0xFFE0A100));
    }

    // ---- Cuello, cabeza y orejas ----
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _rect(50 - 4.5 - m * 2, 38, 50 + 4.5 + m * 2, 51),
        Radius.circular(2 * _k),
      ),
      _relleno(piel),
    );
    _circ(canvas, 50, 29, 12.5, piel);
    _circ(canvas, 37.6, 30, 2.2, piel);
    _circ(canvas, 62.4, 30, 2.2, piel);

    // ---- Pelo ----
    if (c.peinado == 1) {
      // Rapado: una capa fina sobre la cabeza
      _cuerda(canvas, _rect(37.5, 16.5, 62.5, 30), 180, 360, pelo);
    } else {
      _cuerda(canvas, _rect(36.5, 15, 63.5, 42), 175, 365, pelo);
      _poli(canvas, [
        [38, 27], [44, 21], [52, 24], [58, 20], [62.5, 27], [62.5, 23], [50, 15.5], [37.5, 23],
      ], pelo); // flequillo
      if (c.peinado == 3) _circ(canvas, 50, 13, 5.2, pelo); // moño
      if (c.peinado == 2) {
        _poli(canvas, [[36.5, 28], [39, 28], [38.5, 44], [35, 46]], pelo);
        _poli(canvas, [[63.5, 28], [61, 28], [61.5, 44], [65, 46]], pelo);
      }
    }

    // ---- Cintillo (Avanzado) ----
    if (tramo >= 3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(_rect(37.6, 22.5, 62.4, 25.5), Radius.circular(1 * _k)),
        _relleno(lima),
      );
    }

    // ---- Cara ----
    const ojos = Color(0xFF1E1E1E);
    _circ(canvas, 45.3, 30.5, 1.35, ojos);
    _circ(canvas, 54.7, 30.5, 1.35, ojos);
    final colorCeja = c.peinado == 1 ? ojos : pelo;
    final inc = 1.2 * m; // cejas más decididas al subir de nivel
    _linea(canvas, 42.5, 27 + inc * 0.3, 47.5, 27.2 - inc, 0.9, colorCeja);
    _linea(canvas, 52.5, 27.2 - inc, 57.5, 27 + inc * 0.3, 0.9, colorCeja);
    _arco(canvas, _rect(45.5, 31.5, 54.5, 37.5), 20, 160, 0.9, const Color(0xFF783228));
    if (fem) {
      final rubor = const Color(0xFFF08282).withValues(alpha: 0.35);
      _circ(canvas, 42.5, 34, 1.6, rubor);
      _circ(canvas, 57.5, 34, 1.6, rubor);
    }

    // ---- Corona (Chetado) ----
    if (tramo >= 5) {
      final y = c.peinado == 3 ? 9.0 : 12.0;
      _poli(canvas, [
        [42, y + 6], [42, y], [46, y + 3], [50, y - 2], [54, y + 3], [58, y], [58, y + 6],
      ], oro);
      _circ(canvas, 50, y - 2, 1.2, Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorAvatar old) =>
      old.tramo != tramo ||
      old.c.genero != c.genero ||
      old.c.piel != c.piel ||
      old.c.peinado != c.peinado ||
      old.c.colorPelo != c.colorPelo ||
      old.c.colorRopa != c.colorRopa;
}
