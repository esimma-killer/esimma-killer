-- Pruebas SQL permanentes para Issue #23.
-- Requiere 01_profesores_base.sql y 04_fragmentacion_sensible.sql.
-- Usa unicamente datos sinteticos y revierte los INSERT al terminar.

BEGIN;

INSERT INTO public.campus (id_campus, nombre_campus, codigo_campus)
VALUES (1, 'Campus Central', 'CENTRAL')
ON CONFLICT (id_campus) DO NOTHING;

INSERT INTO public.usuarios (
    id_usuario,
    correo_institucional,
    password_hash,
    rol
)
VALUES (
    987654321,
    'profesor.sintetico.issue23@edu.uaa.mx',
    'hash-sintetico-no-utilizable',
    'profesor'
)
ON CONFLICT (id_usuario) DO NOTHING;

INSERT INTO public.profesores_publico (
    id_campus,
    id_profesor,
    id_usuario,
    nombre_completo,
    departamento,
    cubiculo,
    email_contacto
)
VALUES (
    1,
    987654321,
    987654321,
    'Profesor Sintetico Issue 23',
    'Sistemas de Informacion',
    'Edificio 1 - Cubiculo 1',
    'profesor.sintetico.issue23@edu.uaa.mx'
)
ON CONFLICT (id_campus, id_profesor) DO NOTHING;

SELECT datos_sensibles.guardar_profesor_sensible(
    1,
    987654321,
    'RFC-SINTETICO-ISSUE23',
    'CURP-SINTETICA-ISSUE23',
    32000.00,
    'CUENTA-SINTETICA-ISSUE23',
    'DOMICILIO-SINTETICO-ISSUE23',
    'CLAVE-SOLO-PRUEBAS-ISSUE23'
);

DO $$
DECLARE
    datos_cifrados RECORD;
    dato_sensible_en_vista BOOLEAN;
    permiso_publico BOOLEAN;
    permiso_vista_publica BOOLEAN;
    perfil_publico_disponible BOOLEAN;
    procedimiento_publico_disponible BOOLEAN;
    perfil_nombre VARCHAR(120);
    perfil_departamento VARCHAR(80);
    perfil_cubiculo VARCHAR(20);
    perfil_email VARCHAR(120);
    acceso_directo_profesores_publico BOOLEAN;
    rol_puede_insertar_directamente BOOLEAN;
BEGIN
    IF to_regprocedure('public.pgp_sym_encrypt(text,text)') IS NULL THEN
        RAISE EXCEPTION 'No esta disponible pgcrypto.pgp_sym_encrypt.';
    END IF;

    SELECT
        sensible.rfc_cifrado,
        sensible.curp_cifrada,
        sensible.salario_base,
        sensible.cuenta_bancaria,
        sensible.direccion_particular
    INTO datos_cifrados
    FROM datos_sensibles.profesores_sensible AS sensible
    WHERE sensible.id_campus = 1
      AND sensible.id_profesor = 987654321;

    IF datos_cifrados.rfc_cifrado IS NULL
       OR datos_cifrados.curp_cifrada IS NULL
       OR datos_cifrados.salario_base IS NULL
       OR datos_cifrados.cuenta_bancaria IS NULL
       OR datos_cifrados.direccion_particular IS NULL THEN
        RAISE EXCEPTION 'Falta almacenar alguno de los campos sensibles cifrados.';
    END IF;

    IF datos_cifrados.rfc_cifrado = convert_to('RFC-SINTETICO-ISSUE23', 'UTF8')
       OR datos_cifrados.curp_cifrada = convert_to('CURP-SINTETICA-ISSUE23', 'UTF8')
       OR datos_cifrados.salario_base = convert_to('32000.00', 'UTF8')
       OR datos_cifrados.cuenta_bancaria = convert_to('CUENTA-SINTETICA-ISSUE23', 'UTF8')
       OR datos_cifrados.direccion_particular = convert_to('DOMICILIO-SINTETICO-ISSUE23', 'UTF8') THEN
        RAISE EXCEPTION 'Al menos un dato sensible esta guardado sin cifrado.';
    END IF;

    IF public.pgp_sym_decrypt(
        datos_cifrados.rfc_cifrado,
        'CLAVE-SOLO-PRUEBAS-ISSUE23'
    ) <> 'RFC-SINTETICO-ISSUE23'
       OR public.pgp_sym_decrypt(
           datos_cifrados.curp_cifrada,
           'CLAVE-SOLO-PRUEBAS-ISSUE23'
       ) <> 'CURP-SINTETICA-ISSUE23'
       OR public.pgp_sym_decrypt(
           datos_cifrados.salario_base,
           'CLAVE-SOLO-PRUEBAS-ISSUE23'
       ) <> '32000.00'
       OR public.pgp_sym_decrypt(
           datos_cifrados.cuenta_bancaria,
           'CLAVE-SOLO-PRUEBAS-ISSUE23'
       ) <> 'CUENTA-SINTETICA-ISSUE23'
       OR public.pgp_sym_decrypt(
           datos_cifrados.direccion_particular,
           'CLAVE-SOLO-PRUEBAS-ISSUE23'
       ) <> 'DOMICILIO-SINTETICO-ISSUE23' THEN
        RAISE EXCEPTION 'El descifrado no recupero todos los datos sinteticos.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'vista_profesores_publico'
          AND column_name IN (
              'rfc_cifrado',
              'curp_cifrada',
              'salario_base',
              'cuenta_bancaria',
              'direccion_particular'
          )
    ) INTO dato_sensible_en_vista;

    IF dato_sensible_en_vista THEN
        RAISE EXCEPTION 'La vista publica expone columnas sensibles.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_class AS tabla
        JOIN pg_namespace AS esquema ON esquema.oid = tabla.relnamespace
        CROSS JOIN LATERAL aclexplode(
            COALESCE(tabla.relacl, acldefault('r', tabla.relowner))
        ) AS permiso
        WHERE esquema.nspname = 'public'
          AND tabla.relname = 'profesores_publico'
          AND permiso.grantee = 0
          AND permiso.privilege_type = 'SELECT'
    ) INTO acceso_directo_profesores_publico;

    IF acceso_directo_profesores_publico THEN
        RAISE EXCEPTION 'PUBLIC tiene acceso directo a la tabla base de profesores.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.obtener_perfil_profesor_publico(1, 987654321)
    ) INTO perfil_publico_disponible;

    IF NOT perfil_publico_disponible THEN
        RAISE EXCEPTION 'La funcion no devuelve el perfil publico sintetico.';
    END IF;

    CALL public.consultar_perfil_profesor_publico_sp(
        1,
        987654321,
        perfil_nombre,
        perfil_departamento,
        perfil_cubiculo,
        perfil_email
    );

    IF perfil_nombre <> 'Profesor Sintetico Issue 23'
       OR perfil_departamento <> 'Sistemas de Informacion'
       OR perfil_email <> 'profesor.sintetico.issue23@edu.uaa.mx' THEN
        RAISE EXCEPTION 'El procedimiento no devuelve el perfil publico esperado.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_proc AS procedimiento
        JOIN pg_namespace AS esquema ON esquema.oid = procedimiento.pronamespace
        CROSS JOIN LATERAL aclexplode(
            COALESCE(
                procedimiento.proacl,
                acldefault('f', procedimiento.proowner)
            )
        ) AS permiso
        WHERE esquema.nspname = 'public'
          AND procedimiento.proname = 'consultar_perfil_profesor_publico_sp'
          AND procedimiento.prokind = 'p'
          AND permiso.grantee = 0
          AND permiso.privilege_type = 'EXECUTE'
    ) INTO procedimiento_publico_disponible;

    IF NOT procedimiento_publico_disponible THEN
        RAISE EXCEPTION 'PUBLIC no puede ejecutar el procedimiento de perfil publico.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_class AS tabla
        JOIN pg_namespace AS esquema ON esquema.oid = tabla.relnamespace
        CROSS JOIN LATERAL aclexplode(
            COALESCE(tabla.relacl, acldefault('r', tabla.relowner))
        ) AS permiso
        WHERE esquema.nspname = 'datos_sensibles'
          AND tabla.relname = 'profesores_sensible'
          AND permiso.grantee = 0
          AND permiso.privilege_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
    ) INTO permiso_publico;

    IF permiso_publico THEN
        RAISE EXCEPTION 'PUBLIC conserva permisos directos sobre la tabla sensible.';
    END IF;

    IF NOT has_schema_privilege(
        'esimma_gestion_sensibles', 'datos_sensibles', 'USAGE'
    ) OR NOT has_table_privilege(
        'esimma_gestion_sensibles',
        'datos_sensibles.profesores_sensible',
        'SELECT'
    ) OR NOT has_function_privilege(
        'esimma_gestion_sensibles',
        'datos_sensibles.guardar_profesor_sensible(SMALLINT,BIGINT,TEXT,TEXT,NUMERIC,TEXT,TEXT,TEXT)',
        'EXECUTE'
    ) THEN
        RAISE EXCEPTION 'El rol autorizado no tiene los permisos esperados.';
    END IF;

    SELECT has_table_privilege(
        'esimma_gestion_sensibles',
        'datos_sensibles.profesores_sensible',
        'INSERT'
    ) INTO rol_puede_insertar_directamente;

    IF rol_puede_insertar_directamente THEN
        RAISE EXCEPTION 'El rol debe guardar datos mediante la funcion que cifra.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_class AS vista
        JOIN pg_namespace AS esquema ON esquema.oid = vista.relnamespace
        CROSS JOIN LATERAL aclexplode(
            COALESCE(vista.relacl, acldefault('r', vista.relowner))
        ) AS permiso
        WHERE esquema.nspname = 'public'
          AND vista.relname = 'vista_profesores_publico'
          AND permiso.grantee = 0
          AND permiso.privilege_type = 'SELECT'
    ) INTO permiso_vista_publica;

    IF NOT permiso_vista_publica THEN
        RAISE EXCEPTION 'La consulta de perfiles publicos no esta disponible.';
    END IF;

    RAISE NOTICE 'Issue #23: separacion, cifrado, permisos y perfil publico verificados.';
END
$$;

ROLLBACK;
