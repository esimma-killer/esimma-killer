-- Base minima del Issue #18 necesaria para probar el Issue #23 de forma aislada.
-- Mantiene el contrato de id_campus e id_profesor de profesores_publico.
-- Solo incluye campus, usuarios y profesores_publico; no duplica el esquema completo.

BEGIN;

CREATE TABLE IF NOT EXISTS campus (
    id_campus SMALLINT PRIMARY KEY,
    nombre_campus VARCHAR(80) NOT NULL,
    codigo_campus VARCHAR(10) NOT NULL UNIQUE,
    direccion VARCHAR(200),
    CONSTRAINT chk_campus_permitidos CHECK (id_campus IN (1, 2))
);

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario BIGINT PRIMARY KEY,
    correo_institucional VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(15) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_usuario_rol
        CHECK (rol IN ('estudiante', 'profesor', 'coordinador'))
);

CREATE TABLE IF NOT EXISTS profesores_publico (
    id_profesor BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    nombre_completo VARCHAR(120) NOT NULL,
    departamento VARCHAR(80) NOT NULL,
    cubiculo VARCHAR(20),
    email_contacto VARCHAR(120),
    PRIMARY KEY (id_campus, id_profesor),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    CONSTRAINT uq_profesor_usuario_campus UNIQUE (id_campus, id_usuario),
    CONSTRAINT chk_profesor_campus CHECK (id_campus IN (1, 2))
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS profesores_publico_campus_central
    PARTITION OF profesores_publico FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS profesores_publico_campus_sur
    PARTITION OF profesores_publico FOR VALUES IN (2);

COMMIT;
