<?php
// POST /api/rutinas/generar.php   (requiere token, solo Premium)
// Body: { "objetivo": "fuerza", "dias": [1, 3, 5] }   1 = lunes ... 7 = domingo
//
// Crea una rutina por cada día elegido según el objetivo, usando las
// plantillas de la base de datos. Si el usuario ya tenía rutinas generadas,
// se reemplazan; las rutinas que creó él a mano no se tocan.
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('POST');

$usuario = usuario_actual($conn);
if (!es_premium($usuario)) {
    error_json("Las rutinas personalizadas son una función Premium.", 403, ["requiere_premium" => true]);
}

$datos  = leer_json();
$codigo = texto($datos, 'objetivo', 20);

// ---- Validar días ----
$dias = $datos['dias'] ?? null;
if (!is_array($dias)) {
    error_json("Elige los días que vas a entrenar");
}
$dias = array_values(array_unique(array_map('intval', $dias)));
sort($dias);
foreach ($dias as $d) {
    if ($d < 1 || $d > 7) {
        error_json("Los días deben ir de 1 (lunes) a 7 (domingo)");
    }
}
if (count($dias) < DIAS_RUTINA_MIN || count($dias) > DIAS_RUTINA_MAX) {
    error_json("Elige entre " . DIAS_RUTINA_MIN . " y " . DIAS_RUTINA_MAX . " días de entrenamiento a la semana");
}

// ---- Objetivo ----
$stmt = $conn->prepare("SELECT id, codigo, nombre, indicaciones FROM objetivos WHERE codigo = ?");
$stmt->bind_param("s", $codigo);
$stmt->execute();
$objetivo = $stmt->get_result()->fetch_assoc();
if (!$objetivo) {
    error_json("Elige un objetivo válido", 404);
}
$objetivo_id = (int)$objetivo['id'];

// ---- Qué sesión toca cada día ----
$cantidad = count($dias);
$stmt = $conn->prepare(
    "SELECT d.orden, p.id AS plantilla_id, p.nombre
       FROM divisiones_objetivo d
       JOIN plantillas_rutina p ON p.id = d.plantilla_id
      WHERE d.objetivo_id = ? AND d.dias_por_semana = ?
      ORDER BY d.orden ASC"
);
$stmt->bind_param("ii", $objetivo_id, $cantidad);
$stmt->execute();
$sesiones = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
if (count($sesiones) !== $cantidad) {
    error_json("No hay una rutina configurada para $cantidad días con ese objetivo", 500);
}

// ---- Crear las rutinas (todo o nada) ----
$conn->begin_transaction();

// Reemplazar las rutinas generadas antes (primero sus ejercicios, después las rutinas)
$stmt = $conn->prepare(
    "DELETE re FROM rutina_ejercicios re
       JOIN rutinas r ON r.id = re.rutina_id
      WHERE r.usuario_id = ? AND r.generada = 1"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();

$stmt = $conn->prepare("DELETE FROM rutinas WHERE usuario_id = ? AND generada = 1");
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();

$insRutina = $conn->prepare(
    "INSERT INTO rutinas (usuario_id, nombre, descripcion, dia_semana, generada) VALUES (?, ?, ?, ?, 1)"
);
$insEjercicios = $conn->prepare(
    "INSERT INTO rutina_ejercicios (rutina_id, ejercicio_id, series, repeticiones, peso_kg, orden)
     SELECT ?, ejercicio_id, series, repeticiones, NULL, orden
       FROM plantilla_ejercicios
      WHERE plantilla_id = ?
      ORDER BY orden"
);

$creadas = [];
foreach ($sesiones as $i => $sesion) {
    $dia         = $dias[$i];
    $nombre      = mb_substr($sesion['nombre'] . " · " . $objetivo['nombre'], 0, 100);
    $descripcion = mb_substr("Rutina personalizada. " . $objetivo['indicaciones'], 0, 255);

    $insRutina->bind_param("issi", $usuario['id'], $nombre, $descripcion, $dia);
    $insRutina->execute();
    $rutina_id = (int)$conn->insert_id;

    $plantilla_id = (int)$sesion['plantilla_id'];
    $insEjercicios->bind_param("ii", $rutina_id, $plantilla_id);
    $insEjercicios->execute();

    $creadas[] = [
        "id"               => $rutina_id,
        "nombre"           => $nombre,
        "dia_semana"       => $dia,
        "total_ejercicios" => $insEjercicios->affected_rows,
    ];
}

// Guardar lo que eligió, para mostrarlo la próxima vez
$diasTexto = implode(',', $dias);
$stmt = $conn->prepare(
    "INSERT INTO perfiles_entrenamiento (usuario_id, objetivo_id, dias) VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE objetivo_id = VALUES(objetivo_id), dias = VALUES(dias), actualizado_en = NOW()"
);
$stmt->bind_param("iis", $usuario['id'], $objetivo_id, $diasTexto);
$stmt->execute();

$conn->commit();

responder([
    "mensaje" => "¡Listo! Tu rutina de " . mb_strtolower($objetivo['nombre']) . " para $cantidad días quedó creada",
    "rutinas" => $creadas,
], 201);
