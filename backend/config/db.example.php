<?php
// =====================================================================
//  Conexión a MySQL
//  - Con XAMPP usa los valores de abajo (127.0.0.1, root, tu contraseña).
//  - Con Docker, docker-compose.yml entrega los datos por variables de
//    entorno (DB_HOST, DB_USER, ...) y estas tienen prioridad.
//  Copia este archivo como db.php y pon la contraseña de tu root de MySQL.
// =====================================================================

$host     = getenv('DB_HOST') ?: "127.0.0.1";
$user     = getenv('DB_USER') ?: "root";
$password = getenv('DB_PASSWORD') !== false ? getenv('DB_PASSWORD') : "";
$dbname   = getenv('DB_NAME') ?: "pontechetado";
$port     = (int)(getenv('DB_PORT') ?: 3306);

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
