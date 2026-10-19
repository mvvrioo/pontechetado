<?php
// POST /api/superadmin/asignar_admin.php   (requiere token de superadmin)
// Body: { "gimnasio_id": 1, "email": "pedrito@marfit.cl",
//         "nombre": "Pedrito (solo si la cuenta no existe)",
//         "password": "(solo si la cuenta no existe)" }
//
// - Si la cuenta ya existe: pasa a ser admin de ese gimnasio.
// - Si no existe: se crea con el nombre y contraseña que le asignan ustedes.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
requerir_superadmin($usuario);

$datos       = leer_json();
$gimnasio    = gimnasio_administrado($conn, $usuario, entero($datos, 'gimnasio_id'));
$email       = strtolower(texto($datos, 'email', 120));
$nombre      = texto($datos, 'nombre', 80);
$password    = (string)($datos['password'] ?? '');

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_json("Escribe un correo válido");
}

$stmt = $conn->prepare("SELECT id, nombre, rol FROM usuarios WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$existente = $stmt->get_result()->fetch_assoc();

if ($existente) {
    if ($existente['rol'] === ROL_SUPERADMIN) {
        error_json("Esa cuenta es superadmin; no se puede convertir en admin de gimnasio", 409);
    }
    // Un admin no usa Premium de cliente: se limpia para no contarlo como miembro
    $stmt = $conn->prepare(
        "UPDATE usuarios SET rol = 'admin_gimnasio', gimnasio_id = ?, premium_hasta = NULL WHERE id = ?"
    );
    $stmt->bind_param("ii", $gimnasio['id'], $existente['id']);
    $stmt->execute();

    responder([
        "mensaje" => "{$existente['nombre']} ahora es admin de {$gimnasio['nombre']}",
        "creada"  => false,
    ]);
}

// La cuenta no existe: crearla
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
     VALUES (?, ?, ?, 'admin_gimnasio', ?)"
);
$stmt->bind_param("sssi", $nombre, $email, $hash, $gimnasio['id']);
$stmt->execute();

responder([
    "mensaje" => "Cuenta creada: $email ahora es admin de {$gimnasio['nombre']}",
    "creada"  => true,
], 201);
