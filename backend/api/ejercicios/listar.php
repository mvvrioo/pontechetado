<?php
// GET /api/ejercicios/listar.php   (requiere token)
// Devuelve el catálogo global + los ejercicos personalizados del usuario actual.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$premium = es_premium($usuario);

$stmt = $conn->prepare(
    "SELECT e.id, e.nombre, e.grupo_muscular, e.descripcion, e.es_premium, e.usuario_id
       FROM ejercicios e
      WHERE e.usuario_id IS NULL OR e.usuario_id = ?
      ORDER BY e.usuario_id IS NOT NULL DESC, e.grupo_muscular ASC, e.nombre ASC"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$resultado = $stmt->get_result();

$ejercicios = [];
while ($fila = $resultado->fetch_assoc()) {
    $es_premium = (bool)$fila['es_premium'];
    $personalizado = $fila['usuario_id'] !== null;

    $ejercicios[] = [
        "id"             => (int)$fila['id'],
        "nombre"         => $fila['nombre'],
        "grupo_muscular" => $fila['grupo_muscular'],
        "descripcion"    => $fila['descripcion'],
        "es_premium"     => $es_premium,
        "personalizado"  => $personalizado,
        "bloqueado"      => $es_premium && !$premium,
    ];
}

responder(["ejercicios" => $ejercicios]);
