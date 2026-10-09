<?php
// =====================================================================
//  Funciones compartidas por todos los endpoints de la API.
//  Cada archivo de /api empieza con:  require_once __DIR__ . '/../../config/helpers.php';
// =====================================================================

// No mostrar warnings de PHP en la respuesta (romperían el JSON).
// Mientras desarrollas, los errores igual quedan en el log de Apache.
ini_set('display_errors', '0');
error_reporting(E_ALL);

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
        "SELECT u.id, u.nombre, u.email, u.premium_hasta, u.creado_en
           FROM tokens t
           JOIN usuarios u ON u.id = t.usuario_id
          WHERE t.token_hash = ? AND t.expira_en > NOW()"
    );
    $stmt->bind_param("s", $hash);
    $stmt->execute();
    $usuario = $stmt->get_result()->fetch_assoc();

    if (!$usuario) {
        error_json("Tu sesión expiró, vuelve a iniciar sesión", 401);
    }

    $usuario['id'] = (int)$usuario['id'];
    return $usuario;
}

function es_premium(array $usuario): bool
{
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
    $stmt = $conn->prepare("SELECT id, nombre, descripcion, creado_en FROM rutinas WHERE id = ? AND usuario_id = ?");
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
    return [
        "id"            => (int)$u['id'],
        "nombre"        => $u['nombre'],
        "email"         => $u['email'],
        "es_premium"    => es_premium($u),
        "premium_hasta" => $u['premium_hasta'],
    ];
}
