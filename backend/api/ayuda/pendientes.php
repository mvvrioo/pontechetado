<?php
// GET /api/ayuda/pendientes.php   (requiere token de entrenador, admin del gimnasio o superadmin)
//     El superadmin agrega ?gimnasio_id=2.
//
// Bandeja del entrenador (Historia 015): solicitudes pendientes del
// gimnasio (la más antigua primero) y las atendidas hoy.
// "ultimo_id" sirve para que la app avise cuando llega una nueva.
require_once __DIR__ . '/_comun.php';
requerir_metodo('GET');

$usuario  = usuario_actual($conn);
$gimnasio = gimnasio_del_personal($conn, $usuario, (int)($_GET['gimnasio_id'] ?? 0));

$stmt = $conn->prepare(
    SELECT_SOLICITUD . " WHERE s.gimnasio_id = ? AND s.estado = 'pendiente' ORDER BY s.id ASC"
);
$stmt->bind_param("i", $gimnasio['id']);
$stmt->execute();
$pendientes = array_map('solicitud_publica', $stmt->get_result()->fetch_all(MYSQLI_ASSOC));

$stmt = $conn->prepare(
    SELECT_SOLICITUD . " WHERE s.gimnasio_id = ? AND s.estado = 'atendida' AND s.atendida_en >= CURDATE()
                         ORDER BY s.atendida_en DESC LIMIT 20"
);
$stmt->bind_param("i", $gimnasio['id']);
$stmt->execute();
$atendidas = array_map('solicitud_publica', $stmt->get_result()->fetch_all(MYSQLI_ASSOC));

$ultimo_id = 0;
foreach ($pendientes as $p) {
    $ultimo_id = max($ultimo_id, $p['id']);
}

responder([
    "gimnasio"     => ["id" => $gimnasio['id'], "nombre" => $gimnasio['nombre']],
    "pendientes"   => $pendientes,
    "atendidas_hoy" => $atendidas,
    "ultimo_id"    => $ultimo_id,
]);
