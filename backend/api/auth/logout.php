<?php
// POST /api/auth/logout.php   (requiere token)
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$token = obtener_token();
if ($token !== null) {
    $hash = hash('sha256', $token);
    $stmt = $conn->prepare("DELETE FROM tokens WHERE token_hash = ?");
    $stmt->bind_param("s", $hash);
    $stmt->execute();
}

responder(["mensaje" => "Sesión cerrada"]);
