<?php
// GET /api/rutinas/listar.php   (requiere token)
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

$stmt = $conn->prepare(
    "SELECT r.id, r.nombre, r.descripcion, r.creado_en,
            COUNT(re.id) AS total_ejercicios
       FROM rutinas r
       LEFT JOIN rutina_ejercicios re ON re.rutina_id = r.id
      WHERE r.usuario_id = ?
      GROUP BY r.id
      ORDER BY r.creado_en DESC"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$resultado = $stmt->get_result();

$rutinas = [];
while ($fila = $resultado->fetch_assoc()) {
    $rutinas[] = [
        "id"               => (int)$fila['id'],
        "nombre"           => $fila['nombre'],
        "descripcion"      => $fila['descripcion'],
        "total_ejercicios" => (int)$fila['total_ejercicios'],
    ];
}

$premium = es_premium($usuario);
responder([
    "rutinas"        => $rutinas,
    "limite_rutinas" => $premium ? null : LIMITE_RUTINAS_GRATIS,
]);
