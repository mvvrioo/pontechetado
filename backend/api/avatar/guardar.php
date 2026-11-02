<?php
// POST /api/avatar/guardar.php   (requiere token, solo Premium)
// Body: { "genero": "femenino", "piel": 2, "peinado": 3, "color_pelo": 1, "color_ropa": 0 }
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
if (!es_premium($usuario)) {
    error_json("El avatar es una función Premium.", 403, ["requiere_premium" => true]);
}

$datos  = leer_json();
$genero = texto($datos, 'genero', 10);
if (!in_array($genero, ['masculino', 'femenino'], true)) {
    error_json("Elige masculino o femenino");
}

// Cada opción es un índice dentro de la paleta de la app
$limites = ["piel" => AVATAR_PIELES, "peinado" => AVATAR_PEINADOS, "color_pelo" => AVATAR_PELOS, "color_ropa" => AVATAR_ROPAS];
$valores = [];
foreach ($limites as $campo => $cantidad) {
    $v = entero($datos, $campo);
    if ($v < 0 || $v >= $cantidad) {
        error_json("Opción de avatar no válida: $campo");
    }
    $valores[$campo] = $v;
}

$stmt = $conn->prepare(
    "INSERT INTO avatares (usuario_id, genero, piel, peinado, color_pelo, color_ropa)
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE genero = VALUES(genero), piel = VALUES(piel), peinado = VALUES(peinado),
                             color_pelo = VALUES(color_pelo), color_ropa = VALUES(color_ropa)"
);
$stmt->bind_param(
    "isiiii",
    $usuario['id'], $genero,
    $valores['piel'], $valores['peinado'], $valores['color_pelo'], $valores['color_ropa']
);
$stmt->execute();

responder(["mensaje" => "Avatar guardado"]);
