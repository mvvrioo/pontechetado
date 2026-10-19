<?php
// POST /api/admin/quitar_premium.php   (requiere token de admin de gimnasio o superadmin)
// Body: { "usuario_id": 15, "gimnasio_id": 2 (solo superadmin) }
// Para cuando el cliente deja de pagar antes de que venza su Premium.
// El cliente sigue asociado al gimnasio, pero vuelve al plan gratis.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$admin      = usuario_actual($conn);
$datos      = leer_json();
$gimnasio   = gimnasio_administrado($conn, $admin, entero($datos, 'gimnasio_id'));
$usuario_id = entero($datos, 'usuario_id');

// Solo puede tocar clientes de SU gimnasio
$stmt = $conn->prepare("SELECT id FROM usuarios WHERE id = ? AND gimnasio_id = ? AND rol = 'usuario'");
$stmt->bind_param("ii", $usuario_id, $gimnasio['id']);
$stmt->execute();
if (!$stmt->get_result()->fetch_assoc()) {
    error_json("Ese cliente no es miembro de {$gimnasio['nombre']}", 404);
}

$stmt = $conn->prepare("UPDATE usuarios SET premium_hasta = NULL WHERE id = ?");
$stmt->bind_param("i", $usuario_id);
$stmt->execute();

$stmt = $conn->prepare(
    "INSERT INTO historial_premium (usuario_id, gimnasio_id, admin_id, accion, dias)
     VALUES (?, ?, ?, 'quitar', NULL)"
);
$stmt->bind_param("iii", $usuario_id, $gimnasio['id'], $admin['id']);
$stmt->execute();

responder(["mensaje" => "Premium desactivado"]);
