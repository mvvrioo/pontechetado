import 'package:flutter/material.dart';

import 'services/api_service.dart';

/// Índice 1 = lunes ... 7 = domingo (igual que en la base de datos).
const nombresDias = [
  '',
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const letrasDias = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];

String nombreDia(int? dia) =>
    (dia == null || dia < 1 || dia > 7) ? 'Sin día' : nombresDias[dia];

/// 12450.5 -> "12.451" (separador de miles chileno)
String formatearMiles(num n) {
  final texto = n.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return n < 0 ? '-$buffer' : buffer.toString();
}

String formatearFecha(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

/// 80.0 -> "80", 79.45 -> "79.45"
String formatearKg(double kg) {
  final texto = kg.toStringAsFixed(2);
  return texto.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Convierte "78,5" o "78.5" a 78.5 (en Chile se escribe con coma).
double? leerNumero(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

void mostrarMensaje(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}

/// Muestra un error. Si es por falta de Premium, muestra el aviso Premium.
void mostrarError(BuildContext context, Object error) {
  if (error is ApiException && error.requierePremium) {
    mostrarDialogoPremium(context, error.mensaje);
    return;
  }
  mostrarMensaje(context, error.toString());
}

/// Mensaje de error a pantalla completa con botón "Reintentar".
class VistaError extends StatelessWidget {
  final Object error;
  final VoidCallback alReintentar;

  const VistaError({super.key, required this.error, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> mostrarDialogoPremium(BuildContext context, String mensaje) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.workspace_premium, size: 40),
      title: const Text('Función Premium'),
      content: Text(
        '$mensaje\n\nPremium se activa en tu gimnasio: paga tu membresía en un '
        'gimnasio asociado (pestaña "Gimnasios") y pide que la activen con tu correo.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
