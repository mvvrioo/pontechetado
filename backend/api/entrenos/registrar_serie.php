<?php
// POST /api/entrenos/registrar_serie.php   (requiere token)
// Body: { "ejercicio_id": 12, "fecha": "2026-10-06", "peso_kg": 25, "repeticiones": 8 }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos = leer_json();

$ejercicio_id = (int)($datos['ejercicio_id'] ?? 0);
$fecha = trim((string)($datos['fecha'] ?? ''));
$peso_kg = (float)($datos['peso_kg'] ?? 0);
$repeticiones = (int)($datos['repeticiones'] ?? 0);

if ($ejercicio_id <= 0) {
    error_json("Ejercicio inválido");
}

if ($fecha === '') {
    $fecha = date('Y-m-d');
}

if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha)) {
    error_json("La fecha debe tener formato AAAA-MM-DD");
}

$fecha_obj = DateTimeImmutable::createFromFormat('!Y-m-d', $fecha);
if ($fecha_obj === false) {
    error_json("La fecha es inválida");
}

if ($fecha_obj > new DateTimeImmutable('today')) {
    error_json("La fecha no puede ser futura", 422);
}

if ($peso_kg < 0 || $peso_kg > 1000) {
    error_json("El peso debe estar entre 0 y 1000 kg");
}

if ($repeticiones < 1 || $repeticiones > 300) {
    error_json("Las repeticiones deben estar entre 1 y 300");
}

$stmt = $conn->prepare(
    "SELECT id, nombre, es_premium, usuario_id
       FROM ejercicios
      WHERE id = ?
        AND (usuario_id IS NULL OR usuario_id = ?)"
);
$stmt->bind_param("ii", $ejercicio_id, $usuario['id']);
$stmt->execute();
$ejercicio = $stmt->get_result()->fetch_assoc();

if (!$ejercicio) {
    error_json("Ejercicio no encontrado", 404);
}

if ((int)$ejercicio['es_premium'] === 1 && !es_premium($usuario)) {
    error_json("Este ejercicio requiere Premium", 403, ["requiere_premium" => true]);
}

$stmt = $conn->prepare(
    "SELECT COALESCE(MAX(numero_serie), 0) + 1 AS siguiente
       FROM series_entrenamiento
      WHERE usuario_id = ?
        AND ejercicio_id = ?
        AND fecha = ?"
);
$stmt->bind_param("iis", $usuario['id'], $ejercicio_id, $fecha);
$stmt->execute();
$siguiente = $stmt->get_result()->fetch_assoc();
$numero_serie = (int)($siguiente['siguiente'] ?? 1);

$stmt = $conn->prepare(
    "INSERT INTO series_entrenamiento (usuario_id, ejercicio_id, fecha, numero_serie, peso_kg, repeticiones)
      VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param("iisidi", $usuario['id'], $ejercicio_id, $fecha, $numero_serie, $peso_kg, $repeticiones);
$stmt->execute();

$serie_id = (int)$conn->insert_id;

$stmt = $conn->prepare(
    "SELECT id, usuario_id, ejercicio_id, fecha, numero_serie, peso_kg, repeticiones,
            (peso_kg * repeticiones) AS volumen
       FROM series_entrenamiento
      WHERE id = ? AND usuario_id = ?"
);
$stmt->bind_param("ii", $serie_id, $usuario['id']);
$stmt->execute();
$serie = $stmt->get_result()->fetch_assoc();

if (!$serie) {
    error_json("No se pudo recuperar la serie creada", 500);
}

$serie['id'] = (int)$serie['id'];
$serie['usuario_id'] = (int)$serie['usuario_id'];
$serie['ejercicio_id'] = (int)$serie['ejercicio_id'];
$serie['numero_serie'] = (int)$serie['numero_serie'];
$serie['peso_kg'] = (float)$serie['peso_kg'];
$serie['repeticiones'] = (int)$serie['repeticiones'];
$serie['volumen'] = (float)$serie['volumen'];

responder(["serie" => $serie]);
