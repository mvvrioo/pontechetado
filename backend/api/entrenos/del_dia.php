<?php
// GET /api/entrenos/del_dia.php?fecha=AAAA-MM-DD   (requiere token)
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$fecha = trim((string)($_GET['fecha'] ?? ''));

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

$stmt = $conn->prepare(
    "SELECT s.id, s.ejercicio_id, e.nombre, s.numero_serie, s.peso_kg, s.repeticiones,
            (s.peso_kg * s.repeticiones) AS volumen
       FROM series_entrenamiento s
       JOIN ejercicios e ON e.id = s.ejercicio_id
      WHERE s.usuario_id = ?
        AND s.fecha = ?
      ORDER BY e.nombre ASC, s.numero_serie ASC"
);
$stmt->bind_param("is", $usuario['id'], $fecha);
$stmt->execute();
$resultado = $stmt->get_result();

$ejercicios_por_id = [];
$volumen_total = 0.0;

while ($fila = $resultado->fetch_assoc()) {
    $ejercicio_id = (int)$fila['ejercicio_id'];
    $volumen = (float)$fila['volumen'];
    $volumen_total += $volumen;

    if (!isset($ejercicios_por_id[$ejercicio_id])) {
        $ejercicios_por_id[$ejercicio_id] = [
            "ejercicio_id" => $ejercicio_id,
            "nombre"       => $fila['nombre'],
            "volumen"      => 0.0,
            "series"       => [],
        ];
    }

    $ejercicios_por_id[$ejercicio_id]['series'][] = [
        "id"            => (int)$fila['id'],
        "numero_serie" => (int)$fila['numero_serie'],
        "peso_kg"      => (float)$fila['peso_kg'],
        "repeticiones" => (int)$fila['repeticiones'],
        "volumen"      => $volumen,
    ];
    $ejercicios_por_id[$ejercicio_id]['volumen'] += $volumen;
}

$ejercicios = [];
foreach ($ejercicios_por_id as $grupo) {
    $ejercicios[] = [
        "ejercicio_id" => $grupo['ejercicio_id'],
        "nombre"       => $grupo['nombre'],
        "volumen"      => (float)$grupo['volumen'],
        "series"       => $grupo['series'],
    ];
}

responder([
    "fecha"        => $fecha,
    "volumen_total" => (float)$volumen_total,
    "ejercicios"   => $ejercicios,
]);
