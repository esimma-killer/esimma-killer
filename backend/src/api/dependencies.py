"""Proveedores de dependencias compartidas para los Routers de FastAPI."""

from src.services.inscripcion_service import InscripcionService
from src.services.pago_service import PagoService

_inscripcion_service = InscripcionService(cargar_semilla=True)
_pago_service = PagoService()


def get_inscripcion_service() -> InscripcionService:
    """Devuelve la instancia activa del servicio de gestion academica e inscripciones."""
    return _inscripcion_service


def get_pago_service() -> PagoService:
    """Devuelve la instancia activa del servicio de pagos simulados."""
    return _pago_service


def reset_services_for_testing() -> None:
    """Reinicia el estado en memoria de los servicios para ejecucion aislada de pruebas."""
    global _inscripcion_service, _pago_service
    _inscripcion_service = InscripcionService(cargar_semilla=True)
    _pago_service = PagoService()
