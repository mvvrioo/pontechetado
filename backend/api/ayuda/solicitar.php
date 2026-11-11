<?php
// POST /api/ayuda/solicitar.php   (requiere token de socio Premium con gimnasio)
// Body: { "motivo": "tecnica|rutina|maquina|otro", "ejercicio_id": 12 (opcional),
//         "mensaje": "Estoy en la máquina de remo, no sé regularla" (opcional) }
//
// El socio pide que un entrenador del gimnasio se acerque (Historia 014).
require_once __DIR__ . '/_comun.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
if (($usuario['rol'] ?? '') !== ROL_USUARIO) {
    error_json("Solo los socios del gimnasio pueden pedir ayuda", 403);
}
if ($usuario['gimnasio_id'] === null) {
    error_json("Para pedir ayuda necesitas estar asociado a un gimnasio", 409, ["sin_gimnasio" => true]);
}
if (!es_premium($usuario)) {
    error_json("Pedir ayuda a un entrenador es una función Premium", 403, ["requiere_premium" => true]);
}

$datos   = leer_json();
$motivo  = texto($datos, 'motivo', 20);
$mensaje = texto($datos, 'mensaje', 255);
$ejercicio_id = entero($datos, 'ejercicio_id');

if (!array_key_exists($motivo, MOTIVOS_AYUDA)) {
    error_json("Elige el motivo de tu solicitud");
}
if ($motivo === 'otro' && $mensaje === '') {
    error_json("Cuéntale al entrenador en qué te puede ayudar");
}

$ejercicio = null;
if ($ejercicio_id > 0) {
    $stmt = $conn->prepare("SELECT id FROM ejercicios WHERE id = ? AND (usuario_id IS NULL OR usuario_id = ?)");
    $stmt->bind_param("ii", $ejercicio_id, $usuario['id']);
    $stmt->execute();
    if (!$stmt->get_result()->fetch_assoc()) {
        error_json("Ejercicio no encontrado", 404);
    }
    $ejercicio = $ejercicio_id;
}

// ¿Hay alguien en el gimnasio que pueda recibir la solicitud?
$stmt = $conn->prepare(
    "SELECT COUNT(*) FROM usuarios WHERE gimnasio_id = ? AND rol IN ('entrenador', 'admin_gimnasio')"
);
$stmt->bind_param("i", $usuario['gimnasio_id']);
$stmt->execute();
if ((int)$stmt->get_result()->fetch_row()[0] === 0) {
    error_json(
        "{$usuario['gimnasio_nombre']} todavía no tiene entrenadores disponibles en la app. Acércate a recepción.",
        409,
        ["sin_entrenadores" => true]
    );
}

// Una solicitud pendiente a la vez
$stmt = $conn->prepare("SELECT id FROM solicitudes_ayuda WHERE usuario_id = ? AND estado = 'pendiente'");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
if ($stmt->get_result()->fetch_assoc()) {
    error_json("Ya tienes una solicitud pendiente. Un entrenador irá a ayudarte pronto.", 409);
}

$mensaje_db = $mensaje === '' ? null : $mensaje;
$stmt = $conn->prepare(
    "INSERT INTO solicitudes_ayuda (usuario_id, gimnasio_id, motivo, ejercicio_id, mensaje)
     VALUES (?, ?, ?, ?, ?)"
);
$stmt->bind_param("iisis", $usuario['id'], $usuario['gimnasio_id'], $motivo, $ejercicio, $mensaje_db);
$stmt->execute();
$id = $conn->insert_id;

$stmt = $conn->prepare(SELECT_SOLICITUD . " WHERE s.id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();

responder([
    "mensaje"   => "Solicitud enviada. Un entrenador de {$usuario['gimnasio_nombre']} irá a ayudarte.",
    "solicitud" => solicitud_publica($stmt->get_result()->fetch_assoc()),
], 201);
