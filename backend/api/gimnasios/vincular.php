<?php
// POST /api/gimnasios/vincular.php   (requiere token de socio)
// Body: { "gimnasio_id": 2 }
//
// H005: el socio elige su gimnasio dentro de la app. El sistema revisa si ese
// gimnasio ya registró una membresía pagada con su correo:
//   - si está vigente  -> Premium activo
//   - si no            -> queda vinculado y aparece en el panel del admin,
//                         que activa el Premium cuando paga en recepción.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos   = leer_json();
$gym_id  = entero($datos, 'gimnasio_id');

if ($usuario['rol'] !== ROL_USUARIO) {
    error_json("Solo los socios pueden elegir un gimnasio", 403);
}

$stmt = $conn->prepare("SELECT id, nombre FROM gimnasios WHERE id = ?");
$stmt->bind_param("i", $gym_id);
$stmt->execute();
$gimnasio = $stmt->get_result()->fetch_assoc();
if (!$gimnasio) {
    error_json("Ese gimnasio no existe", 404);
}

$mismo = $usuario['gimnasio_id'] !== null && (int)$usuario['gimnasio_id'] === (int)$gimnasio['id'];

// No puede cambiarse de gimnasio mientras tenga Premium vigente en otro
if (!$mismo && es_premium($usuario)) {
    error_json(
        "Tienes Premium vigente en {$usuario['gimnasio_nombre']} hasta el "
            . date('d/m/Y', strtotime($usuario['premium_hasta']))
            . ". Podrás cambiarte cuando venza.",
        409
    );
}

if (!$mismo) {
    $stmt = $conn->prepare("UPDATE usuarios SET gimnasio_id = ? WHERE id = ?");
    $stmt->bind_param("ii", $gimnasio['id'], $usuario['id']);
    $stmt->execute();
}

// Verificación de la membresía: el gimnasio la registra con el correo del socio
$actualizado = buscar_usuario($conn, (int)$usuario['id']);
$premium     = es_premium($actualizado);

$mensaje = $premium
    ? "Tu membresía en {$gimnasio['nombre']} está pagada. Premium activo hasta el "
        . date('d/m/Y', strtotime($actualizado['premium_hasta'])) . "."
    : "Quedaste vinculado a {$gimnasio['nombre']}. Aún no hay una membresía pagada con tu correo: "
        . "paga en recepción y pide que la activen con {$actualizado['email']}.";

responder([
    "mensaje"    => $mensaje,
    "es_premium" => $premium,
    "usuario"    => usuario_publico($actualizado),
]);
