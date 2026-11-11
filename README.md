# PonteChetado

## Descripción
PonteChetado es una aplicación móvil enfocada en la gestión y gamificación del entrenamiento físico.

**Qué hace:** permite a los usuarios registrar sus entrenamientos diarios, llevando un control de series, repeticiones y pesos. El gimnasio valida el pago de la membresía y con eso se desbloquea la versión Premium, que ofrece rutinas personalizadas según el objetivo, niveles y experiencia (XP), un avatar que evoluciona al subir de nivel, un chatbot de ejercicios, el ranking Top 10 del gimnasio y un botón para pedir la ayuda de un entrenador.

**A quién va dirigido:** usuarios de gimnasios que quieren entrenar con buenas rutinas sin tener conocimientos previos de fitness, y los propios gimnasios.

**Qué problema resuelve:** mejora la retención y la fidelización de los socios, le da una imagen más premium al gimnasio y alivia la carga de los entrenadores gracias al chatbot y a las solicitudes de ayuda desde la app.

## Funcionalidades

| Épica | Qué incluye |
|---|---|
| 001 Registro y funciones básicas | Cuenta gratuita, inicio y cierre de sesión, catálogo de ejercicios, rutinas y registro de series |
| 002 Validación Premium | El administrador del gimnasio activa o quita Premium con el correo del socio |
| 003 Registro de progreso | Rutina personalizada por objetivo (fuerza, hipertrofia, híbrido, salud), historial, volumen levantado y evolución de los pesos por ejercicio |
| 004 Avatar y gamificación | XP por volumen, niveles, avatar personalizable que evoluciona y chatbot de ejercicios |
| 005 Scoreboard Top 10 | Ranking de los más fuertes del gimnasio, que se recalcula al terminar el entrenamiento |
| 006 Ayuda de un profesional | El socio pide ayuda desde la app y el entrenador la recibe y la marca como atendida |

Roles: socio (gratis o Premium), entrenador, administrador del gimnasio y superadmin (equipo PonteChetado).

## Tecnologías utilizadas
- **App (frontend):** Flutter, lenguaje Dart.
- **API (backend):** PHP 8 con una API REST que responde JSON, sobre Apache.
- **Base de datos:** MySQL 8.
- **Entorno:** XAMPP para desarrollo local, o Docker (ver `README_DOCKER.md`).

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `app/` | Aplicación Flutter (`lib/screens`, `lib/widgets`, `lib/services`, `lib/models.dart`) |
| `backend/` | API REST en PHP (`api/` con los endpoints, `config/` con la conexión y funciones compartidas, `pruebas/`) |
| `base_de_datos/` | Scripts SQL |
| `Fase 1/`, `Fase 2/` | Documentación del proyecto |

## Cómo levantar el proyecto localmente

1. Clonar el repositorio.
2. **Base de datos:** abrir `base_de_datos/instalacion_completa.sql` en MySQL Workbench y ejecutarlo. Crea la base `pontechetado` con todas las tablas y el catálogo.
3. **Backend:** copiar la carpeta `backend` dentro de `C:\xampp\htdocs` con el nombre `PonteChetado`. Luego copiar `config/db.example.php` como `config/db.php` y poner la contraseña de MySQL. Encender Apache en XAMPP.
4. **App:** en la carpeta `app` ejecutar `flutter pub get` y después `flutter run -d chrome` (o en un emulador o teléfono).
5. Registrarse en la app y, para administrar gimnasios, convertirse en superadmin desde Workbench:
   `UPDATE usuarios SET rol = 'superadmin' WHERE email = 'tu@correo.cl';`

Para probar en un teléfono físico, escribir la IP del computador en `app/lib/config.dart`.

## Pruebas

| Tipo | Comando | Qué revisa |
|---|---|---|
| API (70 pruebas) | `C:\xampp\php\php.exe C:\xampp\htdocs\PonteChetado\pruebas\probar_api.php` | El flujo completo de las 15 historias contra la API real. Crea datos de prueba y los borra al terminar |
| App (20 pruebas) | `flutter test` dentro de `app/` | Modelos, formato de datos, roles, ranking y solicitudes de ayuda |
| Código | `flutter analyze` dentro de `app/` | Errores y advertencias del código Dart |

## Integrantes
Mario Torres - Desarrollador Full-Stack / Jefe de Proyecto. Responsable de la arquitectura de la solución, el desarrollo frontend y backend y la gestión del proyecto.

## Metodología
SCRUM: enfoque ágil iterativo e incremental. El proyecto se basa en un PMV y en Épicas estimadas con Poker Planning. El desarrollo se organiza en Sprints semanales para tener entregas funcionales y revisiones constantes.

## Arquitectura
El sistema usa una arquitectura cliente-servidor.

- **Capa cliente:** la app Flutter se encarga de la interfaz, captura los datos del entrenamiento y dibuja el avatar.
- **Capa servidor:** la API REST en PHP centraliza la lógica de negocio: valida las sesiones con tokens, calcula la XP y los niveles, genera las rutinas personalizadas, responde el chatbot, calcula el ranking y gestiona las solicitudes de ayuda.
- **Capa de datos:** MySQL guarda de forma persistente los usuarios, entrenamientos, rutinas, gimnasios y el estado Premium.

Cálculos principales:
- **XP de un día** = 2 XP por serie (máximo 30 series) + 1 XP por cada 250 kg de volumen. Subir del nivel N al N+1 cuesta 100 + 50 × (N − 1) XP.
- **Puntaje del ranking** = suma de la mejor marca estimada (1RM, fórmula de Epley) en press banca, sentadilla y peso muerto. Cuentan las series de 1 a 12 repeticiones.
