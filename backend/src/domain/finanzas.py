"""Entidad de dominio financiera para procesamiento de pagos simulados (Pago)."""

from datetime import UTC, datetime
from typing import Any

from src.domain.enums import EstatusPago


class Pago:
    """Representa una transaccion de pago institucional simulado conforme al alcance."""

    def __init__(
        self,
        folio: str,
        alumno_matricula: str,
        monto: float,
        concepto: str,
        estatus: EstatusPago = EstatusPago.PENDIENTE,
        referencia_bancaria: str = "REF-SIMULADA-UAA",
        fecha_creacion: datetime | None = None,
    ) -> None:
        self.folio = folio
        self.alumno_matricula = alumno_matricula
        self.monto = monto
        self.concepto = concepto
        self._estatus = EstatusPago(estatus)
        self._referencia_bancaria = referencia_bancaria.strip() or "REF-SIMULADA-UAA"
        self._fecha_creacion = fecha_creacion or datetime.now(UTC)
        self._motivo_rechazo: str | None = None

    @property
    def folio(self) -> str:
        """Folio unico de la transaccion de pago."""
        return self._folio

    @folio.setter
    def folio(self, valor: str) -> None:
        limpio = valor.strip().upper()
        if not limpio:
            raise ValueError("El folio del pago no puede estar vacio.")
        self._folio = limpio

    @property
    def alumno_matricula(self) -> str:
        """Matricula del alumno que realiza el pago."""
        return self._alumno_matricula

    @alumno_matricula.setter
    def alumno_matricula(self, valor: str) -> None:
        limpio = valor.strip().upper()
        if not limpio:
            raise ValueError("La matricula del alumno es obligatoria para el pago.")
        self._alumno_matricula = limpio

    @property
    def monto(self) -> float:
        """Monto monetario en MXN de la operacion."""
        return self._monto

    @monto.setter
    def monto(self, valor: float) -> None:
        if isinstance(valor, bool) or not isinstance(valor, (int, float)):
            raise ValueError("El monto del pago solo acepta numeros (no letras).")
        numero = float(valor)
        if numero <= 0.0:
            raise ValueError("El monto del pago debe ser estrictamente mayor a 0.0.")
        self._monto = round(numero, 2)

    @property
    def concepto(self) -> str:
        """Concepto institucional (ej. Colegiatura, Inscripcion, Examen)."""
        return self._concepto

    @concepto.setter
    def concepto(self, valor: str) -> None:
        if not isinstance(valor, str):
            raise ValueError("El concepto del pago debe ser texto.")
        limpio = valor.strip()
        if not limpio or not any(ch.isalpha() for ch in limpio):
            raise ValueError(
                "El concepto del pago debe contener letras y no puede ser solo numeros o vacio."
            )
        self._concepto = limpio

    @property
    def estatus(self) -> EstatusPago:
        """Estatus actual de la transaccion."""
        return self._estatus

    @property
    def referencia_bancaria(self) -> str:
        """Referencia bancaria sintetica asociada al pago."""
        return self._referencia_bancaria

    @property
    def motivo_rechazo(self) -> str | None:
        """Detalle en caso de que la transaccion haya sido rechazada."""
        return self._motivo_rechazo

    @property
    def esta_aprobado(self) -> bool:
        """Indica si el pago fue aprobado exitosamente."""
        return self._estatus == EstatusPago.APROBADO

    def aprobar(self) -> None:
        """Marca el pago como aprobado si se encontraba pendiente."""
        if self._estatus == EstatusPago.RECHAZADO:
            raise ValueError("No se puede aprobar un pago previamente rechazado.")
        self._estatus = EstatusPago.APROBADO
        self._motivo_rechazo = None

    def rechazar(self, motivo: str) -> None:
        """Marca el pago como rechazado registrando la causa."""
        self._estatus = EstatusPago.RECHAZADO
        self._motivo_rechazo = motivo.strip() or "Pago rechazado por regla de negocio."

    def to_dict(self) -> dict[str, Any]:
        """Serializa el pago a diccionario."""
        return {
            "folio": self._folio,
            "alumno_matricula": self._alumno_matricula,
            "monto": self._monto,
            "concepto": self._concepto,
            "estatus": self._estatus.value,
            "esta_aprobado": self.esta_aprobado,
            "referencia_bancaria": self._referencia_bancaria,
            "fecha_creacion": self._fecha_creacion.isoformat(),
            "motivo_rechazo": self._motivo_rechazo,
        }
