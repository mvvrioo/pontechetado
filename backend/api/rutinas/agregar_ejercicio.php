<?php
// POST /api/rutinas/agregar_ejercicio.php   (requiere token)
// Body: { "rutina_id": 5, "ejercicio_id": 3, "series": 4, "repeticiones": 10, "peso_kg": 40 }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$premium = es_premium($usuario);
$datos   = leer_json();

$rutina       = rutina_del_usuario($conn, entero($datos, 'rutina_id'), $usuario['id']);
$ejercicio_id = entero($datos, 'ejercicio_id');
$series       = entero($datos, 'series');
$repeticiones = entero($datos, 'repeticiones');
$peso_kg      = isset($datos['peso_kg']) && $datos['peso_kg'] !== '' ? (float)$datos['peso_kg'] : null;

if ($series < 1 || $series > 20) {
    error_json("Las series deben estar entre 1 y 20");
}
if ($repeticiones < 1 || $repeticiones > 300) {
    error_json("Las repeticiones deben estar entre 1 y 300");
}
if ($peso_kg !== null && ($peso_kg < 0 || $peso_kg > 1000)) {
    error_json("El peso debe estar entre 0 y 1000 kg");
}

// ¿Existe el ejercicio?
$stmt = $conn->prepare("SELECT id, nombre, grupo_muscular, es_premium FROM ejercicios WHERE id = ?");
$stmt->bind_param("i", $ejercicio_id);
$stmt->execute();
$ejercicio = $stmt->get_result()->fetch_assoc();
if (!$ejercicio) {
    error_json("Ejercicio no encontrado", 404);
}

// ---- VALIDACIÓN PREMIUM 1: ejercicios exclusivos ----
if ($ejercicio['es_premium'] && !$premium) {
    error_json("\"{$ejercicio['nombre']}\" es un ejercicio Premium.", 403, ["requiere_premium" => true]);
}

// ---- VALIDACIÓN PREMIUM 2: máximo de ejercicios por rutina ----
$stmt = $conn->prepare("SELECT COUNT(*) AS total, COALESCE(MAX(orden), 0) AS ultimo FROM rutina_ejercicios WHERE rutina_id = ?");
$stmt->bind_param("i", $rutina['id']);
$stmt->execute();
$conteo = $stmt->get_result()->fetch_assoc();

if (!$premium && (int)$conteo['total'] >= LIMITE_EJERCICIOS_POR_RUTINA_GRATIS) {
    error_json(
        "El plan gratis permite hasta " . LIMITE_EJERCICIOS_POR_RUTINA_GRATIS . " ejercicios por rutina.",
        403,
        ["requiere_premium" => true]
    );
}

$orden = (int)$conteo['ultimo'] + 1;
$stmt = $conn->prepare(
    "INSERT INTO rutina_ejercicios (rutina_id, ejercicio_id, series, repeticiones, peso_kg, orden)
     VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param("iiiidi", $rutina['id'], $ejercicio_id, $series, $repeticiones, $peso_kg, $orden);
$stmt->execute();

responder([
    "ejercicio" => [
        "id"             => $stmt->insert_id,
        "ejercicio_id"   => $ejercicio_id,
        "nombre"         => $ejercicio['nombre'],
        "grupo_muscular" => $ejercicio['grupo_muscular'],
        "series"         => $series,
        "repeticiones"   => $repeticiones,
        "peso_kg"        => $peso_kg,
    ],
], 201);
