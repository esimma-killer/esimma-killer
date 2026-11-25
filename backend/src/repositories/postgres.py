"""Conexion DB-API 2.0 a los shards PostgreSQL por id_campus."""

from collections.abc import Iterator
from contextlib import contextmanager

import psycopg

from src.core.config import Settings


class PostgresRepository:
    """Gestiona conexiones y transacciones ACID en el shard correspondiente."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def _dsn_for_campus(self, id_campus: int) -> str:
        if id_campus == 1:
            return self._settings.shard_central_dsn
        if id_campus == 2:
            return self._settings.shard_sur_dsn
        raise ValueError("id_campus debe ser 1 (Central) o 2 (Sur).")

    @contextmanager
    def transaction(self, id_campus: int) -> Iterator[psycopg.Connection]:
        """Abre una transaccion: confirma con commit o revierte con rollback."""
        connection = psycopg.connect(self._dsn_for_campus(id_campus))
        try:
            with connection.transaction():
                yield connection
        finally:
            connection.close()
