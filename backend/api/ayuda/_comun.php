<?php
// Funciones compartidas por los endpoints de ayuda del entrenador.
require_once __DIR__ . '/../../config/helpers.php';

const MOTIVOS_AYUDA = [
    'tecnica' => 'Técnica de un ejercicio',
    'rutina'  => 'Orientación con mi rutina',
    'maquina' => 'Uso de una máquina',
    'otro'    => 'Otro',
];

// Convierte una fila de solicitudes_ayuda (con joins) al formato de la app
function solicitud_publica(array $f): array
{
    return [
        "id"            => (int)$f['id'],
        "motivo"        => $f['motivo'],
        "motivo_texto"  => MOTIVOS_AYUDA[$f['motivo']] ?? $f['motivo'],
        "ejercicio"     => $f['ejercicio'] ?? null,
        "mensaje"       => $f['mensaje'],
        "estado"        => $f['estado'],
        "creada_en"     => $f['creada_en'],
        "atendida_en"   => $f['atendida_en'],
        "entrenador"    => $f['entrenador'] ?? null,
        "socio"         => $f['socio'] ?? null,
    ];
}

const SELECT_SOLICITUD = "SELECT s.id, s.motivo, s.mensaje, s.estado, s.creada_en, s.atendida_en,
                                 e.nombre AS ejercicio, en.nombre AS entrenador, u.nombre AS socio
                            FROM solicitudes_ayuda s
                            JOIN usuarios u ON u.id = s.usuario_id
                            LEFT JOIN ejercicios e ON e.id = s.ejercicio_id
                            LEFT JOIN usuarios en ON en.id = s.atendida_por";
