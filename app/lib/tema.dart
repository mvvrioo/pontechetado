import 'package:flutter/material.dart';

/// Colores y estilo visual de toda la app: negro con acento dorado.
/// Diseños anteriores en GitHub: rama "respaldo-diseno-v1" (verde lima).
class Colores {
  static const marca = Color(0xFFD4A84B); // dorado
  static const secundario = Color(0xFFF0D58C); // dorado claro (champaña)
  static const sobreMarca = Color(0xFF0A0A0A); // texto e íconos encima del dorado
  static const sobreMarcaSuave = Color(0xCC0A0A0A);
  static const marcaProfunda = Color(0xFF221C10); // fondo de tarjetas destacadas
  static const marcaTenue = Color(0xFF1B1710); // fila o tarjeta seleccionada
  static const fondo = Color(0xFF0A0A0A); // negro
  static const superficie = Color(0xFF151515);
  static const superficieAlta = Color(0xFF1E1E1E);
  static const borde = Color(0xFF262626);
  static const texto = Color(0xFFF4F1EA); // blanco cálido
  static const textoSuave = Color(0xFFA39E93); // gris cálido
  static const premium = Color(0xFFF0D58C); // champaña (se distingue del dorado de la marca)
  static const peligro = Color(0xFFE5484D);

  /// Degradado dorado para botones y tarjetas destacadas.
  static const degradado = LinearGradient(
    colors: [Color(0xFFB8862F), Color(0xFFE8C46A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData construirTema() {
  final base = ColorScheme.fromSeed(
    seedColor: Colores.marca,
    brightness: Brightness.dark,
  );

  final esquema = base.copyWith(
    primary: Colores.marca,
    onPrimary: Colores.sobreMarca,
    primaryContainer: Colores.marcaProfunda,
    secondary: Colores.secundario,
    onSecondary: Colores.sobreMarca,
    onPrimaryContainer: Colores.texto,
    tertiary: Colores.premium,
    error: Colores.peligro,
    surface: Colores.fondo,
    onSurface: Colores.texto,
    onSurfaceVariant: Colores.textoSuave,
    surfaceContainerLowest: Colores.fondo,
    surfaceContainerLow: Colores.superficie,
    surfaceContainer: Colores.superficie,
    surfaceContainerHigh: Colores.superficieAlta,
    surfaceContainerHighest: Colores.superficieAlta,
    outline: Colores.borde,
    outlineVariant: Colores.borde,
  );

  final redondeo = BorderRadius.circular(20);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Colores.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.fondo,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Colores.texto,
        letterSpacing: -0.8,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: redondeo,
        side: const BorderSide(color: Colores.borde),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colores.marca,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      height: 70,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? Colores.sobreMarca
              : Colores.textoSuave,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontSize: 12,
          fontWeight: estados.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: estados.contains(WidgetState.selected)
              ? Colores.texto
              : Colores.textoSuave,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colores.borde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colores.marca,
      foregroundColor: Colores.sobreMarca,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.superficieAlta,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colores.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colores.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colores.marca, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colores.superficieAlta,
      side: const BorderSide(color: Colores.borde),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colores.superficie,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colores.superficieAlta,
      contentTextStyle: const TextStyle(color: Colores.texto),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: Colores.borde),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colores.marca,
      linearTrackColor: Colores.superficieAlta,
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colores.marca),
  );
}
