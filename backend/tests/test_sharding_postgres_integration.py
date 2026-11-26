"""Prueba de integración física de shards para Issue #26.

Se activa al definir TEST_SHARD_CENTRAL_DSN y TEST_SHARD_SUR_DSN.
"""

import os
from concurrent.futures import ThreadPoolExecutor

import pytest

from src.core.config import Settings
from src.core.sharding import ShardedPostgresPools

CENTRAL_DSN = os.getenv("TEST_SHARD_CENTRAL_DSN")
SUR_DSN = os.getenv("TEST_SHARD_SUR_DSN")

pytestmark = pytest.mark.skipif(
    not CENTRAL_DSN or not SUR_DSN,
    reason="Define TEST_SHARD_CENTRAL_DSN y TEST_SHARD_SUR_DSN para PostgreSQL real.",
)


def test_concurrencia_se_conecta_al_nodo_fisico_de_cada_campus() -> None:
    """Cada solicitud concurrente consulta su shard PostgreSQL esperado."""
    settings = Settings(
        shard_central_dsn=CENTRAL_DSN or "",
        shard_sur_dsn=SUR_DSN or "",
    )
    pools = ShardedPostgresPools(settings, max_size=8)
    solicitudes = [1, 2] * 8

    def consultar_nodo(id_campus: int) -> tuple[int, str]:
        with pools.connection(id_campus) as connection:
            fila = connection.execute("SELECT current_database()").fetchone()
        assert fila is not None
        return id_campus, str(fila[0])

    try:
        with ThreadPoolExecutor(max_workers=8) as executor:
            resultados = list(executor.map(consultar_nodo, solicitudes))
    finally:
        pools.close()

    assert resultados == [
        (1, "esimma_central") if id_campus == 1 else (2, "esimma_sur")
        for id_campus in solicitudes
    ]
