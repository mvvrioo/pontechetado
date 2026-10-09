import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models.dart';

/// Error que devuelve la API (ej: "Email o contraseña incorrectos").
class ApiException implements Exception {
  final String mensaje;
  final int codigo;
  final bool requierePremium;

  ApiException(this.mensaje, {this.codigo = 0, this.requierePremium = false});

  @override
  String toString() => mensaje;
}

/// Todas las llamadas al backend PHP pasan por aquí.
/// Se usa así:  ApiService.instance.login(...)
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _claveToken = 'token';
  static const _timeout = Duration(seconds: 15);

  String? _token;

  /// Se llama cuando el servidor dice que la sesión expiró (la app vuelve al login).
  void Function()? alExpirarSesion;

  bool get haySesion => _token != null;

  // ------------------------------------------------------------------
  //  Sesión (guardar / leer / borrar el token en el teléfono)
  // ------------------------------------------------------------------
  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_claveToken);
  }

  Future<void> _guardarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveToken, token);
  }

  Future<void> _borrarToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveToken);
  }

  // ------------------------------------------------------------------
  //  Peticiones HTTP genéricas
  // ------------------------------------------------------------------
  Map<String, String> get _cabeceras => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _get(String ruta) async {
    return _enviar(
      () => http.get(Uri.parse('${Config.baseUrl}/$ruta'), headers: _cabeceras),
    );
  }

  Future<Map<String, dynamic>> _post(
    String ruta, [
    Map<String, dynamic>? cuerpo,
  ]) async {
    return _enviar(
      () => http.post(
        Uri.parse('${Config.baseUrl}/$ruta'),
        headers: _cabeceras,
        body: jsonEncode(cuerpo ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> _enviar(
    Future<http.Response> Function() peticion,
  ) async {
    final http.Response respuesta;
    try {
      respuesta = await peticion().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder');
    } catch (_) {
      throw ApiException(
        'No se pudo conectar al servidor. ¿Está encendido XAMPP?',
      );
    }

    final Map<String, dynamic> datos;
    try {
      datos =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Respuesta inválida del servidor (código ${respuesta.statusCode})',
      );
    }

    if (datos['ok'] == true) return datos;

    // Sesión vencida o token inválido: limpiar y volver al login
    if (respuesta.statusCode == 401 && _token != null) {
      await _borrarToken();
      alExpirarSesion?.call();
    }

    throw ApiException(
      (datos['mensaje'] as String?) ?? 'Ocurrió un error',
      codigo: respuesta.statusCode,
      requierePremium: datos['requiere_premium'] == true,
    );
  }

  // ------------------------------------------------------------------
  //  Autenticación
  // ------------------------------------------------------------------
  Future<Usuario> registrar(
    String nombre,
    String email,
    String password,
  ) async {
    final datos = await _post('auth/registro.php', {
      'nombre': nombre,
      'email': email,
      'password': password,
    });
    await _guardarToken(datos['token'] as String);
    return Usuario.fromJson(datos['usuario'] as Map<String, dynamic>);
  }

  Future<Usuario> login(String email, String password) async {
    final datos = await _post('auth/login.php', {
      'email': email,
      'password': password,
    });
    await _guardarToken(datos['token'] as String);
    return Usuario.fromJson(datos['usuario'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _post('auth/logout.php');
    } catch (_) {
      // Aunque falle el servidor, cerramos la sesión en el teléfono
    }
    await _borrarToken();
  }

  Future<(Usuario, Plan)> perfil() async {
    final datos = await _get('auth/perfil.php');
    return (
      Usuario.fromJson(datos['usuario'] as Map<String, dynamic>),
      Plan.fromJson(datos['plan'] as Map<String, dynamic>),
    );
  }

  // ------------------------------------------------------------------
  //  Peso corporal
  // ------------------------------------------------------------------
  Future<List<RegistroPeso>> listarPesos() async {
    final datos = await _get('peso/listar.php');
    return (datos['registros'] as List)
        .map((e) => RegistroPeso.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> agregarPeso(double pesoKg, DateTime fecha, String nota) async {
    await _post('peso/agregar.php', {
      'peso_kg': pesoKg,
      'fecha': _fechaIso(fecha),
      'nota': nota,
    });
  }

  Future<void> eliminarPeso(int id) async {
    await _post('peso/eliminar.php', {'id': id});
  }

  // ------------------------------------------------------------------
  //  Ejercicios y rutinas
  // ------------------------------------------------------------------
  Future<List<Ejercicio>> listarEjercicios() async {
    final datos = await _get('ejercicios/listar.php');
    return (datos['ejercicios'] as List)
        .map((e) => Ejercicio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Ejercicio> crearEjercicio(String nombre, String grupoMuscular) async {
    final datos = await _post('ejercicios/crear.php', {
      'nombre': nombre,
      'grupo_muscular': grupoMuscular,
    });
    return Ejercicio.fromJson(datos['ejercicio'] as Map<String, dynamic>);
  }

  Future<SerieEntreno> registrarSerie({
    required int ejercicioId,
    required DateTime fecha,
    required double pesoKg,
    required int repeticiones,
  }) async {
    final datos = await _post('entrenos/registrar_serie.php', {
      'ejercicio_id': ejercicioId,
      'fecha': _fechaIso(fecha),
      'peso_kg': pesoKg,
      'repeticiones': repeticiones,
    });
    return SerieEntreno.fromJson({
      ...datos['serie'] as Map<String, dynamic>,
      'fecha': datos['serie']['fecha'] as String,
      'ejercicio_id': datos['serie']['ejercicio_id'] as int,
    });
  }

  Future<EntrenoDelDia> entrenoDelDia(DateTime fecha) async {
    final datos = await _get('entrenos/del_dia.php?fecha=${_fechaIso(fecha)}');
    return EntrenoDelDia.fromJson(datos);
  }

  Future<void> eliminarSerie(int id) async {
    await _post('entrenos/eliminar_serie.php', {'id': id});
  }

  Future<List<VolumenDia>> resumenVolumen(int dias) async {
    final datos = await _get('entrenos/resumen.php?dias=$dias');
    return (datos['dias'] as List)
        .map((e) => VolumenDia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve las rutinas y el límite del plan (null = ilimitado).
  Future<(List<Rutina>, int?)> listarRutinas() async {
    final datos = await _get('rutinas/listar.php');
    final rutinas = (datos['rutinas'] as List)
        .map((e) => Rutina.fromJson(e as Map<String, dynamic>))
        .toList();
    return (rutinas, datos['limite_rutinas'] as int?);
  }

  Future<void> crearRutina(String nombre, String descripcion) async {
    await _post('rutinas/crear.php', {
      'nombre': nombre,
      'descripcion': descripcion,
    });
  }

  Future<RutinaDetalle> detalleRutina(int id) async {
    final datos = await _get('rutinas/detalle.php?id=$id');
    return RutinaDetalle.fromJson(datos['rutina'] as Map<String, dynamic>);
  }

  Future<void> eliminarRutina(int id) async {
    await _post('rutinas/eliminar.php', {'id': id});
  }

  Future<void> agregarEjercicioARutina({
    required int rutinaId,
    required int ejercicioId,
    required int series,
    required int repeticiones,
    double? pesoKg,
  }) async {
    await _post('rutinas/agregar_ejercicio.php', {
      'rutina_id': rutinaId,
      'ejercicio_id': ejercicioId,
      'series': series,
      'repeticiones': repeticiones,
      'peso_kg': pesoKg,
    });
  }

  Future<void> quitarEjercicioDeRutina(int id) async {
    await _post('rutinas/quitar_ejercicio.php', {'id': id});
  }

  // ------------------------------------------------------------------
  //  Premium
  // ------------------------------------------------------------------
  /// Canjea un código. Devuelve el mensaje del servidor.
  Future<String> activarPremium(String codigo) async {
    final datos = await _post('premium/activar.php', {'codigo': codigo});
    return datos['mensaje'] as String;
  }

  String _fechaIso(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
}
