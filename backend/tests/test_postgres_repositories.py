"""Pruebas unitarias de transacciones y repositorios PostgreSQL (Issue #24)."""

from typing import Any

import pytest

from src.core.config import Settings
from src.repositories.academic_postgres import AcademicPostgresRepository
from src.repositories.postgres import PostgresRepository


class FakeTransaction:
    """Registra si la transaccion confirma o revierte al salir del contexto."""

    def __init__(self, connection: "FakeConnection") -> None:
        self.connection = connection

    def __enter__(self) -> "FakeTransaction":
        return self

    def __exit__(self, exc_type: object, _exc: object, _tb: object) -> bool:
        if exc_type is None:
            self.connection.committed = True
        else:
            self.connection.rolled_back = True
        return False


class FakeCursor:
    def __init__(self, connection: "FakeConnection") -> None:
        self.connection = connection

    def __enter__(self) -> "FakeCursor":
        return self

    def __exit__(self, _exc_type: object, _exc: object, _tb: object) -> None:
        return None

    def execute(self, sql: str, params: tuple[Any, ...]) -> None:
        self.connection.executed.append((sql, params))
        if self.connection.fail_on_execute:
            raise RuntimeError("fallo sintetico durante la transaccion")


class FakeConnection:
    def __init__(self, fail_on_execute: bool = False) -> None:
        self.fail_on_execute = fail_on_execute
        self.committed = False
        self.rolled_back = False
        self.closed = False
        self.executed: list[tuple[str, tuple[Any, ...]]] = []

    def transaction(self) -> FakeTransaction:
        return FakeTransaction(self)

    def cursor(self) -> FakeCursor:
        return FakeCursor(self)

    def close(self) -> None:
        self.closed = True


@pytest.fixture
def repository_factory(
    monkeypatch: pytest.MonkeyPatch,
) -> tuple[PostgresRepository, AcademicPostgresRepository, list[FakeConnection], list[bool]]:
    """Crea repositorios con una conexion DB-API simulada, sin abrir sockets."""
    connections: list[FakeConnection] = []
    fail_next_connection = [False]

    def connect(dsn: str) -> FakeConnection:
        assert dsn in {"postgresql://central", "postgresql://sur"}
        connection = FakeConnection(fail_on_execute=fail_next_connection[0])
        fail_next_connection[0] = False
        connections.append(connection)
        return connection

    monkeypatch.setattr("src.repositories.postgres.psycopg.connect", connect)
    settings = Settings(
        shard_central_dsn="postgresql://central",
        shard_sur_dsn="postgresql://sur",
    )
    postgres = PostgresRepository(settings)
    academic = AcademicPostgresRepository(postgres)
    return postgres, academic, connections, fail_next_connection


def test_transaccion_confirma_y_cierra_conexion(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    postgres, _academic, connections, _fail_next = repository_factory

    with postgres.transaction(1):
        pass

    connection = connections[0]
    assert connection.committed is True
    assert connection.rolled_back is False
    assert connection.closed is True


def test_transaccion_revierte_excepcion_y_cierra_conexion(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    postgres, _academic, connections, _fail_next = repository_factory

    def ejecutar_operacion_fallida() -> None:
        with postgres.transaction(2):
            raise RuntimeError("fallo de negocio")

    with pytest.raises(RuntimeError, match="fallo de negocio"):
        ejecutar_operacion_fallida()

    connection = connections[0]
    assert connection.committed is False
    assert connection.rolled_back is True
    assert connection.closed is True


def test_inscripcion_invoca_procedimiento_con_parametros_y_confirma(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    _postgres, academic, connections, _fail_next = repository_factory

    resultado = academic.inscribir(
        id_campus=1,
        id_alumno=10,
        id_curso=20,
        id_inscripcion=30,
    )

    connection = connections[0]
    sql, params = connection.executed[0]
    assert "CALL registrar_inscripcion" in sql
    assert params == (1, 30, 10, 20)
    assert resultado["id_campus"] == 1
    assert connection.committed is True
    assert connection.closed is True


def test_inscripcion_revierte_fallo_del_procedimiento(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    _postgres, academic, connections, fail_next = repository_factory
    fail_next[0] = True

    with pytest.raises(RuntimeError, match="fallo sintetico"):
        academic.inscribir(
            id_campus=2,
            id_alumno=11,
            id_curso=21,
            id_inscripcion=31,
        )

    connection = connections[0]
    assert connection.rolled_back is True
    assert connection.committed is False
    assert connection.closed is True


def test_pago_aprobado_invoca_procedimiento_y_confirma(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    _postgres, academic, connections, _fail_next = repository_factory

    resultado = academic.procesar_pago(
        id_campus=2,
        id_pago=40,
        id_usuario=1002,
        concepto="Colegiatura sintetica",
        monto=1500.0,
        aprobado=True,
    )

    connection = connections[0]
    sql, params = connection.executed[0]
    assert "CALL registrar_pago" in sql
    assert params == (40, 1002, 2, "Colegiatura sintetica", 1500.0, True)
    assert resultado["estado"] == "PAGADO"
    assert connection.committed is True
    assert connection.closed is True


def test_cancelacion_de_pago_revierte_transaccion(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    postgres, _academic, connections, fail_next = repository_factory
    fail_next[0] = True
    academic = AcademicPostgresRepository(postgres)

    with pytest.raises(RuntimeError, match="fallo sintetico"):
        academic.procesar_pago(
            id_campus=1,
            id_pago=41,
            id_usuario=1001,
            concepto="Pago cancelado sintetico",
            monto=1500.0,
            aprobado=False,
        )

    connection = connections[0]
    assert connection.rolled_back is True
    assert connection.committed is False
    assert connection.closed is True


def test_campus_invalido_no_abre_conexion(
    repository_factory: tuple[
        PostgresRepository,
        AcademicPostgresRepository,
        list[FakeConnection],
        list[bool],
    ],
) -> None:
    postgres, _academic, connections, _fail_next = repository_factory

    with pytest.raises(ValueError, match="1.*2"):
        with postgres.transaction(99):
            pass

    assert connections == []
