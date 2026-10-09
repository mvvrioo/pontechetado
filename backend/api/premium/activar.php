<?php
// POST /api/premium/activar.php   (requiere token)
// Body: { "codigo": "CHETADO-PRUEBA-01" }
// Canjea un código premium. Si el usuario ya es premium, se suman los días.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$codigo  = strtoupper(texto(leer_json(), 'codigo', 40));

if ($codigo === '') {
    error_json("Ingresa un código");
}

// Transacción + FOR UPDATE: evita que dos personas canjeen el mismo código a la vez
$conn->begin_transaction();

$stmt = $conn->prepare("SELECT id, dias, usado_por FROM codigos_premium WHERE codigo = ? FOR UPDATE");
$stmt->bind_param("s", $codigo);
$stmt->execute();
$fila = $stmt->get_result()->fetch_assoc();

if (!$fila) {
    $conn->rollback();
    error_json("Código no válido", 404);
}
if ($fila['usado_por'] !== null) {
    $conn->rollback();
    error_json("Este código ya fue usado", 409);
}

$dias = (int)$fila['dias'];

// Si ya es premium, extiende desde la fecha de vencimiento; si no, desde hoy.
$stmt = $conn->prepare(
    "UPDATE usuarios
        SET premium_hasta = DATE_ADD(GREATEST(COALESCE(premium_hasta, NOW()), NOW()), INTERVAL ? DAY)
      WHERE id = ?"
);
$stmt->bind_param("ii", $dias, $usuario['id']);
$stmt->execute();

$stmt = $conn->prepare("UPDATE codigos_premium SET usado_por = ?, usado_en = NOW() WHERE id = ?");
$stmt->bind_param("ii", $usuario['id'], $fila['id']);
$stmt->execute();

$conn->commit();

// Devolver el usuario actualizado
$stmt = $conn->prepare("SELECT id, nombre, email, premium_hasta FROM usuarios WHERE id = ?");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();

responder([
    "mensaje" => "¡Premium activado por $dias días! 💪",
    "usuario" => usuario_publico($stmt->get_result()->fetch_assoc()),
]);
