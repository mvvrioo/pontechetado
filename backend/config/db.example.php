<?php
// =====================================================================
//  Conexión a MySQL (XAMPP)
//  👉 Cambia $password por la contraseña de tu usuario root.
// =====================================================================

$host     = "127.0.0.1";
$user     = "root";
$password = "2103";
$dbname   = "pontechetado";
$port     = 3306;

// Hace que cualquier error de MySQL lance una excepción (más fácil de manejar)
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($host, $user, $password, $dbname, $port);
    $conn->set_charset("utf8mb4");
} catch (mysqli_sql_exception $e) {
    http_response_code(500);
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode([
        "ok"      => false,
        "mensaje" => "No se pudo conectar a la base de datos",
    ]);
    exit;
}
