"""Enrutamiento de operaciones por la Shard Key id_campus."""

from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from threading import Lock

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse
from psycopg import Connection
from psycopg_pool import ConnectionPool
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from src.core.config import Settings


@dataclass(frozen=True)
class ShardRoute:
    """Descripcion minima del nodo seleccionado."""

    id_campus: int
    nombre_campus: str
    dsn: str


class ShardingRouter:
    """Selecciona el DSN PostgreSQL correspondiente a un campus."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def route(self, id_campus: int) -> ShardRoute:
        """Resuelve Central o Sur y rechaza cualquier campus distinto."""
        if id_campus == 1:
            return ShardRoute(1, "Campus Central", self._settings.shard_central_dsn)
        if id_campus == 2:
            return ShardRoute(2, "Campus Sur", self._settings.shard_sur_dsn)
        raise ValueError(
            f"Shard Key id_campus invalida: {id_campus}. Valores permitidos: 1, 2."
        )

    def validar_mismo_campus(self, campus_a: int, campus_b: int) -> int:
        """Valida que una operacion local no combine datos de distintos campus."""
        ruta_a = self.route(campus_a)
        ruta_b = self.route(campus_b)
        if ruta_a.id_campus != ruta_b.id_campus:
            raise ValueError(
                "Operaciones locales no pueden combinar Campus Central (1) y Campus Sur (2)."
            )
        return ruta_a.id_campus


class ShardedPostgresPools:
    """Mantiene pools de conexiones independientes para los dos nodos PostgreSQL."""

    def __init__(self, settings: Settings, max_size: int = 10) -> None:
        self._router = ShardingRouter(settings)
        self._pools = {
            campus_id: ConnectionPool(
                conninfo=self._router.route(campus_id).dsn,
                min_size=0,
                max_size=max_size,
                open=False,
            )
            for campus_id in (1, 2)
        }
        self._opened_pools: set[int] = set()
        self._open_lock = Lock()

    def _open_pool(self, id_campus: int, pool: ConnectionPool) -> None:
        """Abre el pool una sola vez cuando llega la primera petición de ese campus."""
        with self._open_lock:
            if id_campus not in self._opened_pools:
                pool.open(wait=False)
                self._opened_pools.add(id_campus)

    @contextmanager
    def connection(self, id_campus: int) -> Iterator[Connection[object]]:
        """Entrega una conexión del pool del campus durante una operación."""
        pool = self._pools.get(id_campus)
        if pool is None:
            raise ValueError("id_campus debe ser 1 (Central) o 2 (Sur).")
        self._open_pool(id_campus, pool)
        with pool.connection() as connection:
            yield connection

    def close(self) -> None:
        """Cierra ambos pools al apagar la aplicación."""
        for pool in self._pools.values():
            pool.close()


class CampusShardMiddleware(BaseHTTPMiddleware):
    """Valida X-Campus-ID y guarda el shard en el estado de la petición."""

    async def dispatch(
        self,
        request: Request,
        call_next: RequestResponseEndpoint,
    ) -> Response:
        campus_header = request.headers.get("X-Campus-ID")
        if campus_header is None:
            request.state.id_campus = None
            return await call_next(request)

        try:
            id_campus = int(campus_header)
            request.app.state.sharding_router.route(id_campus)
        except (TypeError, ValueError):
            return JSONResponse(
                status_code=400,
                content={"detail": "X-Campus-ID debe ser 1 (Central) o 2 (Sur)."},
            )

        request.state.id_campus = id_campus
        return await call_next(request)


def get_shard_connection(request: Request) -> Iterator[Connection[object]]:
    """Dependencia FastAPI que entrega la conexión del shard de la petición."""
    id_campus = getattr(request.state, "id_campus", None)
    if id_campus is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La petición requiere la cabecera X-Campus-ID.",
        )
    pools: ShardedPostgresPools = request.app.state.shard_pools
    with pools.connection(id_campus) as connection:
        yield connection
