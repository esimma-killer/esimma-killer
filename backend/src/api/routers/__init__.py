"""Subpaquete de Routers modulares de FastAPI."""

from src.api.routers.academico import router as academico_router
from src.api.routers.auth import router as auth_router
from src.api.routers.health import router as health_router
from src.api.routers.informacion import router as informacion_router
from src.api.routers.pagos import router as pagos_router

__all__ = [
    "academico_router",
    "auth_router",
    "health_router",
    "informacion_router",
    "pagos_router",
]
