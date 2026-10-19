<?php
// GET /api/gamificacion/progreso.php   (requiere token)
// Nivel, XP, la semana actual (lunes a domingo) y el historial de días entrenados.
// La gamificación es Premium: al plan gratis solo se le muestra su XP acumulada
// como "gancho" (bloqueado = true) y el historial va vacío.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
$premium = es_premium($usuario);
$uid     = $usuario['id'];

$dias = dias_entrenados($conn, $uid);   // fecha => {series, volumen, xp}, de más antiguo a más nuevo

$xp_total = 0;
$volumen_total = 0.0;
$numero = 0;
foreach ($dias as $fecha => $dia) {
    $numero++;
    $dias[$fecha]['dia_numero'] = $numero;   // "Día 1", "Día 2"... desde que empezó
    $xp_total += $dia['xp'];
    $volumen_total += $dia['volumen'];
}

// Rutinas asignadas a cada día de la semana (puede haber más de una el mismo día)
$stmt = $conn->prepare(
    "SELECT dia_semana, nombre FROM rutinas
      WHERE usuario_id = ? AND dia_semana IS NOT NULL
      ORDER BY creado_en ASC"
);
$stmt->bind_param("i", $uid);
$stmt->execute();
$res = $stmt->get_result();
$rutina_por_dia = [];
while ($fila = $res->fetch_assoc()) {
    $rutina_por_dia[(int)$fila['dia_semana']][] = $fila['nombre'];
}
$nombre_rutina = fn(int $d) => isset($rutina_por_dia[$d]) ? implode(' + ', $rutina_por_dia[$d]) : null;

// ---- Semana actual (lunes a domingo) ----
$hoy    = new DateTimeImmutable('today');
$lunes  = $hoy->modify('-' . ((int)$hoy->format('N') - 1) . ' days');
$semana = [];
$xp_semana = 0;
$entrenos_semana = 0;
for ($i = 0; $i < 7; $i++) {
    $f   = $lunes->modify("+$i days");
    $key = $f->format('Y-m-d');
    $num = $i + 1;
    $d   = $dias[$key] ?? null;

    if ($d) {
        $xp_semana += $d['xp'];
        $entrenos_semana++;
    }
    $semana[] = [
        "dia_semana" => $num,
        "nombre"     => NOMBRES_DIAS[$num],
        "fecha"      => $key,
        "es_hoy"     => $key === $hoy->format('Y-m-d'),
        "entreno"    => $d !== null,
        "xp"         => $d['xp'] ?? 0,
        "volumen"    => $d['volumen'] ?? 0.0,
        "rutina"     => $nombre_rutina($num),
    ];
}

// ---- Historial: últimos 30 días entrenados, del más nuevo al más antiguo ----
$historial = [];
if ($premium && $dias) {
    $ultimos = array_slice(array_reverse($dias, true), 0, 30, true);
    $desde   = array_key_last($ultimos);   // el más antiguo de esos 30

    // Grupos musculares trabajados cada día (ej: "Pecho · Espalda")
    $stmt = $conn->prepare(
        "SELECT DATE_FORMAT(s.fecha, '%Y-%m-%d') AS fecha,
                GROUP_CONCAT(DISTINCT e.grupo_muscular ORDER BY e.grupo_muscular SEPARATOR '|') AS grupos
           FROM series_entrenamiento s
           JOIN ejercicios e ON e.id = s.ejercicio_id
          WHERE s.usuario_id = ? AND s.fecha >= ?
          GROUP BY DATE_FORMAT(s.fecha, '%Y-%m-%d')"
    );
    $stmt->bind_param("is", $uid, $desde);
    $stmt->execute();
    $res = $stmt->get_result();
    $grupos = [];
    while ($fila = $res->fetch_assoc()) {
        $grupos[$fila['fecha']] = $fila['grupos'] === null ? [] : explode('|', $fila['grupos']);
    }

    foreach ($ultimos as $fecha => $d) {
        $num_dia = (int)(new DateTimeImmutable($fecha))->format('N');
        $historial[] = [
            "dia_numero" => $d['dia_numero'],
            "fecha"      => $fecha,
            "dia_semana" => $num_dia,
            "nombre_dia" => NOMBRES_DIAS[$num_dia],
            "series"     => $d['series'],
            "volumen"    => $d['volumen'],
            "xp"         => $d['xp'],
            "grupos"     => $grupos[$fecha] ?? [],
            "rutina"     => $nombre_rutina($num_dia),
        ];
    }
}

responder([
    "bloqueado" => !$premium,
    "nivel"     => info_nivel($xp_total),
    "estadisticas" => [
        "dias_entrenados" => count($dias),
        "volumen_total"   => $volumen_total,
        "xp_semana"       => $xp_semana,
        "entrenos_semana" => $entrenos_semana,
    ],
    "semana"    => $semana,
    "historial" => $historial,
    "reglas"    => [
        "xp_por_serie"      => XP_POR_SERIE,
        "kg_por_xp"         => XP_KG_POR_PUNTO,
        "max_series_dia"    => XP_MAX_SERIES_POR_DIA,
        "tope_volumen_serie" => XP_TOPE_VOLUMEN_SERIE,
    ],
]);
