-- =====================================================================
--  PonteChetado - Contextura del avatar (delgada, media o gruesa)
--  Para bases ya instaladas. instalacion_completa.sql ya trae esta columna.
-- =====================================================================
USE pontechetado;

ALTER TABLE avatares
  ADD COLUMN contextura ENUM('delgada','media','gruesa') NOT NULL DEFAULT 'media' AFTER genero;
