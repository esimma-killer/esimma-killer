"""Enumeraciones fuertemente tipadas para el dominio educativo de E-SIIMA Killer."""

from enum import IntEnum, StrEnum


class CampusUAA(IntEnum):
    """Llave de fragmentacion horizontal (Shard Key: id_campus)."""

    CENTRAL = 1
    SUR = 2


class RolSistema(StrEnum):
    """Roles de control de acceso minimo (RBAC) definidos en la propuesta tecnica."""

    VISITANTE = "visitante"
    ESTUDIANTE = "estudiante"
    PROFESOR = "profesor"
    COORDINADOR = "coordinador"
    ADMINISTRATIVO = "administrativo"


class EstatusAcademico(StrEnum):
    """Estatus academico de un alumno dentro de la institucion."""

    ACTIVO = "ACTIVO"
    BAJA_TEMPORAL = "BAJA_TEMPORAL"
    BAJA_DEFINITIVA = "BAJA_DEFINITIVA"
    EGRESADO = "EGRESADO"


class EstadoInscripcion(StrEnum):
    """Estados del ciclo de vida de una inscripcion a materia."""

    PENDIENTE = "PENDIENTE"
    CONFIRMADA = "CONFIRMADA"
    CANCELADA = "CANCELADA"


class EstadoEntrega(StrEnum):
    """Estados de una entrega academica respecto a la fecha limite."""

    PENDIENTE = "PENDIENTE"
    A_TIEMPO = "A_TIEMPO"
    TARDIA = "TARDIA"
    EVALUADA = "EVALUADA"


class EstatusPago(StrEnum):
    """Estados de una transaccion de pago institucional simulado."""

    PENDIENTE = "PENDIENTE"
    APROBADO = "APROBADO"
    RECHAZADO = "RECHAZADO"
