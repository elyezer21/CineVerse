-- =====================================================================
--  CineVerse - Script de base de datos (MySQL / MariaDB de XAMPP)
--  Importar en phpMyAdmin (pestaña "Importar") o con:
--     mysql -u root < database/cineverse.sql
--  Crea la BD "cineverse" con las tablas usuarios, favoritos y
--  configuracion_usuario (esta última la usa api/cuenta.jsp al borrar).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS cineverse
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cineverse;

-- ---------------------------------------------------------------------
-- Tabla: usuarios
-- password guarda el hash BCrypt (60 caracteres). Si existen cuentas
-- viejas con la contraseña en texto plano, login.jsp las sigue aceptando
-- y las convierte a BCrypt la primera vez que el usuario inicia sesión.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(80)  NOT NULL,
  apellido       VARCHAR(80)  NOT NULL,
  email          VARCHAR(150) NOT NULL,
  password       VARCHAR(255) NOT NULL,
  fecha_registro TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_usuarios_email UNIQUE (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: favoritos  (películas de TMDB guardadas por cada usuario)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favoritos (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id    INT          NOT NULL,
  tmdb_id       INT          NOT NULL,
  titulo        VARCHAR(255) NOT NULL,
  poster_path   VARCHAR(255) NULL,
  fecha_agregado TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_favorito UNIQUE (usuario_id, tmdb_id),
  CONSTRAINT fk_favoritos_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: configuracion_usuario  (preferencias opcionales por usuario)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS configuracion_usuario (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT         NOT NULL,
  clave      VARCHAR(60) NOT NULL,
  valor      VARCHAR(255) NULL,
  CONSTRAINT uq_config UNIQUE (usuario_id, clave),
  CONSTRAINT fk_config_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;
