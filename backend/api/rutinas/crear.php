<?php
// POST /api/rutinas/crear.php   (requiere token)
// Body: { "nombre": "Pecho y tríceps", "descripcion": "opcional" }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos   = leer_json();

$nombre      = texto($datos, 'nombre', 100);
$descripcion = texto($datos, 'descripcion', 255);

if ($nombre === '') {
    error_json("La rutina necesita un nombre");
}

// ---- VALIDACIÓN PREMIUM: límite de rutinas del plan gratis ----
if (!es_premium($usuario)) {
    $stmt = $conn->prepare("SELECT COUNT(*) AS total FROM rutinas WHERE usuario_id = ?");
    $stmt->bind_param("i", $usuario['id']);
    $stmt->execute();
    $total = (int)$stmt->get_result()->fetch_assoc()['total'];

    if ($total >= LIMITE_RUTINAS_GRATIS) {
        error_json(
            "El plan gratis permite hasta " . LIMITE_RUTINAS_GRATIS . " rutinas. Hazte Premium para crear más.",
            403,
            ["requiere_premium" => true]
        );
    }
}

$desc_db = $descripcion === '' ? null : $descripcion;
$stmt = $conn->prepare("INSERT INTO rutinas (usuario_id, nombre, descripcion) VALUES (?, ?, ?)");
$stmt->bind_param("iss", $usuario['id'], $nombre, $desc_db);
$stmt->execute();

responder([
    "rutina" => [
        "id"               => $stmt->insert_id,
        "nombre"           => $nombre,
        "descripcion"      => $desc_db,
        "total_ejercicios" => 0,
    ],
], 201);
