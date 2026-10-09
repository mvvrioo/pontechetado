// Clases que representan los datos que llegan desde la API (JSON -> Dart).

double _aDouble(dynamic v) => (v as num).toDouble();
double? _aDoubleONull(dynamic v) => v == null ? null : (v as num).toDouble();

class Usuario {
  final int id;
  final String nombre;
  final String email;
  final bool esPremium;
  final DateTime? premiumHasta;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.esPremium,
    this.premiumHasta,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    email: json['email'] as String,
    esPremium: json['es_premium'] as bool,
    premiumHasta: json['premium_hasta'] == null
        ? null
        : DateTime.parse(json['premium_hasta'] as String),
  );
}

class Plan {
  final int rutinasUsadas;
  final int? limiteRutinas; // null = ilimitado (premium)
  final int? limiteEjerciciosPorRutina;

  Plan({
    required this.rutinasUsadas,
    this.limiteRutinas,
    this.limiteEjerciciosPorRutina,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    rutinasUsadas: json['rutinas_usadas'] as int,
    limiteRutinas: json['limite_rutinas'] as int?,
    limiteEjerciciosPorRutina: json['limite_ejercicios_por_rutina'] as int?,
  );
}

class RegistroPeso {
  final int id;
  final double pesoKg;
  final DateTime fecha;
  final String? nota;

  RegistroPeso({
    required this.id,
    required this.pesoKg,
    required this.fecha,
    this.nota,
  });

  factory RegistroPeso.fromJson(Map<String, dynamic> json) => RegistroPeso(
    id: json['id'] as int,
    pesoKg: _aDouble(json['peso_kg']),
    fecha: DateTime.parse(json['fecha'] as String),
    nota: json['nota'] as String?,
  );
}

class Ejercicio {
  final int id;
  final String nombre;
  final String grupoMuscular;
  final String? descripcion;
  final bool esPremium;
  final bool personalizado;
  final bool bloqueado; // true = es premium y el usuario NO es premium

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.grupoMuscular,
    this.descripcion,
    required this.esPremium,
    required this.personalizado,
    required this.bloqueado,
  });

  factory Ejercicio.fromJson(Map<String, dynamic> json) => Ejercicio(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    grupoMuscular: json['grupo_muscular'] as String,
    descripcion: json['descripcion'] as String?,
    esPremium: json['es_premium'] as bool,
    personalizado: json['personalizado'] as bool? ?? false,
    bloqueado: json['bloqueado'] as bool? ?? false,
  );
}

class SerieEntreno {
  final int id;
  final int ejercicioId;
  final DateTime fecha;
  final int numeroSerie;
  final double pesoKg;
  final int repeticiones;
  final double volumen;

  SerieEntreno({
    required this.id,
    required this.ejercicioId,
    required this.fecha,
    required this.numeroSerie,
    required this.pesoKg,
    required this.repeticiones,
    required this.volumen,
  });

  factory SerieEntreno.fromJson(Map<String, dynamic> json) => SerieEntreno(
    id: json['id'] as int,
    ejercicioId: json['ejercicio_id'] as int? ?? 0,
    fecha: DateTime.parse(json['fecha'] as String),
    numeroSerie: json['numero_serie'] as int,
    pesoKg: _aDouble(json['peso_kg']),
    repeticiones: json['repeticiones'] as int,
    volumen: _aDouble(json['volumen']),
  );
}

class EjercicioDelDia {
  final int ejercicioId;
  final String nombre;
  final double volumen;
  final List<SerieEntreno> series;

  EjercicioDelDia({
    required this.ejercicioId,
    required this.nombre,
    required this.volumen,
    required this.series,
  });

  factory EjercicioDelDia.fromJson(Map<String, dynamic> json) =>
      EjercicioDelDia(
        ejercicioId: json['ejercicio_id'] as int,
        nombre: json['nombre'] as String,
        volumen: _aDouble(json['volumen']),
        series: (json['series'] as List)
            .map(
              (s) => SerieEntreno.fromJson({
                'id': s['id'],
                'ejercicio_id': json['ejercicio_id'],
                'fecha': json['fecha'] ?? DateTime.now().toIso8601String(),
                'numero_serie': s['numero_serie'],
                'peso_kg': s['peso_kg'],
                'repeticiones': s['repeticiones'],
                'volumen': s['volumen'],
              }),
            )
            .toList(),
      );
}

class EntrenoDelDia {
  final DateTime fecha;
  final double volumenTotal;
  final List<EjercicioDelDia> ejercicios;

  EntrenoDelDia({
    required this.fecha,
    required this.volumenTotal,
    required this.ejercicios,
  });

  factory EntrenoDelDia.fromJson(Map<String, dynamic> json) => EntrenoDelDia(
    fecha: DateTime.parse(json['fecha'] as String),
    volumenTotal: _aDouble(json['volumen_total']),
    ejercicios: (json['ejercicios'] as List)
        .map(
          (e) => EjercicioDelDia.fromJson({
            'ejercicio_id': e['ejercicio_id'],
            'nombre': e['nombre'],
            'volumen': e['volumen'],
            'fecha': json['fecha'],
            'series': e['series'],
          }),
        )
        .toList(),
  );
}

class VolumenDia {
  final DateTime fecha;
  final double volumen;

  VolumenDia({required this.fecha, required this.volumen});

  factory VolumenDia.fromJson(Map<String, dynamic> json) => VolumenDia(
    fecha: DateTime.parse(json['fecha'] as String),
    volumen: _aDouble(json['volumen']),
  );
}

class Rutina {
  final int id;
  final String nombre;
  final String? descripcion;
  final int totalEjercicios;

  Rutina({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.totalEjercicios,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) => Rutina(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    totalEjercicios: json['total_ejercicios'] as int,
  );
}

/// Un ejercicio ya agregado a una rutina (con sus series y repeticiones).
class EjercicioRutina {
  final int id; // id dentro de la rutina (para quitarlo)
  final int ejercicioId;
  final String nombre;
  final String grupoMuscular;
  final int series;
  final int repeticiones;
  final double? pesoKg;

  EjercicioRutina({
    required this.id,
    required this.ejercicioId,
    required this.nombre,
    required this.grupoMuscular,
    required this.series,
    required this.repeticiones,
    this.pesoKg,
  });

  factory EjercicioRutina.fromJson(Map<String, dynamic> json) =>
      EjercicioRutina(
        id: json['id'] as int,
        ejercicioId: json['ejercicio_id'] as int,
        nombre: json['nombre'] as String,
        grupoMuscular: json['grupo_muscular'] as String,
        series: json['series'] as int,
        repeticiones: json['repeticiones'] as int,
        pesoKg: _aDoubleONull(json['peso_kg']),
      );
}

class RutinaDetalle {
  final int id;
  final String nombre;
  final String? descripcion;
  final List<EjercicioRutina> ejercicios;

  RutinaDetalle({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.ejercicios,
  });

  factory RutinaDetalle.fromJson(Map<String, dynamic> json) => RutinaDetalle(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    ejercicios: (json['ejercicios'] as List)
        .map((e) => EjercicioRutina.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
