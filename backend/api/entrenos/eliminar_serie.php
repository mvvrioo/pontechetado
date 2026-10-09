<?php
// POST /api/entrenos/eliminar_serie.php   (requiere token)
// Body: { "id": 12 }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos = leer_json();
$id = (int)($datos['id'] ?? 0);

if ($id <= 0) {
    error_json("Id de serie inválido");
}

$stmt = $conn->prepare(
    "DELETE FROM series_entrenamiento WHERE id = ? AND usuario_id = ?"
);
$stmt->bind_param("ii", $id, $usuario['id']);
$stmt->execute();

if ($stmt->affected_rows === 0) {
    error_json("Serie no encontrada", 404);
}

responder(["mensaje" => "Serie eliminada"]);
