// Clases que representan los datos que llegan desde la API (JSON -> Dart).

double _aDouble(dynamic v) => (v as num).toDouble();
double? _aDoubleONull(dynamic v) => v == null ? null : (v as num).toDouble();

/// Roles: 'usuario' (cliente), 'admin_gimnasio' o 'superadmin' (equipo PonteChetado).
class Usuario {
  final int id;
  final String nombre;
  final String email;
  final bool esPremium;
  final DateTime? premiumHasta;
  final String rol;
  final int? gimnasioId;
  final String? gimnasioNombre;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.esPremium,
    this.premiumHasta,
    this.rol = 'usuario',
    this.gimnasioId,
    this.gimnasioNombre,
  });

  bool get esAdminGimnasio => rol == 'admin_gimnasio';
  bool get esSuperadmin => rol == 'superadmin';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final gimnasio = json['gimnasio'] as Map<String, dynamic>?;
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      esPremium: json['es_premium'] as bool,
      premiumHasta: json['premium_hasta'] == null
          ? null
          : DateTime.parse(json['premium_hasta'] as String),
      rol: json['rol'] as String? ?? 'usuario',
      gimnasioId: gimnasio?['id'] as int?,
      gimnasioNombre: gimnasio?['nombre'] as String?,
    );
  }
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
  final int? diaSemana; // 1 = lunes ... 7 = domingo, null = sin día

  Rutina({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.totalEjercicios,
    this.diaSemana,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) => Rutina(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    totalEjercicios: json['total_ejercicios'] as int,
    diaSemana: json['dia_semana'] as int?,
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
  final int? diaSemana;
  final List<EjercicioRutina> ejercicios;

  RutinaDetalle({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.diaSemana,
    required this.ejercicios,
  });

  factory RutinaDetalle.fromJson(Map<String, dynamic> json) => RutinaDetalle(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    diaSemana: json['dia_semana'] as int?,
    ejercicios: (json['ejercicios'] as List)
        .map((e) => EjercicioRutina.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// =====================================================================
//  Gimnasios
// =====================================================================
class AdminGimnasio {
  final int id;
  final String nombre;
  final String email;

  AdminGimnasio({required this.id, required this.nombre, required this.email});

  factory AdminGimnasio.fromJson(Map<String, dynamic> json) => AdminGimnasio(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    email: json['email'] as String,
  );
}

class Gimnasio {
  final int id;
  final String nombre;
  final String? direccion;
  final int miembrosPremium;
  final bool esMiGimnasio;
  final List<AdminGimnasio> admins; // solo viene lleno para el superadmin

  Gimnasio({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.miembrosPremium,
    required this.esMiGimnasio,
    this.admins = const [],
  });

  factory Gimnasio.fromJson(Map<String, dynamic> json) => Gimnasio(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    direccion: json['direccion'] as String?,
    miembrosPremium: json['miembros_premium'] as int? ?? 0,
    esMiGimnasio: json['es_mi_gimnasio'] as bool? ?? false,
    admins: ((json['admins'] as List?) ?? [])
        .map((a) => AdminGimnasio.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}

class MiembroGimnasio {
  final int id;
  final String nombre;
  final String email;
  final bool esPremium;
  final DateTime? premiumHasta;

  MiembroGimnasio({
    required this.id,
    required this.nombre,
    required this.email,
    required this.esPremium,
    this.premiumHasta,
  });

  factory MiembroGimnasio.fromJson(Map<String, dynamic> json) =>
      MiembroGimnasio(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        esPremium: json['es_premium'] as bool,
        premiumHasta: json['premium_hasta'] == null
            ? null
            : DateTime.parse(json['premium_hasta'] as String),
      );
}

/// Lo que ve el admin del gimnasio en su panel.
class PanelGimnasio {
  final Gimnasio gimnasio;
  final List<MiembroGimnasio> miembros;
  final List<int> mesesPermitidos;

  PanelGimnasio({
    required this.gimnasio,
    required this.miembros,
    required this.mesesPermitidos,
  });

  factory PanelGimnasio.fromJson(Map<String, dynamic> json) => PanelGimnasio(
    gimnasio: Gimnasio.fromJson(json['gimnasio'] as Map<String, dynamic>),
    miembros: (json['miembros'] as List)
        .map((m) => MiembroGimnasio.fromJson(m as Map<String, dynamic>))
        .toList(),
    mesesPermitidos: (json['meses_permitidos'] as List)
        .map((m) => m as int)
        .toList(),
  );
}

// =====================================================================
//  Gamificación
// =====================================================================
class InfoNivel {
  final int xpTotal;
  final int nivel;
  final String titulo;
  final int xpEnNivel;
  final int xpParaSiguiente;

  InfoNivel({
    required this.xpTotal,
    required this.nivel,
    required this.titulo,
    required this.xpEnNivel,
    required this.xpParaSiguiente,
  });

  /// De 0.0 a 1.0: cuánto lleva del nivel actual.
  double get progreso =>
      xpParaSiguiente == 0 ? 0 : (xpEnNivel / xpParaSiguiente).clamp(0.0, 1.0);

  int get xpFaltante => xpParaSiguiente - xpEnNivel;

  factory InfoNivel.fromJson(Map<String, dynamic> json) => InfoNivel(
    xpTotal: json['xp_total'] as int,
    nivel: json['nivel'] as int,
    titulo: json['titulo'] as String,
    xpEnNivel: json['xp_en_nivel'] as int,
    xpParaSiguiente: json['xp_para_siguiente'] as int,
  );
}

/// XP que devuelve el servidor al registrar una serie.
class XpGanada {
  final int ganada;
  final bool subioNivel;
  final InfoNivel nivel;

  XpGanada({required this.ganada, required this.subioNivel, required this.nivel});

  factory XpGanada.fromJson(Map<String, dynamic> json) => XpGanada(
    ganada: json['ganada'] as int,
    subioNivel: json['subio_nivel'] as bool,
    nivel: InfoNivel.fromJson(json['nivel'] as Map<String, dynamic>),
  );
}

/// Un día de la semana actual (lunes a domingo).
class DiaSemana {
  final int diaSemana;
  final String nombre;
  final DateTime fecha;
  final bool esHoy;
  final bool entreno;
  final int xp;
  final double volumen;
  final String? rutina;

  DiaSemana({
    required this.diaSemana,
    required this.nombre,
    required this.fecha,
    required this.esHoy,
    required this.entreno,
    required this.xp,
    required this.volumen,
    this.rutina,
  });

  factory DiaSemana.fromJson(Map<String, dynamic> json) => DiaSemana(
    diaSemana: json['dia_semana'] as int,
    nombre: json['nombre'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    esHoy: json['es_hoy'] as bool,
    entreno: json['entreno'] as bool,
    xp: json['xp'] as int,
    volumen: _aDouble(json['volumen']),
    rutina: json['rutina'] as String?,
  );
}

/// Un día entrenado del historial: "Día 12 · Lunes · Pecho · +46 XP".
class DiaEntrenado {
  final int diaNumero;
  final DateTime fecha;
  final String nombreDia;
  final int series;
  final double volumen;
  final int xp;
  final List<String> grupos;
  final String? rutina;

  DiaEntrenado({
    required this.diaNumero,
    required this.fecha,
    required this.nombreDia,
    required this.series,
    required this.volumen,
    required this.xp,
    required this.grupos,
    this.rutina,
  });

  factory DiaEntrenado.fromJson(Map<String, dynamic> json) => DiaEntrenado(
    diaNumero: json['dia_numero'] as int,
    fecha: DateTime.parse(json['fecha'] as String),
    nombreDia: json['nombre_dia'] as String,
    series: json['series'] as int,
    volumen: _aDouble(json['volumen']),
    xp: json['xp'] as int,
    grupos: (json['grupos'] as List).map((g) => g as String).toList(),
    rutina: json['rutina'] as String?,
  );
}

class Progreso {
  final bool bloqueado; // true = plan gratis (solo ve su XP acumulada)
  final InfoNivel nivel;
  final int diasEntrenados;
  final double volumenTotal;
  final int xpSemana;
  final int entrenosSemana;
  final List<DiaSemana> semana;
  final List<DiaEntrenado> historial;
  final int xpPorSerie;
  final int kgPorXp;
  final int maxSeriesDia;
  final double topeVolumenSerie;

  Progreso({
    required this.bloqueado,
    required this.nivel,
    required this.diasEntrenados,
    required this.volumenTotal,
    required this.xpSemana,
    required this.entrenosSemana,
    required this.semana,
    required this.historial,
    required this.xpPorSerie,
    required this.kgPorXp,
    required this.maxSeriesDia,
    required this.topeVolumenSerie,
  });

  /// Misma fórmula que el backend (helpers.php -> xp_de_dia), para mostrar
  /// la XP de cualquier día sin pedirla al servidor.
  int xpDeDia(List<SerieEntreno> series) {
    var volumen = 0.0;
    for (final s in series) {
      volumen += s.volumen < topeVolumenSerie ? s.volumen : topeVolumenSerie;
    }
    final contadas = series.length < maxSeriesDia ? series.length : maxSeriesDia;
    return xpPorSerie * contadas + (volumen / kgPorXp).floor();
  }

  /// Lo que toca hoy según las rutinas asignadas a cada día.
  DiaSemana? get hoy {
    for (final d in semana) {
      if (d.esHoy) return d;
    }
    return null;
  }

  factory Progreso.fromJson(Map<String, dynamic> json) {
    final est = json['estadisticas'] as Map<String, dynamic>;
    final reglas = json['reglas'] as Map<String, dynamic>;
    return Progreso(
      bloqueado: json['bloqueado'] as bool,
      nivel: InfoNivel.fromJson(json['nivel'] as Map<String, dynamic>),
      diasEntrenados: est['dias_entrenados'] as int,
      volumenTotal: _aDouble(est['volumen_total']),
      xpSemana: est['xp_semana'] as int,
      entrenosSemana: est['entrenos_semana'] as int,
      semana: (json['semana'] as List)
          .map((d) => DiaSemana.fromJson(d as Map<String, dynamic>))
          .toList(),
      historial: (json['historial'] as List)
          .map((d) => DiaEntrenado.fromJson(d as Map<String, dynamic>))
          .toList(),
      xpPorSerie: reglas['xp_por_serie'] as int,
      kgPorXp: reglas['kg_por_xp'] as int,
      maxSeriesDia: reglas['max_series_dia'] as int,
      topeVolumenSerie: _aDouble(reglas['tope_volumen_serie']),
    );
  }
}
