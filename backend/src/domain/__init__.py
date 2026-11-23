"""Capa de Dominio: Entidades POO, enumeraciones, esquemas NoSQL y excepciones."""

from src.domain.academico import (
    CALIFICACION_MINIMA_APROBATORIA,
    Calificacion,
    Entrega,
    Inscripcion,
    Materia,
    Tarea,
)
from src.domain.enums import (
    CampusUAA,
    EstadoEntrega,
    EstadoInscripcion,
    EstatusAcademico,
    EstatusPago,
    RolSistema,
)
from src.domain.exceptions import (
    DominioError,
    InscripcionInvalidaError,
    PagoRechazadoError,
    RecursoNoEncontradoError,
    ValidacionDominioError,
    ValidacionError,
)
from src.domain.finanzas import Pago
from src.domain.mongo_schemas import (
    EVENTOS_ENTREGAS_JSON_SCHEMA,
    LOGS_AUDITORIA_JSON_SCHEMA,
    MONGO_COLLECTION_SCHEMAS,
    MONGO_INDEX_DEFINITIONS,
    TELEMETRIA_ACCESOS_JSON_SCHEMA,
    MongoCollectionValidator,
)
from src.domain.personas import Administrativo, Alumno, Persona, Profesor

__all__ = [
    "Administrativo",
    "Alumno",
    "CALIFICACION_MINIMA_APROBATORIA",
    "Calificacion",
    "CampusUAA",
    "DominioError",
    "EVENTOS_ENTREGAS_JSON_SCHEMA",
    "Entrega",
    "EstadoEntrega",
    "EstadoInscripcion",
    "EstatusAcademico",
    "EstatusPago",
    "Inscripcion",
    "InscripcionInvalidaError",
    "LOGS_AUDITORIA_JSON_SCHEMA",
    "MONGO_COLLECTION_SCHEMAS",
    "MONGO_INDEX_DEFINITIONS",
    "Materia",
    "MongoCollectionValidator",
    "Pago",
    "PagoRechazadoError",
    "Persona",
    "Profesor",
    "RecursoNoEncontradoError",
    "RolSistema",
    "TELEMETRIA_ACCESOS_JSON_SCHEMA",
    "Tarea",
    "ValidacionDominioError",
    "ValidacionError",
]
