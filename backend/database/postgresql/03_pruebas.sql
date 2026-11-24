-- E-SIIMA Killer - Datos y comprobaciones del Issue #18

INSERT INTO campus (id_campus, nombre_campus, codigo_campus, direccion)
VALUES
    (1, 'Campus Central', 'CENTRAL', 'Avenida Universidad'),
    (2, 'Campus Sur', 'SUR', 'Campus Sur')
ON CONFLICT (id_campus) DO NOTHING;

INSERT INTO materias (clave_materia, nombre_materia, departamento)
VALUES
    ('ISC-101', 'Ingenieria de Software', 'Ingenieria'),
    ('SIST-201', 'Sistemas Distribuidos', 'Ingenieria')
ON CONFLICT (clave_materia) DO NOTHING;

INSERT INTO usuarios (id_usuario, correo_institucional, password_hash, rol)
VALUES
    (1001, 'alumno.central@edu.uaa.mx', 'HASH_SINTETICO', 'estudiante'),
    (1002, 'alumno.sur@edu.uaa.mx', 'HASH_SINTETICO', 'estudiante'),
    (2001, 'profesor.central@edu.uaa.mx', 'HASH_SINTETICO', 'profesor'),
    (2002, 'profesor.sur@edu.uaa.mx', 'HASH_SINTETICO', 'profesor')
ON CONFLICT (id_usuario) DO NOTHING;

INSERT INTO alumnos (
    id_alumno, id_usuario, id_campus, matricula,
    nombre_completo, carrera, semestre
)
VALUES
    (1, 1001, 1, 'AL100001', 'Alumno Central Prueba', 'Ingenieria en Sistemas', 7),
    (2, 1002, 2, 'AL200002', 'Alumno Sur Prueba', 'Ingenieria en Sistemas', 7)
ON CONFLICT (id_campus, id_alumno) DO NOTHING;

INSERT INTO profesores_publico (
    id_profesor, id_usuario, id_campus, nombre_completo,
    departamento, cubiculo, email_contacto
)
VALUES
    (1, 2001, 1, 'Profesor Central Prueba', 'Ingenieria', 'A101', 'central@edu.uaa.mx'),
    (2, 2002, 2, 'Profesor Sur Prueba', 'Ingenieria', 'B202', 'sur@edu.uaa.mx')
ON CONFLICT (id_campus, id_profesor) DO NOTHING;

INSERT INTO cursos (
    id_curso, id_profesor, id_campus, clave_materia,
    periodo_semestral, cupo_maximo
)
VALUES
    (1, 1, 1, 'SIST-201', '2026-2', 30),
    (2, 2, 2, 'SIST-201', '2026-2', 30)
ON CONFLICT (id_campus, id_curso) DO NOTHING;

INSERT INTO inscripciones (
    id_inscripcion, id_alumno, id_curso, id_campus
)
VALUES
    (1, 1, 1, 1),
    (2, 2, 2, 2)
ON CONFLICT (id_campus, id_inscripcion) DO NOTHING;

-- Comprobacion: debe existir una fila en cada particion.
DO $$
DECLARE
    total_central BIGINT;
    total_sur BIGINT;
BEGIN
    SELECT COUNT(*) INTO total_central
    FROM alumnos_campus_central;

    SELECT COUNT(*) INTO total_sur
    FROM alumnos_campus_sur;

    IF total_central < 1 OR total_sur < 1 THEN
        RAISE EXCEPTION 'Las particiones no contienen datos de prueba esperados';
    END IF;
END $$;

-- Consultas utiles para la evidencia del Issue #18:
-- SELECT * FROM alumnos_campus_central;
-- SELECT * FROM alumnos_campus_sur;
-- SELECT * FROM vista_alumnos_global;
-- SELECT tableoid::regclass, id_campus, matricula FROM alumnos;
-- EXPLAIN (COSTS OFF) SELECT * FROM alumnos WHERE id_campus = 1;
