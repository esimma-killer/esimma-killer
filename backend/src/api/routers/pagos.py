"""Router modular para simulacion y consulta de Pagos institucionales."""

from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, status

from src.api.dependencies import get_pago_service
from src.api.schemas import PagoCreateRequest, PagoResponse
from src.services.pago_service import PagoService

router = APIRouter(prefix="/pagos", tags=["Pagos Institucionales (Simulados)"])

PagoServiceDep = Annotated[PagoService, Depends(get_pago_service)]


@router.post(
    "",
    response_model=PagoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Procesar un pago institucional simulado (try-except-else-finally)",
)
def procesar_pago(
    payload: PagoCreateRequest,
    service: PagoServiceDep,
) -> dict[str, Any]:
    """Procesa un pago simulado o lanza PagoRechazadoError (HTTP 400) ante fondos invalidos."""
    return service.procesar_pago(
        folio=payload.folio,
        alumno_matricula=payload.alumno_matricula,
        monto=payload.monto,
        concepto=payload.concepto,
        referencia_bancaria=payload.referencia_bancaria,
        id_campus=payload.id_campus,
    )


@router.get(
    "",
    response_model=list[PagoResponse],
    summary="Listar pagos procesados",
)
def listar_pagos(
    service: PagoServiceDep,
    alumno_matricula: Annotated[
        str | None,
        Query(description="Filtrar pagos por matricula del alumno"),
    ] = None,
) -> list[dict[str, Any]]:
    """Devuelve el historial de transacciones de pago simuladas."""
    return service.listar_pagos(alumno_matricula=alumno_matricula)


@router.get(
    "/{folio}",
    response_model=PagoResponse,
    summary="Consultar el estado de un pago por su folio",
)
def obtener_pago(
    folio: str,
    service: PagoServiceDep,
) -> dict[str, Any]:
    """Busca una transaccion por su folio o responde HTTP 404 si no existe."""
    pago = service.obtener_pago(folio)
    return pago.to_dict()
