<?php
// POST /api/ranking/actualizar.php   (requiere token de socio)
//
// Se llama al terminar el entrenamiento (Historia 013): recalcula el
// puntaje del socio, lo compara con su último puesto guardado y le
// avisa si subió o bajó en el ranking de su gimnasio.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);

if (($usuario['rol'] ?? '') !== ROL_USUARIO || $usuario['gimnasio_id'] === null || !es_premium($usuario)) {
    // Sin gimnasio o sin Premium no hay ranking: no es un error, solo no aplica
    responder(["aplica" => false, "cambio" => "no_aplica", "mensaje" => null]);
}

$gimnasio_id = (int)$usuario['gimnasio_id'];
$gimnasio    = $usuario['gimnasio_nombre'];

$yo = null;
foreach (calcular_ranking($conn, $gimnasio_id) as $fila) {
    if ($fila['usuario_id'] === $usuario['id']) {
        $yo = $fila;
        break;
    }
}

if ($yo === null) {
    responder([
        "aplica"  => true,
        "cambio"  => "sin_marcas",
        "antes"   => null,
        "ahora"   => null,
        "puntaje" => 0,
        "mensaje" => "Registra press banca, sentadilla o peso muerto (de 1 a " . RANKING_MAX_REPS
                   . " repeticiones) para entrar al ranking de $gimnasio.",
    ]);
}

// Último puesto guardado (si cambió de gimnasio, cuenta como nuevo)
$stmt = $conn->prepare("SELECT posicion, gimnasio_id FROM ranking_posiciones WHERE usuario_id = ?");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$guardado = $stmt->get_result()->fetch_assoc();
$antes = ($guardado && (int)$guardado['gimnasio_id'] === $gimnasio_id) ? (int)$guardado['posicion'] : null;
$ahora = (int)$yo['posicion'];

$stmt = $conn->prepare(
    "INSERT INTO ranking_posiciones (usuario_id, gimnasio_id, posicion, puntaje)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE gimnasio_id = VALUES(gimnasio_id), posicion = VALUES(posicion), puntaje = VALUES(puntaje)"
);
$stmt->bind_param("iiid", $usuario['id'], $gimnasio_id, $ahora, $yo['puntaje']);
$stmt->execute();

if ($antes === null) {
    $cambio = "nuevo";
    $mensaje = "Entraste al ranking de $gimnasio en el puesto #$ahora.";
} elseif ($ahora < $antes) {
    $cambio = "subio";
    $mensaje = "Subiste del puesto #$antes al #$ahora en $gimnasio.";
} elseif ($ahora > $antes) {
    $cambio = "bajo";
    $mensaje = "Bajaste del puesto #$antes al #$ahora en $gimnasio. Otros socios subieron sus marcas.";
} else {
    $cambio = "igual";
    $mensaje = "Sigues en el puesto #$ahora de $gimnasio.";
}

responder([
    "aplica"  => true,
    "cambio"  => $cambio,
    "antes"   => $antes,
    "ahora"   => $ahora,
    "puntaje" => $yo['puntaje'],
    "mensaje" => $mensaje,
]);
