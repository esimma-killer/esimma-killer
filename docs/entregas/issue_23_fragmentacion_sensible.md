# Issue #23: fragmentación vertical de profesores

Este Issue separa el perfil de consulta normal de los datos personales y patrimoniales del profesor. La tabla pública conserva únicamente los datos académicos y de contacto. RFC, CURP, salario, cuenta bancaria y domicilio se guardan en `datos_sensibles.profesores_sensible` como `BYTEA` cifrado con `pgcrypto`.

## Relación con el Issue #18

El esquema base conserva la llave compuesta `(id_campus, id_profesor)` de `profesores_publico`, para que cada fila sensible corresponda al profesor correcto dentro de su campus. El archivo `backend/database/postgresql/01_profesores_base.sql` incluye solo las tablas mínimas (`campus`, `usuarios` y `profesores_publico`) para que este Issue pueda probarse por separado; no reemplaza el esquema completo del Issue #18.

Si la migración se ejecuta después del DDL completo del Issue #18, detecta y mueve su tabla `public.profesores_sensible` al esquema restringido `datos_sensibles`, en vez de conservar una segunda copia.

Se usa el nombre `profesores_sensible` del esquema SQL existente y de la propuesta técnica. El nombre identifica el fragmento sensible aunque el Issue también lo describa como información confidencial.

## Acceso y cifrado

- `datos_sensibles` no concede acceso a `PUBLIC`.
- `esimma_gestion_sensibles` es un rol grupal `NOLOGIN`; una cuenta autorizada debe recibir membresía de ese rol por parte del administrador de la base. El rol puede consultar el fragmento cifrado, pero no insertar directamente.
- El acceso público al perfil se realiza mediante `public.vista_profesores_publico`, `public.obtener_perfil_profesor_publico(...)` o `CALL public.consultar_perfil_profesor_publico_sp(...)`. Ninguno devuelve información fiscal ni patrimonial.
- La escritura de datos sensibles se hace mediante `datos_sensibles.guardar_profesor_sensible(...)`, que cifra los cinco campos con `pgcrypto` antes de almacenarlos. La función usa permisos de su propietario; el rol de aplicación solo tiene permiso para ejecutarla.
- La clave de cifrado se recibe en tiempo de ejecución. No debe guardarse en el repositorio ni reutilizarse la clave sintética del script de pruebas.
- El rol `NOLOGIN` no crea usuarios de aplicación ni asigna contraseñas; esa configuración depende del entorno y debe hacerse fuera de estos scripts.

## Orden de aplicación y prueba

En una base de pruebas vacía, con PostgreSQL y permisos administrativos:

1. Aplicar `backend/database/postgresql/01_profesores_base.sql`.
2. Aplicar `backend/database/postgresql/04_fragmentacion_sensible.sql`.
3. Aplicar `backend/database/postgresql/05_pruebas_sensibles.sql`.

Si ya está instalado el esquema del Issue #18, no volver a crear una base alternativa: aplicar solamente `04_fragmentacion_sensible.sql` y después `05_pruebas_sensibles.sql` en esa misma base. La prueba usa datos sintéticos dentro de una transacción y termina con `ROLLBACK`.

El script de pruebas comprueba que los cinco valores se almacenan cifrados y se recuperan con la clave de prueba, que la vista y el procedimiento no publican esos campos, que `PUBLIC` no tiene acceso directo a la tabla y que el rol autorizado tiene los permisos esperados.

> **Estado de validación:** los scripts y las pruebas están preparados, pero falta ejecutarlos en la instalación PostgreSQL del proyecto y conservar la salida como evidencia. La documentación no considera validado el Issue hasta observar que la ejecución termina correctamente.
