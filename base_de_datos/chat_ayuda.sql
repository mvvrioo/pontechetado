-- =====================================================================
--  PonteChetado - Chat entre el socio y el entrenador
--  Cada solicitud de ayuda tiene su propio chat, para resolver dudas sin
--  que el entrenador tenga que ir (ej: una consulta sobre la mensualidad).
--  Ejecutar en MySQL Workbench con el botón del rayo.
--  Se puede volver a ejecutar sin problemas: no duplica nada.
-- =====================================================================

USE pontechetado;
SET NAMES utf8mb4;

-- Nuevo motivo: consultas que no requieren que el entrenador vaya
ALTER TABLE solicitudes_ayuda
    MODIFY COLUMN motivo ENUM('tecnica', 'rutina', 'maquina', 'consulta', 'otro') NOT NULL;

CREATE TABLE IF NOT EXISTS mensajes_ayuda (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    solicitud_id  INT NOT NULL,
    usuario_id    INT NOT NULL,              -- quién lo escribió (socio o entrenador)
                                             -- (sin FK: usuarios.id es INT UNSIGNED)
    texto         VARCHAR(500) NOT NULL,
    creado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    leido_en      DATETIME NULL,             -- cuándo lo leyó la otra persona
    KEY idx_mensajes_solicitud (solicitud_id, id),
    CONSTRAINT fk_mensaje_solicitud FOREIGN KEY (solicitud_id) REFERENCES solicitudes_ayuda (id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

SELECT COUNT(*) AS mensajes_de_chat FROM mensajes_ayuda;
