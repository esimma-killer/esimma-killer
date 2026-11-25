"""Enrutamiento de operaciones por la Shard Key id_campus."""

from dataclasses import dataclass

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
