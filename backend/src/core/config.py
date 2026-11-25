"""Configuracion desacoplada de entorno y resolucion de Shards por campus."""

import os
from dataclasses import dataclass, field
from functools import lru_cache
from typing import Any


def _parse_cors_origins(raw_origins: str) -> list[str]:
    """Convierte una cadena de origenes separados por coma en una lista limpia."""
    origins = [origin.strip() for origin in raw_origins.split(",") if origin.strip()]
    return origins or ["*"]


@dataclass(frozen=True)
class Settings:
    """Parametros de configuracion central de la API y nodos distribuidos."""

    app_name: str = field(
        default_factory=lambda: os.getenv("APP_NAME", "E-SIIMA Killer API (E-SIIMA 3)")
    )
    app_version: str = field(default_factory=lambda: os.getenv("APP_VERSION", "0.2.0"))
    environment: str = field(default_factory=lambda: os.getenv("ENVIRONMENT", "development"))
    debug: bool = field(
        default_factory=lambda: os.getenv("DEBUG", "true").lower() in {"1", "true", "yes"}
    )
    api_v1_prefix: str = field(default_factory=lambda: os.getenv("API_V1_PREFIX", "/api/v1"))
    cors_origins: list[str] = field(
        default_factory=lambda: _parse_cors_origins(
            os.getenv(
                "CORS_ORIGINS",
                "http://localhost:3000,http://localhost:8080,http://127.0.0.1:8080,*",
            )
        )
    )
    shard_central_dsn: str = field(
        default_factory=lambda: os.getenv(
            "SHARD_CENTRAL_DSN",
            "postgresql://esimma_user:synthetic_pass_only@localhost:5432/esimma_central",
        )
    )
    shard_sur_dsn: str = field(
        default_factory=lambda: os.getenv(
            "SHARD_SUR_DSN",
            "postgresql://esimma_user:synthetic_pass_only@localhost:5433/esimma_sur",
        )
    )
    mongo_uri: str = field(
        default_factory=lambda: os.getenv("MONGO_URI", "mongodb://localhost:27017/esimma_analytics")
    )
    jwt_secret: str = field(
        default_factory=lambda: os.getenv("JWT_SECRET", "e-siima-killer-development-only-secret")
    )
    jwt_algorithm: str = field(default_factory=lambda: os.getenv("JWT_ALGORITHM", "HS256"))
    jwt_access_minutes: int = field(
        default_factory=lambda: int(os.getenv("JWT_ACCESS_MINUTES", "30"))
    )
    jwt_refresh_days: int = field(
        default_factory=lambda: int(os.getenv("JWT_REFRESH_DAYS", "7"))
    )

    def obtener_info_shard(self, id_campus: int) -> dict[str, Any]:
        """Resuelve el metadato del nodo PostgreSQL correspondiente a la Shard Key id_campus."""
        if id_campus == 1:
            return {
                "id_campus": 1,
                "nombre_campus": "Campus Central",
                "nodo": "pg-shard-central-master (Local)",
                "postura_cap_escritura": "CP (Consistencia Fuerte)",
                "postura_cap_lectura_publica": "AP (Replica Asincrona)",
            }
        if id_campus == 2:
            return {
                "id_campus": 2,
                "nombre_campus": "Campus Sur",
                "nodo": "pg-shard-sur-master (Remoto / Red Cifrada)",
                "postura_cap_escritura": "CP (Consistencia Fuerte)",
                "postura_cap_lectura_publica": "AP (Replica Asincrona)",
            }
        raise ValueError(f"Shard Key id_campus invalida: {id_campus}. Valores permitidos: 1, 2.")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Devuelve la instancia cacheada de configuracion."""
    return Settings()
