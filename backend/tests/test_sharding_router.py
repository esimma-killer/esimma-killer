"""Pruebas del enrutamiento y aislamiento de conexiones por campus (Issue #26)."""

from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from types import SimpleNamespace

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from src.core.config import Settings
from src.core.sharding import CampusShardMiddleware, ShardingRouter, get_shard_connection


def test_router_resuelve_campus_central() -> None:
    settings = Settings(
        shard_central_dsn="postgresql://central",
        shard_sur_dsn="postgresql://sur",
    )
    route = ShardingRouter(settings).route(1)

    assert route.id_campus == 1
    assert route.nombre_campus == "Campus Central"
    assert route.dsn == "postgresql://central"


def test_router_resuelve_campus_sur() -> None:
    settings = Settings(
        shard_central_dsn="postgresql://central",
        shard_sur_dsn="postgresql://sur",
    )
    route = ShardingRouter(settings).route(2)

    assert route.id_campus == 2
    assert route.nombre_campus == "Campus Sur"
    assert route.dsn == "postgresql://sur"


def test_router_rechaza_campus_invalido() -> None:
    router = ShardingRouter(Settings())

    with pytest.raises(ValueError, match="id_campus"):
        router.route(99)


def test_operacion_no_combina_campus_distintos() -> None:
    router = ShardingRouter(Settings())

    assert router.validar_mismo_campus(1, 1) == 1
    assert router.validar_mismo_campus(2, 2) == 2

    with pytest.raises(ValueError, match="no pueden combinar"):
        router.validar_mismo_campus(1, 2)


class FakeShardPools:
    """Simula pools independientes y registra el campus atendido por cada hilo."""

    @contextmanager
    def connection(self, id_campus: int) -> Iterator[SimpleNamespace]:
        yield SimpleNamespace(id_campus=id_campus)

    def close(self) -> None:
        return None


@pytest.fixture
def sharding_client() -> Iterator[TestClient]:
    app = FastAPI()
    app.state.sharding_router = ShardingRouter(
        Settings(
            shard_central_dsn="postgresql://central",
            shard_sur_dsn="postgresql://sur",
        )
    )
    app.state.shard_pools = FakeShardPools()
    app.add_middleware(CampusShardMiddleware)

    @app.get("/probe")
    def probe(connection: SimpleNamespace = Depends(get_shard_connection)) -> dict[str, int]:
        return {"connection_campus": connection.id_campus}

    with TestClient(app) as client:
        try:
            yield client
        finally:
            app.state.shard_pools.close()


def test_middleware_asigna_conexion_del_campus_indicado(sharding_client: TestClient) -> None:
    central = sharding_client.get("/probe", headers={"X-Campus-ID": "1"})
    sur = sharding_client.get("/probe", headers={"X-Campus-ID": "2"})

    assert central.status_code == 200
    assert central.json() == {"connection_campus": 1}
    assert sur.status_code == 200
    assert sur.json() == {"connection_campus": 2}


def test_middleware_rechaza_campus_invalido_y_falta_de_campus(
    sharding_client: TestClient,
) -> None:
    invalido = sharding_client.get("/probe", headers={"X-Campus-ID": "9"})
    ausente = sharding_client.get("/probe")

    assert invalido.status_code == 400
    assert ausente.status_code == 400


def test_peticion_concurrente_no_cruza_las_conexiones_de_campus(
    sharding_client: TestClient,
) -> None:
    campus_solicitados = [1, 2] * 8

    def consultar(id_campus: int) -> tuple[int, int]:
        response = sharding_client.get(
            "/probe",
            headers={"X-Campus-ID": str(id_campus)},
        )
        return id_campus, response.json()["connection_campus"]

    with ThreadPoolExecutor(max_workers=8) as executor:
        resultados = list(executor.map(consultar, campus_solicitados))

    assert resultados == [(campus, campus) for campus in campus_solicitados]
