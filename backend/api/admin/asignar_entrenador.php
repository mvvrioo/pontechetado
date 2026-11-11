<?php
// POST /api/admin/asignar_entrenador.php   (requiere token de admin de gimnasio o superadmin)
// Body: { "email": "coach@marfit.cl", "gimnasio_id": 2 (solo superadmin),
//         "nombre": "(solo si la cuenta no existe)", "password": "(solo si la cuenta no existe)" }
//
// El admin del gimnasio agrega a sus entrenadores. Ellos reciben las
// solicitudes de ayuda de los socios (Historias 014 y 015).
//  - Si la cuenta ya existe: pasa a ser entrenador de este gimnasio.
//  - Si no existe: se crea con el nombre y contraseña que escribe el admin.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$admin    = usuario_actual($conn);
$datos    = leer_json();
$gimnasio = gimnasio_administrado($conn, $admin, entero($datos, 'gimnasio_id'));
$email    = strtolower(texto($datos, 'email', 120));
$nombre   = texto($datos, 'nombre', 80);
$password = (string)($datos['password'] ?? '');

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_json("Escribe un correo válido");
}

$stmt = $conn->prepare(
    "SELECT u.id, u.nombre, u.rol, u.gimnasio_id, g.nombre AS gimnasio_nombre
       FROM usuarios u LEFT JOIN gimnasios g ON g.id = u.gimnasio_id
      WHERE u.email = ?"
);
$stmt->bind_param("s", $email);
$stmt->execute();
$existente = $stmt->get_result()->fetch_assoc();

if ($existente) {
    if ($existente['rol'] === ROL_SUPERADMIN || $existente['rol'] === ROL_ADMIN_GYM) {
        error_json("Esa cuenta es de un administrador; no se puede convertir en entrenador", 409);
    }
    if ($existente['rol'] === ROL_ENTRENADOR && (int)$existente['gimnasio_id'] !== $gimnasio['id']) {
        error_json("{$existente['nombre']} ya es entrenador de {$existente['gimnasio_nombre']}", 409);
    }
    $stmt = $conn->prepare("UPDATE usuarios SET rol = 'entrenador', gimnasio_id = ? WHERE id = ?");
    $stmt->bind_param("ii", $gimnasio['id'], $existente['id']);
    $stmt->execute();

    responder([
        "mensaje" => "{$existente['nombre']} ahora es entrenador de {$gimnasio['nombre']}",
        "creada"  => false,
    ]);
}

if ($nombre === '' || strlen($password) < 8) {
    error_json(
        "Esa cuenta no existe todavía. Para crearla escribe también un nombre y una contraseña de al menos 8 caracteres.",
        422,
        ["requiere_datos_cuenta" => true]
    );
}

$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $conn->prepare(
    "INSERT INTO usuarios (nombre, email, password_hash, rol, gimnasio_id)
     VALUES (?, ?, ?, 'entrenador', ?)"
);
$stmt->bind_param("sssi", $nombre, $email, $hash, $gimnasio['id']);
$stmt->execute();

responder([
    "mensaje" => "Cuenta creada: $email ahora es entrenador de {$gimnasio['nombre']}",
    "creada"  => true,
], 201);
