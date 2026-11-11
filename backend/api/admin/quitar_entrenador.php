<?php
// POST /api/admin/quitar_entrenador.php   (requiere token de admin de gimnasio o superadmin)
// Body: { "usuario_id": 7, "gimnasio_id": 2 (solo superadmin) }
// La cuenta vuelve a ser de socio normal (sus datos se mantienen).
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$admin    = usuario_actual($conn);
$datos    = leer_json();
$gimnasio = gimnasio_administrado($conn, $admin, entero($datos, 'gimnasio_id'));
$id       = entero($datos, 'usuario_id');

// Si tiene Premium vigente se queda como socio del gimnasio; si no, queda sin gimnasio
$stmt = $conn->prepare(
    "UPDATE usuarios
        SET rol = 'usuario',
            gimnasio_id = IF(premium_hasta > NOW(), gimnasio_id, NULL)
      WHERE id = ? AND rol = 'entrenador' AND gimnasio_id = ?"
);
$stmt->bind_param("ii", $id, $gimnasio['id']);
$stmt->execute();

if ($stmt->affected_rows === 0) {
    error_json("Ese entrenador no pertenece a este gimnasio", 404);
}
responder(["mensaje" => "Entrenador quitado de {$gimnasio['nombre']}"]);
