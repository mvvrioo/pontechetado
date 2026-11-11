<?php
// GET /api/entrenos/evolucion.php                  (requiere token, solo Premium)
//     -> ejercicios que el usuario ha entrenado, el más reciente primero
// GET /api/entrenos/evolucion.php?ejercicio_id=12
//     -> además, la evolución de ese ejercicio: por cada día el mayor peso
//        levantado, la mejor marca estimada (1RM) y el volumen.
// Historia 008: ver la evolución de los pesos por ejercicio.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);
if (!es_premium($usuario)) {
    error_json("La evolución por ejercicio es una función Premium", 403, ["requiere_premium" => true]);
}

$stmt = $conn->prepare(
    "SELECT e.id, e.nombre, e.grupo_muscular,
            COUNT(DISTINCT s.fecha) AS dias, MAX(s.fecha) AS ultima
       FROM series_entrenamiento s
       JOIN ejercicios e ON e.id = s.ejercicio_id
      WHERE s.usuario_id = ?
      GROUP BY e.id, e.nombre, e.grupo_muscular
      ORDER BY ultima DESC, e.nombre ASC"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$ejercicios = [];
foreach ($stmt->get_result()->fetch_all(MYSQLI_ASSOC) as $f) {
    $ejercicios[] = [
        "id"            => (int)$f['id'],
        "nombre"        => $f['nombre'],
        "grupo_muscular" => $f['grupo_muscular'],
        "dias"          => (int)$f['dias'],
    ];
}

$ejercicio_id = (int)($_GET['ejercicio_id'] ?? 0);
if ($ejercicio_id <= 0) {
    responder(["ejercicios" => $ejercicios, "ejercicio_id" => null, "puntos" => [], "resumen" => null]);
}

$stmt = $conn->prepare(
    "SELECT DATE_FORMAT(fecha, '%Y-%m-%d') AS fecha,
            MAX(peso_kg) AS peso_max,
            MAX(CASE WHEN repeticiones <= 1 THEN peso_kg
                     WHEN repeticiones <= 12 THEN peso_kg * (1 + repeticiones / 30)
                     ELSE peso_kg END) AS marca,
            COUNT(*) AS series,
            SUM(peso_kg * repeticiones) AS volumen
       FROM series_entrenamiento
      WHERE usuario_id = ? AND ejercicio_id = ?
      GROUP BY DATE_FORMAT(fecha, '%Y-%m-%d')
      ORDER BY fecha ASC"
);
$stmt->bind_param("ii", $usuario['id'], $ejercicio_id);
$stmt->execute();

$puntos = [];
foreach ($stmt->get_result()->fetch_all(MYSQLI_ASSOC) as $f) {
    $puntos[] = [
        "fecha"    => $f['fecha'],
        "peso_max" => (float)$f['peso_max'],
        "marca"    => medio_kilo((float)$f['marca']),
        "series"   => (int)$f['series'],
        "volumen"  => (float)$f['volumen'],
    ];
}

$resumen = null;
if ($puntos) {
    $primero = $puntos[0]['peso_max'];
    $ultimo  = $puntos[count($puntos) - 1]['peso_max'];
    $resumen = [
        "dias"        => count($puntos),
        "peso_inicial" => $primero,
        "peso_actual" => $ultimo,
        "mejor_peso"  => max(array_column($puntos, 'peso_max')),
        "mejor_marca" => max(array_column($puntos, 'marca')),
        "diferencia"  => $ultimo - $primero,
    ];
}

responder(["ejercicios" => $ejercicios, "ejercicio_id" => $ejercicio_id, "puntos" => $puntos, "resumen" => $resumen]);
