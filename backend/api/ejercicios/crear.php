<?php
// POST /api/ejercicios/crear.php   (requiere token)
// Body: { "nombre": "...", "grupo_muscular": "..." }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos = leer_json();

$nombre = trim((string)($datos['nombre'] ?? ''));
$grupo_muscular = trim((string)($datos['grupo_muscular'] ?? ''));

if ($nombre === '') {
    error_json("El nombre del ejercicio no puede estar vacío");
}

if ($grupo_muscular === '') {
    error_json("El grupo muscular es obligatorio");
}

$nombre = mb_substr($nombre, 0, 100);
$grupo_muscular = mb_substr($grupo_muscular, 0, 50);

$stmt = $conn->prepare(
    "SELECT id FROM ejercicios WHERE nombre = ? AND usuario_id = ?"
);
$stmt->bind_param("si", $nombre, $usuario['id']);
$stmt->execute();

if ($stmt->get_result()->fetch_assoc()) {
    error_json("Ya tienes un ejercicio con ese nombre", 409);
}

$stmt = $conn->prepare(
    "INSERT INTO ejercicios (nombre, grupo_muscular, descripcion, es_premium, usuario_id)
      VALUES (?, ?, NULL, 0, ?)"
);
$stmt->bind_param("ssi", $nombre, $grupo_muscular, $usuario['id']);
$stmt->execute();

$ejercicio_id = (int)$conn->insert_id;

$responder([
    "ejercicio" => [
        "id"             => $ejercicio_id,
        "nombre"         => $nombre,
        "grupo_muscular" => $grupo_muscular,
        "descripcion"    => null,
        "es_premium"     => false,
        "personalizado"  => true,
    ],
]);
