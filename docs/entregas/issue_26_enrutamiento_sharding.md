# Issue #26: enrutamiento de PostgreSQL por campus

La API selecciona el shard por `X-Campus-ID`: `1` dirige al Campus Central y `2` al Campus Sur. El middleware valida el encabezado y guarda el campus en el estado de la petición. La dependencia `get_shard_connection` obtiene la conexión del pool correspondiente, y `ShardedPostgresPools` mantiene pools separados por nodo.

## Preparación incluida

- Pools independientes con apertura perezosa y cierre al apagar FastAPI.
- Rechazo de campus inválidos y de operaciones que necesitan conexión cuando falta `X-Campus-ID`.
- Pruebas unitarias de enrutamiento, middleware, dependencia y solicitudes concurrentes simuladas.
- Prueba de integración contra ambos PostgreSQL, activada al definir `TEST_SHARD_CENTRAL_DSN` y `TEST_SHARD_SUR_DSN`.

La prueba de integración consulta `current_database()` en ambos nodos y envía varias solicitudes concurrentes. Los DSN de prueba deben apuntar a las bases `esimma_central` y `esimma_sur` levantadas por el Compose del Issue #18. No se deben usar las credenciales de producción.

## Validación pendiente

Aún se debe ejecutar la suite unitaria y levantar PostgreSQL para la prueba de integración. El test unitario concurrente usa pools simulados; por sí solo no demuestra aislamiento físico. Solo la prueba con ambos servicios de PostgreSQL puede aportar esa evidencia.

La cabecera identifica el campus para enrutamiento, pero en el despliegue integrado debe vincularse con el campus autorizado del usuario/token. La cabecera por sí sola no es una credencial de seguridad.
