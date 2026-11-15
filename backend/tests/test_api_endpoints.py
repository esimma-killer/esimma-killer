"""Pruebas unitarias para la configuracion, contratos OpenAPI y Routers de FastAPI."""

import json

import pytest
from src.api.dependencies import (
    get_inscripcion_service,
    get_pago_service,
    reset_services_for_testing,
)
from src.api.routers.academico import (
    consultar_auditoria_academica,
    crear_alumno,
    crear_inscripcion,
    crear_materia,
    listar_alumnos,
    listar_inscripciones,
    listar_materias,
    obtener_alumno,
    registrar_entrega,
)
from src.api.routers.health import verificar_salud
from src.api.routers.informacion import (
    obtener_informacion_institucional,
    obtener_metadatos_campus,
)
from src.api.routers.pagos import listar_pagos, obtener_pago, procesar_pago
from src.api.schemas import (
    AlumnoCreateRequest,
    EntregaTareaRequest,
    InscripcionCreateRequest,
    MateriaCreateRequest,
    PagoCreateRequest,
)
from src.core.config import get_settings
from src.domain.exceptions import (
    DominioError,
    InscripcionInvalidaError,
    PagoRechazadoError,
    RecursoNoEncontradoError,
)
from src.main import app, create_app
from starlette.requests import Request


def _ejecutar_corutina_inmediata(corutina: object) -> object:
    """Evalua una funcion async sin I/O pendiente sin requerir sockets del SO."""
    try:
        corutina.send(None)  # type: ignore[attr-defined]
    except StopIteration as stop:
        return stop.value
    raise RuntimeError("La corutina no finalizo de forma inmediata.")


def test_configuracion_y_resolucion_de_shards() -> None:
    """Verifica Settings y la resolucion de metadatos por id_campus (1 y 2)."""
    settings = get_settings()
    shard_central = settings.obtener_info_shard(1)
    shard_sur = settings.obtener_info_shard(2)

    assert shard_central["nombre_campus"] == "Campus Central"
    assert shard_sur["nombre_campus"] == "Campus Sur"

    with pytest.raises(ValueError, match="Shard Key"):
        settings.obtener_info_shard(99)


def test_creacion_app_fastapi_y_contrato_openapi() -> None:
    """Valida que create_app configure rutas, tags y esquema OpenAPI (/docs)."""
    instancia = create_app()
    esquema = instancia.openapi()

    assert esquema["info"]["title"] == "E-SIIMA Killer API (E-SIIMA 3)"
    rutas = esquema["paths"]
    assert "/api/v1/health" in rutas
    assert "/api/v1/informacion" in rutas
    assert "/api/v1/academico/alumnos" in rutas
    assert "/api/v1/academico/inscripciones" in rutas
    assert "/api/v1/pagos" in rutas


def test_manejadores_globales_de_excepciones_http_400_y_404() -> None:
    """Verifica que los exception handlers conviertan errores del dominio en JSON 404/400."""
    request_falso = Request(
        {"type": "http", "method": "GET", "path": "/api/v1/test", "headers": []}
    )

    handler_404 = app.exception_handlers[RecursoNoEncontradoError]
    exc_404 = RecursoNoEncontradoError(recurso="Alumno", identificador="ID000")
    resp_404 = _ejecutar_corutina_inmediata(handler_404(request_falso, exc_404))
    assert resp_404.status_code == 404  # type: ignore[attr-defined]
    cuerpo_404 = json.loads(resp_404.body.decode("utf-8"))  # type: ignore[attr-defined]
    assert cuerpo_404["codigo_error"] == "RECURSO_NO_ENCONTRADO"

    handler_400 = app.exception_handlers[DominioError]
    exc_400 = InscripcionInvalidaError(mensaje="Sin cupo", motivo="SIN_CUPO")
    resp_400 = _ejecutar_corutina_inmediata(handler_400(request_falso, exc_400))
    assert resp_400.status_code == 400  # type: ignore[attr-defined]
    cuerpo_400 = json.loads(resp_400.body.decode("utf-8"))  # type: ignore[attr-defined]
    assert cuerpo_400["codigo_error"] == "INSCRIPCION_INVALIDA"


def test_routers_health_e_informacion_institucional() -> None:
    """Valida respuestas de los endpoints de monitoreo y Portal Institucional UAA."""
    salud = verificar_salud()
    assert salud.status == "ok"
    assert "shard_campus_central_id_1" in salud.shards_status

    info = obtener_informacion_institucional()
    assert "UAA" in info.institucion
    assert len(info.campus_activos) == 2
    assert len(info.avisos) >= 2

    meta_sur = obtener_metadatos_campus(2)
    assert meta_sur["id_campus"] == 2

    with pytest.raises(RecursoNoEncontradoError):
        obtener_metadatos_campus(3)


def test_router_academico_flujo_completo() -> None:
    """Prueba listado, creacion de alumnos/materias, inscripciones, entregas y auditoria."""
    reset_services_for_testing()
    svc = get_inscripcion_service()

    alumnos_central = listar_alumnos(service=svc, id_campus=1)
    assert len(alumnos_central) == 1
    assert alumnos_central[0]["matricula"] == "ID345678"

    perfil = obtener_alumno(matricula="ID345678", service=svc)
    assert perfil["campus_nombre"] == "CENTRAL"

    nuevo_alumno = crear_alumno(
        payload=AlumnoCreateRequest(
            nombre="Lucia",
            apellidos="Mendez",
            curp="MENL040505MDFRNN08",
            email="lucia.mendez@edu.uaa.mx",
            matricula="ID555666",
            id_campus=1,
            carrera="Ingenieria en Sistemas Computacionales",
            semestre=4,
        ),
        service=svc,
    )
    assert nuevo_alumno["matricula"] == "ID555666"

    nueva_materia = crear_materia(
        payload=MateriaCreateRequest(
            clave="ISC-609",
            nombre="Computo en la Nube",
            creditos=8,
            cupo_maximo=25,
            id_campus=1,
        ),
        service=svc,
    )
    assert nueva_materia["clave"] == "ISC-609"
    assert len(listar_materias(service=svc, id_campus=1)) >= 3

    inscripcion = crear_inscripcion(
        payload=InscripcionCreateRequest(
            folio="INS-ENDPOINT-01",
            alumno_matricula="ID555666",
            materia_clave="ISC-609",
        ),
        service=svc,
    )
    assert inscripcion["estado"] == "CONFIRMADA"
    assert len(listar_inscripciones(service=svc)) == 1

    entrega = registrar_entrega(
        payload=EntregaTareaRequest(
            id_entrega="ENT-ENDPOINT-01",
            id_tarea="TAR-001",
            alumno_matricula="ID555666",
            archivo_url="https://uaa.mx/entregas/cloud.pdf",
        ),
        service=svc,
    )
    assert entrega["es_entrega_a_tiempo"] is True
    assert len(consultar_auditoria_academica(service=svc)) >= 2


def test_router_pagos_flujo_completo() -> None:
    """Prueba procesamiento exitoso, listado, consulta y rechazo en el router de pagos."""
    reset_services_for_testing()
    psvc = get_pago_service()

    pago_ok = procesar_pago(
        payload=PagoCreateRequest(
            folio="PAG-ENDPOINT-01",
            alumno_matricula="ID345678",
            monto=1950.0,
            concepto="Reinscripcion",
        ),
        service=psvc,
    )
    assert pago_ok["estatus"] == "APROBADO"

    consultado = obtener_pago(folio="PAG-ENDPOINT-01", service=psvc)
    assert consultado["monto"] == 1950.0
    assert len(listar_pagos(service=psvc, alumno_matricula="ID345678")) == 1

    with pytest.raises(PagoRechazadoError):
        procesar_pago(
            payload=PagoCreateRequest(
                folio="PAG-ENDPOINT-02",
                alumno_matricula="ID345678",
                monto=95000.0,
                concepto="Monto Excesivo",
            ),
            service=psvc,
        )
