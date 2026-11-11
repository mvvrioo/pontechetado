-- =====================================================================
--  PonteChetado - Ranking Top 10 y ayuda de un entrenador
--  (Historias 012, 013, 014 y 015)
--  Ejecutar en MySQL Workbench con el botón del rayo.
--  Se puede volver a ejecutar sin problemas: no duplica nada.
--
--  Modelo:
--    usuarios.rol            -> se agrega el rol 'entrenador'
--    ranking_posiciones      -> último puesto conocido de cada usuario en
--                               el ranking de su gimnasio (para avisarle si
--                               subió o bajó al terminar el entreno)
--    solicitudes_ayuda       -> pedidos de ayuda de los socios a los
--                               entrenadores de su gimnasio
-- =====================================================================

USE pontechetado;
SET NAMES utf8mb4;

-- Nuevo rol: entrenador del gimnasio (lo asigna el admin del gimnasio)
ALTER TABLE usuarios
    MODIFY COLUMN rol ENUM('usuario', 'entrenador', 'admin_gimnasio', 'superadmin') NOT NULL DEFAULT 'usuario';

CREATE TABLE IF NOT EXISTS ranking_posiciones (
    usuario_id      INT           NOT NULL PRIMARY KEY,
    gimnasio_id     INT           NOT NULL,
    posicion        INT           NOT NULL,
    puntaje         DECIMAL(7,1)  NOT NULL,
    actualizado_en  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_ranking_gimnasio (gimnasio_id, posicion),
    CONSTRAINT fk_ranking_gimnasio FOREIGN KEY (gimnasio_id) REFERENCES gimnasios (id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS solicitudes_ayuda (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id    INT NOT NULL,
    gimnasio_id   INT NOT NULL,
    motivo        ENUM('tecnica', 'rutina', 'maquina', 'otro') NOT NULL,
    ejercicio_id  INT NULL,
    mensaje       VARCHAR(255) NULL,
    estado        ENUM('pendiente', 'atendida', 'cancelada') NOT NULL DEFAULT 'pendiente',
    atendida_por  INT NULL,
    creada_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atendida_en   DATETIME NULL,
    KEY idx_ayuda_gimnasio (gimnasio_id, estado, id),
    KEY idx_ayuda_usuario (usuario_id, id),
    CONSTRAINT fk_ayuda_gimnasio FOREIGN KEY (gimnasio_id) REFERENCES gimnasios (id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Revisión rápida
SELECT (SELECT COUNT(*) FROM ranking_posiciones) AS posiciones_guardadas,
       (SELECT COUNT(*) FROM solicitudes_ayuda)  AS solicitudes_de_ayuda;
