-- E-SIIMA Killer - Esquema PostgreSQL
-- Issue #18: modelo relacional y particionamiento horizontal por id_campus

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
    CONSTRAINT chk_usuario_rol CHECK (rol IN ('estudiante', 'profesor', 'coordinador'))
);

CREATE TABLE IF NOT EXISTS materias (
    clave_materia VARCHAR(12) PRIMARY KEY,
    nombre_materia VARCHAR(120) NOT NULL,
    departamento VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS alumnos (
    id_alumno BIGINT,
    id_usuario BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    matricula VARCHAR(12) NOT NULL,
    nombre_completo VARCHAR(120) NOT NULL,
    carrera VARCHAR(80) NOT NULL,
    semestre SMALLINT NOT NULL,
    PRIMARY KEY (id_campus, id_alumno),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    CONSTRAINT uq_alumno_usuario_campus UNIQUE (id_campus, id_usuario),
    CONSTRAINT uq_alumno_matricula_campus UNIQUE (id_campus, matricula),
    CONSTRAINT chk_alumno_campus CHECK (id_campus IN (1, 2)),
    CONSTRAINT chk_alumno_semestre CHECK (semestre BETWEEN 1 AND 12)
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS alumnos_campus_central
    PARTITION OF alumnos FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS alumnos_campus_sur
    PARTITION OF alumnos FOR VALUES IN (2);

CREATE TABLE IF NOT EXISTS profesores_publico (
    id_profesor BIGINT,
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

CREATE TABLE IF NOT EXISTS profesores_sensible (
    id_campus SMALLINT NOT NULL,
    id_profesor BIGINT NOT NULL,
    rfc_cifrado BYTEA,
    curp_cifrada BYTEA,
    salario_base BYTEA,
    cuenta_bancaria BYTEA,
    direccion_particular BYTEA,
    PRIMARY KEY (id_campus, id_profesor),
    FOREIGN KEY (id_campus, id_profesor)
        REFERENCES profesores_publico(id_campus, id_profesor)
        ON DELETE CASCADE,
    CONSTRAINT chk_profesor_sensible_campus CHECK (id_campus IN (1, 2))
);

CREATE TABLE IF NOT EXISTS cursos (
    id_curso BIGINT,
    id_profesor BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    clave_materia VARCHAR(12) NOT NULL,
    periodo_semestral VARCHAR(10) NOT NULL,
    cupo_maximo SMALLINT NOT NULL,
    PRIMARY KEY (id_campus, id_curso),
    FOREIGN KEY (clave_materia) REFERENCES materias(clave_materia),
    FOREIGN KEY (id_campus, id_profesor)
        REFERENCES profesores_publico(id_campus, id_profesor),
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    CONSTRAINT chk_curso_campus CHECK (id_campus IN (1, 2)),
    CONSTRAINT chk_cupo_maximo CHECK (cupo_maximo > 0)
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS cursos_campus_central
    PARTITION OF cursos FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS cursos_campus_sur
    PARTITION OF cursos FOR VALUES IN (2);

CREATE TABLE IF NOT EXISTS inscripciones (
    id_inscripcion BIGINT,
    id_alumno BIGINT NOT NULL,
    id_curso BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    fecha_inscripcion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_campus, id_inscripcion),
    FOREIGN KEY (id_campus, id_alumno)
        REFERENCES alumnos(id_campus, id_alumno),
    FOREIGN KEY (id_campus, id_curso)
        REFERENCES cursos(id_campus, id_curso),
    CONSTRAINT uq_inscripcion_alumno_curso UNIQUE (id_campus, id_alumno, id_curso),
    CONSTRAINT chk_inscripcion_campus CHECK (id_campus IN (1, 2))
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS inscripciones_campus_central
    PARTITION OF inscripciones FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS inscripciones_campus_sur
    PARTITION OF inscripciones FOR VALUES IN (2);

CREATE TABLE IF NOT EXISTS tareas (
    id_tarea BIGINT,
    id_curso BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT,
    fecha_limite TIMESTAMPTZ NOT NULL,
    ponderacion NUMERIC(5,2) NOT NULL,
    PRIMARY KEY (id_campus, id_tarea),
    FOREIGN KEY (id_campus, id_curso)
        REFERENCES cursos(id_campus, id_curso),
    CONSTRAINT chk_tarea_campus CHECK (id_campus IN (1, 2)),
    CONSTRAINT chk_ponderacion CHECK (ponderacion BETWEEN 0 AND 100)
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS tareas_campus_central
    PARTITION OF tareas FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS tareas_campus_sur
    PARTITION OF tareas FOR VALUES IN (2);

CREATE TABLE IF NOT EXISTS entregas (
    id_entrega BIGINT,
    id_tarea BIGINT NOT NULL,
    id_alumno BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    fecha_entrega TIMESTAMPTZ NOT NULL,
    archivo_url VARCHAR(300) NOT NULL,
    hash_sha256 CHAR(64) NOT NULL,
    estado_entrega VARCHAR(10) NOT NULL,
    calificacion NUMERIC(5,2),
    retroalimentacion TEXT,
    PRIMARY KEY (id_campus, id_entrega),
    FOREIGN KEY (id_campus, id_tarea)
        REFERENCES tareas(id_campus, id_tarea),
    FOREIGN KEY (id_campus, id_alumno)
        REFERENCES alumnos(id_campus, id_alumno),
    CONSTRAINT uq_entrega_tarea_alumno UNIQUE (id_campus, id_tarea, id_alumno),
    CONSTRAINT chk_entrega_campus CHECK (id_campus IN (1, 2)),
    CONSTRAINT chk_estado_entrega CHECK (estado_entrega IN ('A_TIEMPO', 'TARDIA')),
    CONSTRAINT chk_entrega_calificacion
        CHECK (calificacion IS NULL OR calificacion BETWEEN 0 AND 100),
    CONSTRAINT chk_hash_sha256 CHECK (hash_sha256 ~ '^[0-9A-Fa-f]{64}$')
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS entregas_campus_central
    PARTITION OF entregas FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS entregas_campus_sur
    PARTITION OF entregas FOR VALUES IN (2);

CREATE TABLE IF NOT EXISTS pagos (
    id_pago BIGINT,
    id_usuario BIGINT NOT NULL,
    id_campus SMALLINT NOT NULL,
    concepto VARCHAR(120) NOT NULL,
    monto NUMERIC(10,2) NOT NULL,
    estado VARCHAR(15) NOT NULL,
    fecha_pago TIMESTAMPTZ,
    PRIMARY KEY (id_campus, id_pago),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    CONSTRAINT chk_pago_campus CHECK (id_campus IN (1, 2)),
    CONSTRAINT chk_pago_monto CHECK (monto >= 0),
    CONSTRAINT chk_pago_estado CHECK (estado IN ('PENDIENTE', 'PAGADO', 'RECHAZADO'))
) PARTITION BY LIST (id_campus);

CREATE TABLE IF NOT EXISTS pagos_campus_central
    PARTITION OF pagos FOR VALUES IN (1);

CREATE TABLE IF NOT EXISTS pagos_campus_sur
    PARTITION OF pagos FOR VALUES IN (2);

CREATE INDEX IF NOT EXISTS idx_alumnos_campus_matricula
    ON alumnos (id_campus, matricula);
CREATE INDEX IF NOT EXISTS idx_cursos_campus_materia
    ON cursos (id_campus, clave_materia);
CREATE INDEX IF NOT EXISTS idx_inscripciones_campus_alumno
    ON inscripciones (id_campus, id_alumno);
CREATE INDEX IF NOT EXISTS idx_tareas_campus_curso_fecha
    ON tareas (id_campus, id_curso, fecha_limite);
CREATE INDEX IF NOT EXISTS idx_entregas_campus_tarea
    ON entregas (id_campus, id_tarea);
CREATE INDEX IF NOT EXISTS idx_entregas_campus_estado
    ON entregas (id_campus, estado_entrega);
CREATE INDEX IF NOT EXISTS idx_pagos_campus_usuario
    ON pagos (id_campus, id_usuario);

COMMIT;
