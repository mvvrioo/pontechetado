-- =====================================================================
--  PonteChetado - Datos de demostración (solo para Docker)
--  Docker lo carga una sola vez, justo después de instalacion_completa.sql,
--  para que la app se pueda probar apenas se levanta.
--  Todas las cuentas usan la contraseña: Chetado2026
-- =====================================================================
SET NAMES utf8mb4;
USE pontechetado;

INSERT INTO gimnasios (nombre, direccion) VALUES ('Gimnasio Demo', 'Av. Demo 123, Santiago');
SET @gimnasio = LAST_INSERT_ID();

INSERT INTO usuarios (nombre, email, password_hash, rol, gimnasio_id, premium_hasta) VALUES
  ('Superadmin Demo', 'superadmin.demo@pontechetado.test', '$2y$10$fgJRffmLmLEe5P9nRlkcSe9.ItgZ.dB1GvoO2ZEIKgEGxquE8fmt6', 'superadmin',     NULL,      NULL),
  ('Admin Demo',      'admin.demo@pontechetado.test',      '$2y$10$fgJRffmLmLEe5P9nRlkcSe9.ItgZ.dB1GvoO2ZEIKgEGxquE8fmt6', 'admin_gimnasio', @gimnasio, NULL),
  ('Entrenador Demo', 'entrenador.demo@pontechetado.test', '$2y$10$fgJRffmLmLEe5P9nRlkcSe9.ItgZ.dB1GvoO2ZEIKgEGxquE8fmt6', 'entrenador',     @gimnasio, NULL),
  ('Usuario Demo',    'usuario.demo@pontechetado.test',    '$2y$10$fgJRffmLmLEe5P9nRlkcSe9.ItgZ.dB1GvoO2ZEIKgEGxquE8fmt6', 'usuario',        @gimnasio, DATE_ADD(NOW(), INTERVAL 1 YEAR)),
  ('Socio Gratis',    'gratis.demo@pontechetado.test',     '$2y$10$fgJRffmLmLEe5P9nRlkcSe9.ItgZ.dB1GvoO2ZEIKgEGxquE8fmt6', 'usuario',        NULL,      NULL);
