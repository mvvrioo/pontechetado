<?php
// POST /api/ayuda/atender.php   (requiere token de entrenador, admin del gimnasio o superadmin)
// Body: { "id": 5 }   Marca la solicitud como atendida; el socio lo ve en su app.
require_once __DIR__ . '/_comun.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos   = leer_json();
$id      = entero($datos, 'id');

$stmt = $conn->prepare("SELECT gimnasio_id, estado FROM solicitudes_ayuda WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$solicitud = $stmt->get_result()->fetch_assoc();
if (!$solicitud) {
    error_json("Solicitud no encontrada", 404);
}

// Verifica que la solicitud sea del gimnasio de este entrenador
$gimnasio = gimnasio_del_personal($conn, $usuario, (int)$solicitud['gimnasio_id']);
if ($gimnasio['id'] !== (int)$solicitud['gimnasio_id']) {
    error_json("Esa solicitud es de otro gimnasio", 403);
}
if ($solicitud['estado'] !== 'pendiente') {
    error_json($solicitud['estado'] === 'cancelada' ? "El socio canceló esta solicitud" : "Esta solicitud ya fue atendida", 409);
}

$stmt = $conn->prepare(
    "UPDATE solicitudes_ayuda SET estado = 'atendida', atendida_por = ?, atendida_en = NOW()
      WHERE id = ? AND estado = 'pendiente'"
);
$stmt->bind_param("ii", $usuario['id'], $id);
$stmt->execute();

responder(["mensaje" => "Solicitud marcada como atendida"]);
