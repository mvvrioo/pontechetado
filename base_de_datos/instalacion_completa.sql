-- =====================================================================
--  PonteChetado - Instalación completa de la base de datos
--  Crea la base 'pontechetado' desde cero: todas las tablas más el
--  catálogo (ejercicios, objetivos, plantillas de rutinas, respuestas
--  del chatbot y los gimnasios asociados). No trae usuarios.
--
--  Ejecutar en MySQL Workbench con el botón del rayo.
--  Se puede volver a ejecutar sin problemas: no borra ni duplica nada.
--  Después regístrate en la app y conviértete en superadmin con:
--      UPDATE usuarios SET rol = 'superadmin' WHERE email = 'tu@correo.cl';
-- =====================================================================

CREATE DATABASE IF NOT EXISTS pontechetado CHARACTER SET utf8mb4;
USE pontechetado;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------- avatares ----------
CREATE TABLE IF NOT EXISTS `avatares` (
  `usuario_id` int NOT NULL,
  `genero` enum('masculino','femenino') NOT NULL DEFAULT 'masculino',
  `piel` tinyint NOT NULL DEFAULT '1',
  `peinado` tinyint NOT NULL DEFAULT '0',
  `color_pelo` tinyint NOT NULL DEFAULT '0',
  `color_ropa` tinyint NOT NULL DEFAULT '0',
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- chat_mensajes ----------
CREATE TABLE IF NOT EXISTS `chat_mensajes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `rol` enum('usuario','bot') NOT NULL,
  `texto` text NOT NULL,
  `respuesta_id` int DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_chat_usuario` (`usuario_id`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- chatbot_respuestas ----------
CREATE TABLE IF NOT EXISTS `chatbot_respuestas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tema` varchar(50) NOT NULL,
  `palabras_clave` text NOT NULL,
  `respuesta` text NOT NULL,
  `ejemplo` varchar(150) DEFAULT NULL,
  `es_respaldo` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_chatbot_tema` (`tema`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- codigos_premium ----------
CREATE TABLE IF NOT EXISTS `codigos_premium` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dias` smallint unsigned NOT NULL DEFAULT '30',
  `usado_por` int unsigned DEFAULT NULL,
  `usado_en` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `fk_codigo_usuario` (`usado_por`),
  CONSTRAINT `fk_codigo_usuario` FOREIGN KEY (`usado_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- divisiones_objetivo ----------
CREATE TABLE IF NOT EXISTS `divisiones_objetivo` (
  `objetivo_id` int NOT NULL,
  `dias_por_semana` tinyint NOT NULL,
  `orden` tinyint NOT NULL,
  `plantilla_id` int NOT NULL,
  PRIMARY KEY (`objetivo_id`,`dias_por_semana`,`orden`),
  KEY `fk_division_plantilla` (`plantilla_id`),
  CONSTRAINT `fk_division_objetivo` FOREIGN KEY (`objetivo_id`) REFERENCES `objetivos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_division_plantilla` FOREIGN KEY (`plantilla_id`) REFERENCES `plantillas_rutina` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- ejercicios ----------
CREATE TABLE IF NOT EXISTS `ejercicios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `grupo_muscular` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `es_premium` tinyint(1) NOT NULL DEFAULT '0',
  `usuario_id` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ejercicio_nombre_usuario` (`nombre`,`usuario_id`),
  KEY `fk_ejercicio_usuario` (`usuario_id`),
  CONSTRAINT `fk_ejercicio_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- gimnasios ----------
CREATE TABLE IF NOT EXISTS `gimnasios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_gimnasios_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- historial_premium ----------
CREATE TABLE IF NOT EXISTS `historial_premium` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `gimnasio_id` int NOT NULL,
  `admin_id` int NOT NULL,
  `accion` enum('activar','quitar') NOT NULL,
  `dias` int DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_historial_usuario` (`usuario_id`),
  KEY `idx_historial_gimnasio` (`gimnasio_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- objetivos ----------
CREATE TABLE IF NOT EXISTS `objetivos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `indicaciones` varchar(255) NOT NULL,
  `orden` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_objetivos_codigo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- perfiles_entrenamiento ----------
CREATE TABLE IF NOT EXISTS `perfiles_entrenamiento` (
  `usuario_id` int NOT NULL,
  `objetivo_id` int NOT NULL,
  `dias` varchar(20) NOT NULL,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`usuario_id`),
  KEY `fk_perfil_objetivo` (`objetivo_id`),
  CONSTRAINT `fk_perfil_objetivo` FOREIGN KEY (`objetivo_id`) REFERENCES `objetivos` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- plantilla_ejercicios ----------
CREATE TABLE IF NOT EXISTS `plantilla_ejercicios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `plantilla_id` int NOT NULL,
  `ejercicio_id` int NOT NULL,
  `series` tinyint NOT NULL,
  `repeticiones` smallint NOT NULL,
  `orden` tinyint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_plantilla_ejercicios` (`plantilla_id`,`orden`),
  CONSTRAINT `fk_pe_plantilla` FOREIGN KEY (`plantilla_id`) REFERENCES `plantillas_rutina` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- plantillas_rutina ----------
CREATE TABLE IF NOT EXISTS `plantillas_rutina` (
  `id` int NOT NULL AUTO_INCREMENT,
  `objetivo_id` int NOT NULL,
  `codigo` varchar(30) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plantilla` (`objetivo_id`,`codigo`),
  CONSTRAINT `fk_plantilla_objetivo` FOREIGN KEY (`objetivo_id`) REFERENCES `objetivos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- ranking_posiciones ----------
CREATE TABLE IF NOT EXISTS `ranking_posiciones` (
  `usuario_id` int NOT NULL,
  `gimnasio_id` int NOT NULL,
  `posicion` int NOT NULL,
  `puntaje` decimal(7,1) NOT NULL,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`usuario_id`),
  KEY `idx_ranking_gimnasio` (`gimnasio_id`,`posicion`),
  CONSTRAINT `fk_ranking_gimnasio` FOREIGN KEY (`gimnasio_id`) REFERENCES `gimnasios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- registros_peso ----------
CREATE TABLE IF NOT EXISTS `registros_peso` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL,
  `peso_kg` decimal(5,2) NOT NULL,
  `fecha` date NOT NULL,
  `nota` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_peso_usuario_fecha` (`usuario_id`,`fecha`),
  CONSTRAINT `fk_peso_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- rutina_ejercicios ----------
CREATE TABLE IF NOT EXISTS `rutina_ejercicios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `rutina_id` int unsigned NOT NULL,
  `ejercicio_id` int unsigned NOT NULL,
  `series` tinyint unsigned NOT NULL DEFAULT '3',
  `repeticiones` smallint unsigned NOT NULL DEFAULT '10',
  `peso_kg` decimal(6,2) DEFAULT NULL,
  `orden` smallint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_re_rutina` (`rutina_id`),
  KEY `fk_re_ejercicio` (`ejercicio_id`),
  CONSTRAINT `fk_re_ejercicio` FOREIGN KEY (`ejercicio_id`) REFERENCES `ejercicios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_re_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- rutinas ----------
CREATE TABLE IF NOT EXISTS `rutinas` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `dia_semana` tinyint DEFAULT NULL,
  `generada` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_rutinas_usuario` (`usuario_id`),
  CONSTRAINT `fk_rutinas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- series_entrenamiento ----------
CREATE TABLE IF NOT EXISTS `series_entrenamiento` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL,
  `ejercicio_id` int unsigned NOT NULL,
  `fecha` date NOT NULL,
  `numero_serie` smallint unsigned NOT NULL,
  `peso_kg` decimal(6,2) NOT NULL,
  `repeticiones` smallint unsigned NOT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_serie_ejercicio` (`ejercicio_id`),
  KEY `idx_series_usuario_fecha` (`usuario_id`,`fecha`),
  CONSTRAINT `fk_serie_ejercicio` FOREIGN KEY (`ejercicio_id`) REFERENCES `ejercicios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_serie_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- solicitudes_ayuda ----------
CREATE TABLE IF NOT EXISTS `solicitudes_ayuda` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `gimnasio_id` int NOT NULL,
  `motivo` enum('tecnica','rutina','maquina','otro') NOT NULL,
  `ejercicio_id` int DEFAULT NULL,
  `mensaje` varchar(255) DEFAULT NULL,
  `estado` enum('pendiente','atendida','cancelada') NOT NULL DEFAULT 'pendiente',
  `atendida_por` int DEFAULT NULL,
  `creada_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `atendida_en` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ayuda_gimnasio` (`gimnasio_id`,`estado`,`id`),
  KEY `idx_ayuda_usuario` (`usuario_id`,`id`),
  CONSTRAINT `fk_ayuda_gimnasio` FOREIGN KEY (`gimnasio_id`) REFERENCES `gimnasios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- tokens ----------
CREATE TABLE IF NOT EXISTS `tokens` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL,
  `token_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expira_en` datetime NOT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `fk_tokens_usuario` (`usuario_id`),
  CONSTRAINT `fk_tokens_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- usuarios ----------
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `premium_hasta` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rol` enum('usuario','entrenador','admin_gimnasio','superadmin') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'usuario',
  `gimnasio_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_usuarios_gimnasio` (`gimnasio_id`),
  CONSTRAINT `fk_usuarios_gimnasio` FOREIGN KEY (`gimnasio_id`) REFERENCES `gimnasios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- Catálogo ----------
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('1', 'Press de banca', 'Pecho', 'Barra, banco plano', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('2', 'Flexiones de brazos', 'Pecho', 'Peso corporal', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('3', 'Aperturas con mancuernas', 'Pecho', 'Banco plano o inclinado', '1', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('4', 'Sentadilla', 'Piernas', 'Barra libre o multipower', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('5', 'Prensa de piernas', 'Piernas', 'Máquina de prensa 45°', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('6', 'Peso muerto rumano', 'Piernas', 'Barra o mancuernas, foco en isquios', '1', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('7', 'Zancadas', 'Piernas', 'Con mancuernas o peso corporal', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('8', 'Dominadas', 'Espalda', 'Barra fija, agarre prono', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('9', 'Remo con barra', 'Espalda', 'Torso inclinado, barra al abdomen', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('10', 'Jalón al pecho', 'Espalda', 'Polea alta', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('11', 'Press militar', 'Hombros', 'Barra o mancuernas, de pie o sentado', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('12', 'Elevaciones laterales', 'Hombros', 'Mancuernas', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('13', 'Face pull', 'Hombros', 'Polea con cuerda', '1', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('14', 'Curl de bíceps', 'Brazos', 'Barra o mancuernas', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('15', 'Extensión de tríceps', 'Brazos', 'Polea alta con cuerda', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('16', 'Plancha abdominal', 'Core', 'Mantener posición (repeticiones = segundos)', '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('17', 'Rueda abdominal', 'Core', 'Ab wheel', '1', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('18', 'Hip thrust', 'Glúteos', 'Barra apoyada en banco', '1', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('19', 'Press banca', 'Pecho', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('20', 'Press inclinado con mancuernas', 'Pecho', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('21', 'Press con mancuernas', 'Pecho', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('22', 'Fondos en paralelas', 'Pecho', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('23', 'Peso muerto', 'Espalda', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('24', 'Remo con mancuerna', 'Espalda', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('25', 'Remo en polea baja', 'Espalda', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('26', 'Press de hombro con mancuernas', 'Hombro', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('27', 'Sentadilla goblet', 'Pierna', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('28', 'Curl femoral', 'Pierna', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('29', 'Extensión de cuádriceps', 'Pierna', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('30', 'Elevación de talones', 'Pierna', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('31', 'Puente de glúteo', 'Glúteo', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('32', 'Curl con barra', 'Bíceps', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('33', 'Curl martillo', 'Bíceps', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('34', 'Extensión de tríceps en polea', 'Tríceps', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('35', 'Press francés', 'Tríceps', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('36', 'Crunch abdominal', 'Abdomen', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('37', 'Elevación de piernas colgado', 'Abdomen', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('38', 'Kettlebell swing', 'Cuerpo completo', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('39', 'Burpees', 'Cuerpo completo', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('40', 'Cruce de poleas', 'Pecho', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('41', 'Sentadilla búlgara', 'Pierna', NULL, '0', NULL);
INSERT IGNORE INTO `ejercicios` (`id`, `nombre`, `grupo_muscular`, `descripcion`, `es_premium`, `usuario_id`) VALUES ('42', 'Curl inclinado con mancuernas', 'Bíceps', NULL, '0', NULL);

INSERT IGNORE INTO `objetivos` (`id`, `codigo`, `nombre`, `descripcion`, `indicaciones`, `orden`) VALUES ('1', 'fuerza', 'Fuerza', 'Levantar más peso en los ejercicios básicos: sentadilla, banca, peso muerto y press militar.', 'Pocas repeticiones con mucho peso. Descansa 2 a 3 minutos entre series.', '1');
INSERT IGNORE INTO `objetivos` (`id`, `codigo`, `nombre`, `descripcion`, `indicaciones`, `orden`) VALUES ('2', 'hipertrofia', 'Hipertrofia', 'Ganar masa muscular con más volumen de trabajo por grupo muscular.', '8 a 15 repeticiones cerca del fallo. Descansa 2 minutos en los básicos y 60 a 90 segundos en el resto.', '2');
INSERT IGNORE INTO `objetivos` (`id`, `codigo`, `nombre`, `descripcion`, `indicaciones`, `orden`) VALUES ('3', 'hibrido', 'Híbrido', 'Fuerza en los básicos más un circuito final para mejorar la resistencia.', 'Básicos pesados y cierra con el circuito a buen ritmo. Descansa 90 segundos.', '3');
INSERT IGNORE INTO `objetivos` (`id`, `codigo`, `nombre`, `descripcion`, `indicaciones`, `orden`) VALUES ('4', 'salud', 'Salud', 'Moverte mejor y mantenerte activo con rutinas de cuerpo completo.', 'Cargas moderadas y buena técnica. Descansa 60 segundos entre series.', '4');

INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('1', '1', 'cuerpo_a', 'Cuerpo completo A');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('2', '1', 'cuerpo_b', 'Cuerpo completo B');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('3', '1', 'empuje', 'Empuje (pecho, hombro y tríceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('4', '1', 'tiron', 'Tirón (espalda y bíceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('5', '1', 'pierna_a', 'Pierna A (cuádriceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('6', '1', 'pierna_b', 'Pierna B (femoral y glúteo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('7', '1', 'torso_a', 'Torso A');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('8', '1', 'torso_b', 'Torso B');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('9', '2', 'cuerpo_a', 'Cuerpo completo A');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('10', '2', 'cuerpo_b', 'Cuerpo completo B');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('11', '2', 'empuje', 'Empuje (pecho, hombro y tríceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('12', '2', 'tiron', 'Tirón (espalda y bíceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('13', '2', 'pierna_a', 'Pierna A (cuádriceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('14', '2', 'pierna_b', 'Pierna B (femoral y glúteo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('15', '2', 'torso_a', 'Torso A');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('16', '2', 'torso_b', 'Torso B');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('17', '3', 'cuerpo_a', 'Cuerpo completo A');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('18', '3', 'cuerpo_b', 'Cuerpo completo B');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('19', '3', 'empuje', 'Empuje (pecho, hombro y tríceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('20', '3', 'tiron', 'Tirón (espalda y bíceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('21', '3', 'pierna_a', 'Pierna A (cuádriceps)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('22', '3', 'pierna_b', 'Pierna B (femoral y glúteo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('23', '3', 'torso_a', 'Torso A');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('24', '3', 'torso_b', 'Torso B');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('25', '4', 'salud_a', 'Salud A (cuerpo completo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('26', '4', 'salud_b', 'Salud B (cuerpo completo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('27', '4', 'salud_c', 'Salud C (cuerpo completo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('32', '1', 'pierna', 'Pierna (cuádriceps, femoral y glúteo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('41', '2', 'pierna', 'Pierna (cuádriceps, femoral y glúteo)');
INSERT IGNORE INTO `plantillas_rutina` (`id`, `objetivo_id`, `codigo`, `nombre`) VALUES ('50', '3', 'pierna', 'Pierna (cuádriceps, femoral y glúteo)');

INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('470', '1', '4', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('471', '1', '19', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('472', '1', '9', '5', '5', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('473', '1', '6', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('474', '1', '12', '3', '8', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('475', '2', '23', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('476', '2', '11', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('477', '2', '8', '5', '5', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('478', '2', '7', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('479', '2', '20', '3', '8', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('480', '3', '19', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('481', '3', '11', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('482', '3', '20', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('483', '3', '12', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('484', '4', '23', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('485', '4', '8', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('486', '4', '9', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('487', '4', '10', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('488', '32', '4', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('489', '32', '6', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('490', '32', '5', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('491', '32', '28', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('492', '5', '4', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('493', '5', '5', '3', '8', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('494', '5', '7', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('495', '6', '6', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('496', '6', '18', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('497', '6', '28', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('498', '6', '27', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('499', '7', '19', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('500', '7', '9', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('501', '7', '11', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('502', '7', '10', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('503', '8', '20', '5', '5', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('504', '8', '8', '5', '5', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('505', '8', '26', '3', '8', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('506', '8', '24', '3', '8', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('507', '9', '4', '4', '8', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('508', '9', '19', '4', '8', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('509', '9', '9', '4', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('510', '9', '6', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('511', '9', '20', '3', '10', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('512', '9', '12', '3', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('513', '9', '32', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('514', '9', '36', '3', '15', '8');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('515', '10', '5', '4', '12', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('516', '10', '8', '4', '8', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('517', '10', '11', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('518', '10', '3', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('519', '10', '25', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('520', '10', '28', '3', '12', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('521', '10', '34', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('522', '10', '37', '3', '12', '8');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('523', '11', '19', '4', '8', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('524', '11', '20', '3', '10', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('525', '11', '3', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('526', '11', '40', '3', '15', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('527', '11', '11', '3', '10', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('528', '11', '12', '4', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('529', '11', '34', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('530', '11', '35', '3', '12', '8');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('531', '12', '8', '4', '8', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('532', '12', '9', '4', '10', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('533', '12', '10', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('534', '12', '25', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('535', '12', '13', '3', '15', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('536', '12', '32', '3', '10', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('537', '12', '42', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('538', '12', '33', '3', '12', '8');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('539', '41', '4', '4', '8', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('540', '41', '5', '3', '12', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('541', '41', '6', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('542', '41', '29', '3', '15', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('543', '41', '28', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('544', '41', '18', '3', '10', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('545', '41', '30', '4', '15', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('546', '13', '4', '4', '8', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('547', '13', '5', '4', '12', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('548', '13', '41', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('549', '13', '29', '3', '15', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('550', '13', '28', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('551', '13', '30', '4', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('552', '13', '36', '3', '15', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('553', '14', '6', '4', '10', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('554', '14', '18', '4', '10', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('555', '14', '28', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('556', '14', '7', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('557', '14', '27', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('558', '14', '30', '4', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('559', '14', '37', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('560', '15', '19', '4', '8', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('561', '15', '9', '4', '10', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('562', '15', '20', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('563', '15', '10', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('564', '15', '40', '3', '15', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('565', '15', '12', '3', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('566', '15', '32', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('567', '15', '34', '3', '12', '8');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('568', '16', '21', '4', '10', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('569', '16', '8', '4', '8', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('570', '16', '3', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('571', '16', '24', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('572', '16', '26', '3', '10', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('573', '16', '13', '3', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('574', '16', '33', '3', '12', '7');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('575', '16', '35', '3', '12', '8');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('576', '17', '4', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('577', '17', '19', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('578', '17', '9', '4', '6', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('579', '17', '6', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('580', '17', '12', '3', '10', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('581', '17', '38', '3', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('582', '18', '23', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('583', '18', '11', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('584', '18', '8', '4', '6', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('585', '18', '7', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('586', '18', '20', '3', '10', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('587', '18', '38', '3', '15', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('588', '19', '19', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('589', '19', '11', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('590', '19', '20', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('591', '19', '12', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('592', '19', '39', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('593', '20', '23', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('594', '20', '8', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('595', '20', '9', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('596', '20', '10', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('597', '20', '39', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('598', '50', '4', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('599', '50', '6', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('600', '50', '5', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('601', '50', '28', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('602', '50', '38', '3', '15', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('603', '21', '4', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('604', '21', '5', '3', '10', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('605', '21', '7', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('606', '21', '38', '3', '15', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('607', '22', '6', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('608', '22', '18', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('609', '22', '28', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('610', '22', '27', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('611', '22', '38', '3', '15', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('612', '23', '19', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('613', '23', '9', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('614', '23', '11', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('615', '23', '10', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('616', '23', '39', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('617', '24', '20', '4', '6', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('618', '24', '8', '4', '6', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('619', '24', '26', '3', '10', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('620', '24', '24', '3', '10', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('621', '24', '39', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('622', '25', '27', '3', '12', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('623', '25', '21', '3', '12', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('624', '25', '25', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('625', '25', '31', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('626', '25', '12', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('627', '25', '36', '3', '12', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('628', '26', '5', '3', '12', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('629', '26', '10', '3', '12', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('630', '26', '26', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('631', '26', '7', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('632', '26', '13', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('633', '26', '33', '3', '12', '6');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('634', '27', '6', '3', '12', '1');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('635', '27', '24', '3', '12', '2');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('636', '27', '20', '3', '12', '3');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('637', '27', '30', '3', '12', '4');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('638', '27', '34', '3', '12', '5');
INSERT IGNORE INTO `plantilla_ejercicios` (`id`, `plantilla_id`, `ejercicio_id`, `series`, `repeticiones`, `orden`) VALUES ('639', '27', '36', '3', '12', '6');

INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '2', '1', '1');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '2', '2', '2');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '3', '1', '3');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '3', '2', '4');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '3', '3', '32');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '4', '1', '7');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '4', '2', '5');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '4', '3', '8');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '4', '4', '6');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '5', '1', '7');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '5', '2', '5');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '5', '3', '3');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '5', '4', '4');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '5', '5', '6');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '6', '1', '3');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '6', '2', '4');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '6', '3', '5');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '6', '4', '7');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '6', '5', '8');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('1', '6', '6', '6');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '2', '1', '9');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '2', '2', '10');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '3', '1', '11');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '3', '2', '12');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '3', '3', '41');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '4', '1', '15');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '4', '2', '13');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '4', '3', '16');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '4', '4', '14');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '5', '1', '15');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '5', '2', '13');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '5', '3', '11');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '5', '4', '12');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '5', '5', '14');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '6', '1', '11');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '6', '2', '12');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '6', '3', '13');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '6', '4', '15');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '6', '5', '16');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('2', '6', '6', '14');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '2', '1', '17');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '2', '2', '18');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '3', '1', '19');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '3', '2', '20');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '3', '3', '50');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '4', '1', '23');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '4', '2', '21');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '4', '3', '24');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '4', '4', '22');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '5', '1', '23');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '5', '2', '21');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '5', '3', '19');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '5', '4', '20');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '5', '5', '22');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '6', '1', '19');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '6', '2', '20');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '6', '3', '21');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '6', '4', '23');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '6', '5', '24');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('3', '6', '6', '22');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '2', '1', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '2', '2', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '3', '1', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '3', '2', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '3', '3', '27');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '4', '1', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '4', '2', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '4', '3', '27');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '4', '4', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '5', '1', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '5', '2', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '5', '3', '27');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '5', '4', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '5', '5', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '6', '1', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '6', '2', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '6', '3', '27');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '6', '4', '25');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '6', '5', '26');
INSERT IGNORE INTO `divisiones_objetivo` (`objetivo_id`, `dias_por_semana`, `orden`, `plantilla_id`) VALUES ('4', '6', '6', '27');

INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('1', 'saludo', 'hola, buenas, buenos dias, buenas tardes, buenas noches, hey, que tal', '¡Hola! Soy el asistente de PonteChetado. Pregúntame sobre técnica de ejercicios, series y repeticiones, descanso o cómo armar tu entrenamiento.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('2', 'gracias', 'gracias, muchas gracias, vale, perfecto, genial, buena', '¡De nada! Si tienes otra duda de entrenamiento, aquí estoy.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('3', 'sentadilla', 'sentadilla, sentadillas, squat, sentadilla goblet', 'Sentadilla: pies al ancho de hombros con las puntas levemente hacia afuera. Baja llevando la cadera atrás y abajo, con las rodillas siguiendo la línea de los pies, la espalda neutra y el pecho arriba. Baja hasta que el muslo quede al menos paralelo al suelo y sube empujando con todo el pie. Error común: que las rodillas se vayan hacia adentro.', '¿Cómo hago una sentadilla?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('4', 'press_banca', 'press banca, press de banca, banca, bench, pecho plano, pecho', 'Press banca: junta las escápulas y llévalas hacia abajo, pies firmes en el suelo y una leve curva en la zona lumbar. Baja la barra controlada hasta la parte baja del pecho con los codos a unos 45° del cuerpo y empuja hacia arriba. Si vas a cargar pesado, usa un compañero o los seguros del rack.', '¿Cuál es la técnica del press banca?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('5', 'peso_muerto', 'peso muerto, deadlift, muerto', 'Peso muerto: barra sobre la mitad del pie y agárrala justo por fuera de las piernas. Espalda neutra, pecho arriba y brazos estirados. Empuja el suelo con las piernas y lleva la cadera adelante al final, con la barra siempre pegada al cuerpo. Nunca redondees la espalda baja: si pasa, el peso es demasiado.', '¿Cómo hago peso muerto sin dañarme la espalda?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('6', 'peso_muerto_rumano', 'peso muerto rumano, rumano, femoral, femorales, isquiotibiales', 'Peso muerto rumano: rodillas levemente flectadas y fijas. Lleva la cadera hacia atrás bajando la barra pegada a las piernas hasta sentir el estiramiento en los femorales (normalmente un poco bajo la rodilla). Espalda recta todo el tiempo y sube apretando los glúteos.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('7', 'dominadas', 'dominada, dominadas, pull up, pullup, chin up, jalon, jalon al pecho', 'Dominadas: agarre algo más ancho que los hombros y cuerpo firme. Tira llevando los codos hacia abajo y atrás hasta pasar el mentón sobre la barra, y baja controlado. Si todavía no puedes, usa banda elástica o máquina asistida, haz jalón al pecho o practica negativas (solo la bajada, lenta).', 'No puedo hacer dominadas, ¿qué hago?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('8', 'press_militar', 'press militar, militar, press de hombro, overhead, hombro, hombros', 'Press militar: de pie, barra a la altura de las clavículas, glúteos y abdomen apretados. Empuja la barra en línea recta sobre la cabeza, moviendo un poco la cabeza hacia atrás para dejarla pasar, y termina con los brazos estirados. No arquees la espalda baja para subir el peso.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('9', 'remo', 'remo, remo con barra, remo con mancuerna, remo en polea, espalda', 'Remo con barra: inclina el torso unos 45° con la espalda recta y las rodillas flectadas. Tira la barra hacia el ombligo llevando los codos atrás y juntando las escápulas, y baja controlado. Evita dar tirones con la espalda baja.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('10', 'gluteo', 'hip thrust, gluteo, gluteos, puente de gluteo, cola, trasero', 'Hip thrust: espalda alta apoyada en un banco y la barra sobre la cadera (usa una almohadilla). Empuja con los talones hasta que el torso quede paralelo al suelo y aprieta los glúteos arriba un segundo. Lleva el mentón hacia el pecho para no arquear la zona lumbar. También suman sentadilla, zancadas y peso muerto rumano.', '¿Cómo trabajo glúteos?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('11', 'zancadas', 'zancada, zancadas, lunge, estocada, estocadas', 'Zancadas: da un paso largo y baja hasta que ambas rodillas queden cerca de 90°, con la rodilla de atrás casi tocando el suelo. El torso va recto y la rodilla de adelante sigue la línea del pie. Empuja con el talón de adelante para volver.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('12', 'biceps', 'biceps, curl, curl con barra, curl martillo, brazo, brazos', 'Curl de bíceps: codos pegados al cuerpo y quietos. Sube el peso sin balancear el torso y bájalo lento (2 a 3 segundos). Si tienes que tirar con la espalda, el peso es demasiado. El curl martillo (agarre neutro) trabaja además el braquial y el antebrazo.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('13', 'triceps', 'triceps, extension de triceps, press frances, fondos, fondos en paralelas', 'Tríceps: en la extensión en polea mantén los codos fijos al costado y estira por completo abajo. En el press francés baja la barra hacia la frente moviendo solo los codos. En fondos, inclina un poco el torso y baja hasta unos 90° de codo, siempre sin dolor de hombro.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('14', 'abdomen', 'abdomen, abdominal, abdominales, core, plancha, six pack, crunch', 'Abdomen: combina ejercicios de flexión (crunch, elevación de piernas) con ejercicios de estabilidad (plancha). Con 2 a 3 veces por semana basta. Ojo: los abdominales se marcan sobre todo al bajar el porcentaje de grasa, no solo entrenándolos.', '¿Cómo marco el abdomen?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('15', 'hipertrofia', 'ganar musculo, hipertrofia, masa muscular, crecer, aumentar musculo, volumen muscular', 'Para ganar músculo: entre 8 y 12 repeticiones por serie (aunque de 6 a 20 también funciona), terminando a 1 a 3 repeticiones del fallo. Apunta a unas 10 a 20 series semanales por grupo muscular, repartidas en 2 sesiones, con 60 a 90 segundos de descanso. Lo más importante es ir subiendo peso o repeticiones con el tiempo.', '¿Cuántas repeticiones para ganar músculo?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('16', 'fuerza', 'fuerza, mas fuerte, 5x5, levantar mas peso, powerlifting, maximo', 'Para ganar fuerza: series de 3 a 6 repeticiones con peso alto en los ejercicios básicos (sentadilla, banca, peso muerto, press militar) y 2 a 3 minutos de descanso entre series. Sube el peso de a poco, por ejemplo 2,5 kg, cuando completes todas las series con buena técnica.', '¿Cómo gano más fuerza?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('17', 'descanso_series', 'descanso entre series, cuanto descanso, tiempo de descanso, descansar entre series, descanso', 'Descanso entre series: para fuerza, 2 a 3 minutos; para hipertrofia, 60 a 90 segundos; para resistencia o circuitos, 30 a 60 segundos. Si en la serie siguiente pierdes muchas repeticiones, descansa un poco más.', '¿Cuánto descanso entre series?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('18', 'frecuencia', 'cuantos dias, frecuencia, veces por semana, dias a la semana, entrenar todos los dias, cuantas veces', 'Con 3 a 4 días por semana se progresa muy bien. Lo ideal es trabajar cada grupo muscular unas 2 veces por semana y dejar al menos un día de descanso. En la app puedes elegir tus días en Rutinas → Arma tu rutina personalizada.', '¿Cuántos días a la semana debo entrenar?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('19', 'principiante', 'principiante, empezar, novato, primera vez, nunca he entrenado, por donde empiezo, recien empiezo', 'Si estás empezando: 3 días a la semana de cuerpo completo con ejercicios básicos (sentadilla, press, remo y peso muerto rumano) a 3 series de 10 a 12. Prioriza aprender la técnica con poco peso y súbelo de a poco. Puedes generar tu rutina en Rutinas → Arma tu rutina personalizada.', 'Soy principiante, ¿por dónde empiezo?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('20', 'calentamiento', 'calentar, calentamiento, antes de entrenar, warm up, entrar en calor', 'Calentamiento: 5 a 10 minutos de cardio suave, movilidad de las articulaciones que vas a usar y 2 a 3 series de aproximación del primer ejercicio con poco peso (por ejemplo, al 50% y al 70% del peso de trabajo).', '¿Cómo debo calentar?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('21', 'progresion', 'progresion, progresar, subir peso, cuando subir, estancado, estancamiento, no avanzo', 'Sobrecarga progresiva: cuando hagas todas las series con las repeticiones máximas del rango (por ejemplo 3×12) y buena técnica, sube el peso entre un 2% y un 5% y vuelve al rango bajo. Si llevas 2 a 3 semanas estancado, revisa tu sueño, alimentación y descanso, o haz una semana más liviana.', 'Estoy estancado, ¿qué hago?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('22', 'dolor_muscular', 'agujetas, dolor muscular, adolorido, me duele el musculo, dolor al otro dia, quedé adolorido', 'El dolor muscular que aparece 24 a 72 horas después de entrenar es normal, sobre todo al empezar o cambiar de rutina. Ayudan el movimiento suave, dormir bien y comer suficiente proteína. Mientras tanto puedes entrenar otro grupo muscular.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('23', 'lesion', 'lesion, lesionado, me lesione, dolor articular, me duele la rodilla, me duele la espalda, me duele el hombro, me duele la muneca, dolor agudo, pinchazo, crujido', 'Si sientes un dolor agudo, punzante o en una articulación, detén el ejercicio: no es lo mismo que el cansancio muscular. Si el dolor sigue, consulta a un profesional de la salud y pide a un entrenador del gimnasio que revise tu técnica.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('24', 'fallo', 'fallo, al fallo, rpe, rir, intensidad, hasta no poder', 'Entrenar al fallo es hacer repeticiones hasta no poder hacer otra con buena técnica. No hace falta en todas las series: quedarse a 1 a 3 repeticiones del fallo da casi los mismos resultados con menos fatiga. Deja el fallo para la última serie de ejercicios de aislamiento.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('25', 'cardio', 'cardio, correr, trotar, bicicleta, quemar grasa, bajar de peso, perder grasa, adelgazar', 'Para bajar grasa lo que más influye es la alimentación (gastar un poco más de lo que comes), y las pesas ayudan a no perder músculo. El cardio suma: 2 a 3 sesiones de 20 a 30 minutos por semana, idealmente después de las pesas o en días distintos.', '¿Cómo bajo grasa?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('26', 'alimentacion', 'proteina, proteinas, dieta, comer, alimentacion, suplementos, creatina, nutricion, calorias', 'Como guía general, para ganar músculo se suele recomendar entre 1,6 y 2,2 g de proteína por kilo de peso al día. Para un plan de alimentación o suplementos adaptado a ti, consulta a un nutricionista: este chat responde sobre entrenamiento y técnica.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('27', 'estiramientos', 'estirar, estiramiento, estiramientos, elongar, elongacion, movilidad, flexibilidad', 'Los estiramientos estáticos largos conviene dejarlos para después de entrenar o para otro momento. Antes de entrenar es mejor la movilidad dinámica: círculos de brazos, balanceos de piernas y sentadillas sin peso.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('28', 'recuperacion', 'dormir, sueno, recuperacion, recuperarme, sobreentrenamiento, cansado, agotado, deload', 'Dormir 7 a 9 horas es clave para recuperarte y ganar fuerza. Si te sientes agotado, rindes menos varias sesiones seguidas o duermes mal, haz una semana de descarga con la mitad de las series.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('29', 'series_reps', 'cuantas series, cuantas repeticiones, series y repeticiones, reps, repeticiones, series', 'Depende de tu objetivo: fuerza, 3 a 6 repeticiones; hipertrofia, 8 a 12; resistencia, 15 o más. En general, 3 a 4 series por ejercicio y 10 a 20 series por grupo muscular a la semana funcionan bien.', '¿Cuántas series y repeticiones hago?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('30', 'respiracion', 'respirar, respiracion, aire', 'Toma aire antes de la parte difícil del movimiento y bótalo al terminar el esfuerzo (al subir en la sentadilla o al empujar en el press). En levantamientos pesados, mantener el aire con el abdomen firme ayuda a proteger la espalda.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('31', 'app_xp', 'xp, experiencia, nivel, niveles, subir de nivel, puntos', 'En PonteChetado ganas 2 XP por cada serie que registras y 1 XP por cada 250 kg de volumen (peso × repeticiones). Cada nivel pide 50 XP más que el anterior, y tu avatar evoluciona al subir de nivel. Revisa tu avance en la pestaña Progreso.', '¿Cómo gano XP en la app?', '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('32', 'app_avatar', 'avatar, personaje, mi avatar', 'Tu avatar se edita en Perfil → Mi avatar. Eliges género, piel, peinado y colores, y a medida que subes de nivel gana muñequeras, hombros más anchos, cintillo, medalla y hasta corona.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('33', 'app_rutina', 'rutina personalizada, generar rutina, que rutina, armar rutina, crear rutina, rutina', 'Ve a Rutinas → Arma tu rutina personalizada: eliges tu objetivo (fuerza, hipertrofia, híbrido o salud) y los días que entrenas, y la app te arma una rutina para cada día con sus series y repeticiones.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('34', 'entrenador', 'entrenador, coach, profesor, ayuda presencial, alguien que me ayude', 'Si necesitas que alguien revise tu técnica, pide ayuda a un entrenador de tu gimnasio. Muy pronto podrás llamarlo directamente desde la app con el botón de ayuda.', NULL, '0');
INSERT IGNORE INTO `chatbot_respuestas` (`id`, `tema`, `palabras_clave`, `respuesta`, `ejemplo`, `es_respaldo`) VALUES ('35', 'respaldo', '', 'No tengo una respuesta para eso. Solo respondo sobre ejercicios, técnica y entrenamiento. Prueba con algo como «¿Cómo hago una sentadilla?» o «¿Cuánto descanso entre series?».', NULL, '1');

-- ---------- Gimnasios asociados ----------
INSERT INTO gimnasios (nombre) SELECT 'Marfit' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM gimnasios WHERE nombre = 'Marfit');
INSERT INTO gimnasios (nombre) SELECT 'Energy' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM gimnasios WHERE nombre = 'Energy');

SET FOREIGN_KEY_CHECKS = 1;

-- Revisión rápida
SELECT (SELECT COUNT(*) FROM ejercicios) AS ejercicios, (SELECT COUNT(*) FROM objetivos) AS objetivos,
       (SELECT COUNT(*) FROM chatbot_respuestas) AS respuestas_chatbot, (SELECT COUNT(*) FROM gimnasios) AS gimnasios;
