<?php
// GET /api/auth/perfil.php   (requiere token)
// Devuelve el usuario, si es premium y los límites de su plan.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$premium = es_premium($usuario);

$stmt = $conn->prepare("SELECT COUNT(*) AS total FROM rutinas WHERE usuario_id = ?");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$total_rutinas = (int)$stmt->get_result()->fetch_assoc()['total'];

responder([
    "usuario" => usuario_publico($usuario),
    "plan" => [
        "rutinas_usadas"                => $total_rutinas,
        "limite_rutinas"                => $premium ? null : LIMITE_RUTINAS_GRATIS,
        "limite_ejercicios_por_rutina"  => $premium ? null : LIMITE_EJERCICIOS_POR_RUTINA_GRATIS,
        "ejercicios_premium"            => $premium,
    ],
]);
