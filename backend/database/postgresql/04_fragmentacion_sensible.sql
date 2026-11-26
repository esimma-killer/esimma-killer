-- Issue #23: fragmentacion vertical y proteccion de datos sensibles de profesores.
-- Ejecutar despues de 01_profesores_base.sql y con un usuario administrador.
-- Las claves se entregan en tiempo de ejecucion; no se guardan en este repositorio.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS datos_sensibles;

REVOKE ALL ON SCHEMA datos_sensibles FROM PUBLIC;
REVOKE ALL ON TABLE profesores_publico FROM PUBLIC;

-- Si se ejecuta sobre el esquema completo de Issue #18, reutiliza y mueve
-- su tabla existente en lugar de crear una segunda tabla sensible.
DO $$
BEGIN
    IF to_regclass('datos_sensibles.profesores_sensible') IS NULL
       AND to_regclass('public.profesores_sensible') IS NOT NULL THEN
        ALTER TABLE public.profesores_sensible SET SCHEMA datos_sensibles;
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS datos_sensibles.profesores_sensible (
    id_campus SMALLINT NOT NULL,
    id_profesor BIGINT NOT NULL,
    rfc_cifrado BYTEA NOT NULL,
    curp_cifrada BYTEA NOT NULL,
    salario_base BYTEA NOT NULL,
    cuenta_bancaria BYTEA NOT NULL,
    direccion_particular BYTEA NOT NULL,
    PRIMARY KEY (id_campus, id_profesor),
    FOREIGN KEY (id_campus, id_profesor)
        REFERENCES profesores_publico(id_campus, id_profesor)
        ON DELETE CASCADE,
    CONSTRAINT chk_profesor_sensible_campus CHECK (id_campus IN (1, 2))
);

ALTER TABLE datos_sensibles.profesores_sensible
    ALTER COLUMN rfc_cifrado SET NOT NULL,
    ALTER COLUMN curp_cifrada SET NOT NULL,
    ALTER COLUMN salario_base SET NOT NULL,
    ALTER COLUMN cuenta_bancaria SET NOT NULL,
    ALTER COLUMN direccion_particular SET NOT NULL;

COMMENT ON TABLE datos_sensibles.profesores_sensible IS
    'Fragmento vertical de profesores con PII y datos patrimoniales cifrados.';
COMMENT ON COLUMN datos_sensibles.profesores_sensible.rfc_cifrado IS
    'RFC cifrado con pgcrypto.pgp_sym_encrypt.';
COMMENT ON COLUMN datos_sensibles.profesores_sensible.curp_cifrada IS
    'CURP cifrada con pgcrypto.pgp_sym_encrypt.';
COMMENT ON COLUMN datos_sensibles.profesores_sensible.salario_base IS
    'Salario cifrado como BYTEA; no almacenar el monto en texto claro.';
COMMENT ON COLUMN datos_sensibles.profesores_sensible.cuenta_bancaria IS
    'Cuenta bancaria cifrada como BYTEA.';
COMMENT ON COLUMN datos_sensibles.profesores_sensible.direccion_particular IS
    'Domicilio cifrado como BYTEA.';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'esimma_gestion_sensibles'
    ) THEN
        CREATE ROLE esimma_gestion_sensibles NOLOGIN;
    END IF;
END
$$;

CREATE OR REPLACE VIEW public.vista_profesores_publico AS
SELECT
    id_campus,
    id_profesor,
    id_usuario,
    nombre_completo,
    departamento,
    cubiculo,
    email_contacto
FROM public.profesores_publico;

CREATE OR REPLACE FUNCTION public.obtener_perfil_profesor_publico(
    p_id_campus SMALLINT,
    p_id_profesor BIGINT
)
RETURNS TABLE (
    id_campus SMALLINT,
    id_profesor BIGINT,
    nombre_completo VARCHAR(120),
    departamento VARCHAR(80),
    cubiculo VARCHAR(20),
    email_contacto VARCHAR(120)
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT
        profesor.id_campus,
        profesor.id_profesor,
        profesor.nombre_completo,
        profesor.departamento,
        profesor.cubiculo,
        profesor.email_contacto
    FROM public.profesores_publico AS profesor
    WHERE profesor.id_campus = p_id_campus
      AND profesor.id_profesor = p_id_profesor
$$;

CREATE OR REPLACE PROCEDURE public.consultar_perfil_profesor_publico_sp(
    IN p_id_campus SMALLINT,
    IN p_id_profesor BIGINT,
    OUT p_nombre_completo VARCHAR(120),
    OUT p_departamento VARCHAR(80),
    OUT p_cubiculo VARCHAR(20),
    OUT p_email_contacto VARCHAR(120)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    SELECT
        profesor.nombre_completo,
        profesor.departamento,
        profesor.cubiculo,
        profesor.email_contacto
    INTO
        p_nombre_completo,
        p_departamento,
        p_cubiculo,
        p_email_contacto
    FROM public.profesores_publico AS profesor
    WHERE profesor.id_campus = p_id_campus
      AND profesor.id_profesor = p_id_profesor;
END
$$;

CREATE OR REPLACE FUNCTION datos_sensibles.guardar_profesor_sensible(
    p_id_campus SMALLINT,
    p_id_profesor BIGINT,
    p_rfc TEXT,
    p_curp TEXT,
    p_salario_base NUMERIC,
    p_cuenta_bancaria TEXT,
    p_direccion_particular TEXT,
    p_clave_cifrado TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, datos_sensibles
AS $$
BEGIN
    IF p_clave_cifrado IS NULL OR length(p_clave_cifrado) < 16 THEN
        RAISE EXCEPTION 'La clave de cifrado debe tener al menos 16 caracteres.';
    END IF;

    INSERT INTO datos_sensibles.profesores_sensible (
        id_campus,
        id_profesor,
        rfc_cifrado,
        curp_cifrada,
        salario_base,
        cuenta_bancaria,
        direccion_particular
    )
    VALUES (
        p_id_campus,
        p_id_profesor,
        public.pgp_sym_encrypt(p_rfc, p_clave_cifrado),
        public.pgp_sym_encrypt(p_curp, p_clave_cifrado),
        public.pgp_sym_encrypt(p_salario_base::TEXT, p_clave_cifrado),
        public.pgp_sym_encrypt(p_cuenta_bancaria, p_clave_cifrado),
        public.pgp_sym_encrypt(p_direccion_particular, p_clave_cifrado)
    )
    ON CONFLICT (id_campus, id_profesor) DO UPDATE SET
        rfc_cifrado = EXCLUDED.rfc_cifrado,
        curp_cifrada = EXCLUDED.curp_cifrada,
        salario_base = EXCLUDED.salario_base,
        cuenta_bancaria = EXCLUDED.cuenta_bancaria,
        direccion_particular = EXCLUDED.direccion_particular;
END
$$;

REVOKE ALL ON TABLE datos_sensibles.profesores_sensible FROM PUBLIC;
REVOKE ALL ON TABLE datos_sensibles.profesores_sensible
    FROM esimma_gestion_sensibles;
REVOKE ALL ON FUNCTION datos_sensibles.guardar_profesor_sensible(
    SMALLINT, BIGINT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT
) FROM PUBLIC;

GRANT SELECT ON public.vista_profesores_publico TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.obtener_perfil_profesor_publico(
    SMALLINT, BIGINT
) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE public.consultar_perfil_profesor_publico_sp(
    SMALLINT, BIGINT
) TO PUBLIC;

GRANT USAGE ON SCHEMA datos_sensibles TO esimma_gestion_sensibles;
GRANT SELECT ON TABLE datos_sensibles.profesores_sensible
    TO esimma_gestion_sensibles;
GRANT EXECUTE ON FUNCTION datos_sensibles.guardar_profesor_sensible(
    SMALLINT, BIGINT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT
) TO esimma_gestion_sensibles;

COMMIT;
