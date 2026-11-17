<?php
// GET /api/rutinas/basicas.php   (requiere token)
// Rutinas básicas listas para usar. Están disponibles en el plan gratis (H003).
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

responder([
    "rutinas_basicas" => rutinas_basicas($conn),
    "es_premium"      => es_premium($usuario),
]);
