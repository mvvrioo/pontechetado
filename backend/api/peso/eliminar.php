<?php
// POST /api/peso/eliminar.php   (requiere token)
// Body: { "id": 12 }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$id      = entero(leer_json(), 'id');

// El "AND usuario_id = ?" evita que alguien borre registros de otro usuario
$stmt = $conn->prepare("DELETE FROM registros_peso WHERE id = ? AND usuario_id = ?");
$stmt->bind_param("ii", $id, $usuario['id']);
$stmt->execute();

if ($stmt->affected_rows === 0) {
    error_json("Registro no encontrado", 404);
}

responder(["mensaje" => "Registro eliminado"]);
