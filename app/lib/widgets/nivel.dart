import 'package:flutter/material.dart';

import '../models.dart';
import '../tema.dart';

/// Círculo con el número de nivel y un anillo de progreso alrededor.
class InsigniaNivel extends StatelessWidget {
  final InfoNivel nivel;
  final double tamano;

  const InsigniaNivel({super.key, required this.nivel, this.tamano = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: nivel.progreso,
              strokeWidth: tamano * 0.08,
              strokeCap: StrokeCap.round,
              color: Colores.marca,
              backgroundColor: Colores.borde,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NIVEL',
                style: TextStyle(
                  fontSize: tamano * 0.11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: Colores.textoSuave,
                ),
              ),
              Text(
                '${nivel.nivel}',
                style: TextStyle(
                  fontSize: tamano * 0.36,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colores.texto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra horizontal de XP: "120 / 150 XP".
class BarraXp extends StatelessWidget {
  final InfoNivel nivel;

  const BarraXp({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: nivel.progreso,
            minHeight: 10,
            color: Colores.marca,
            backgroundColor: Colores.borde,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${nivel.xpEnNivel} / ${nivel.xpParaSiguiente} XP',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colores.texto,
              ),
            ),
            const Spacer(),
            Text(
              'Faltan ${nivel.xpFaltante} XP para nivel ${nivel.nivel + 1}',
              style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
            ),
          ],
        ),
      ],
    );
  }
}

/// Etiqueta pequeña tipo "+46 XP".
class ChipXp extends StatelessWidget {
  final int xp;

  const ChipXp(this.xp, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colores.marca.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$xp XP',
        style: const TextStyle(
          color: Colores.marca,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Celebración al subir de nivel.
Future<void> mostrarSubidaDeNivel(BuildContext context, InfoNivel nivel) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            '¡SUBISTE DE NIVEL!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colores.marca,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          InsigniaNivel(nivel: nivel, tamano: 110),
          const SizedBox(height: 12),
          Text(
            'Ahora eres ${nivel.titulo}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('¡Vamos! 💪'),
        ),
      ],
    ),
  );
}
