<?php
// GET /api/gimnasios/listar.php   (requiere token)
// Lista los gimnasios asociados a PonteChetado.
// Si quien pregunta es superadmin, también incluye los admins de cada gimnasio.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$superadmin = es_superadmin($usuario);

$resultado = $conn->query(
    "SELECT g.id, g.nombre, g.direccion,
            COUNT(CASE WHEN u.rol = 'usuario' AND u.premium_hasta > NOW() THEN 1 END) AS miembros_premium
       FROM gimnasios g
       LEFT JOIN usuarios u ON u.gimnasio_id = g.id
      GROUP BY g.id, g.nombre, g.direccion
      ORDER BY g.nombre ASC"
);

$gimnasios = [];
while ($fila = $resultado->fetch_assoc()) {
    $id = (int)$fila['id'];
    $gimnasios[$id] = [
        "id"               => $id,
        "nombre"           => $fila['nombre'],
        "direccion"        => $fila['direccion'],
        "miembros_premium" => (int)$fila['miembros_premium'],
        "es_mi_gimnasio"   => $usuario['gimnasio_id'] === $id,
    ];
    if ($superadmin) {
        $gimnasios[$id]["admins"] = [];
    }
}

if ($superadmin) {
    $admins = $conn->query(
        "SELECT id, nombre, email, gimnasio_id
           FROM usuarios
          WHERE rol = 'admin_gimnasio' AND gimnasio_id IS NOT NULL
          ORDER BY nombre ASC"
    );
    while ($a = $admins->fetch_assoc()) {
        $gid = (int)$a['gimnasio_id'];
        if (isset($gimnasios[$gid])) {
            $gimnasios[$gid]["admins"][] = [
                "id"     => (int)$a['id'],
                "nombre" => $a['nombre'],
                "email"  => $a['email'],
            ];
        }
    }
}

responder(["gimnasios" => array_values($gimnasios)]);
