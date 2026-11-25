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
        """Inserta una inscripcion y confirma o revierte toda la transaccion."""
        sql = """
            INSERT INTO inscripciones
                (id_campus, id_inscripcion, id_alumno, id_curso, fecha_inscripcion)
            VALUES
                (%s, %s, %s, %s, %s)
        """
        fecha = datetime.now(UTC)
        with self._postgres.transaction(id_campus) as connection, connection.cursor() as cursor:
            cursor.execute(sql, (id_campus, id_inscripcion, id_alumno, id_curso, fecha))
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
