"""Operaciones transaccionales academicas sobre PostgreSQL."""

from datetime import UTC, datetime
from typing import Any

from src.repositories.postgres import PostgresRepository


class AcademicPostgresRepository:
    """Persiste inscripciones y entregas en el nodo del campus correspondiente."""

    def __init__(self, postgres: PostgresRepository) -> None:
        self._postgres = postgres

    def inscribir(
        self,
        *,
        id_campus: int,
        id_alumno: int,
        id_curso: int,
        id_inscripcion: int,
    ) -> dict[str, Any]:
        """Registra una inscripcion con validacion de cupo en una transaccion."""
        sql = """
            CALL registrar_inscripcion(
                %s::SMALLINT, %s::BIGINT, %s::BIGINT, %s::BIGINT
            )
        """
        fecha = datetime.now(UTC)
        with self._postgres.transaction(id_campus) as connection, connection.cursor() as cursor:
            cursor.execute(sql, (id_campus, id_inscripcion, id_alumno, id_curso))
        return {
            "id_campus": id_campus,
            "id_inscripcion": id_inscripcion,
            "id_alumno": id_alumno,
            "id_curso": id_curso,
            "fecha_inscripcion": fecha.isoformat(),
        }

    def registrar_entrega(
        self,
        *,
        id_campus: int,
        id_entrega: int,
        id_tarea: int,
        id_alumno: int,
        archivo_url: str,
        hash_sha256: str,
        estado_entrega: str,
        calificacion: float | None = None,
        retroalimentacion: str | None = None,
    ) -> dict[str, Any]:
        """Inserta una entrega dentro de una transaccion ACID por campus."""
        sql = """
            INSERT INTO entregas
                (id_campus, id_entrega, id_tarea, id_alumno, fecha_entrega,
                 archivo_url, hash_sha256, estado_entrega, calificacion, retroalimentacion)
            VALUES
                (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        fecha = datetime.now(UTC)
        with self._postgres.transaction(id_campus) as connection, connection.cursor() as cursor:
            cursor.execute(
                sql,
                (
                    id_campus,
                    id_entrega,
                    id_tarea,
                    id_alumno,
                    fecha,
                    archivo_url,
                    hash_sha256,
                    estado_entrega,
                    calificacion,
                    retroalimentacion,
                ),
            )
        return {
            "id_campus": id_campus,
            "id_entrega": id_entrega,
            "id_tarea": id_tarea,
            "id_alumno": id_alumno,
            "fecha_entrega": fecha.isoformat(),
            "archivo_url": archivo_url,
            "hash_sha256": hash_sha256,
            "estado_entrega": estado_entrega,
        }

    def procesar_pago(
        self,
        *,
        id_campus: int,
        id_pago: int,
        id_usuario: int,
        concepto: str,
        monto: float,
        aprobado: bool,
    ) -> dict[str, Any]:
        """Registra un pago aprobado; si se cancela, la transaccion se revierte."""
        sql = """
            CALL registrar_pago(
                %s::BIGINT, %s::BIGINT, %s::SMALLINT,
                %s::VARCHAR, %s::NUMERIC, %s::BOOLEAN
            )
        """
        fecha = datetime.now(UTC)
        with self._postgres.transaction(id_campus) as connection, connection.cursor() as cursor:
            cursor.execute(
                sql,
                (id_pago, id_usuario, id_campus, concepto, monto, aprobado),
            )
        return {
            "id_pago": id_pago,
            "id_usuario": id_usuario,
            "id_campus": id_campus,
            "concepto": concepto,
            "monto": monto,
            "estado": "PAGADO",
            "fecha_pago": fecha.isoformat(),
        }
