-- Issue #24: procedimientos transaccionales para inscripciones y pagos.
-- Requiere el esquema del Issue #18 y se aplica en cada nodo PostgreSQL.

CREATE OR REPLACE PROCEDURE public.registrar_inscripcion(
    IN p_id_campus SMALLINT,
    IN p_id_inscripcion BIGINT,
    IN p_id_alumno BIGINT,
    IN p_id_curso BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cupo_maximo SMALLINT;
    v_inscripciones_actuales BIGINT;
BEGIN
    -- El bloqueo serializa las inscripciones simultaneas del mismo curso.
    SELECT curso.cupo_maximo
    INTO v_cupo_maximo
    FROM public.cursos AS curso
    WHERE curso.id_campus = p_id_campus
      AND curso.id_curso = p_id_curso
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Curso % no encontrado en el campus %.',
            p_id_curso, p_id_campus;
    END IF;

    SELECT COUNT(*)
    INTO v_inscripciones_actuales
    FROM public.inscripciones AS inscripcion
    WHERE inscripcion.id_campus = p_id_campus
      AND inscripcion.id_curso = p_id_curso;

    IF v_inscripciones_actuales >= v_cupo_maximo THEN
        RAISE EXCEPTION 'Cupo completo para el curso % en el campus %.',
            p_id_curso, p_id_campus;
    END IF;

    INSERT INTO public.inscripciones (
        id_campus,
        id_inscripcion,
        id_alumno,
        id_curso
    )
    VALUES (
        p_id_campus,
        p_id_inscripcion,
        p_id_alumno,
        p_id_curso
    );
END
$$;

CREATE OR REPLACE PROCEDURE public.registrar_pago(
    IN p_id_pago BIGINT,
    IN p_id_usuario BIGINT,
    IN p_id_campus SMALLINT,
    IN p_concepto VARCHAR(120),
    IN p_monto NUMERIC(10, 2),
    IN p_aprobado BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_monto <= 0 THEN
        RAISE EXCEPTION 'El monto del pago debe ser mayor que cero.';
    END IF;

    -- La fila pendiente solo se conserva si el pago finaliza aprobado.
    INSERT INTO public.pagos (
        id_pago,
        id_usuario,
        id_campus,
        concepto,
        monto,
        estado,
        fecha_pago
    )
    VALUES (
        p_id_pago,
        p_id_usuario,
        p_id_campus,
        p_concepto,
        p_monto,
        'PENDIENTE',
        NULL
    );

    IF NOT p_aprobado THEN
        RAISE EXCEPTION 'Pago cancelado o rechazado; se revierte la operacion.';
    END IF;

    UPDATE public.pagos
    SET estado = 'PAGADO',
        fecha_pago = CURRENT_TIMESTAMP
    WHERE id_campus = p_id_campus
      AND id_pago = p_id_pago;
END
$$;
