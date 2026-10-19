<?php
// =====================================================================
//  Funciones compartidas por todos los endpoints de la API.
//  Cada archivo de /api empieza con:  require_once __DIR__ . '/../../config/helpers.php';
// =====================================================================

// No mostrar warnings de PHP en la respuesta (romperían el JSON).
// Mientras desarrollas, los errores igual quedan en el log de Apache.
ini_set('display_errors', '0');
error_reporting(E_ALL);

// XAMPP viene con la hora de Alemania por defecto: usamos la de Chile
// para que "hoy" y los días de la semana calcen con el teléfono.
date_default_timezone_set('America/Santiago');

// Si algo explota (por ejemplo un error de SQL), responder JSON en vez de una página de error.
set_exception_handler(function (Throwable $e) {
    error_log("[PonteChetado] " . $e->getMessage());
    http_response_code(500);
    echo json_encode(["ok" => false, "mensaje" => "Error interno del servidor"]);
});

// ---------- Cabeceras (CORS + JSON) ----------
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

// El navegador (Flutter web / Chrome) manda primero un OPTIONS: respondemos y listo.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/db.php';

// ---------- Límites del plan gratis ----------
const LIMITE_RUTINAS_GRATIS = 3;
const LIMITE_EJERCICIOS_POR_RUTINA_GRATIS = 6;
const DIAS_SESION = 30;

// Columnas del usuario que usan login, perfil, etc. (u = usuarios, g = gimnasios)
const CAMPOS_USUARIO = "u.id, u.nombre, u.email, u.premium_hasta, u.rol, u.gimnasio_id, g.nombre AS gimnasio_nombre";

// ---------- Respuestas ----------
function responder(array $datos, int $codigo = 200): void
{
    http_response_code($codigo);
    echo json_encode(["ok" => true] + $datos, JSON_UNESCAPED_UNICODE);
    exit;
}

function error_json(string $mensaje, int $codigo = 400, array $extra = []): void
{
    http_response_code($codigo);
    echo json_encode(["ok" => false, "mensaje" => $mensaje] + $extra, JSON_UNESCAPED_UNICODE);
    exit;
}

// ---------- Entrada ----------
function requerir_metodo(string $metodo): void
{
    if ($_SERVER['REQUEST_METHOD'] !== $metodo) {
        error_json("Método no permitido. Usa $metodo.", 405);
    }
}

// Lee el cuerpo JSON que manda Flutter
function leer_json(): array
{
    $datos = json_decode(file_get_contents('php://input'), true);
    return is_array($datos) ? $datos : [];
}

function texto(array $datos, string $campo, int $max = 255): string
{
    $valor = trim((string)($datos[$campo] ?? ''));
    return mb_substr($valor, 0, $max);
}

function entero(array $datos, string $campo): int
{
    return (int)($datos[$campo] ?? 0);
}

// ---------- Autenticación ----------
function obtener_token(): ?string
{
    $cabecera = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';

    if ($cabecera === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $nombre => $valor) {
            if (strtolower($nombre) === 'authorization') {
                $cabecera = $valor;
                break;
            }
        }
    }

    if (preg_match('/Bearer\s+([a-f0-9]{64})/i', $cabecera, $m)) {
        return $m[1];
    }
    return null;
}

// Devuelve el usuario dueño del token, o corta con 401 si no hay sesión válida.
function usuario_actual(mysqli $conn): array
{
    $token = obtener_token();
    if ($token === null) {
        error_json("Debes iniciar sesión", 401);
    }

    $hash = hash('sha256', $token);
    $stmt = $conn->prepare(
        "SELECT " . CAMPOS_USUARIO . ", u.creado_en
           FROM tokens t
           JOIN usuarios u ON u.id = t.usuario_id
           LEFT JOIN gimnasios g ON g.id = u.gimnasio_id
          WHERE t.token_hash = ? AND t.expira_en > NOW()"
    );
    $stmt->bind_param("s", $hash);
    $stmt->execute();
    $usuario = $stmt->get_result()->fetch_assoc();

    if (!$usuario) {
        error_json("Tu sesión expiró, vuelve a iniciar sesión", 401);
    }

    $usuario['id'] = (int)$usuario['id'];
    $usuario['gimnasio_id'] = $usuario['gimnasio_id'] === null ? null : (int)$usuario['gimnasio_id'];
    return $usuario;
}

function es_premium(array $usuario): bool
{
    // El equipo PonteChetado (superadmin) tiene todo desbloqueado para probar la app
    if (($usuario['rol'] ?? '') === 'superadmin') {
        return true;
    }
    return !empty($usuario['premium_hasta'])
        && strtotime($usuario['premium_hasta']) > time();
}

function crear_token(mysqli $conn, int $usuario_id): string
{
    $token = bin2hex(random_bytes(32));          // 64 caracteres
    $hash  = hash('sha256', $token);
    $dias  = DIAS_SESION;

    $stmt = $conn->prepare(
        "INSERT INTO tokens (usuario_id, token_hash, expira_en)
         VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))"
    );
    $stmt->bind_param("isi", $usuario_id, $hash, $dias);
    $stmt->execute();

    return $token;
}

// Busca una rutina y verifica que sea del usuario. Si no, corta con 404.
function rutina_del_usuario(mysqli $conn, int $rutina_id, int $usuario_id): array
{
    $stmt = $conn->prepare("SELECT id, nombre, descripcion, dia_semana, creado_en FROM rutinas WHERE id = ? AND usuario_id = ?");
    $stmt->bind_param("ii", $rutina_id, $usuario_id);
    $stmt->execute();
    $rutina = $stmt->get_result()->fetch_assoc();

    if (!$rutina) {
        error_json("Rutina no encontrada", 404);
    }
    $rutina['id'] = (int)$rutina['id'];
    return $rutina;
}

// Datos del usuario que se mandan a la app (nunca el password_hash)
function usuario_publico(array $u): array
{
    $gimnasio = null;
    if (!empty($u['gimnasio_id'])) {
        $gimnasio = [
            "id"     => (int)$u['gimnasio_id'],
            "nombre" => $u['gimnasio_nombre'] ?? null,
        ];
    }

    return [
        "id"            => (int)$u['id'],
        "nombre"        => $u['nombre'],
        "email"         => $u['email'],
        "es_premium"    => es_premium($u),
        "premium_hasta" => $u['premium_hasta'],
        "rol"           => $u['rol'] ?? 'usuario',
        "gimnasio"      => $gimnasio,
    ];
}

// Busca un usuario por id con los mismos campos que usuario_actual()
function buscar_usuario(mysqli $conn, int $id): ?array
{
    $stmt = $conn->prepare(
        "SELECT " . CAMPOS_USUARIO . "
           FROM usuarios u
           LEFT JOIN gimnasios g ON g.id = u.gimnasio_id
          WHERE u.id = ?"
    );
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $u = $stmt->get_result()->fetch_assoc();
    return $u ?: null;
}

// =====================================================================
//  Roles y gimnasios
// =====================================================================
const ROL_USUARIO    = 'usuario';
const ROL_ADMIN_GYM  = 'admin_gimnasio';
const ROL_SUPERADMIN = 'superadmin';

// Duraciones de Premium que puede elegir el admin del gimnasio (en meses)
const MESES_PREMIUM_PERMITIDOS = [1, 3, 6, 12];

function es_superadmin(array $usuario): bool
{
    return ($usuario['rol'] ?? '') === ROL_SUPERADMIN;
}

function requerir_superadmin(array $usuario): void
{
    if (!es_superadmin($usuario)) {
        error_json("Solo el equipo de PonteChetado puede hacer esto", 403);
    }
}

// Devuelve el gimnasio que este usuario puede administrar.
//  - admin_gimnasio: siempre el suyo (ignora lo que mande la app).
//  - superadmin: el que pida en "gimnasio_id" (puede administrar cualquiera).
//  - usuario normal: 403.
function gimnasio_administrado(mysqli $conn, array $usuario, int $gimnasio_pedido = 0): array
{
    if (($usuario['rol'] ?? '') === ROL_ADMIN_GYM) {
        $gimnasio_id = (int)$usuario['gimnasio_id'];
    } elseif (es_superadmin($usuario)) {
        $gimnasio_id = $gimnasio_pedido;
    } else {
        error_json("No tienes permisos de administrador de gimnasio", 403);
    }

    $stmt = $conn->prepare("SELECT id, nombre, direccion FROM gimnasios WHERE id = ?");
    $stmt->bind_param("i", $gimnasio_id);
    $stmt->execute();
    $gimnasio = $stmt->get_result()->fetch_assoc();

    if (!$gimnasio) {
        error_json("Gimnasio no encontrado", 404);
    }
    $gimnasio['id'] = (int)$gimnasio['id'];
    return $gimnasio;
}

// =====================================================================
//  Gamificación: XP y niveles
// ---------------------------------------------------------------------
//  XP de un día de entrenamiento =
//      2 XP por cada serie (máximo 30 series por día)
//    + 1 XP por cada 250 kg de volumen (peso × repeticiones)
//  Cada serie cuenta como máximo 2.000 kg de volumen (evita trampas
//  como "1000 kg × 300 reps").
//
//  Ejemplos de un día típico:
//    Novato     (15 series, ~4.000 kg)  -> 30 + 16 = 46 XP
//    Intermedio (18 series, ~8.000 kg)  -> 36 + 32 = 68 XP
//    Avanzado   (20 series, ~12.000 kg) -> 40 + 48 = 88 XP
//
//  Niveles: subir del nivel N al N+1 cuesta 100 + 50·(N-1) XP
//    Nivel 2 = 100 XP, nivel 3 = +150, nivel 4 = +200 ...
//  Entrenando 3-4 veces por semana: ~nivel 4 al mes, ~13 a los 6 meses,
//  ~20 al año y ~33 a los dos años.
// =====================================================================
const XP_POR_SERIE           = 2;
const XP_MAX_SERIES_POR_DIA  = 30;
const XP_KG_POR_PUNTO        = 250;
const XP_TOPE_VOLUMEN_SERIE  = 2000;
const XP_NIVEL_BASE          = 100;
const XP_NIVEL_INCREMENTO    = 50;

function xp_de_dia(int $series, float $volumen_topado): int
{
    return XP_POR_SERIE * min($series, XP_MAX_SERIES_POR_DIA)
        + (int)floor($volumen_topado / XP_KG_POR_PUNTO);
}

// Resumen por día de todo el historial del usuario (fecha => datos)
function dias_entrenados(mysqli $conn, int $usuario_id): array
{
    $tope = XP_TOPE_VOLUMEN_SERIE;
    $stmt = $conn->prepare(
        "SELECT DATE_FORMAT(fecha, '%Y-%m-%d') AS fecha,
                COUNT(*) AS series,
                COALESCE(SUM(peso_kg * repeticiones), 0) AS volumen,
                COALESCE(SUM(LEAST(peso_kg * repeticiones, ?)), 0) AS volumen_topado
           FROM series_entrenamiento
          WHERE usuario_id = ?
          GROUP BY DATE_FORMAT(fecha, '%Y-%m-%d')
          ORDER BY fecha ASC"
    );
    $stmt->bind_param("di", $tope, $usuario_id);
    $stmt->execute();
    $resultado = $stmt->get_result();

    $dias = [];
    while ($fila = $resultado->fetch_assoc()) {
        $series = (int)$fila['series'];
        $dias[$fila['fecha']] = [
            "fecha"   => $fila['fecha'],
            "series"  => $series,
            "volumen" => (float)$fila['volumen'],
            "xp"      => xp_de_dia($series, (float)$fila['volumen_topado']),
        ];
    }
    return $dias;
}

function xp_total(mysqli $conn, int $usuario_id): int
{
    $total = 0;
    foreach (dias_entrenados($conn, $usuario_id) as $dia) {
        $total += $dia['xp'];
    }
    return $total;
}

function xp_para_subir(int $nivel): int
{
    return XP_NIVEL_BASE + XP_NIVEL_INCREMENTO * ($nivel - 1);
}

function titulo_nivel(int $nivel): string
{
    if ($nivel >= 40) return "Chetado";
    if ($nivel >= 30) return "Élite";
    if ($nivel >= 20) return "Avanzado";
    if ($nivel >= 10) return "Intermedio";
    if ($nivel >= 5)  return "En progreso";
    return "Novato";
}

// A partir de la XP total calcula nivel, XP dentro del nivel y cuánto falta
function info_nivel(int $xp_total): array
{
    $nivel = 1;
    $restante = $xp_total;
    while ($restante >= xp_para_subir($nivel)) {
        $restante -= xp_para_subir($nivel);
        $nivel++;
    }

    return [
        "xp_total"          => $xp_total,
        "nivel"             => $nivel,
        "titulo"            => titulo_nivel($nivel),
        "xp_en_nivel"       => $restante,
        "xp_para_siguiente" => xp_para_subir($nivel),
    ];
}

const NOMBRES_DIAS = [1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles', 4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado', 7 => 'Domingo'];

// Lee "dia_semana" del JSON: 1..7 o null (sin día). Corta con 400 si viene algo raro.
function leer_dia_semana(array $datos): ?int
{
    if (!array_key_exists('dia_semana', $datos) || $datos['dia_semana'] === null || $datos['dia_semana'] === '') {
        return null;
    }
    $dia = (int)$datos['dia_semana'];
    if ($dia < 1 || $dia > 7) {
        error_json("El día debe ser de 1 (lunes) a 7 (domingo)");
    }
    return $dia;
}
