"""Jerarquia de excepciones personalizadas para el dominio educativo E-SIIMA Killer."""

from typing import Any


class DominioError(Exception):
    """Excepcion base para cualquier error de regla de negocio o validacion del dominio."""

    def __init__(
        self,
        mensaje: str,
        codigo_error: str = "DOMINIO_ERROR",
        detalles: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(mensaje)
        self.mensaje = mensaje
        self.codigo_error = codigo_error
        self.detalles: dict[str, Any] = detalles or {}

    def to_dict(self) -> dict[str, Any]:
        """Serializa la excepcion para respuestas estructuradas de API o logs."""
        return {
            "error": self.__class__.__name__,
            "codigo_error": self.codigo_error,
            "mensaje": self.mensaje,
            "detalles": self.detalles,
        }


class ValidacionDominioError(DominioError):
    """Error lanzado cuando un dato de entrada viola invariantes o formatos del dominio."""

    def __init__(
        self,
        mensaje: str,
        campo: str | None = None,
        detalles: dict[str, Any] | None = None,
    ) -> None:
        info = dict(detalles or {})
        if campo:
            info["campo"] = campo
        super().__init__(
            mensaje=mensaje,
            codigo_error="VALIDACION_DOMINIO_ERROR",
            detalles=info,
        )


# Alias compatible con la nomenclatura del Issue #9
ValidacionError = ValidacionDominioError


class RecursoNoEncontradoError(DominioError):
    """Error lanzado cuando una entidad solicitada no existe en el sistema."""

    def __init__(
        self,
        recurso: str,
        identificador: str,
        detalles: dict[str, Any] | None = None,
    ) -> None:
        info = dict(detalles or {})
        info.update({"recurso": recurso, "identificador": identificador})
        super().__init__(
            mensaje=f"{recurso} con identificador '{identificador}' no fue encontrado.",
            codigo_error="RECURSO_NO_ENCONTRADO",
            detalles=info,
        )


class InscripcionInvalidaError(DominioError):
    """Error lanzado cuando una solicitud de inscripcion incumple reglas academicas."""

    def __init__(
        self,
        mensaje: str,
        alumno_matricula: str | None = None,
        materia_clave: str | None = None,
        motivo: str = "REGLA_INSCRIPCION_VIOLADA",
        detalles: dict[str, Any] | None = None,
    ) -> None:
        info = dict(detalles or {})
        if alumno_matricula:
            info["alumno_matricula"] = alumno_matricula
        if materia_clave:
            info["materia_clave"] = materia_clave
        info["motivo"] = motivo
        super().__init__(
            mensaje=mensaje,
            codigo_error="INSCRIPCION_INVALIDA",
            detalles=info,
        )


class PagoRechazadoError(DominioError):
    """Error lanzado cuando el procesamiento de un pago simulado es rechazado."""

    def __init__(
        self,
        mensaje: str,
        folio: str | None = None,
        alumno_matricula: str | None = None,
        motivo: str = "PAGO_RECHAZADO",
        detalles: dict[str, Any] | None = None,
    ) -> None:
        info = dict(detalles or {})
        if folio:
            info["folio"] = folio
        if alumno_matricula:
            info["alumno_matricula"] = alumno_matricula
        info["motivo"] = motivo
        super().__init__(
            mensaje=mensaje,
            codigo_error="PAGO_RECHAZADO",
            detalles=info,
        )
