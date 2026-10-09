<?php
// GET /api/rutinas/detalle.php?id=5   (requiere token)
// Devuelve la rutina con sus ejercicios.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$rutina  = rutina_del_usuario($conn, (int)($_GET['id'] ?? 0), $usuario['id']);

$stmt = $conn->prepare(
    "SELECT re.id, re.ejercicio_id, e.nombre, e.grupo_muscular,
            re.series, re.repeticiones, re.peso_kg, re.orden
       FROM rutina_ejercicios re
       JOIN ejercicios e ON e.id = re.ejercicio_id
      WHERE re.rutina_id = ?
      ORDER BY re.orden ASC, re.id ASC"
);
$stmt->bind_param("i", $rutina['id']);
$stmt->execute();
$resultado = $stmt->get_result();

$ejercicios = [];
while ($fila = $resultado->fetch_assoc()) {
    $ejercicios[] = [
        "id"             => (int)$fila['id'],          // id dentro de la rutina
        "ejercicio_id"   => (int)$fila['ejercicio_id'],
        "nombre"         => $fila['nombre'],
        "grupo_muscular" => $fila['grupo_muscular'],
        "series"         => (int)$fila['series'],
        "repeticiones"   => (int)$fila['repeticiones'],
        "peso_kg"        => $fila['peso_kg'] === null ? null : (float)$fila['peso_kg'],
    ];
}

responder([
    "rutina" => [
        "id"          => $rutina['id'],
        "nombre"      => $rutina['nombre'],
        "descripcion" => $rutina['descripcion'],
        "ejercicios"  => $ejercicios,
    ],
]);
