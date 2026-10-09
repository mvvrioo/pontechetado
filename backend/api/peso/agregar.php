<?php
// POST /api/peso/agregar.php   (requiere token)
// Body: { "peso_kg": 78.5, "fecha": "2026-10-06", "nota": "opcional" }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos   = leer_json();

$peso  = (float)($datos['peso_kg'] ?? 0);
$fecha = texto($datos, 'fecha', 10);
$nota  = texto($datos, 'nota', 255);

if ($peso < 20 || $peso > 400) {
    error_json("Ingresa un peso válido (entre 20 y 400 kg)");
}

if ($fecha === '') {
    $fecha = date('Y-m-d');
}
$d = DateTime::createFromFormat('Y-m-d', $fecha);
if (!$d || $d->format('Y-m-d') !== $fecha) {
    error_json("La fecha debe tener formato AAAA-MM-DD");
}
if ($fecha > date('Y-m-d')) {
    error_json("La fecha no puede ser futura");
}

$nota_db = $nota === '' ? null : $nota;
$stmt = $conn->prepare("INSERT INTO registros_peso (usuario_id, peso_kg, fecha, nota) VALUES (?, ?, ?, ?)");
$stmt->bind_param("idss", $usuario['id'], $peso, $fecha, $nota_db);
$stmt->execute();

responder([
    "registro" => [
        "id"      => $stmt->insert_id,
        "peso_kg" => $peso,
        "fecha"   => $fecha,
        "nota"    => $nota_db,
    ],
], 201);
