"""Definicion y validacion en Python de los esquemas NoSQL e indices de MongoDB (Issue #20)."""

from typing import Any

from src.domain.exceptions import ValidacionDominioError

ROLES_VALIDOS: set[str] = {
    "visitante",
    "estudiante",
    "profesor",
    "coordinador",
    "administrativo",
}

CAMPUS_VALIDOS: set[int] = {1, 2}

LOGS_AUDITORIA_JSON_SCHEMA: dict[str, Any] = {
    "bsonType": "object",
    "required": [
        "id_usuario",
        "rol",
        "id_campus",
        "accion",
        "resultado",
        "ip_origen",
        "timestamp",
    ],
    "properties": {
        "id_usuario": {"bsonType": "string"},
        "rol": {"bsonType": "string", "enum": sorted(ROLES_VALIDOS)},
        "id_campus": {"bsonType": "int", "enum": [1, 2]},
        "accion": {"bsonType": "string"},
        "entidad_afectada": {"bsonType": "string"},
        "resultado": {"bsonType": "string", "enum": ["EXITO", "ERROR"]},
        "ip_origen": {"bsonType": "string"},
        "timestamp": {"bsonType": "string"},
        "detalle": {"bsonType": "string"},
    },
}

TELEMETRIA_ACCESOS_JSON_SCHEMA: dict[str, Any] = {
    "bsonType": "object",
    "required": [
        "id_sesion",
        "id_usuario",
        "rol",
        "id_campus",
        "endpoint",
        "metodo_http",
        "status_code",
        "latencia_ms",
        "franja_horaria",
        "timestamp",
    ],
    "properties": {
        "id_sesion": {"bsonType": "string"},
        "id_usuario": {"bsonType": "string"},
        "rol": {"bsonType": "string", "enum": sorted(ROLES_VALIDOS)},
        "id_campus": {"bsonType": "int", "enum": [1, 2]},
        "endpoint": {"bsonType": "string"},
        "metodo_http": {
            "bsonType": "string",
            "enum": ["GET", "POST", "PUT", "PATCH", "DELETE"],
        },
        "status_code": {"bsonType": "int", "minimum": 100, "maximum": 599},
        "latencia_ms": {"bsonType": ["double", "int"], "minimum": 0},
        "plataforma_cliente": {
            "bsonType": "string",
            "enum": ["web", "mobile", "desktop"],
        },
        "franja_horaria": {"bsonType": "int", "minimum": 0, "maximum": 23},
        "timestamp": {"bsonType": "string"},
    },
}

EVENTOS_ENTREGAS_JSON_SCHEMA: dict[str, Any] = {
    "bsonType": "object",
    "required": [
        "id_entrega",
        "id_tarea",
        "materia_clave",
        "departamento",
        "alumno_matricula",
        "id_campus",
        "fecha_limite",
        "fecha_entrega",
        "estado_entrega",
        "ponderacion",
        "calificacion",
        "hash_sha256",
    ],
    "properties": {
        "id_entrega": {"bsonType": "string"},
        "id_tarea": {"bsonType": "string"},
        "materia_clave": {"bsonType": "string"},
        "departamento": {"bsonType": "string"},
        "docente_empleado": {"bsonType": "string"},
        "alumno_matricula": {"bsonType": "string"},
        "id_campus": {"bsonType": "int", "enum": [1, 2]},
        "fecha_limite": {"bsonType": "string"},
        "fecha_entrega": {"bsonType": "string"},
        "estado_entrega": {"bsonType": "string", "enum": ["A_TIEMPO", "TARDIA"]},
        "ponderacion": {"bsonType": ["double", "int"], "minimum": 0.1, "maximum": 100.0},
        "calificacion": {"bsonType": ["double", "int"], "minimum": 0.0, "maximum": 10.0},
        "hash_sha256": {"bsonType": "string", "minLength": 64, "maxLength": 64},
    },
}

MONGO_COLLECTION_SCHEMAS: dict[str, dict[str, Any]] = {
    "logs_auditoria": LOGS_AUDITORIA_JSON_SCHEMA,
    "telemetria_accesos": TELEMETRIA_ACCESOS_JSON_SCHEMA,
    "eventos_entregas": EVENTOS_ENTREGAS_JSON_SCHEMA,
}

MONGO_INDEX_DEFINITIONS: dict[str, list[dict[str, Any]]] = {
    "logs_auditoria": [
        {
            "name": "idx_auditoria_campus_fecha",
            "keys": [("id_campus", 1), ("timestamp", -1)],
            "unique": False,
        },
        {
            "name": "idx_auditoria_usuario_fecha",
            "keys": [("id_usuario", 1), ("timestamp", -1)],
            "unique": False,
        },
        {
            "name": "idx_auditoria_accion_resultado",
            "keys": [("accion", 1), ("resultado", 1)],
            "unique": False,
        },
    ],
    "telemetria_accesos": [
        {
            "name": "idx_telemetria_campus_franja_fecha",
            "keys": [("id_campus", 1), ("franja_horaria", 1), ("timestamp", -1)],
            "unique": False,
        },
        {
            "name": "idx_telemetria_usuario_fecha",
            "keys": [("id_usuario", 1), ("timestamp", -1)],
            "unique": False,
        },
        {
            "name": "idx_telemetria_endpoint_status",
            "keys": [("endpoint", 1), ("status_code", 1)],
            "unique": False,
        },
    ],
    "eventos_entregas": [
        {
            "name": "idx_entregas_campus_estado_fecha",
            "keys": [("id_campus", 1), ("estado_entrega", 1), ("fecha_entrega", -1)],
            "unique": False,
        },
        {
            "name": "idx_entregas_materia_campus",
            "keys": [("materia_clave", 1), ("id_campus", 1)],
            "unique": False,
        },
        {
            "name": "idx_entregas_alumno_tarea_unique",
            "keys": [("alumno_matricula", 1), ("id_tarea", 1)],
            "unique": True,
        },
    ],
}


class MongoCollectionValidator:
    """Valida documentos contra el JSON Schema de MongoDB y verifica planes de indices."""

    @staticmethod
    def validar_documento(coleccion: str, documento: dict[str, Any]) -> dict[str, Any]:
        """Valida que un documento cumpla con las reglas de $jsonSchema de la coleccion."""
        if coleccion not in MONGO_COLLECTION_SCHEMAS:
            raise ValidacionDominioError(
                mensaje=f"La coleccion MongoDB '{coleccion}' no esta registrada en el esquema.",
                campo="coleccion",
            )

        esquema = MONGO_COLLECTION_SCHEMAS[coleccion]
        requeridos: list[str] = esquema["required"]
        propiedades: dict[str, dict[str, Any]] = esquema["properties"]

        faltantes = [campo for campo in requeridos if campo not in documento]
        if faltantes:
            raise ValidacionDominioError(
                mensaje=(
                    f"Documento invalido para '{coleccion}': faltan campos "
                    f"obligatorios {faltantes}."
                ),
                campo=faltantes[0],
            )

        for campo, valor in documento.items():
            if campo not in propiedades:
                continue
            regla = propiedades[campo]
            bson_type = regla.get("bsonType")

            if bson_type == "string" and not isinstance(valor, str):
                raise ValidacionDominioError(
                    mensaje=f"El campo '{campo}' debe ser string.",
                    campo=campo,
                )
            if bson_type == "int" and (not isinstance(valor, int) or isinstance(valor, bool)):
                raise ValidacionDominioError(
                    mensaje=f"El campo '{campo}' debe ser entero (int).",
                    campo=campo,
                )
            if isinstance(bson_type, list) and not isinstance(valor, (int, float)):
                raise ValidacionDominioError(
                    mensaje=f"El campo '{campo}' debe ser numerico.",
                    campo=campo,
                )

            if "enum" in regla and valor not in regla["enum"]:
                raise ValidacionDominioError(
                    mensaje=(
                        f"Valor '{valor}' no permitido para '{campo}'. "
                        f"Opciones validas: {regla['enum']}."
                    ),
                    campo=campo,
                )

            if "minimum" in regla and isinstance(valor, (int, float)) and valor < regla["minimum"]:
                raise ValidacionDominioError(
                    mensaje=f"El campo '{campo}' ({valor}) es menor al minimo {regla['minimum']}.",
                    campo=campo,
                )
            if "maximum" in regla and isinstance(valor, (int, float)) and valor > regla["maximum"]:
                raise ValidacionDominioError(
                    mensaje=f"El campo '{campo}' ({valor}) excede el maximo {regla['maximum']}.",
                    campo=campo,
                )
            if "minLength" in regla and isinstance(valor, str) and len(valor) < regla["minLength"]:
                raise ValidacionDominioError(
                    mensaje=(
                        f"El campo '{campo}' debe tener longitud minima de "
                        f"{regla['minLength']} caracteres."
                    ),
                    campo=campo,
                )

        return dict(documento)

    @staticmethod
    def simular_explain_consulta(
        coleccion: str,
        campos_filtro: list[str],
        campos_orden: list[str] | None = None,
    ) -> dict[str, Any]:
        """Determina si una consulta utiliza un indice compuesto (IXSCAN) por prefijo."""
        if coleccion not in MONGO_INDEX_DEFINITIONS:
            raise ValidacionDominioError(
                mensaje=f"Coleccion '{coleccion}' sin definicion de indices.",
                campo="coleccion",
            )

        campos_consulta = list(campos_filtro) + list(campos_orden or [])
        indices_coleccion = MONGO_INDEX_DEFINITIONS[coleccion]

        for idx in indices_coleccion:
            llaves_idx = [k[0] for k in idx["keys"]]
            # Regla de prefijo izquierdo de indices compuestos en MongoDB
            prefijo_coincide = all(
                pos < len(llaves_idx) and llaves_idx[pos] == campo
                for pos, campo in enumerate(campos_filtro)
            )
            if prefijo_coincide and campos_filtro:
                return {
                    "coleccion": coleccion,
                    "queryPlanner": {
                        "winningPlan": {
                            "stage": "IXSCAN",
                            "indexName": idx["name"],
                            "keyPattern": dict(idx["keys"]),
                        }
                    },
                    "executionStats": {
                        "executionSuccess": True,
                        "stage": "IXSCAN",
                        "indexName": idx["name"],
                        "campos_cubiertos": campos_consulta,
                    },
                }

        return {
            "coleccion": coleccion,
            "queryPlanner": {
                "winningPlan": {
                    "stage": "COLLSCAN",
                    "indexName": None,
                }
            },
            "executionStats": {
                "executionSuccess": True,
                "stage": "COLLSCAN",
                "indexName": None,
                "campos_cubiertos": campos_consulta,
            },
        }
