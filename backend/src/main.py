"""Punto de entrada principal de la API REST E-SIIMA Killer (FastAPI)."""

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.api.routers import (
    academico_router,
    health_router,
    informacion_router,
    pagos_router,
)
from src.core.config import get_settings
from src.core.sharding import CampusShardMiddleware, ShardedPostgresPools, ShardingRouter
from src.domain.exceptions import DominioError, RecursoNoEncontradoError

OPENAPI_TAGS = [
    {
        "name": "Salud y Monitoreo",
        "description": "Verificacion de disponibilidad del servicio y estado de los Shards.",
    },
    {
        "name": "Portal Institucional UAA",
        "description": "Cartelera informativa, avisos por campus y calendario (Landing Page).",
    },
    {
        "name": "Gestion Academica e Inscripciones",
        "description": "Operaciones sobre Alumnos, Materias, Inscripciones, Tareas y Entregas.",
    },
    {
        "name": "Pagos Institucionales (Simulados)",
        "description": "Simulacion transaccional de pagos con control de excepciones.",
    },
]


def create_app() -> FastAPI:
    """Construye y configura la instancia de FastAPI con middlewares, routers y manejadores."""
    settings = get_settings()

    application = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "API REST central para **E-SIIMA Killer (E-SIIMA 3)** — Proyecto Final Integrador "
            "de la Universidad Autonoma de Aguascalientes (UAA).\n\n"
            "Expone el modelo de dominio POO con soporte para fragmentacion horizontal por "
            "campus (`id_campus`), integridad de entregas con SHA-256 y telemetria para MongoDB."
        ),
        openapi_tags=OPENAPI_TAGS,
        docs_url="/docs",
        redoc_url="/redoc",
    )
    application.state.sharding_router = ShardingRouter(settings)
    application.state.shard_pools = ShardedPostgresPools(settings)

    @application.on_event("shutdown")
    def close_shard_pools() -> None:
        """Libera las conexiones PostgreSQL al apagar el proceso de la API."""
        application.state.shard_pools.close()

    application.add_middleware(CampusShardMiddleware)

    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @application.exception_handler(RecursoNoEncontradoError)
    async def recurso_no_encontrado_handler(
        _request: Request,
        exc: RecursoNoEncontradoError,
    ) -> JSONResponse:
        """Traduce RecursoNoEncontradoError a una respuesta HTTP 404 estructurada."""
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content=exc.to_dict(),
        )

    @application.exception_handler(DominioError)
    async def dominio_error_handler(
        _request: Request,
        exc: DominioError,
    ) -> JSONResponse:
        """Traduce excepciones de negocio (InscripcionInvalidaError, PagoRechazadoError) a 400."""
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content=exc.to_dict(),
        )

    @application.get("/", include_in_schema=False)
    def root_endpoint() -> dict[str, str]:
        """Punto de entrada informativo que dirige hacia /docs y /api/v1/health."""
        return {
            "sistema": settings.app_name,
            "version": settings.app_version,
            "documentacion_swagger": "/docs",
            "documentacion_redoc": "/redoc",
            "healthcheck": f"{settings.api_v1_prefix}/health",
        }

    application.include_router(health_router, prefix=settings.api_v1_prefix)
    application.include_router(informacion_router, prefix=settings.api_v1_prefix)
    application.include_router(academico_router, prefix=settings.api_v1_prefix)
    application.include_router(pagos_router, prefix=settings.api_v1_prefix)

    return application


app = create_app()
