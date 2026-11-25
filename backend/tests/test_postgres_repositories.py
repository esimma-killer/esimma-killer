"""Pruebas permanentes de los repositorios transaccionales PostgreSQL (Issue #24)."""

from contextlib import contextmanager

import pytest

from src.repositories.academic_postgres import AcademicPostgresRepository


class FakeCursor:
    def __enter__(self) -> "FakeCursor":
        return self

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        return None

    def execute(self, sql: str, params: tuple[object, ...]) -> None:
        assert "%s" in sql
        assert len(params) == 5 if "inscripciones" in sql else len(params) == 10


class FakeConnection:
    def cursor(self) -> FakeCursor:
        return FakeCursor()


class FakePostgres:
    def __init__(self) -> None:
        self.campuses: list[int] = []

    @contextmanager
    def transaction(self, id_campus: int):
        self.campuses.append(id_campus)
        yield FakeConnection()


def test_inscripcion_usa_parametros_y_shard_campus() -> None:
    postgres = FakePostgres()
    repository = AcademicPostgresRepository(postgres)  # type: ignore[arg-type]

    result = repository.inscribir(
        id_campus=1,
        id_alumno=10,
        id_curso=20,
        id_inscripcion=30,
    )

    assert result["id_campus"] == 1
    assert postgres.campuses == [1]


def test_entrega_usa_parametros_y_shard_campus() -> None:
    postgres = FakePostgres()
    repository = AcademicPostgresRepository(postgres)  # type: ignore[arg-type]

    result = repository.registrar_entrega(
        id_campus=2,
        id_entrega=40,
        id_tarea=50,
        id_alumno=10,
        archivo_url="https://uaa.mx/entrega.pdf",
        hash_sha256="A" * 64,
        estado_entrega="A_TIEMPO",
    )

    assert result["id_campus"] == 2
    assert result["estado_entrega"] == "A_TIEMPO"
    assert postgres.campuses == [2]


def test_campus_invalido_requiere_validacion() -> None:
    from src.core.config import Settings
    from src.repositories.postgres import PostgresRepository

    repository = PostgresRepository(Settings())

    with pytest.raises(ValueError, match="1.*2"):
        repository._dsn_for_campus(99)
