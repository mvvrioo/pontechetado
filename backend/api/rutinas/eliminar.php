<?php
// POST /api/rutinas/eliminar.php   (requiere token)
// Body: { "id": 5 }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$rutina  = rutina_del_usuario($conn, entero(leer_json(), 'id'), $usuario['id']);

// Los ejercicios de la rutina se borran solos (ON DELETE CASCADE)
$stmt = $conn->prepare("DELETE FROM rutinas WHERE id = ?");
$stmt->bind_param("i", $rutina['id']);
$stmt->execute();

responder(["mensaje" => "Rutina eliminada"]);
