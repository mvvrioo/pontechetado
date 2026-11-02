<?php
// POST /api/chatbot/borrar.php   (requiere token)
// Borra la conversación del usuario con el chatbot.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$stmt = $conn->prepare("DELETE FROM chat_mensajes WHERE usuario_id = ?");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();

responder(["mensaje" => "Conversación borrada"]);
