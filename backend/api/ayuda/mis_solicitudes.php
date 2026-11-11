<?php
// GET /api/ayuda/mis_solicitudes.php   (requiere token)
// Últimas solicitudes de ayuda del socio, la más reciente primero.
// "activa" es la pendiente (si hay) para mostrarla destacada en la app.
require_once __DIR__ . '/_comun.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

$stmt = $conn->prepare(SELECT_SOLICITUD . " WHERE s.usuario_id = ? ORDER BY s.id DESC LIMIT 10");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$resultado = $stmt->get_result();

$solicitudes = [];
$activa = null;
while ($fila = $resultado->fetch_assoc()) {
    $s = solicitud_publica($fila);
    if ($s['estado'] === 'pendiente' && $activa === null) {
        $activa = $s;
    }
    $solicitudes[] = $s;
}

$motivos = [];
foreach (MOTIVOS_AYUDA as $codigo => $texto) {
    $motivos[] = ["codigo" => $codigo, "texto" => $texto];
}

responder([
    "puede_pedir" => ($usuario['rol'] ?? '') === ROL_USUARIO && $usuario['gimnasio_id'] !== null && es_premium($usuario),
    "gimnasio"    => $usuario['gimnasio_nombre'],
    "motivos"     => $motivos,
    "activa"      => $activa,
    "solicitudes" => $solicitudes,
]);
