<?php
// GET /api/peso/listar.php   (requiere token)
// Devuelve los registros de peso del usuario, del más antiguo al más nuevo.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

$stmt = $conn->prepare(
    "SELECT id, peso_kg, fecha, nota
       FROM registros_peso
      WHERE usuario_id = ?
      ORDER BY fecha ASC, id ASC"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$resultado = $stmt->get_result();

$registros = [];
while ($fila = $resultado->fetch_assoc()) {
    $registros[] = [
        "id"      => (int)$fila['id'],
        "peso_kg" => (float)$fila['peso_kg'],
        "fecha"   => $fila['fecha'],
        "nota"    => $fila['nota'],
    ];
}

responder(["registros" => $registros]);
