<?php
// POST /api/rutinas/usar_basica.php   (requiere token)
// Body: { "clave": "full_body", "dia_semana": 1 (opcional) }
// Copia una rutina básica a "mis rutinas" para poder entrenarla y editarla (H003).
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario    = usuario_actual($conn);
$datos      = leer_json();
$clave      = texto($datos, 'clave', 40);
$dia_semana = leer_dia_semana($datos);

$basica = null;
foreach (rutinas_basicas($conn) as $r) {
    if ($r['clave'] === $clave) {
        $basica = $r;
        break;
    }
}
if ($basica === null) {
    error_json("Esa rutina básica no existe", 404);
}

// El plan gratis mantiene su límite de rutinas
if (!es_premium($usuario)) {
    $stmt = $conn->prepare("SELECT COUNT(*) AS total FROM rutinas WHERE usuario_id = ?");
    $stmt->bind_param("i", $usuario['id']);
    $stmt->execute();
    if ((int)$stmt->get_result()->fetch_assoc()['total'] >= LIMITE_RUTINAS_GRATIS) {
        error_json(
            "El plan gratis permite hasta " . LIMITE_RUTINAS_GRATIS . " rutinas. Elimina una o hazte Premium.",
            403,
            ["requiere_premium" => true]
        );
    }
}

$conn->begin_transaction();

$stmt = $conn->prepare("INSERT INTO rutinas (usuario_id, nombre, descripcion, dia_semana) VALUES (?, ?, ?, ?)");
$stmt->bind_param("issi", $usuario['id'], $basica['nombre'], $basica['descripcion'], $dia_semana);
$stmt->execute();
$rutina_id = $stmt->insert_id;

$stmt = $conn->prepare(
    "INSERT INTO rutina_ejercicios (rutina_id, ejercicio_id, series, repeticiones, orden) VALUES (?, ?, ?, ?, ?)"
);
foreach ($basica['ejercicios'] as $i => $e) {
    $stmt->bind_param("iiiii", $rutina_id, $e['ejercicio_id'], $e['series'], $e['repeticiones'], $i);
    $stmt->execute();
}

$conn->commit();

responder([
    "mensaje" => "\"{$basica['nombre']}\" quedó en tus rutinas",
    "rutina"  => [
        "id"               => $rutina_id,
        "nombre"           => $basica['nombre'],
        "descripcion"      => $basica['descripcion'],
        "dia_semana"       => $dia_semana,
        "total_ejercicios" => count($basica['ejercicios']),
    ],
], 201);
