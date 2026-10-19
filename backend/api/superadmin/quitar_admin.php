<?php
// POST /api/superadmin/quitar_admin.php   (requiere token de superadmin)
// Body: { "usuario_id": 7 }
// La cuenta vuelve a ser un usuario normal (sin gimnasio).
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
requerir_superadmin($usuario);

$id = entero(leer_json(), 'usuario_id');

$stmt = $conn->prepare(
    "UPDATE usuarios SET rol = 'usuario', gimnasio_id = NULL WHERE id = ? AND rol = 'admin_gimnasio'"
);
$stmt->bind_param("i", $id);
$stmt->execute();

if ($stmt->affected_rows === 0) {
    error_json("Ese usuario no es admin de un gimnasio", 404);
}

responder(["mensaje" => "Admin quitado"]);
