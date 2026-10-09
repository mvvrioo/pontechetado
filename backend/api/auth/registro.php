<?php
// POST /api/auth/registro.php
// Body: { "nombre": "...", "email": "...", "password": "..." }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$datos    = leer_json();
$nombre   = texto($datos, 'nombre', 80);
$email    = strtolower(texto($datos, 'email', 120));
$password = (string)($datos['password'] ?? '');

if ($nombre === '' || $email === '' || $password === '') {
    error_json("Completa nombre, email y contraseña");
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_json("El email no es válido");
}
if (strlen($password) < 8) {
    error_json("La contraseña debe tener al menos 8 caracteres");
}

// ¿Ya existe?
$stmt = $conn->prepare("SELECT id FROM usuarios WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
if ($stmt->get_result()->fetch_assoc()) {
    error_json("Ese email ya está registrado", 409);
}

$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $conn->prepare("INSERT INTO usuarios (nombre, email, password_hash) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $nombre, $email, $hash);
$stmt->execute();
$id = $stmt->insert_id;

$token = crear_token($conn, $id);

responder([
    "token"   => $token,
    "usuario" => usuario_publico([
        "id" => $id, "nombre" => $nombre, "email" => $email, "premium_hasta" => null,
    ]),
], 201);
