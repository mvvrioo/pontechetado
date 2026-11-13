<?php
// POST /api/ayuda/enviar_mensaje.php   (requiere token)
// Body: { "id": 5, "texto": "¿Hasta qué día puedo pagar la mensualidad?" }
//
// Escribe en el chat de una solicitud de ayuda pendiente. Pueden escribir
// el socio que la pidió y los entrenadores / admin de su gimnasio.
require_once __DIR__ . '/_comun.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos = leer_json();
$id = entero($datos, 'id');
$texto = texto($datos, 'texto', MAX_MENSAJE_CHAT);

[$solicitud, $es_socio] = acceso_solicitud($conn, $usuario, $id);

if ($texto === '') {
    error_json("Escribe un mensaje");
}
if ($solicitud['estado'] !== 'pendiente') {
    error_json(
        $solicitud['estado'] === 'atendida'
            ? "Esta solicitud ya fue atendida. Si necesitas algo más, pide ayuda de nuevo."
            : "Esta solicitud fue cancelada",
        409
    );
}

$stmt = $conn->prepare("INSERT INTO mensajes_ayuda (solicitud_id, usuario_id, texto) VALUES (?, ?, ?)");
$stmt->bind_param("iis", $id, $usuario['id'], $texto);
$stmt->execute();
$mensaje_id = $conn->insert_id;

responder([
    "mensaje" => [
        "id"        => $mensaje_id,
        "texto"     => $texto,
        "autor"     => $usuario['nombre'],
        "es_mio"    => true,
        "del_socio" => $es_socio,
        "creado_en" => date('Y-m-d H:i:s'),
        "leido"     => false,
    ],
], 201);
