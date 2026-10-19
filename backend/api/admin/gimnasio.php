<?php
// GET /api/admin/gimnasio.php   (requiere token de admin de gimnasio o superadmin)
//     El superadmin agrega ?gimnasio_id=2 para ver cualquier gimnasio.
// Devuelve los datos del gimnasio y sus miembros (Premium activos primero).
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

responder([
    "gimnasio" => [
        "id"               => $gimnasio['id'],
        "nombre"           => $gimnasio['nombre'],
        "direccion"        => $gimnasio['direccion'],
        "miembros_premium" => $activos,
    ],
    "miembros"        => $miembros,
    "meses_permitidos" => MESES_PREMIUM_PERMITIDOS,
]);
