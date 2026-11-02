<?php
// GET /api/avatar/obtener.php   (requiere token)
// Devuelve el avatar del usuario (o null si no lo ha creado) y su nivel,
// que define cuánto ha evolucionado el avatar.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

$stmt = $conn->prepare(
    "SELECT genero, piel, peinado, color_pelo, color_ropa FROM avatares WHERE usuario_id = ?"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$fila = $stmt->get_result()->fetch_assoc();

responder([
    "es_premium" => es_premium($usuario),
    "avatar"     => $fila ? [
        "genero"     => $fila['genero'],
        "piel"       => (int)$fila['piel'],
        "peinado"    => (int)$fila['peinado'],
        "color_pelo" => (int)$fila['color_pelo'],
        "color_ropa" => (int)$fila['color_ropa'],
    ] : null,
    "nivel"      => info_nivel(xp_total($conn, $usuario['id'])),
]);
