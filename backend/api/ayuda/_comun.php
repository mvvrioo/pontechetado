<?php
// Funciones compartidas por los endpoints de ayuda del entrenador.
require_once __DIR__ . '/../../config/helpers.php';

const MOTIVOS_AYUDA = [
    'tecnica'  => 'Técnica de un ejercicio',
    'rutina'   => 'Orientación con mi rutina',
    'maquina'  => 'Uso de una máquina',
    'consulta' => 'Consulta (pagos, horarios u otra duda)',
    'otro'     => 'Otro',
];

const MAX_MENSAJE_CHAT = 500;

// Convierte una fila de solicitudes_ayuda (con joins) al formato de la app
function solicitud_publica(array $f): array
{
    return [
        "id"                  => (int)$f['id'],
        "motivo"              => $f['motivo'],
        "motivo_texto"        => MOTIVOS_AYUDA[$f['motivo']] ?? $f['motivo'],
        "ejercicio"           => $f['ejercicio'] ?? null,
        "mensaje"             => $f['mensaje'],
        "estado"              => $f['estado'],
        "creada_en"           => $f['creada_en'],
        "atendida_en"         => $f['atendida_en'],
        "entrenador"          => $f['entrenador'] ?? null,
        "socio"               => $f['socio'] ?? null,
        // Chat: total de mensajes y los que cada lado aún no ha leído
        "mensajes_chat"       => (int)($f['mensajes_chat'] ?? 0),
        "sin_leer_socio"      => (int)($f['sin_leer_socio'] ?? 0),
        "sin_leer_entrenador" => (int)($f['sin_leer_entrenador'] ?? 0),
    ];
}

const SELECT_SOLICITUD = "SELECT s.id, s.motivo, s.mensaje, s.estado, s.creada_en, s.atendida_en,
                                 e.nombre AS ejercicio, en.nombre AS entrenador, u.nombre AS socio,
                                 (SELECT COUNT(*) FROM mensajes_ayuda m WHERE m.solicitud_id = s.id) AS mensajes_chat,
                                 (SELECT COUNT(*) FROM mensajes_ayuda m
                                   WHERE m.solicitud_id = s.id AND m.usuario_id <> s.usuario_id AND m.leido_en IS NULL) AS sin_leer_socio,
                                 (SELECT COUNT(*) FROM mensajes_ayuda m
                                   WHERE m.solicitud_id = s.id AND m.usuario_id = s.usuario_id AND m.leido_en IS NULL) AS sin_leer_entrenador
                            FROM solicitudes_ayuda s
                            JOIN usuarios u ON u.id = s.usuario_id
                            LEFT JOIN ejercicios e ON e.id = s.ejercicio_id
                            LEFT JOIN usuarios en ON en.id = s.atendida_por";

// Verifica que el usuario pueda ver el chat de esta solicitud:
// el socio que la pidió, o el personal (entrenador / admin) de ese gimnasio, o el superadmin.
// Devuelve [fila de la solicitud, es_socio_dueno].
function acceso_solicitud(mysqli $conn, array $usuario, int $id): array
{
    $stmt = $conn->prepare("SELECT id, usuario_id, gimnasio_id, estado FROM solicitudes_ayuda WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $s = $stmt->get_result()->fetch_assoc();
    if (!$s) {
        error_json("Solicitud no encontrada", 404);
    }

    if ((int)$s['usuario_id'] === $usuario['id']) {
        return [$s, true];
    }
    $rol = $usuario['rol'] ?? '';
    $es_personal = ($rol === ROL_ENTRENADOR || $rol === ROL_ADMIN_GYM)
        && (int)$usuario['gimnasio_id'] === (int)$s['gimnasio_id'];
    if ($es_personal || es_superadmin($usuario)) {
        return [$s, false];
    }
    error_json("No tienes acceso a esta conversación", 403);
}
