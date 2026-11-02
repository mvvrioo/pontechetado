<?php
// GET /api/chatbot/historial.php   (requiere token)
// Últimos 100 mensajes de la conversación del usuario + preguntas sugeridas.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

$stmt = $conn->prepare(
    "SELECT id, rol, texto, creado_en FROM (
        SELECT id, rol, texto, creado_en FROM chat_mensajes
         WHERE usuario_id = ? ORDER BY id DESC LIMIT 100
     ) ultimos ORDER BY id ASC"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$res = $stmt->get_result();

$mensajes = [];
while ($fila = $res->fetch_assoc()) {
    $mensajes[] = [
        "id"        => (int)$fila['id'],
        "rol"       => $fila['rol'],
        "texto"     => $fila['texto'],
        "creado_en" => $fila['creado_en'],
    ];
}

responder([
    "es_premium"  => es_premium($usuario),
    "mensajes"    => $mensajes,
    "sugerencias" => sugerencias_chatbot($conn),
]);
