<?php
// POST /api/admin/activar_premium.php   (requiere token de admin de gimnasio o superadmin)
// Body: { "email": "cliente@gmail.com", "meses": 1, "gimnasio_id": 2 (solo superadmin) }
//
// El cliente paga la membresía en el gimnasio -> el admin escribe su correo
// -> el cliente queda asociado al gimnasio y con Premium por X meses.
// Si ya tenía Premium vigente en ESTE gimnasio, se suman los meses (renovación).
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$admin    = usuario_actual($conn);
$datos    = leer_json();
$gimnasio = gimnasio_administrado($conn, $admin, entero($datos, 'gimnasio_id'));

$email = strtolower(texto($datos, 'email', 120));
$meses = entero($datos, 'meses');

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_json("Escribe un correo válido");
}
if (!in_array($meses, MESES_PREMIUM_PERMITIDOS, true)) {
    error_json("Elige una duración válida: " . implode(', ', MESES_PREMIUM_PERMITIDOS) . " meses");
}

$conn->begin_transaction();

$stmt = $conn->prepare(
    "SELECT u.id, u.nombre, u.email, u.rol, u.gimnasio_id, u.premium_hasta, g.nombre AS gimnasio_nombre
       FROM usuarios u
       LEFT JOIN gimnasios g ON g.id = u.gimnasio_id
      WHERE u.email = ?
      FOR UPDATE"
);
$stmt->bind_param("s", $email);
$stmt->execute();
$cliente = $stmt->get_result()->fetch_assoc();

if (!$cliente) {
    $conn->rollback();
    error_json("No existe ninguna cuenta con ese correo. Pídele al cliente que se registre primero en la app.", 404);
}
if ($cliente['rol'] !== ROL_USUARIO) {
    $conn->rollback();
    error_json("Esa cuenta es de un administrador, no de un cliente", 409);
}

$otro_gimnasio = $cliente['gimnasio_id'] !== null && (int)$cliente['gimnasio_id'] !== $gimnasio['id'];
if ($otro_gimnasio && es_premium($cliente)) {
    $conn->rollback();
    error_json(
        "{$cliente['nombre']} ya tiene Premium vigente en {$cliente['gimnasio_nombre']} hasta el "
            . date('d/m/Y', strtotime($cliente['premium_hasta'])) . ".",
        409
    );
}

$dias = $meses * 30;
$id_cliente = (int)$cliente['id'];

// Renovación: si ya es premium aquí, extiende desde su vencimiento; si no, desde hoy.
$stmt = $conn->prepare(
    "UPDATE usuarios
        SET gimnasio_id = ?,
            premium_hasta = DATE_ADD(GREATEST(COALESCE(premium_hasta, NOW()), NOW()), INTERVAL ? DAY)
      WHERE id = ?"
);
$stmt->bind_param("iii", $gimnasio['id'], $dias, $id_cliente);
$stmt->execute();

$stmt = $conn->prepare(
    "INSERT INTO historial_premium (usuario_id, gimnasio_id, admin_id, accion, dias)
     VALUES (?, ?, ?, 'activar', ?)"
);
$stmt->bind_param("iiii", $id_cliente, $gimnasio['id'], $admin['id'], $dias);
$stmt->execute();

$conn->commit();

$actualizado = buscar_usuario($conn, $id_cliente);
$hasta = date('d/m/Y', strtotime($actualizado['premium_hasta']));

responder([
    "mensaje" => "Premium activado para {$actualizado['nombre']} hasta el $hasta ✅",
    "miembro" => [
        "id"            => $id_cliente,
        "nombre"        => $actualizado['nombre'],
        "email"         => $actualizado['email'],
        "es_premium"    => true,
        "premium_hasta" => $actualizado['premium_hasta'],
    ],
]);
