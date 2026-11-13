<?php
// =====================================================================
//  PonteChetado - Pruebas automáticas de la API (Sprint 11, semana 15)
//
//  Recorre el flujo completo del usuario contra la API real:
//  registro, login, Premium por gimnasio, entrenamiento y XP, rutina
//  personalizada, avatar, chatbot, ranking Top 10 y ayuda del entrenador.
//
//  Cómo ejecutarlas (con Apache y MySQL encendidos):
//      C:\xampp\php\php.exe C:\xampp\htdocs\PonteChetado\pruebas\probar_api.php
//  Con Docker:
//      php probar_api.php http://localhost:8080/api
//
//  Crea cuentas y un gimnasio de prueba (correos @pruebas.pontechetado.test)
//  y los borra al terminar, así que no ensucia tus datos.
// =====================================================================
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

// Misma zona horaria que la API, para que "hoy" sea el mismo día
date_default_timezone_set('America/Santiago');

require __DIR__ . '/../config/db.php';

$BASE = rtrim($argv[1] ?? (getenv('API_URL') ?: 'http://localhost/PonteChetado/api'), '/');
const DOMINIO_PRUEBA = '@pruebas.pontechetado.test';
const GIMNASIO_PRUEBA = 'Gimnasio de Pruebas Automáticas';
const CLAVE = 'ClaveDePrueba2026';

$ok = 0;
$fallos = [];

// ---------- Utilidades ----------
function api(string $metodo, string $ruta, ?array $cuerpo = null, ?string $token = null): array
{
    global $BASE;
    $cabeceras = "Content-Type: application/json\r\n";
    if ($token !== null) {
        $cabeceras .= "Authorization: Bearer $token\r\n";
    }
    $ctx = stream_context_create(["http" => [
        "method"        => $metodo,
        "header"        => $cabeceras,
        "content"       => $cuerpo === null ? '' : json_encode($cuerpo),
        "ignore_errors" => true,
        "timeout"       => 15,
    ]]);
    $texto = @file_get_contents("$BASE/$ruta", false, $ctx);
    $codigo = 0;
    if (isset($http_response_header[0]) && preg_match('/\s(\d{3})\s?/', $http_response_header[0], $m)) {
        $codigo = (int)$m[1];
    }
    $json = json_decode((string)$texto, true);
    return ["codigo" => $codigo, "json" => is_array($json) ? $json : []];
}

function comprobar(string $nombre, bool $condicion, string $detalle = ''): void
{
    global $ok, $fallos;
    if ($condicion) {
        $ok++;
        echo "  [OK]    $nombre\n";
    } else {
        $fallos[] = $nombre;
        echo "  [FALLA] $nombre" . ($detalle === '' ? '' : "  ->  $detalle") . "\n";
    }
}

function seccion(string $titulo): void
{
    echo "\n$titulo\n" . str_repeat('-', strlen($titulo)) . "\n";
}

function limpiar(mysqli $conn): void
{
    $patron = '%' . DOMINIO_PRUEBA;
    $ids = [];
    $stmt = $conn->prepare("SELECT id FROM usuarios WHERE email LIKE ?");
    $stmt->bind_param("s", $patron);
    $stmt->execute();
    foreach ($stmt->get_result()->fetch_all(MYSQLI_NUM) as $f) {
        $ids[] = (int)$f[0];
    }
    if ($ids) {
        $lista = implode(',', $ids);
        $conn->query("DELETE re FROM rutina_ejercicios re JOIN rutinas r ON r.id = re.rutina_id WHERE r.usuario_id IN ($lista)");
        $conn->query("DELETE FROM solicitudes_ayuda WHERE usuario_id IN ($lista) OR atendida_por IN ($lista)");
        $conn->query("DELETE FROM historial_premium WHERE usuario_id IN ($lista) OR admin_id IN ($lista)");
        $conn->query("DELETE FROM mensajes_ayuda WHERE usuario_id IN ($lista)");
        foreach (['ranking_posiciones', 'registros_peso', 'chat_mensajes', 'series_entrenamiento', 'ejercicios',
                  'rutinas', 'tokens', 'avatares', 'perfiles_entrenamiento'] as $tabla) {
            $conn->query("DELETE FROM $tabla WHERE usuario_id IN ($lista)");
        }
        $conn->query("DELETE FROM usuarios WHERE id IN ($lista)");
    }
    $nombre = GIMNASIO_PRUEBA;
    $stmt = $conn->prepare("DELETE FROM gimnasios WHERE nombre = ?");
    $stmt->bind_param("s", $nombre);
    $stmt->execute();
}

function id_ejercicio(mysqli $conn, string $nombre): int
{
    $stmt = $conn->prepare("SELECT id FROM ejercicios WHERE nombre = ? AND usuario_id IS NULL ORDER BY id LIMIT 1");
    $stmt->bind_param("s", $nombre);
    $stmt->execute();
    return (int)($stmt->get_result()->fetch_row()[0] ?? 0);
}

function registrar_cuenta(string $alias, string $nombre): ?string
{
    $r = api('POST', 'auth/registro.php', ["nombre" => $nombre, "email" => $alias . DOMINIO_PRUEBA, "password" => CLAVE]);
    return $r['json']['token'] ?? null;
}

function serie(string $token, int $ejercicio, float $peso, int $reps): array
{
    return api('POST', 'entrenos/registrar_serie.php',
        ["ejercicio_id" => $ejercicio, "peso_kg" => $peso, "repeticiones" => $reps], $token);
}

// ---------- Inicio ----------
echo "Pruebas de la API de PonteChetado\nServidor: $BASE\n";
limpiar($conn);

try {
    // ================================================================
    seccion("1. Registro e inicio de sesión (Historias 001 y 002)");
    $tA = registrar_cuenta('ana', 'Ana Prueba');
    comprobar("Se puede crear una cuenta gratuita", $tA !== null);

    $r = api('POST', 'auth/registro.php', ["nombre" => "Otra", "email" => 'ana' . DOMINIO_PRUEBA, "password" => CLAVE]);
    comprobar("No permite registrar un correo que ya existe", $r['codigo'] >= 400 && ($r['json']['ok'] ?? true) === false);

    $r = api('POST', 'auth/registro.php', ["nombre" => "Corta", "email" => 'corta' . DOMINIO_PRUEBA, "password" => "123"]);
    comprobar("Rechaza contraseñas de menos de 8 caracteres", $r['codigo'] >= 400);

    $r = api('POST', 'auth/login.php', ["email" => 'ana' . DOMINIO_PRUEBA, "password" => "incorrecta"]);
    comprobar("Login con contraseña incorrecta muestra error", $r['codigo'] === 401 || ($r['json']['ok'] ?? true) === false);

    $r = api('POST', 'auth/login.php', ["email" => 'ana' . DOMINIO_PRUEBA, "password" => CLAVE]);
    comprobar("Login correcto entrega un token", isset($r['json']['token']));

    $r = api('GET', 'auth/perfil.php', null, $tA);
    comprobar("La cuenta nueva queda en plan gratis", ($r['json']['usuario']['es_premium'] ?? null) === false);

    $r = api('GET', 'auth/perfil.php');
    comprobar("Sin token no se puede ver el perfil", $r['codigo'] === 401);

    // ================================================================
    seccion("2. Catálogo y funciones bloqueadas del plan gratis (Historia 003)");
    $r = api('GET', 'ejercicios/listar.php', null, $tA);
    comprobar("Se lista el catálogo de ejercicios", count($r['json']['ejercicios'] ?? []) > 10);

    $r = api('POST', 'rutinas/generar.php', ["objetivo" => "fuerza", "dias" => [1, 3, 5]], $tA);
    comprobar("La rutina personalizada está bloqueada sin Premium", $r['codigo'] === 403 && ($r['json']['requiere_premium'] ?? false));

    $r = api('GET', 'ranking/top.php', null, $tA);
    comprobar("El ranking pide estar asociado a un gimnasio", $r['codigo'] === 409);

    $r = api('POST', 'ayuda/solicitar.php', ["motivo" => "tecnica"], $tA);
    comprobar("No se puede pedir ayuda sin gimnasio", $r['codigo'] === 409);

    // ================================================================
    seccion("3. Premium validado por el gimnasio (Historias 005 y 006)");
    $nombre = GIMNASIO_PRUEBA;
    $stmt = $conn->prepare("INSERT INTO gimnasios (nombre, direccion) VALUES (?, 'Calle Falsa 123')");
    $stmt->bind_param("s", $nombre);
    $stmt->execute();
    $gimnasio_id = $conn->insert_id;

    $tAdmin = registrar_cuenta('admin', 'Admin Prueba');
    $correo_admin = 'admin' . DOMINIO_PRUEBA;
    $stmt = $conn->prepare("UPDATE usuarios SET rol = 'admin_gimnasio', gimnasio_id = ? WHERE email = ?");
    $stmt->bind_param("is", $gimnasio_id, $correo_admin);
    $stmt->execute();

    $tSinPremium = registrar_cuenta('gratis', 'Gratis Prueba');
    $tB = registrar_cuenta('beto', 'Beto Prueba');
    $tC = registrar_cuenta('caro', 'Caro Prueba');

    $r = api('POST', 'admin/activar_premium.php', ["email" => 'ana' . DOMINIO_PRUEBA, "meses" => 1], $tA);
    comprobar("Un socio no puede activarse Premium a sí mismo", $r['codigo'] === 403);

    $r = api('POST', 'admin/activar_premium.php', ["email" => 'ana' . DOMINIO_PRUEBA, "meses" => 1], $tAdmin);
    comprobar("El admin del gimnasio activa Premium con el correo del socio", $r['codigo'] === 200, json_encode($r['json']));
    api('POST', 'admin/activar_premium.php', ["email" => 'beto' . DOMINIO_PRUEBA, "meses" => 1], $tAdmin);
    api('POST', 'admin/activar_premium.php', ["email" => 'caro' . DOMINIO_PRUEBA, "meses" => 3], $tAdmin);

    $r = api('POST', 'admin/activar_premium.php', ["email" => 'nadie' . DOMINIO_PRUEBA, "meses" => 1], $tAdmin);
    comprobar("Avisa si el correo no tiene cuenta", $r['codigo'] === 404);

    $r = api('GET', 'auth/perfil.php', null, $tA);
    comprobar("El socio queda Premium y asociado a su gimnasio",
        ($r['json']['usuario']['es_premium'] ?? false) && ($r['json']['usuario']['gimnasio']['id'] ?? 0) === $gimnasio_id);

    $r = api('GET', 'admin/gimnasio.php', null, $tAdmin);
    comprobar("El panel del gimnasio muestra sus 3 miembros Premium", ($r['json']['gimnasio']['miembros_premium'] ?? 0) === 3);
    $id_caro = 0;
    foreach ($r['json']['miembros'] ?? [] as $m) {
        if ($m['email'] === 'caro' . DOMINIO_PRUEBA) $id_caro = $m['id'];
    }

    // ================================================================
    seccion("4. Entrenamiento, XP y niveles (Historias 004, 008 y 010)");
    $banca = id_ejercicio($conn, 'Press banca');
    $sentadilla = id_ejercicio($conn, 'Sentadilla');
    $muerto = id_ejercicio($conn, 'Peso muerto');
    comprobar("Existen los tres básicos en el catálogo", $banca > 0 && $sentadilla > 0 && $muerto > 0);

    $r = serie($tA, $banca, 80, 5);
    comprobar("Se registra una serie con kilos y repeticiones", $r['codigo'] < 300 && ($r['json']['serie']['volumen'] ?? 0) == 400.0, json_encode($r['json']));
    comprobar("Una serie de 80 kg x 5 entrega 3 XP (2 por la serie + 1 por 400 kg)", ($r['json']['xp']['ganada'] ?? -1) === 3, json_encode($r['json']['xp'] ?? null));
    serie($tA, $sentadilla, 100, 5);
    serie($tA, $muerto, 120, 3);

    $r = serie($tA, $banca, 80, 0);
    comprobar("Rechaza una serie con 0 repeticiones", $r['codigo'] >= 400);
    $r = serie($tA, $banca, 5000, 5);
    comprobar("Rechaza pesos imposibles (más de 1000 kg)", $r['codigo'] >= 400);
    $r = api('POST', 'entrenos/registrar_serie.php', ["ejercicio_id" => $banca, "peso_kg" => 50, "repeticiones" => 5, "fecha" => date('Y-m-d', strtotime('+2 days'))], $tA);
    comprobar("Rechaza fechas futuras", $r['codigo'] >= 400);

    $r = api('GET', 'gamificacion/progreso.php', null, $tA);
    $p = $r['json'];
    // 3 series = 6 XP, más 1.260 kg de volumen = 5 XP
    comprobar("El progreso suma 11 XP por las 3 series del día", ($p['nivel']['nivel'] ?? 0) === 1 && ($p['nivel']['xp_total'] ?? 0) === 11, json_encode($p['nivel'] ?? null));

    $r = api('GET', 'entrenos/evolucion.php', null, $tA);
    comprobar("Lista los 3 ejercicios que el socio ha entrenado", count($r['json']['ejercicios'] ?? []) === 3);
    $ayer = date('Y-m-d', strtotime('-1 day'));
    api('POST', 'entrenos/registrar_serie.php', ["ejercicio_id" => $banca, "peso_kg" => 70, "repeticiones" => 5, "fecha" => $ayer], $tB);
    serie($tB, $banca, 60, 5);
    $r = api('GET', 'entrenos/evolucion.php?ejercicio_id=' . $banca, null, $tB);
    $pts = $r['json']['puntos'] ?? [];
    comprobar("La evolución de un ejercicio trae un punto por día, ordenados por fecha",
        count($pts) === 2 && $pts[0]['fecha'] === $ayer && $pts[0]['peso_max'] == 70.0 && $pts[1]['peso_max'] == 60.0, json_encode($r['json']));
    comprobar("El resumen compara el peso inicial con el actual", ($r['json']['resumen']['diferencia'] ?? 0) == -10.0);
    $r = api('GET', 'entrenos/evolucion.php', null, $tSinPremium);
    comprobar("La evolución por ejercicio está bloqueada sin Premium", $r['codigo'] === 403);

    // ================================================================
    seccion("5. Rutina personalizada (Historia 007)");
    $r = api('POST', 'rutinas/generar.php', ["objetivo" => "hipertrofia", "dias" => [1, 3, 5]], $tA);
    comprobar("Genera la rutina de hipertrofia para 3 días", $r['codigo'] < 300, json_encode($r['json']));
    $r = api('GET', 'rutinas/listar.php', null, $tA);
    $rutinas = $r['json']['rutinas'] ?? [];
    comprobar("Quedan 3 rutinas, una por cada día elegido", count($rutinas) === 3);
    $det = api('GET', 'rutinas/detalle.php?id=' . ($rutinas[0]['id'] ?? 0), null, $tA);
    $ejs = $det['json']['rutina']['ejercicios'] ?? $det['json']['ejercicios'] ?? [];
    comprobar("Cada día de hipertrofia trae al menos 7 ejercicios", count($ejs) >= 7, "trae " . count($ejs));

    api('POST', 'rutinas/generar.php', ["objetivo" => "fuerza", "dias" => [2, 4]], $tA);
    $r = api('GET', 'rutinas/listar.php', null, $tA);
    comprobar("Al cambiar de objetivo la rutina se reemplaza (2 días de fuerza)", count($r['json']['rutinas'] ?? []) === 2);

    $r = api('POST', 'rutinas/generar.php', ["objetivo" => "fuerza", "dias" => [1]], $tA);
    comprobar("Exige elegir entre 2 y 6 días", $r['codigo'] >= 400);

    // ================================================================
    seccion("6. Avatar (Historia 009)");
    $r = api('POST', 'avatar/guardar.php', ["genero" => "femenino", "piel" => 1, "peinado" => 2, "color_pelo" => 1, "color_ropa" => 4], $tA);
    comprobar("Se guarda el avatar personalizado", $r['codigo'] === 200);
    $r = api('GET', 'avatar/obtener.php', null, $tA);
    comprobar("El avatar guardado se recupera igual", ($r['json']['avatar']['genero'] ?? '') === 'femenino' && ($r['json']['avatar']['color_ropa'] ?? -1) === 4);
    $r = api('POST', 'avatar/guardar.php', ["genero" => "robot", "piel" => 1, "peinado" => 2, "color_pelo" => 1, "color_ropa" => 4], $tA);
    comprobar("Rechaza opciones de avatar inválidas", $r['codigo'] >= 400);

    // ================================================================
    seccion("7. Chatbot de ejercicios (Historia 011)");
    $r = api('POST', 'chatbot/preguntar.php', ["mensaje" => "¿Cuánto descanso entre series?"], $tA);
    comprobar("Responde una pregunta de entrenamiento", ($r['json']['entendida'] ?? false) === true && strlen($r['json']['respuesta']['texto'] ?? '') > 20);
    $r = api('POST', 'chatbot/preguntar.php', ["mensaje" => "¿Quién ganó el partido de ayer?"], $tA);
    comprobar("Si la pregunta no es de ejercicios, lo dice", ($r['json']['entendida'] ?? true) === false);
    $r = api('GET', 'chatbot/historial.php', null, $tA);
    comprobar("La conversación queda guardada (4 mensajes)", count($r['json']['mensajes'] ?? []) === 4);

    // ================================================================
    seccion("8. Ranking Top 10 del gimnasio (Historias 012 y 013)");
    // Ana: banca 80x5 (93,5) + sentadilla 100x5 (116,5) + peso muerto 120x3 (132) = 342
    // Beto ya registró banca 70x5 (81,5) y 60x5 en la prueba de evolución
    serie($tB, $sentadilla, 80, 5);   //       93,5
    serie($tC, $banca, 40, 10);       // Caro: 53,5

    $r = api('GET', 'ranking/top.php', null, $tA);
    $top = $r['json']['top'] ?? [];
    comprobar("El ranking muestra solo a los 3 socios del gimnasio con marcas", count($top) === 3, json_encode($r['json']));
    comprobar("Está ordenado de mayor a menor puntaje",
        count($top) === 3 && $top[0]['puntaje'] >= $top[1]['puntaje'] && $top[1]['puntaje'] >= $top[2]['puntaje']);
    comprobar("El puntaje es la suma de los tres básicos (342 para Ana)", ($top[0]['puntaje'] ?? 0) == 342.0 && ($top[0]['es_yo'] ?? false), json_encode($top[0] ?? null));
    comprobar("El socio ve su propia posición", ($r['json']['yo']['posicion'] ?? 0) === 1);

    $r = api('GET', 'ranking/top.php', null, $tC);
    comprobar("Caro ve que está en el puesto 3", ($r['json']['yo']['posicion'] ?? 0) === 3);

    $r = api('POST', 'ranking/actualizar.php', null, $tA);
    comprobar("Al terminar el entreno, Ana entra al ranking en el puesto 1", ($r['json']['cambio'] ?? '') === 'nuevo' && ($r['json']['ahora'] ?? 0) === 1);
    api('POST', 'ranking/actualizar.php', null, $tB);
    $r = api('POST', 'ranking/actualizar.php', null, $tA);
    comprobar("Si nada cambia, avisa que mantiene su puesto", ($r['json']['cambio'] ?? '') === 'igual');

    // Beto mejora sus marcas y pasa a Ana
    serie($tB, $banca, 110, 5);
    serie($tB, $sentadilla, 150, 5);
    serie($tB, $muerto, 180, 3);
    $r = api('POST', 'ranking/actualizar.php', null, $tB);
    comprobar("Beto sube del puesto 2 al 1 y la app se lo avisa",
        ($r['json']['cambio'] ?? '') === 'subio' && ($r['json']['antes'] ?? 0) === 2 && ($r['json']['ahora'] ?? 0) === 1, json_encode($r['json']));
    $r = api('POST', 'ranking/actualizar.php', null, $tA);
    comprobar("Ana baja al puesto 2 y la app se lo avisa", ($r['json']['cambio'] ?? '') === 'bajo' && ($r['json']['ahora'] ?? 0) === 2);

    serie($tC, $banca, 20, 30);
    $r = api('GET', 'ranking/top.php', null, $tC);
    comprobar("Las series de más de 12 repeticiones no cuentan para el ranking", ($r['json']['yo']['puntaje'] ?? 0) == 53.5, json_encode($r['json']['yo'] ?? null));

    // ================================================================
    seccion("9. Ayuda de un entrenador (Historias 014 y 015)");
    $r = api('POST', 'admin/asignar_entrenador.php', ["email" => 'coach' . DOMINIO_PRUEBA], $tAdmin);
    comprobar("Para un entrenador sin cuenta pide nombre y contraseña", $r['codigo'] === 422);
    $r = api('POST', 'admin/asignar_entrenador.php', ["email" => 'coach' . DOMINIO_PRUEBA, "nombre" => "Coach Prueba", "password" => CLAVE], $tAdmin);
    comprobar("El admin del gimnasio crea la cuenta del entrenador", $r['codigo'] === 201, json_encode($r['json']));
    $r = api('POST', 'auth/login.php', ["email" => 'coach' . DOMINIO_PRUEBA, "password" => CLAVE]);
    $tCoach = $r['json']['token'] ?? null;
    comprobar("El entrenador inicia sesión con rol de entrenador", ($r['json']['usuario']['rol'] ?? '') === 'entrenador');

    $r = api('POST', 'admin/asignar_entrenador.php', ["email" => 'x' . DOMINIO_PRUEBA, "nombre" => "X", "password" => CLAVE], $tA);
    comprobar("Un socio no puede crear entrenadores", $r['codigo'] === 403);

    $r = api('POST', 'ayuda/solicitar.php', ["motivo" => "bailar"], $tA);
    comprobar("Exige elegir un motivo válido", $r['codigo'] >= 400);
    $r = api('POST', 'ayuda/solicitar.php', ["motivo" => "tecnica", "ejercicio_id" => $sentadilla, "mensaje" => "Estoy en el rack 2"], $tA);
    $id_solicitud = $r['json']['solicitud']['id'] ?? 0;
    comprobar("El socio pide ayuda y recibe la confirmación", $r['codigo'] === 201 && strpos($r['json']['mensaje'] ?? '', 'enviada') !== false, json_encode($r['json']));
    $r = api('POST', 'ayuda/solicitar.php', ["motivo" => "rutina"], $tA);
    comprobar("No puede tener dos solicitudes pendientes a la vez", $r['codigo'] === 409);

    $r = api('GET', 'ayuda/pendientes.php', null, $tA);
    comprobar("Un socio no puede ver la bandeja del entrenador", $r['codigo'] === 403);
    $r = api('GET', 'ayuda/pendientes.php', null, $tCoach);
    $pend = $r['json']['pendientes'][0] ?? [];
    comprobar("El entrenador recibe la solicitud con el nombre del socio y el motivo",
        ($pend['socio'] ?? '') === 'Ana Prueba' && ($pend['motivo'] ?? '') === 'tecnica' && ($pend['ejercicio'] ?? '') === 'Sentadilla', json_encode($r['json']));

    // Chat de la solicitud
    $r = api('POST', 'ayuda/enviar_mensaje.php', ["id" => $id_solicitud, "texto" => "Voy en 2 minutos, termina tu serie"], $tCoach);
    comprobar("El entrenador responde por el chat de la solicitud", $r['codigo'] === 201, json_encode($r['json']));
    $r = api('GET', 'ayuda/mis_solicitudes.php', null, $tA);
    comprobar("El socio ve que tiene 1 mensaje sin leer", ($r['json']['activa']['sin_leer_socio'] ?? 0) === 1);
    $r = api('GET', 'ayuda/chat.php?id=' . $id_solicitud, null, $tA);
    comprobar("El socio lee la conversación con el mensaje del entrenador",
        count($r['json']['mensajes'] ?? []) === 1 && ($r['json']['mensajes'][0]['es_mio'] ?? true) === false
        && ($r['json']['puede_escribir'] ?? false) === true, json_encode($r['json']));
    $r = api('GET', 'ayuda/mis_solicitudes.php', null, $tA);
    comprobar("Al abrir el chat el mensaje queda leído", ($r['json']['activa']['sin_leer_socio'] ?? 1) === 0);
    api('POST', 'ayuda/enviar_mensaje.php', ["id" => $id_solicitud, "texto" => "Dale, gracias"], $tA);
    $r = api('GET', 'ayuda/pendientes.php', null, $tCoach);
    comprobar("El entrenador ve la respuesta sin leer del socio", ($r['json']['pendientes'][0]['sin_leer_entrenador'] ?? 0) === 1);
    $r = api('GET', 'ayuda/chat.php?id=' . $id_solicitud, null, $tB);
    comprobar("Otro socio no puede leer esa conversación", $r['codigo'] === 403);
    $r = api('POST', 'ayuda/enviar_mensaje.php', ["id" => $id_solicitud, "texto" => "   "], $tA);
    comprobar("No se pueden enviar mensajes vacíos", $r['codigo'] >= 400);

    $r = api('POST', 'ayuda/atender.php', ["id" => $id_solicitud], $tB);
    comprobar("Otro socio no puede marcarla como atendida", $r['codigo'] === 403);
    $r = api('POST', 'ayuda/atender.php', ["id" => $id_solicitud], $tCoach);
    comprobar("El entrenador la marca como atendida", $r['codigo'] === 200);
    $r = api('POST', 'ayuda/atender.php', ["id" => $id_solicitud], $tCoach);
    comprobar("No se puede atender dos veces", $r['codigo'] === 409);

    $r = api('POST', 'ayuda/enviar_mensaje.php', ["id" => $id_solicitud, "texto" => "Otra cosa"], $tA);
    comprobar("Con la solicitud atendida el chat queda cerrado", $r['codigo'] === 409);

    $r = api('GET', 'ayuda/mis_solicitudes.php', null, $tA);
    $s = $r['json']['solicitudes'][0] ?? [];
    comprobar("El socio ve que su solicitud fue atendida y por quién",
        ($s['estado'] ?? '') === 'atendida' && ($s['entrenador'] ?? '') === 'Coach Prueba' && array_key_exists('activa', $r['json']) && $r['json']['activa'] === null);

    $r = api('POST', 'ayuda/solicitar.php', ["motivo" => "consulta"], $tB);
    comprobar("Una consulta (ej: mensualidad) exige escribir la pregunta", $r['codigo'] >= 400);
    $r = api('POST', 'ayuda/solicitar.php', ["motivo" => "maquina"], $tB);
    $r = api('POST', 'ayuda/cancelar.php', ["id" => $r['json']['solicitud']['id'] ?? 0], $tB);
    comprobar("El socio puede cancelar su solicitud", $r['codigo'] === 200);
    $r = api('GET', 'ayuda/pendientes.php', null, $tCoach);
    comprobar("La bandeja queda vacía y muestra 1 atendida hoy", count($r['json']['pendientes'] ?? [1]) === 0 && count($r['json']['atendidas_hoy'] ?? []) === 1);

    // ================================================================
    seccion("10. Pérdida de Premium (Historia 006)");
    $r = api('POST', 'admin/quitar_premium.php', ["usuario_id" => $id_caro], $tAdmin);
    comprobar("El admin quita Premium a un socio que dejó de pagar", $r['codigo'] === 200, json_encode($r['json']));
    $r = api('GET', 'auth/perfil.php', null, $tC);
    comprobar("El socio vuelve al plan gratis", ($r['json']['usuario']['es_premium'] ?? true) === false);
    $r = api('GET', 'ranking/top.php', null, $tC);
    comprobar("Sin Premium el ranking queda bloqueado", $r['codigo'] === 403 || $r['codigo'] === 409);
    $r = api('GET', 'ranking/top.php', null, $tB);
    comprobar("El ranking deja de mostrar a los socios sin Premium", count($r['json']['top'] ?? []) === 2 && ($r['json']['participantes'] ?? 0) === 2);
    $r = api('GET', 'entrenos/del_dia.php?fecha=' . date('Y-m-d'), null, $tC);
    comprobar("Sus registros de entrenamiento se mantienen", $r['codigo'] === 200 && strpos(json_encode($r['json']), '"repeticiones"') !== false);

    // ================================================================
    seccion("11. Cierre de sesión");
    $r = api('POST', 'auth/logout.php', null, $tA);
    comprobar("Se puede cerrar sesión", $r['codigo'] === 200);
    $r = api('GET', 'auth/perfil.php', null, $tA);
    comprobar("El token deja de servir después de cerrar sesión", $r['codigo'] === 401);
} finally {
    limpiar($conn);
}

$total = $ok + count($fallos);
echo "\n=====================================================\n";
echo "Resultado: $ok de $total pruebas correctas\n";
if ($fallos) {
    echo "Fallaron:\n";
    foreach ($fallos as $f) {
        echo "  - $f\n";
    }
    exit(1);
}
echo "Todo funciona correctamente. Los datos de prueba fueron eliminados.\n";
exit(0);
