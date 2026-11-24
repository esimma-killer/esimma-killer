-- E-SIIMA Killer - Vistas de consulta global

CREATE OR REPLACE VIEW vista_alumnos_global AS
SELECT
    id_campus,
    id_alumno,
    id_usuario,
    matricula,
    nombre_completo,
    carrera,
    semestre
FROM alumnos;

CREATE OR REPLACE VIEW vista_profesores_global AS
SELECT
    publico.id_campus,
    publico.id_profesor,
    publico.id_usuario,
    publico.nombre_completo,
    publico.departamento,
    publico.cubiculo,
    publico.email_contacto
FROM profesores_publico AS publico;

CREATE OR REPLACE VIEW vista_inscripciones_global AS
SELECT
    inscripciones.id_campus,
    inscripciones.id_inscripcion,
    inscripciones.id_alumno,
    inscripciones.id_curso,
    inscripciones.fecha_inscripcion,
    alumnos.matricula,
    cursos.clave_materia,
    cursos.periodo_semestral
FROM inscripciones
JOIN alumnos
  ON alumnos.id_campus = inscripciones.id_campus
 AND alumnos.id_alumno = inscripciones.id_alumno
JOIN cursos
  ON cursos.id_campus = inscripciones.id_campus
 AND cursos.id_curso = inscripciones.id_curso;
