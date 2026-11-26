-- Pruebas SQL de integración del Issue #24.
-- Ejecutar después del esquema y datos sintéticos del Issue #18 y del archivo 04.
-- Todo queda dentro de una transacción que se revierte al final.

BEGIN;

INSERT INTO public.usuarios (
    id_usuario,
    correo_institucional,
    password_hash,
    rol
)
VALUES (
    989001,
    'qa.issue24@edu.uaa.mx',
    'HASH_SINTETICO_QA_24',
    'estudiante'
)
ON CONFLICT (id_usuario) DO NOTHING;

INSERT INTO public.alumnos (
    id_alumno,
    id_usuario,
    id_campus,
    matricula,
    nombre_completo,
    carrera,
    semestre
)
VALUES (
    989001,
    989001,
    1,
    'QA240001',
    'Alumno Sintetico QA',
    'Ingenieria en Sistemas',
    6
)
ON CONFLICT (id_campus, id_alumno) DO NOTHING;

DO $$
DECLARE
    v_inscripciones BIGINT;
    v_resultado TEXT;
BEGIN
    -- Deja exactamente un lugar para la primera llamada.
    SELECT COUNT(*)
    INTO v_inscripciones
    FROM public.inscripciones
    WHERE id_campus = 1 AND id_curso = 1;

    UPDATE public.cursos
    SET cupo_maximo = (v_inscripciones + 1)::SMALLINT
    WHERE id_campus = 1 AND id_curso = 1;

    CALL public.registrar_inscripcion(1, 989001, 989001, 1);

    IF NOT EXISTS (
        SELECT 1 FROM public.inscripciones
        WHERE id_campus = 1 AND id_inscripcion = 989001
    ) THEN
        RAISE EXCEPTION 'No se guardo la inscripcion aprobada.';
    END IF;

    -- Al llenarse el curso, la llamada falla y no deja una segunda inscripcion.
    SELECT COUNT(*)
    INTO v_inscripciones
    FROM public.inscripciones
    WHERE id_campus = 1 AND id_curso = 1;

    UPDATE public.cursos
    SET cupo_maximo = v_inscripciones::SMALLINT
    WHERE id_campus = 1 AND id_curso = 1;

    BEGIN
        CALL public.registrar_inscripcion(1, 989002, 989001, 1);
        RAISE EXCEPTION 'La prueba esperaba que el curso rechazara el cupo lleno.';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_resultado = MESSAGE_TEXT;
        IF v_resultado NOT LIKE 'Cupo completo para el curso %' THEN
            RAISE;
        END IF;
    END;

    IF EXISTS (
        SELECT 1 FROM public.inscripciones
        WHERE id_campus = 1 AND id_inscripcion = 989002
    ) THEN
        RAISE EXCEPTION 'El rechazo por cupo dejo una fila parcial.';
    END IF;

    -- La fila PENDIENTE insertada internamente debe desaparecer al cancelar.
    BEGIN
        CALL public.registrar_pago(
            989001, 1001, 1, 'Prueba sintetica Issue 24', 100.00, FALSE
        );
        RAISE EXCEPTION 'La prueba esperaba que el pago se cancelara.';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_resultado = MESSAGE_TEXT;
        IF v_resultado NOT LIKE 'Pago cancelado o rechazado%' THEN
            RAISE;
        END IF;
    END;

    IF EXISTS (
        SELECT 1 FROM public.pagos
        WHERE id_campus = 1 AND id_pago = 989001
    ) THEN
        RAISE EXCEPTION 'El pago cancelado dejo una fila parcial.';
    END IF;

    CALL public.registrar_pago(
        989002, 1001, 1, 'Pago sintetico aprobado Issue 24', 100.00, TRUE
    );

    IF NOT EXISTS (
        SELECT 1 FROM public.pagos
        WHERE id_campus = 1
          AND id_pago = 989002
          AND estado = 'PAGADO'
          AND fecha_pago IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'El pago aprobado no quedo confirmado.';
    END IF;

    RAISE NOTICE 'Issue #24: cupo, inscripcion atomica y commit/rollback de pagos verificados.';
END
$$;

ROLLBACK;
