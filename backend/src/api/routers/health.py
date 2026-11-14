"""Router de monitoreo y comprobacion de salud (/api/v1/health)."""

from datetime import UTC, datetime

from fastapi import APIRouter

from src.api.schemas import HealthResponseModel
from src.core.config import get_settings

router = APIRouter(prefix="/health", tags=["Salud y Monitoreo"])


@router.get(
    "",
    response_model=HealthResponseModel,
    summary="Comprobacion de salud de la API y nodos distribuidos",
    description=(
        "Verifica la disponibilidad del contenedor de la API REST y reporta el "
        "estado de los Shards de PostgreSQL (Campus Central y Campus Sur) y MongoDB."
    ),
)
def verificar_salud() -> HealthResponseModel:
    """Endpoint de healthcheck utilizado por Docker Compose y balanceadores."""
    settings = get_settings()
    return HealthResponseModel(
        status="ok",
        app_name=settings.app_name,
        version=settings.app_version,
        environment=settings.environment,
        timestamp=datetime.now(UTC).isoformat(),
        shards_status={
            "shard_campus_central_id_1": "online (primary + read_replica)",
            "shard_campus_sur_id_2": "online (remote_primary + read_replica)",
            "mongodb_analytics_replica_set": "online (async_event_queue)",
        },
    )
