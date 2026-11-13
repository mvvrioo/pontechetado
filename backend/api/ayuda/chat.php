<?php
// GET /api/ayuda/chat.php?id=5   (requiere token)
//
// Conversación de una solicitud de ayuda entre el socio y los entrenadores
// de su gimnasio. Al abrirla se marcan como leídos los mensajes de la otra persona.
// Mientras la solicitud está pendiente se puede escribir; después queda como historial.
require_once __DIR__ . '/_comun.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$id = (int)($_GET['id'] ?? 0);
[$solicitud, $es_socio] = acceso_solicitud($conn, $usuario, $id);

// Marcar como leídos los mensajes del otro lado
$socio_id = (int)$solicitud['usuario_id'];
if ($es_socio) {
    $stmt = $conn->prepare(
        "UPDATE mensajes_ayuda SET leido_en = NOW()
          WHERE solicitud_id = ? AND usuario_id <> ? AND leido_en IS NULL"
    );
} else {
    $stmt = $conn->prepare(
        "UPDATE mensajes_ayuda SET leido_en = NOW()
          WHERE solicitud_id = ? AND usuario_id = ? AND leido_en IS NULL"
    );
}
$stmt->bind_param("ii", $id, $socio_id);
$stmt->execute();

$stmt = $conn->prepare(
    "SELECT m.id, m.usuario_id, m.texto, m.creado_en, m.leido_en, u.nombre
       FROM mensajes_ayuda m
       JOIN usuarios u ON u.id = m.usuario_id
      WHERE m.solicitud_id = ?
      ORDER BY m.id ASC"
);
$stmt->bind_param("i", $id);
$stmt->execute();
$mensajes = [];
foreach ($stmt->get_result()->fetch_all(MYSQLI_ASSOC) as $m) {
    $mensajes[] = [
        "id"        => (int)$m['id'],
        "texto"     => $m['texto'],
        "autor"     => $m['nombre'],
        "es_mio"    => (int)$m['usuario_id'] === $usuario['id'],
        "del_socio" => (int)$m['usuario_id'] === $socio_id,
        "creado_en" => $m['creado_en'],
        "leido"     => $m['leido_en'] !== null,
    ];
}

$stmt = $conn->prepare(SELECT_SOLICITUD . " WHERE s.id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();

responder([
    "solicitud"     => solicitud_publica($stmt->get_result()->fetch_assoc()),
    "soy_el_socio"  => $es_socio,
    "puede_escribir" => $solicitud['estado'] === 'pendiente',
    "mensajes"      => $mensajes,
]);
