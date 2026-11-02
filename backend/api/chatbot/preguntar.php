<?php
// POST /api/chatbot/preguntar.php   (requiere token, solo Premium)
// Body: { "mensaje": "¿cómo hago una sentadilla?" }
//
// El chatbot NO usa IA: busca en la tabla chatbot_respuestas la respuesta
// cuyas palabras clave calzan mejor con la pregunta (sin importar tildes ni
// mayúsculas). Si ninguna calza, responde con el mensaje de respaldo.
// La pregunta y la respuesta quedan guardadas en chat_mensajes.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
if (!es_premium($usuario)) {
    error_json("El asistente de ejercicios es una función Premium.", 403, ["requiere_premium" => true]);
}

$mensaje = texto(leer_json(), 'mensaje', 300);
if ($mensaje === '') {
    error_json("Escribe tu pregunta");
}

// ---- Buscar la mejor respuesta ----
$normal = ' ' . normalizar_texto($mensaje) . ' ';
$filas  = $conn->query(
    "SELECT id, tema, palabras_clave, respuesta, es_respaldo FROM chatbot_respuestas ORDER BY id ASC"
)->fetch_all(MYSQLI_ASSOC);

$mejor = null;
$mejorPuntaje = 0;
$respaldo = null;
foreach ($filas as $fila) {
    if ((int)$fila['es_respaldo'] === 1) {
        $respaldo = $fila;
        continue;
    }
    $puntaje = 0;
    foreach (explode(',', $fila['palabras_clave']) as $clave) {
        $clave = normalizar_texto($clave);
        if ($clave !== '' && strpos($normal, ' ' . $clave . ' ') !== false) {
            // Frases más largas = coincidencia más específica
            $puntaje += count(explode(' ', $clave));
        }
    }
    // Saludos y agradecimientos pesan menos que una pregunta real
    if (in_array($fila['tema'], ['saludo', 'gracias'], true)) {
        $puntaje *= 0.5;
    }
    if ($puntaje > $mejorPuntaje) {
        $mejorPuntaje = $puntaje;
        $mejor = $fila;
    }
}
$elegida = $mejor ?? $respaldo;
if ($elegida === null) {
    error_json("El chatbot todavía no tiene respuestas cargadas", 500);
}

// ---- Guardar la conversación ----
$stmt = $conn->prepare("INSERT INTO chat_mensajes (usuario_id, rol, texto) VALUES (?, 'usuario', ?)");
$stmt->bind_param("is", $usuario['id'], $mensaje);
$stmt->execute();
$idPregunta = (int)$conn->insert_id;

$respuestaId = (int)$elegida['id'];
$stmt = $conn->prepare(
    "INSERT INTO chat_mensajes (usuario_id, rol, texto, respuesta_id) VALUES (?, 'bot', ?, ?)"
);
$stmt->bind_param("isi", $usuario['id'], $elegida['respuesta'], $respuestaId);
$stmt->execute();
$idRespuesta = (int)$conn->insert_id;

$ahora = date('Y-m-d H:i:s');
responder([
    "pregunta"    => ["id" => $idPregunta, "rol" => "usuario", "texto" => $mensaje, "creado_en" => $ahora],
    "respuesta"   => ["id" => $idRespuesta, "rol" => "bot", "texto" => $elegida['respuesta'], "creado_en" => $ahora],
    "entendida"   => $mejor !== null,
    "sugerencias" => sugerencias_chatbot($conn, $elegida['tema']),
]);
