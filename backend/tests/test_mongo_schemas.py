"""Pruebas unitarias para los esquemas NoSQL, validadores e indices de MongoDB (Issue #20)."""

from pathlib import Path

import pytest
from src.domain.exceptions import ValidacionDominioError
from src.domain.mongo_schemas import (
    MONGO_COLLECTION_SCHEMAS,
    MONGO_INDEX_DEFINITIONS,
    MongoCollectionValidator,
)


def test_definicion_de_las_tres_colecciones_e_indices() -> None:
    """Verifica que existan las 3 colecciones documentales y sus 9 indices configurados."""
    assert set(MONGO_COLLECTION_SCHEMAS.keys()) == {
        "logs_auditoria",
        "telemetria_accesos",
        "eventos_entregas",
    }
    assert len(MONGO_INDEX_DEFINITIONS["logs_auditoria"]) == 3
    assert len(MONGO_INDEX_DEFINITIONS["telemetria_accesos"]) == 3
    assert len(MONGO_INDEX_DEFINITIONS["eventos_entregas"]) == 3


def test_validacion_exitosa_y_rechazo_en_logs_auditoria() -> None:
    """Valida insercion sintetica en logs_auditoria y rechazo ante campos invalidos."""
    validador = MongoCollectionValidator()
    doc_valido = {
        "id_usuario": "ID300001",
        "rol": "estudiante",
        "id_campus": 1,
        "accion": "inscripcion_materia",
        "entidad_afectada": "Inscripcion",
        "resultado": "EXITO",
        "ip_origen": "127.0.0.1",
        "timestamp": "2026-11-23T15:00:00Z",
        "detalle": "Inscripcion confirmada",
    }
    resultado = validador.validar_documento("logs_auditoria", doc_valido)
    assert resultado["id_campus"] == 1

    # Campus fuera de [1, 2]
    doc_campus_invalido = {**doc_valido, "id_campus": 5}
    with pytest.raises(ValidacionDominioError, match="id_campus"):
        validador.validar_documento("logs_auditoria", doc_campus_invalido)

    # Falta campo requerido
    doc_incompleto = {"id_usuario": "ID300001"}
    with pytest.raises(ValidacionDominioError, match="faltan campos"):
        validador.validar_documento("logs_auditoria", doc_incompleto)


def test_validacion_telemetria_accesos_y_eventos_entregas() -> None:
    """Valida documentos sinteticos de telemetria_accesos y eventos_entregas."""
    validador = MongoCollectionValidator()

    telemetria_ok = {
        "id_sesion": "SES-001",
        "id_usuario": "ID300001",
        "rol": "estudiante",
        "id_campus": 1,
        "endpoint": "/api/v1/academico/entregas",
        "metodo_http": "POST",
        "status_code": 201,
        "latencia_ms": 35.4,
        "plataforma_cliente": "web",
        "franja_horaria": 23,
        "timestamp": "2026-11-23T23:50:00Z",
    }
    assert validador.validar_documento("telemetria_accesos", telemetria_ok)["status_code"] == 201

    with pytest.raises(ValidacionDominioError, match="franja_horaria"):
        validador.validar_documento("telemetria_accesos", {**telemetria_ok, "franja_horaria": 25})

    entrega_ok = {
        "id_entrega": "ENT-001",
        "id_tarea": "TAR-001",
        "materia_clave": "ISC-0101",
        "departamento": "Sistemas de Informacion",
        "alumno_matricula": "ID300001",
        "id_campus": 2,
        "fecha_limite": "2026-11-23T23:59:00Z",
        "fecha_entrega": "2026-11-23T21:00:00Z",
        "estado_entrega": "A_TIEMPO",
        "ponderacion": 20.0,
        "calificacion": 9.5,
        "hash_sha256": "a" * 64,
    }
    assert validador.validar_documento("eventos_entregas", entrega_ok)["id_campus"] == 2

    with pytest.raises(ValidacionDominioError, match="hash_sha256"):
        validador.validar_documento("eventos_entregas", {**entrega_ok, "hash_sha256": "hash_corto"})

    with pytest.raises(ValidacionDominioError, match="coleccion"):
        validador.validar_documento("coleccion_inexistente", {})


def test_verificacion_indices_con_explain_execution_stats() -> None:
    """Verifica que las consultas por campus, fecha y usuario utilicen IXSCAN en explain()."""
    validador = MongoCollectionValidator()

    explain_auditoria = validador.simular_explain_consulta(
        coleccion="logs_auditoria",
        campos_filtro=["id_campus"],
        campos_orden=["timestamp"],
    )
    assert explain_auditoria["executionStats"]["stage"] == "IXSCAN"
    assert explain_auditoria["executionStats"]["indexName"] == "idx_auditoria_campus_fecha"

    explain_telemetria = validador.simular_explain_consulta(
        coleccion="telemetria_accesos",
        campos_filtro=["id_campus", "franja_horaria"],
        campos_orden=["timestamp"],
    )
    assert explain_telemetria["executionStats"]["stage"] == "IXSCAN"
    assert explain_telemetria["executionStats"]["indexName"] == "idx_telemetria_campus_franja_fecha"

    explain_entregas = validador.simular_explain_consulta(
        coleccion="eventos_entregas",
        campos_filtro=["id_campus", "estado_entrega"],
    )
    assert explain_entregas["executionStats"]["stage"] == "IXSCAN"
    assert explain_entregas["executionStats"]["indexName"] == "idx_entregas_campus_estado_fecha"

    # Consulta por campo no indexado produce COLLSCAN
    explain_no_idx = validador.simular_explain_consulta(
        coleccion="logs_auditoria",
        campos_filtro=["ip_origen"],
    )
    assert explain_no_idx["executionStats"]["stage"] == "COLLSCAN"


def test_script_init_mongo_schemas_js_existe_y_contiene_validadores() -> None:
    """Comprueba que el script oficial de MongoDB incluya $jsonSchema, indices y explain()."""
    ruta_js = (
        Path(__file__).resolve().parent.parent / "database" / "mongodb" / "init_mongo_schemas.js"
    )
    assert ruta_js.exists()
    contenido = ruta_js.read_text(encoding="utf-8")
    assert "$jsonSchema" in contenido
    assert "logs_auditoria" in contenido
    assert "telemetria_accesos" in contenido
    assert "eventos_entregas" in contenido
    assert 'explain("executionStats")' in contenido
