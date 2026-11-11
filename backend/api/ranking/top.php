<?php
// GET /api/ranking/top.php   (requiere token)
//     El superadmin agrega ?gimnasio_id=2 para ver el ranking de cualquier gimnasio.
//
// Top 10 de los más fuertes del gimnasio (Historia 012).
//  - Socio Premium: ve el ranking de su gimnasio y su propio puesto,
//    aunque no esté en el Top 10.
//  - Entrenador / admin del gimnasio: ve el ranking de su gimnasio.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$es_socio = ($usuario['rol'] ?? '') === ROL_USUARIO;

if ($es_socio) {
    if ($usuario['gimnasio_id'] === null) {
        error_json("Para ver el ranking necesitas estar asociado a un gimnasio", 409, ["sin_gimnasio" => true]);
    }
    if (!es_premium($usuario)) {
        error_json("El ranking del gimnasio es una función Premium", 403, ["requiere_premium" => true]);
    }
    $gimnasio = ["id" => (int)$usuario['gimnasio_id'], "nombre" => $usuario['gimnasio_nombre']];
} else {
    if (es_superadmin($usuario) && (int)($_GET['gimnasio_id'] ?? 0) <= 0) {
        error_json("Como superadmin, abre el ranking desde el panel de cada gimnasio (pestaña Gimnasios).");
    }
    $gimnasio = gimnasio_del_personal($conn, $usuario, (int)($_GET['gimnasio_id'] ?? 0));
}

$ranking = calcular_ranking($conn, $gimnasio['id']);

$top = [];
foreach (array_slice($ranking, 0, RANKING_TOP) as $fila) {
    $fila['nivel'] = info_nivel(xp_total($conn, $fila['usuario_id']))['nivel'];
    $fila['es_yo'] = $fila['usuario_id'] === $usuario['id'];
    $top[] = $fila;
}

// Mi puesto (solo socios)
$yo = null;
if ($es_socio) {
    $yo = ["posicion" => null, "puntaje" => 0, "banca" => 0, "sentadilla" => 0, "peso_muerto" => 0];
    foreach ($ranking as $fila) {
        if ($fila['usuario_id'] === $usuario['id']) {
            $yo = $fila;
            break;
        }
    }
}

responder([
    "gimnasio"      => ["id" => $gimnasio['id'], "nombre" => $gimnasio['nombre']],
    "criterio"      => "Suma de tu mejor marca estimada (1RM) en press banca, sentadilla y peso muerto. "
                     . "Cuentan las series de 1 a " . RANKING_MAX_REPS . " repeticiones.",
    "participantes" => count($ranking),
    "top"           => $top,
    "yo"            => $yo,
]);
