"""Capa de Dominio: Entidades POO, enumeraciones y excepciones del negocio educativo."""

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
from src.domain.personas import Administrativo, Alumno, Persona, Profesor

__all__ = [
    "Administrativo",
    "Alumno",
    "CALIFICACION_MINIMA_APROBATORIA",
    "Calificacion",
    "CampusUAA",
    "DominioError",
    "Entrega",
    "EstadoEntrega",
    "EstadoInscripcion",
    "EstatusAcademico",
    "EstatusPago",
    "Inscripcion",
    "InscripcionInvalidaError",
    "Materia",
    "Pago",
    "PagoRechazadoError",
    "Persona",
    "Profesor",
    "RecursoNoEncontradoError",
    "RolSistema",
    "Tarea",
    "ValidacionDominioError",
    "ValidacionError",
]
