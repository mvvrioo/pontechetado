// Pruebas unitarias de la lógica de la app (no necesitan servidor).
// Se ejecutan con:  flutter test
import 'package:flutter_test/flutter_test.dart';

import 'package:ponte_chetado/models.dart';
import 'package:ponte_chetado/utils.dart';
import 'package:ponte_chetado/widgets/avatar.dart';

void main() {
  group('Formato de datos', () {
    test('los miles se separan con punto', () {
      expect(formatearMiles(950), '950');
      expect(formatearMiles(10350), '10.350');
      expect(formatearMiles(1234567), '1.234.567');
    });

    test('los kilos no muestran decimales innecesarios', () {
      expect(formatearKg(80), '80');
      expect(formatearKg(82.5), '82.5');
      expect(formatearKg(93.50), '93.5');
    });

    test('los números aceptan coma decimal', () {
      expect(leerNumero('82,5'), 82.5);
      expect(leerNumero(' 60 '), 60);
      expect(leerNumero('abc'), isNull);
    });

    test('los días de la semana van de lunes (1) a domingo (7)', () {
      expect(nombreDia(1), 'Lunes');
      expect(nombreDia(7), 'Domingo');
      expect(nombreDia(null), 'Sin día');
      expect(nombreDia(9), 'Sin día');
    });
  });

  group('Usuario y roles', () {
    Map<String, dynamic> json(String rol) => {
      'id': 1,
      'nombre': 'Mario',
      'email': 'mario@correo.cl',
      'es_premium': true,
      'premium_hasta': '2026-12-01 10:00:00',
      'rol': rol,
      'gimnasio': {'id': 2, 'nombre': 'Marfit'},
    };

    test('un socio es cliente y no es personal del gimnasio', () {
      final u = Usuario.fromJson(json('usuario'));
      expect(u.esCliente, isTrue);
      expect(u.esPersonalGimnasio, isFalse);
      expect(u.gimnasioNombre, 'Marfit');
      expect(u.premiumHasta, DateTime(2026, 12, 1, 10));
    });

    test('el entrenador y el admin reciben las solicitudes de ayuda', () {
      expect(Usuario.fromJson(json('entrenador')).esPersonalGimnasio, isTrue);
      expect(Usuario.fromJson(json('admin_gimnasio')).esPersonalGimnasio, isTrue);
      expect(Usuario.fromJson(json('entrenador')).esCliente, isFalse);
      expect(Usuario.fromJson(json('superadmin')).esSuperadmin, isTrue);
    });

    test('una cuenta sin gimnasio no falla', () {
      final u = Usuario.fromJson({
        'id': 5,
        'nombre': 'Nuevo',
        'email': 'nuevo@correo.cl',
        'es_premium': false,
        'premium_hasta': null,
        'rol': 'usuario',
        'gimnasio': null,
      });
      expect(u.gimnasioId, isNull);
      expect(u.esPremium, isFalse);
    });
  });

  group('Avatar', () {
    test('evoluciona en los niveles 5, 10, 20, 30 y 40', () {
      expect(tramoAvatar(1), 0);
      expect(tramoAvatar(4), 0);
      expect(tramoAvatar(5), 1);
      expect(tramoAvatar(10), 2);
      expect(tramoAvatar(20), 3);
      expect(tramoAvatar(30), 4);
      expect(tramoAvatar(40), 5);
      expect(tramoAvatar(99), 5);
    });

    test('cada etapa tiene nombre y nivel mínimo', () {
      expect(nombresTramo.length, nivelesTramo.length);
      expect(nombresTramo.last, 'Chetado');
    });
  });

  group('Ranking del gimnasio', () {
    final ranking = RankingGimnasio.fromJson({
      'gimnasio': {'id': 1, 'nombre': 'Marfit'},
      'criterio': 'Suma de los tres básicos.',
      'participantes': 12,
      'top': [
        {
          'usuario_id': 7, 'nombre': 'Beto', 'banca': 128.5, 'sentadilla': 175,
          'peso_muerto': 198, 'puntaje': 501.5, 'posicion': 1, 'nivel': 14, 'es_yo': false,
        },
        {
          'usuario_id': 3, 'nombre': 'Ana', 'banca': 93.5, 'sentadilla': 116.5,
          'peso_muerto': 132, 'puntaje': 342, 'posicion': 2, 'nivel': 9, 'es_yo': true,
        },
      ],
      'yo': {
        'usuario_id': 3, 'nombre': 'Ana', 'banca': 93.5, 'sentadilla': 116.5,
        'peso_muerto': 132, 'puntaje': 342, 'posicion': 2,
      },
    });

    test('lee el Top y la posición propia', () {
      expect(ranking.gimnasio, 'Marfit');
      expect(ranking.top.length, 2);
      expect(ranking.top.first.puntaje, 501.5);
      expect(ranking.top[1].esYo, isTrue);
      expect(ranking.yo!.posicion, 2);
      expect(ranking.yo!.pesoMuerto, 132);
    });

    test('un socio sin marcas no tiene posición', () {
      final yo = MiPuestoRanking.fromJson({
        'posicion': null, 'puntaje': 0, 'banca': 0, 'sentadilla': 0, 'peso_muerto': 0,
      });
      expect(yo.posicion, isNull);
    });

    test('distingue si subió, bajó o mantuvo su puesto', () {
      final subio = CambioRanking.fromJson({
        'aplica': true, 'cambio': 'subio', 'antes': 4, 'ahora': 2, 'mensaje': 'Subiste',
      });
      final bajo = CambioRanking.fromJson({
        'aplica': true, 'cambio': 'bajo', 'antes': 1, 'ahora': 2, 'mensaje': 'Bajaste',
      });
      final sinGimnasio = CambioRanking.fromJson({
        'aplica': false, 'cambio': 'no_aplica', 'mensaje': null,
      });
      expect(subio.subio, isTrue);
      expect(subio.bajo, isFalse);
      expect(bajo.bajo, isTrue);
      expect(sinGimnasio.aplica, isFalse);
      expect(sinGimnasio.mensaje, isNull);
    });
  });

  group('Ayuda de un entrenador', () {
    Map<String, dynamic> solicitud(String estado) => {
      'id': 9,
      'motivo': 'tecnica',
      'motivo_texto': 'Técnica de un ejercicio',
      'ejercicio': 'Sentadilla',
      'mensaje': 'Estoy en el rack 2',
      'estado': estado,
      'creada_en': '2026-11-09 19:30:00',
      'atendida_en': estado == 'atendida' ? '2026-11-09 19:34:00' : null,
      'entrenador': estado == 'atendida' ? 'Coach' : null,
      'socio': 'Ana',
    };

    test('una solicitud nueva queda pendiente', () {
      final s = SolicitudAyuda.fromJson(solicitud('pendiente'));
      expect(s.pendiente, isTrue);
      expect(s.atendida, isFalse);
      expect(s.atendidaEn, isNull);
      expect(s.ejercicio, 'Sentadilla');
    });

    test('una solicitud atendida guarda quién y cuándo', () {
      final s = SolicitudAyuda.fromJson(solicitud('atendida'));
      expect(s.atendida, isTrue);
      expect(s.entrenador, 'Coach');
      expect(s.atendidaEn, DateTime(2026, 11, 9, 19, 34));
    });

    test('la bandeja del entrenador separa pendientes y atendidas', () {
      final b = BandejaAyuda.fromJson({
        'gimnasio': {'id': 1, 'nombre': 'Marfit'},
        'pendientes': [solicitud('pendiente')],
        'atendidas_hoy': [solicitud('atendida'), solicitud('atendida')],
        'ultimo_id': 9,
      });
      expect(b.pendientes.length, 1);
      expect(b.atendidasHoy.length, 2);
      expect(b.ultimoId, 9);
    });

    test('el socio sin solicitud activa puede pedir ayuda', () {
      final m = MisSolicitudesAyuda.fromJson({
        'puede_pedir': true,
        'gimnasio': 'Marfit',
        'motivos': [
          {'codigo': 'tecnica', 'texto': 'Técnica de un ejercicio'},
          {'codigo': 'otro', 'texto': 'Otro'},
        ],
        'activa': null,
        'solicitudes': [solicitud('atendida')],
      });
      expect(m.puedePedir, isTrue);
      expect(m.activa, isNull);
      expect(m.motivos.length, 2);
    });
  });

  group('Evolución por ejercicio', () {
    test('calcula cuánto subió el peso desde el primer día', () {
      final e = EvolucionEjercicio.fromJson({
        'ejercicios': [
          {'id': 3, 'nombre': 'Press banca', 'grupo_muscular': 'Pecho', 'dias': 2},
        ],
        'ejercicio_id': 3,
        'puntos': [
          {'fecha': '2026-10-01', 'peso_max': 60, 'marca': 70, 'series': 4, 'volumen': 1920},
          {'fecha': '2026-11-01', 'peso_max': 72.5, 'marca': 84.5, 'series': 4, 'volumen': 2320},
        ],
        'resumen': {
          'dias': 2, 'peso_inicial': 60, 'peso_actual': 72.5,
          'mejor_peso': 72.5, 'mejor_marca': 84.5, 'diferencia': 12.5,
        },
      });
      expect(e.puntos.length, 2);
      expect(e.diferencia, 12.5);
      expect(e.mejorMarca, 84.5);
      expect(e.puntos.first.fecha, DateTime(2026, 10, 1));
    });

    test('sin ejercicio elegido no hay puntos ni resumen', () {
      final e = EvolucionEjercicio.fromJson({
        'ejercicios': [], 'ejercicio_id': null, 'puntos': [], 'resumen': null,
      });
      expect(e.puntos, isEmpty);
      expect(e.mejorPeso, isNull);
      expect(e.diferencia, 0);
    });
  });

  group('Panel del gimnasio', () {
    test('incluye entrenadores y solicitudes pendientes', () {
      final p = PanelGimnasio.fromJson({
        'gimnasio': {'id': 1, 'nombre': 'Marfit', 'direccion': null, 'miembros_premium': 1},
        'miembros': [],
        'entrenadores': [
          {'id': 4, 'nombre': 'Coach', 'email': 'coach@marfit.cl'},
        ],
        'ayuda_pendiente': 2,
        'meses_permitidos': [1, 3, 6, 12],
      });
      expect(p.entrenadores.single.nombre, 'Coach');
      expect(p.ayudaPendiente, 2);
      expect(p.mesesPermitidos, [1, 3, 6, 12]);
    });
  });

  group('Chat de ayuda', () {
    test('separa mis mensajes de los del entrenador y cuenta los sin leer', () {
      final chat = ChatAyuda.fromJson({
        'solicitud': {
          'id': 9, 'motivo': 'consulta', 'motivo_texto': 'Consulta (pagos, horarios u otra duda)',
          'ejercicio': null, 'mensaje': '¿Hasta qué día pago?', 'estado': 'pendiente',
          'creada_en': '2026-11-12 20:00:00', 'atendida_en': null, 'entrenador': null,
          'socio': 'Ana', 'mensajes_chat': 2, 'sin_leer_socio': 1, 'sin_leer_entrenador': 0,
        },
        'soy_el_socio': true,
        'puede_escribir': true,
        'mensajes': [
          {'id': 1, 'texto': 'Hasta el 5 de cada mes', 'autor': 'Coach', 'es_mio': false,
           'del_socio': false, 'creado_en': '2026-11-12 20:01:00', 'leido': true},
          {'id': 2, 'texto': 'Gracias', 'autor': 'Ana', 'es_mio': true,
           'del_socio': true, 'creado_en': '2026-11-12 20:02:00', 'leido': false},
        ],
      });
      expect(chat.soyElSocio, isTrue);
      expect(chat.puedeEscribir, isTrue);
      expect(chat.solicitud.sinLeerSocio, 1);
      expect(chat.mensajes.where((m) => m.esMio).single.texto, 'Gracias');
      expect(chat.mensajes.first.delSocio, isFalse);
    });
  });
}
