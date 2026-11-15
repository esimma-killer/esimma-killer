"""Pruebas unitarias para excepciones personalizadas y el bloque try-except-else-finally."""

import pytest
from src.domain import (
    Alumno,
    Calificacion,
    CampusUAA,
    DominioError,
    EstatusAcademico,
    InscripcionInvalidaError,
    Materia,
    PagoRechazadoError,
    RecursoNoEncontradoError,
    ValidacionDominioError,
)
from src.services import InscripcionService, PagoService


def test_jerarquia_excepciones_hereda_de_dominio_error() -> None:
    """Verifica que todas las excepciones personalizadas hereden de DominioError."""
    exc_inscripcion = InscripcionInvalidaError(
        mensaje="Materia sin cupo",
        alumno_matricula="ID345678",
        materia_clave="ISC-601",
        motivo="SIN_CUPO",
    )
    assert isinstance(exc_inscripcion, DominioError)
    serializado = exc_inscripcion.to_dict()
    assert serializado["codigo_error"] == "INSCRIPCION_INVALIDA"
    assert serializado["detalles"]["motivo"] == "SIN_CUPO"


def test_inscripcion_service_try_else_finally_exitoso(
    inscripcion_service: InscripcionService,
) -> None:
    """Valida las ramas try + else + finally en una inscripcion valida."""
    resumen = inscripcion_service.inscribir_alumno(
        folio="INS-OK-01",
        alumno_matricula="ID345678",
        materia_clave="ISC-601",
    )
    assert resumen["folio"] == "INS-OK-01"
    assert resumen["estado"] == "CONFIRMADA"
    assert resumen["cupo_restante"] == 29

    # El bloque finally siempre registra el evento en logs_actividad
    assert len(inscripcion_service.logs_actividad) == 1
    ultimo_log = inscripcion_service.logs_actividad[-1]
    assert ultimo_log["resultado"] == "EXITO"
    assert ultimo_log["accion"] == "inscripcion_materia"
    assert ultimo_log["campus"] == 1


def test_inscripcion_service_except_y_finally_por_prerrequisitos_y_duplicados(
    inscripcion_service: InscripcionService,
) -> None:
    """Valida que pytest.raises capture InscripcionInvalidaError y ejecute finally."""
    with pytest.raises(InscripcionInvalidaError) as exc_info:
        inscripcion_service.inscribir_alumno(
            folio="INS-FAIL-PRERREQ",
            alumno_matricula="ID345678",
            materia_clave="ISC-602",
        )
    assert exc_info.value.detalles["motivo"] == "PRERREQUISITOS_NO_ACREDITADOS"
    assert inscripcion_service.logs_actividad[-1]["resultado"] == "ERROR"

    # Si acredita el prerrequisito ISC-501, la inscripcion procede en el bloque else
    inscripcion_service.registrar_calificacion(Calificacion("ID345678", "ISC-501", "2026-1", 8.5))
    confirmada = inscripcion_service.inscribir_alumno(
        folio="INS-OK-PRERREQ",
        alumno_matricula="ID345678",
        materia_clave="ISC-602",
    )
    assert confirmada["estado"] == "CONFIRMADA"

    # Intentar inscribir de nuevo al mismo alumno en la misma materia lanza duplicado
    with pytest.raises(InscripcionInvalidaError) as exc_dup:
        inscripcion_service.inscribir_alumno(
            folio="INS-DUP-MATERIA",
            alumno_matricula="ID345678",
            materia_clave="ISC-602",
        )
    assert exc_dup.value.detalles["motivo"] == "INSCRIPCION_DUPLICADA"

    # Intentar reutilizar el mismo folio lanza FOLIO_DUPLICADO
    with pytest.raises(InscripcionInvalidaError) as exc_folio:
        inscripcion_service.inscribir_alumno(
            folio="INS-OK-PRERREQ",
            alumno_matricula="ID345678",
            materia_clave="ISC-601",
        )
    assert exc_folio.value.detalles["motivo"] == "FOLIO_DUPLICADO"


def test_inscripcion_service_reglas_shard_campus_sin_cupo_y_estatus(
    inscripcion_service: InscripcionService,
) -> None:
    """Valida rechazo por conflicto de Shard Key id_campus, falta de cupo y baja."""
    # Conflicto de Shard Key: Alumno Central (1) intentando inscribir materia de Sur (2)
    with pytest.raises(InscripcionInvalidaError) as exc_shard:
        inscripcion_service.inscribir_alumno(
            folio="INS-SHARD-ERR",
            alumno_matricula="ID345678",
            materia_clave="ISC-603",
        )
    assert exc_shard.value.detalles["motivo"] == "SHARD_CAMPUS_MISMATCH"

    # Materia con cupo 1 que se llena
    materia_cupo_uno = Materia(
        clave="ISC-CUPO1",
        nombre="Seminario Especial",
        creditos=4,
        cupo_maximo=1,
        id_campus=CampusUAA.CENTRAL,
        cupo_actual=1,
    )
    inscripcion_service.registrar_materia(materia_cupo_uno)
    with pytest.raises(InscripcionInvalidaError) as exc_cupo:
        inscripcion_service.inscribir_alumno(
            folio="INS-SIN-CUPO",
            alumno_matricula="ID345678",
            materia_clave="ISC-CUPO1",
        )
    assert exc_cupo.value.detalles["motivo"] == "SIN_CUPO"

    # Alumno en baja temporal no elegible
    alumno_baja = Alumno(
        nombre="Carlos",
        apellidos="Ruiz",
        curp="RUIC040101HDFRNN09",
        email="carlos@edu.uaa.mx",
        matricula="ID000111",
        id_campus=CampusUAA.CENTRAL,
        carrera="ISC",
        estatus_academico=EstatusAcademico.BAJA_TEMPORAL,
    )
    inscripcion_service.registrar_alumno(alumno_baja)
    with pytest.raises(InscripcionInvalidaError) as exc_baja:
        inscripcion_service.inscribir_alumno(
            folio="INS-BAJA-01",
            alumno_matricula="ID000111",
            materia_clave="ISC-601",
        )
    assert exc_baja.value.detalles["motivo"] == "ALUMNO_NO_ELEGIBLE"


def test_inscripcion_service_recurso_no_encontrado_y_entregas(
    inscripcion_service: InscripcionService,
) -> None:
    """Verifica RecursoNoEncontradoError y registro de entregas con SHA-256."""
    with pytest.raises(RecursoNoEncontradoError):
        inscripcion_service.obtener_alumno("ID-INEXISTENTE")

    with pytest.raises(RecursoNoEncontradoError):
        inscripcion_service.obtener_materia("MAT-INEXISTENTE")

    with pytest.raises(ValidacionDominioError):
        inscripcion_service.inscribir_alumno(
            folio="   ",
            alumno_matricula="ID345678",
            materia_clave="ISC-601",
        )

    entrega = inscripcion_service.registrar_entrega_tarea(
        id_entrega="ENT-TEST-01",
        id_tarea="TAR-001",
        alumno_matricula="ID345678",
        archivo_url="https://uaa.mx/entregas/test.pdf",
        contenido_texto="contenido de prueba",
    )
    assert entrega["id_entrega"] == "ENT-TEST-01"
    assert len(entrega["hash_sha256"]) == 64

    with pytest.raises(RecursoNoEncontradoError):
        inscripcion_service.registrar_entrega_tarea(
            id_entrega="ENT-TEST-02",
            id_tarea="TAR-NO-EXISTE",
            alumno_matricula="ID345678",
            archivo_url="https://uaa.mx/entregas/test.pdf",
        )


def test_pago_service_try_except_else_finally_completo(
    pago_service: PagoService,
) -> None:
    """Valida todas las ramas de ejecucion de PagoService.procesar_pago."""
    # 1. Rama try + else + finally (Exito)
    aprobado = pago_service.procesar_pago(
        folio="PAG-OK-01",
        alumno_matricula="ID345678",
        monto=2500.0,
        concepto="Inscripcion Semestral",
    )
    assert aprobado["estatus"] == "APROBADO"
    assert pago_service.obtener_pago("PAG-OK-01").esta_aprobado is True
    assert len(pago_service.listar_pagos(alumno_matricula="ID345678")) == 1

    # 2. Rama except: Folio duplicado
    with pytest.raises(PagoRechazadoError) as exc_dup:
        pago_service.procesar_pago(
            folio="PAG-OK-01",
            alumno_matricula="ID345678",
            monto=2500.0,
            concepto="Inscripcion Semestral",
        )
    assert exc_dup.value.detalles["motivo"] == "FOLIO_DUPLICADO"

    # 3. Rama except: Fondos insuficientes simulados
    with pytest.raises(PagoRechazadoError) as exc_fondos:
        pago_service.procesar_pago(
            folio="PAG-EXCESO-01",
            alumno_matricula="ID345678",
            monto=85000.0,
            concepto="Pago Excesivo",
        )
    assert exc_fondos.value.detalles["motivo"] == "FONDOS_INSUFICIENTES"

    # 4. Rama except: Referencia bancaria rechazada
    with pytest.raises(PagoRechazadoError) as exc_ref:
        pago_service.procesar_pago(
            folio="PAG-REF-BAD",
            alumno_matricula="ID345678",
            monto=1200.0,
            concepto="Colegiatura",
            referencia_bancaria="RECHAZADA-999",
        )
    assert exc_ref.value.detalles["motivo"] == "REFERENCIA_BANCARIA_INVALIDA"

    # 5. Rama except (ValueError traducido a PagoRechazadoError): Monto negativo
    with pytest.raises(PagoRechazadoError) as exc_monto:
        pago_service.procesar_pago(
            folio="PAG-NEGATIVO",
            alumno_matricula="ID345678",
            monto=-50.0,
            concepto="Colegiatura",
        )
    assert exc_monto.value.detalles["motivo"] == "DATOS_PAGO_INVALIDOS"

    # 6. RecursoNoEncontradoError al buscar un folio inexistente
    with pytest.raises(RecursoNoEncontradoError):
        pago_service.obtener_pago("PAG-NO-EXISTE")

    # El bloque finally registro los 5 intentos en logs_actividad
    assert len(pago_service.logs_actividad) == 5
    assert pago_service.logs_actividad[0]["resultado"] == "EXITO"
    assert pago_service.logs_actividad[-1]["resultado"] == "ERROR"
