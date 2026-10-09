<?php
// POST /api/auth/login.php
// Body: { "email": "...", "password": "..." }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$datos    = leer_json();
$email    = strtolower(texto($datos, 'email', 120));
$password = (string)($datos['password'] ?? '');

if ($email === '' || $password === '') {
    error_json("Ingresa email y contraseña");
}

$stmt = $conn->prepare("SELECT id, nombre, email, password_hash, premium_hasta FROM usuarios WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$usuario = $stmt->get_result()->fetch_assoc();

// Mismo mensaje si no existe o si la clave está mal (no revelamos cuál fue)
if (!$usuario || !password_verify($password, $usuario['password_hash'])) {
    error_json("Email o contraseña incorrectos", 401);
}

// Limpieza: borrar tokens vencidos de este usuario
$stmt = $conn->prepare("DELETE FROM tokens WHERE usuario_id = ? AND expira_en <= NOW()");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();

$token = crear_token($conn, (int)$usuario['id']);

responder([
    "token"   => $token,
    "usuario" => usuario_publico($usuario),
]);
