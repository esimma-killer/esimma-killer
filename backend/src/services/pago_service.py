"""Servicio de procesamiento de pagos simulados con manejo try-except-else-finally."""

from datetime import UTC, datetime
from typing import Any

from src.domain.enums import CampusUAA, RolSistema
from src.domain.exceptions import (
    DominioError,
    PagoRechazadoError,
    RecursoNoEncontradoError,
)
from src.domain.finanzas import Pago

MONTO_MAXIMO_SIMULADO: float = 50000.0


class PagoService:
    """Gestiona transacciones de pago simulado aplicando reglas de negocio y auditoria."""

    def __init__(self, monto_maximo_permitido: float = MONTO_MAXIMO_SIMULADO) -> None:
        self._pagos: dict[str, Pago] = {}
        self._folios_en_proceso: set[str] = set()
        self._logs_actividad: list[dict[str, Any]] = []
        self._monto_maximo_permitido = float(monto_maximo_permitido)

    @property
    def logs_actividad(self) -> list[dict[str, Any]]:
        """Devuelve la bitacora de eventos financieros con estructura logs_actividad."""
        return list(self._logs_actividad)

    def obtener_pago(self, folio: str) -> Pago:
        """Consulta un pago por su folio o lanza RecursoNoEncontradoError."""
        clave = folio.strip().upper()
        pago = self._pagos.get(clave)
        if not pago:
            raise RecursoNoEncontradoError(recurso="Pago", identificador=clave)
        return pago

    def listar_pagos(self, alumno_matricula: str | None = None) -> list[dict[str, Any]]:
        """Lista todos los pagos registrados, opcionalmente filtrados por matricula."""
        pagos = list(self._pagos.values())
        if alumno_matricula:
            mat = alumno_matricula.strip().upper()
            pagos = [p for p in pagos if p.alumno_matricula == mat]
        return [p.to_dict() for p in pagos]

    def procesar_pago(
        self,
        folio: str,
        alumno_matricula: str,
        monto: float,
        concepto: str,
        referencia_bancaria: str = "REF-SIMULADA-UAA",
        id_campus: int = int(CampusUAA.CENTRAL),
        ip_origen: str = "127.0.0.1",
    ) -> dict[str, Any]:
        """Procesa un pago simulado utilizando el bloque completo try-except-else-finally."""
        folio_normalizado = folio.strip().upper()
        self._folios_en_proceso.add(folio_normalizado)
        resultado_auditoria = "ERROR"
        detalle_auditoria = "Intento de pago iniciado"

        try:
            if folio_normalizado in self._pagos:
                raise PagoRechazadoError(
                    mensaje=f"El pago con folio '{folio_normalizado}' ya fue procesado antes.",
                    folio=folio_normalizado,
                    alumno_matricula=alumno_matricula,
                    motivo="FOLIO_DUPLICADO",
                )

            nuevo_pago = Pago(
                folio=folio_normalizado,
                alumno_matricula=alumno_matricula,
                monto=monto,
                concepto=concepto,
                referencia_bancaria=referencia_bancaria,
            )

            if nuevo_pago.referencia_bancaria.upper().startswith("RECHAZADA"):
                nuevo_pago.rechazar("Referencia bancaria rechazada por el emisor simulado.")
                self._pagos[nuevo_pago.folio] = nuevo_pago
                raise PagoRechazadoError(
                    mensaje="La referencia bancaria proporcionada fue rechazada por el banco.",
                    folio=nuevo_pago.folio,
                    alumno_matricula=nuevo_pago.alumno_matricula,
                    motivo="REFERENCIA_BANCARIA_INVALIDA",
                )

            if nuevo_pago.monto > self._monto_maximo_permitido:
                nuevo_pago.rechazar("Fondos insuficientes o limite por transaccion excedido.")
                self._pagos[nuevo_pago.folio] = nuevo_pago
                raise PagoRechazadoError(
                    mensaje=(
                        f"El monto ${nuevo_pago.monto:.2f} excede el limite simulado "
                        f"de ${self._monto_maximo_permitido:.2f} (fondos insuficientes)."
                    ),
                    folio=nuevo_pago.folio,
                    alumno_matricula=nuevo_pago.alumno_matricula,
                    motivo="FONDOS_INSUFICIENTES",
                    detalles={
                        "monto_solicitado": nuevo_pago.monto,
                        "limite_permitido": self._monto_maximo_permitido,
                    },
                )

        except DominioError as exc:
            detalle_auditoria = f"{exc.codigo_error}: {exc.mensaje}"
            raise
        except (ValueError, TypeError) as exc:
            detalle_auditoria = f"Datos de pago invalidos: {exc}"
            raise PagoRechazadoError(
                mensaje=str(exc),
                folio=folio_normalizado or None,
                alumno_matricula=alumno_matricula,
                motivo="DATOS_PAGO_INVALIDOS",
            ) from exc
        else:
            nuevo_pago.aprobar()
            self._pagos[nuevo_pago.folio] = nuevo_pago
            resultado_auditoria = "EXITO"
            detalle_auditoria = f"Pago {nuevo_pago.folio} aprobado por ${nuevo_pago.monto:.2f} MXN."
            return nuevo_pago.to_dict()
        finally:
            self._folios_en_proceso.discard(folio_normalizado)
            self._logs_actividad.append(
                {
                    "id_usuario": alumno_matricula.strip().upper(),
                    "rol": RolSistema.ESTUDIANTE.value,
                    "campus": int(id_campus),
                    "accion": "procesar_pago_simulado",
                    "ip_origen": ip_origen,
                    "timestamp": datetime.now(UTC).isoformat(),
                    "resultado": resultado_auditoria,
                    "detalle": detalle_auditoria,
                }
            )
