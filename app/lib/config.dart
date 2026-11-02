import 'package:flutter/foundation.dart';

/// Dónde está tu backend PHP.
class Config {
  /// false = backend en XAMPP (carpeta PonteChetado dentro de htdocs, puerto 80).
  /// true  = backend en Docker (docker compose up), puerto 8080.
  static const bool usarDocker = false;

  /// Si pruebas en un CELULAR FÍSICO conectado a tu misma red WiFi,
  /// pon aquí la IP de tu PC (la ves con `ipconfig` en CMD, "Dirección IPv4").
  /// Ejemplo: '192.168.1.15'. Déjalo vacío para emulador o Chrome.
  static const String ipManual = '';

  static String get _puerto => usarDocker ? ':8080' : '';

  static String get baseUrl {
    if (ipManual.isNotEmpty) return 'http://$ipManual$_puerto/PonteChetado/api';

    // Chrome / web: el navegador corre en tu misma PC
    if (kIsWeb) return 'http://localhost$_puerto/PonteChetado/api';

    // Emulador de Android: 10.0.2.2 es "localhost de tu PC" visto desde el emulador
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2$_puerto/PonteChetado/api';
    }

    // Simulador de iOS (en Mac) y escritorio
    return 'http://localhost$_puerto/PonteChetado/api';
  }
}
