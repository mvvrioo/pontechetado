import 'package:flutter/foundation.dart';

/// Dónde está tu backend PHP (la carpeta PonteChetado dentro de htdocs).
class Config {
  /// Si pruebas en un CELULAR FÍSICO conectado a tu misma red WiFi,
  /// pon aquí la IP de tu PC (la ves con `ipconfig` en CMD, "Dirección IPv4").
  /// Ejemplo: '192.168.1.15'. Déjalo vacío para emulador o Chrome.
  static const String ipManual = '';

  static String get baseUrl {
    if (ipManual.isNotEmpty) return 'http://$ipManual/PonteChetado/api';

    // Chrome / web: el navegador corre en tu misma PC
    if (kIsWeb) return 'http://localhost/PonteChetado/api';

    // Emulador de Android: 10.0.2.2 es "localhost de tu PC" visto desde el emulador
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/PonteChetado/api';
    }

    // Simulador de iOS (en Mac) y escritorio
    return 'http://localhost/PonteChetado/api';
  }
}
