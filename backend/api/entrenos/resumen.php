<?php
// GET /api/entrenos/resumen.php?dias=30   (requiere token)
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$dias = (int)($_GET['dias'] ?? 30);

if ($dias < 1) {
    $dias = 1;
}

if ($dias > 365) {
    $dias = 365;
}

$fecha_hoy = new DateTimeImmutable('today');
$fecha_inicio = $fecha_hoy->modify('-' . ($dias - 1) . ' days')->format('Y-m-d');
$fecha_fin = $fecha_hoy->format('Y-m-d');

$stmt = $conn->prepare(
    "SELECT DATE(fecha) AS fecha, COALESCE(SUM(peso_kg * repeticiones), 0) AS volumen
       FROM series_entrenamiento
      WHERE usuario_id = ?
        AND fecha BETWEEN ? AND ?
      GROUP BY DATE(fecha)"
);
$stmt->bind_param("iss", $usuario['id'], $fecha_inicio, $fecha_fin);
$stmt->execute();
$resultado = $stmt->get_result();

$volumen_por_fecha = [];
while ($fila = $resultado->fetch_assoc()) {
    $volumen_por_fecha[$fila['fecha']] = (float)$fila['volumen'];
}

$periodo = [];
$cursor = new DateTimeImmutable($fecha_inicio);
for ($i = 0; $i < $dias; $i++) {
    $fecha = $cursor->format('Y-m-d');
    $periodo[] = [
        "fecha"   => $fecha,
        "volumen" => (float)($volumen_por_fecha[$fecha] ?? 0.0),
    ];
    $cursor = $cursor->modify('+1 day');
}

responder(["dias" => $periodo]);
