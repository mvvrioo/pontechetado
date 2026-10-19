import 'package:flutter/material.dart';

/// Colores y estilo visual de toda la app.
class Colores {
  static const marca = Color(0xFFB6FF3B); // verde "chetado"
  static const fondo = Color(0xFF0D0F0B);
  static const superficie = Color(0xFF161A12);
  static const superficieAlta = Color(0xFF1F2419);
  static const borde = Color(0xFF2B3223);
  static const texto = Color(0xFFEEF2E6);
  static const textoSuave = Color(0xFF9AA38E);
  static const premium = Color(0xFFFFC145); // dorado
  static const peligro = Color(0xFFFF6B5E);
}

ThemeData construirTema() {
  final base = ColorScheme.fromSeed(
    seedColor: Colores.marca,
    brightness: Brightness.dark,
  );

  final esquema = base.copyWith(
    primary: Colores.marca,
    onPrimary: Colors.black,
    primaryContainer: const Color(0xFF2E3D12),
    onPrimaryContainer: Colores.marca,
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

  final redondeo = BorderRadius.circular(18);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Colores.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.fondo,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colores.texto,
        letterSpacing: -0.5,
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
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? Colors.black
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
      foregroundColor: Colors.black,
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
  );
}
