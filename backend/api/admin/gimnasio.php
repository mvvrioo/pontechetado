<?php
// GET /api/admin/gimnasio.php   (requiere token de admin de gimnasio o superadmin)
//     El superadmin agrega ?gimnasio_id=2 para ver cualquier gimnasio.
// Devuelve los datos del gimnasio, sus miembros (Premium activos primero)
// y sus entrenadores.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario  = usuario_actual($conn);
$gimnasio = gimnasio_administrado($conn, $usuario, (int)($_GET['gimnasio_id'] ?? 0));

$stmt = $conn->prepare(
    "SELECT id, nombre, email, premium_hasta
       FROM usuarios
      WHERE gimnasio_id = ? AND rol = 'usuario'
      ORDER BY (premium_hasta > NOW()) DESC, premium_hasta DESC, nombre ASC"
);
$stmt->bind_param("i", $gimnasio['id']);
$stmt->execute();
$resultado = $stmt->get_result();

$miembros = [];
$activos  = 0;
while ($fila = $resultado->fetch_assoc()) {
    $premium = es_premium($fila);
    if ($premium) $activos++;

    $miembros[] = [
        "id"            => (int)$fila['id'],
        "nombre"        => $fila['nombre'],
        "email"         => $fila['email'],
        "es_premium"    => $premium,
        "premium_hasta" => $fila['premium_hasta'],
    ];
}

// Entrenadores del gimnasio (reciben las solicitudes de ayuda)
$stmt = $conn->prepare(
    "SELECT id, nombre, email FROM usuarios WHERE gimnasio_id = ? AND rol = 'entrenador' ORDER BY nombre"
);
$stmt->bind_param("i", $gimnasio['id']);
$stmt->execute();
$entrenadores = [];
foreach ($stmt->get_result()->fetch_all(MYSQLI_ASSOC) as $e) {
    $entrenadores[] = ["id" => (int)$e['id'], "nombre" => $e['nombre'], "email" => $e['email']];
}

$stmt = $conn->prepare("SELECT COUNT(*) FROM solicitudes_ayuda WHERE gimnasio_id = ? AND estado = 'pendiente'");
$stmt->bind_param("i", $gimnasio['id']);
$stmt->execute();
$ayuda_pendiente = (int)$stmt->get_result()->fetch_row()[0];

responder([
    "gimnasio" => [
        "id"               => $gimnasio['id'],
        "nombre"           => $gimnasio['nombre'],
        "direccion"        => $gimnasio['direccion'],
        "miembros_premium" => $activos,
    ],
    "miembros"        => $miembros,
    "entrenadores"    => $entrenadores,
    "ayuda_pendiente" => $ayuda_pendiente,
    "meses_permitidos" => MESES_PREMIUM_PERMITIDOS,
]);
