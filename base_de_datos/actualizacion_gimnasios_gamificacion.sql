-- =====================================================================
--  PonteChetado - Actualización: Gimnasios + Gamificación
--  Ejecutar UNA sola vez en MySQL Workbench (botón del rayo ⚡).
--
--  Agrega:
--    1. Tabla de gimnasios asociados (Marfit y Energy de partida).
--    2. Roles de usuario: usuario / admin_gimnasio / superadmin.
--    3. Gimnasio al que pertenece cada usuario (o que administra el admin).
--    4. Día de la semana de cada rutina (Lunes = 1 ... Domingo = 7).
--    5. Historial de activaciones Premium hechas por los gimnasios.
--
--  La XP NO se guarda en una tabla: se calcula a partir de las series
--  registradas. Así, si alguien borra una serie, también pierde esa XP.
-- =====================================================================

USE pontechetado;

-- Workbench trae activado el "safe update mode", que bloquea algunos UPDATE.
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- 1. Gimnasios
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gimnasios (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nombre     VARCHAR(100) NOT NULL,
    direccion  VARCHAR(200) NULL,
    creado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_gimnasios_nombre (nombre)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT IGNORE INTO gimnasios (nombre, direccion) VALUES
    ('Marfit', NULL),
    ('Energy', NULL);

-- ---------------------------------------------------------------------
-- 2 y 3. Rol del usuario y gimnasio al que pertenece
--   - usuario:        cliente normal. gimnasio_id = gimnasio donde paga.
--   - admin_gimnasio: recepción/administración del gimnasio. gimnasio_id = el que administra.
--   - superadmin:     ustedes (PonteChetado). Crean gimnasios y asignan admins.
-- ---------------------------------------------------------------------
ALTER TABLE usuarios
    ADD COLUMN rol ENUM('usuario', 'admin_gimnasio', 'superadmin') NOT NULL DEFAULT 'usuario',
    ADD COLUMN gimnasio_id INT NULL,
    ADD CONSTRAINT fk_usuarios_gimnasio
        FOREIGN KEY (gimnasio_id) REFERENCES gimnasios (id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------
-- 4. Día de la semana de cada rutina (NULL = sin día asignado)
-- ---------------------------------------------------------------------
ALTER TABLE rutinas
    ADD COLUMN dia_semana TINYINT NULL;

-- ---------------------------------------------------------------------
-- 5. Historial de activaciones (quién activó/quitó Premium y cuándo)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historial_premium (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id   INT NOT NULL,
    gimnasio_id  INT NOT NULL,
    admin_id     INT NOT NULL,
    accion       ENUM('activar', 'quitar') NOT NULL,
    dias         INT NULL,
    creado_en    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_historial_usuario (usuario_id),
    KEY idx_historial_gimnasio (gimnasio_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Para que el cálculo de XP sea rápido
CREATE INDEX idx_series_usuario_fecha ON series_entrenamiento (usuario_id, fecha);

-- ---------------------------------------------------------------------
-- 6. Tu cuenta pasa a ser SUPERADMIN
--    👉 Si tu cuenta usa otro correo, cámbialo aquí antes de ejecutar.
-- ---------------------------------------------------------------------
UPDATE usuarios SET rol = 'superadmin' WHERE email = 'marij.torres@duocuc.cl';

SET SQL_SAFE_UPDATES = 1;

-- Revisión rápida: deberías ver Marfit y Energy, y tu cuenta como superadmin
SELECT * FROM gimnasios;
SELECT id, nombre, email, rol, gimnasio_id, premium_hasta FROM usuarios;
