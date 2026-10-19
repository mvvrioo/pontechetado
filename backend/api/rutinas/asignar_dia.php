<?php
// POST /api/rutinas/asignar_dia.php   (requiere token)
// Body: { "id": 5, "dia_semana": 1 }   1 = lunes ... 7 = domingo, null = sin día
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
$datos   = leer_json();
$rutina  = rutina_del_usuario($conn, entero($datos, 'id'), $usuario['id']);
$dia     = leer_dia_semana($datos);

$stmt = $conn->prepare("UPDATE rutinas SET dia_semana = ? WHERE id = ?");
$stmt->bind_param("ii", $dia, $rutina['id']);
$stmt->execute();

responder([
    "mensaje" => $dia === null
        ? "\"{$rutina['nombre']}\" quedó sin día asignado"
        : "\"{$rutina['nombre']}\" asignada al " . mb_strtolower(NOMBRES_DIAS[$dia]),
]);
