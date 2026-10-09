<?php
// POST /api/rutinas/quitar_ejercicio.php   (requiere token)
// Body: { "id": 17 }   <- el "id" del ejercicio DENTRO de la rutina
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$id      = entero(leer_json(), 'id');

// Solo borra si la rutina pertenece al usuario
$stmt = $conn->prepare(
    "DELETE re FROM rutina_ejercicios re
       JOIN rutinas r ON r.id = re.rutina_id
      WHERE re.id = ? AND r.usuario_id = ?"
);
$stmt->bind_param("ii", $id, $usuario['id']);
$stmt->execute();

if ($stmt->affected_rows === 0) {
    error_json("Ejercicio no encontrado en tus rutinas", 404);
}

responder(["mensaje" => "Ejercicio quitado de la rutina"]);
