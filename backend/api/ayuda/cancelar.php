<?php
// POST /api/ayuda/cancelar.php   (requiere token)
// Body: { "id": 5 }   El socio cancela su solicitud pendiente.
require_once __DIR__ . '/_comun.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$id = entero(leer_json(), 'id');

$stmt = $conn->prepare(
    "UPDATE solicitudes_ayuda SET estado = 'cancelada'
      WHERE id = ? AND usuario_id = ? AND estado = 'pendiente'"
);
$stmt->bind_param("ii", $id, $usuario['id']);
$stmt->execute();

if ($stmt->affected_rows === 0) {
    error_json("Esa solicitud ya no está pendiente", 404);
}
responder(["mensaje" => "Solicitud cancelada"]);
