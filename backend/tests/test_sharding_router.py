"""Pruebas permanentes del enrutamiento por Shard Key (Issue #26)."""

import pytest

from src.core.config import Settings
from src.core.sharding import ShardingRouter


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
