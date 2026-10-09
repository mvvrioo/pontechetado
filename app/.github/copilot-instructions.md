# Ponte Chetado – App de gimnasio

## Arquitectura
- App: Flutter (Android e iOS). Código en `lib/`.
- Backend: PHP + MySQL en XAMPP, carpeta `C:\xampp\htdocs\PonteChetado`.
  La app se comunica SOLO por HTTP con la API (`lib/services/api_service.dart`).
  Nunca conectar Flutter directo a MySQL.
- Base de datos: `pontechetado` (tablas: usuarios, tokens, ejercicios, rutinas,
  rutina_ejercicios, registros_peso, codigos_premium).

## Reglas de la API (PHP)
- Un archivo por endpoint en `api/<modulo>/<accion>.php`.
- Todo endpoint empieza con `require_once __DIR__ . '/../../config/helpers.php';`
- Responder siempre con `responder([...])` o `error_json("mensaje", codigo)`.
- Endpoints con sesión usan `$usuario = usuario_actual($conn);`
- SIEMPRE consultas preparadas (`$conn->prepare` + `bind_param`). Nunca concatenar datos del usuario en SQL.
- Filtrar siempre por `usuario_id` para que nadie vea ni modifique datos de otro.
- Las reglas Premium se validan en el servidor con `es_premium($usuario)`.
  Si falta Premium: `error_json("...", 403, ["requiere_premium" => true])`.

## Reglas de la app (Flutter)
- Textos de la interfaz en español.
- Llamadas HTTP solo dentro de `ApiService`; las pantallas usan `ApiService.instance`.
- Modelos en `lib/models.dart` con `fromJson`.
- Errores: `mostrarError(context, e)` (ya muestra el aviso Premium si corresponde).
- Después de cada `await` en un State, revisar `if (!mounted) return;` antes de usar `context`.
- Pantallas en `lib/screens/`, un archivo por pantalla.
