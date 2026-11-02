<?php
// GET /api/rutinas/personalizada.php   (requiere token)
// Lo que necesita la pantalla "Rutina personalizada":
//  - los objetivos (fuerza, hipertrofia, híbrido, salud)
//  - qué sesiones tocan según cuántos días entrena (para mostrar la vista previa)
//  - el objetivo y los días que el usuario ya eligió (si los eligió)
require_once __DIR__ . '/../../config/helpers.php';
requerir_metodo('GET');

$usuario = usuario_actual($conn);

// Objetivos
$objetivos = [];
$res = $conn->query("SELECT id, codigo, nombre, descripcion, indicaciones FROM objetivos ORDER BY orden ASC, id ASC");
while ($fila = $res->fetch_assoc()) {
    $objetivos[(int)$fila['id']] = [
        "codigo"       => $fila['codigo'],
        "nombre"       => $fila['nombre'],
        "descripcion"  => $fila['descripcion'],
        "indicaciones" => $fila['indicaciones'],
        "divisiones"   => new stdClass(),   // "3" => ["Empuje", "Tirón", "Pierna A"]
    ];
}

// Sesiones de cada objetivo según días por semana
$divisiones = [];
$res = $conn->query(
    "SELECT d.objetivo_id, d.dias_por_semana, p.nombre
       FROM divisiones_objetivo d
       JOIN plantillas_rutina p ON p.id = d.plantilla_id
      ORDER BY d.objetivo_id, d.dias_por_semana, d.orden"
);
while ($fila = $res->fetch_assoc()) {
    $divisiones[(int)$fila['objetivo_id']][(string)$fila['dias_por_semana']][] = $fila['nombre'];
}
foreach ($divisiones as $objetivo_id => $porDias) {
    if (isset($objetivos[$objetivo_id])) {
        $objetivos[$objetivo_id]['divisiones'] = $porDias;
    }
}

// Lo que el usuario ya eligió
$stmt = $conn->prepare(
    "SELECT o.codigo, pe.dias, pe.actualizado_en
       FROM perfiles_entrenamiento pe
       JOIN objetivos o ON o.id = pe.objetivo_id
      WHERE pe.usuario_id = ?"
);
$stmt->bind_param("i", $usuario['id']);
$stmt->execute();
$perfil = $stmt->get_result()->fetch_assoc();

responder([
    "es_premium" => es_premium($usuario),
    "dias_min"   => DIAS_RUTINA_MIN,
    "dias_max"   => DIAS_RUTINA_MAX,
    "objetivos"  => array_values($objetivos),
    "perfil"     => $perfil ? [
        "objetivo"       => $perfil['codigo'],
        "dias"           => array_map('intval', explode(',', $perfil['dias'])),
        "actualizado_en" => $perfil['actualizado_en'],
    ] : null,
]);
