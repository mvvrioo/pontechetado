<?php
// POST /api/superadmin/crear_gimnasio.php   (requiere token de superadmin)
// Body: { "nombre": "Marfit", "direccion": "opcional" }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
requerir_superadmin($usuario);

$datos     = leer_json();
$nombre    = texto($datos, 'nombre', 100);
$direccion = texto($datos, 'direccion', 200);

if ($nombre === '') {
    error_json("El gimnasio necesita un nombre");
}

$stmt = $conn->prepare("SELECT id FROM gimnasios WHERE nombre = ?");
$stmt->bind_param("s", $nombre);
$stmt->execute();
if ($stmt->get_result()->fetch_assoc()) {
    error_json("Ya existe un gimnasio con ese nombre", 409);
}

$dir_db = $direccion === '' ? null : $direccion;
$stmt = $conn->prepare("INSERT INTO gimnasios (nombre, direccion) VALUES (?, ?)");
$stmt->bind_param("ss", $nombre, $dir_db);
$stmt->execute();

responder([
    "mensaje"  => "Gimnasio \"$nombre\" creado",
    "gimnasio" => [
        "id"               => (int)$stmt->insert_id,
        "nombre"           => $nombre,
        "direccion"        => $dir_db,
        "miembros_premium" => 0,
        "es_mi_gimnasio"   => false,
        "admins"           => [],
    ],
], 201);
