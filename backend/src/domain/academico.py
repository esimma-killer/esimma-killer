"""Entidades de negocio academicas: Materia, Inscripcion, Calificacion, Tarea y Entrega."""

import hashlib
from datetime import UTC, datetime
from typing import Any

from src.domain.enums import CampusUAA, EstadoEntrega, EstadoInscripcion
from src.domain.personas import Alumno

CALIFICACION_MINIMA_APROBATORIA: float = 6.0


class Materia:
    """Representa una asignatura o curso ofertado en un campus (Shard Key: id_campus)."""

    def __init__(
        self,
        clave: str,
        nombre: str,
        creditos: int,
        cupo_maximo: int,
        id_campus: CampusUAA = CampusUAA.CENTRAL,
        periodo_semestral: str = "2026-2",
        cupo_actual: int = 0,
        prerrequisitos: list[str] | None = None,
    ) -> None:
        self.clave = clave
        self.nombre = nombre
        self.creditos = creditos
        self.cupo_maximo = cupo_maximo
        self.id_campus = id_campus
        self.periodo_semestral = periodo_semestral
        if cupo_actual < 0 or cupo_actual > self._cupo_maximo:
            raise ValueError("El cupo actual debe estar entre 0 y el cupo maximo.")
        self._cupo_actual = int(cupo_actual)
        self._prerrequisitos = [p.strip().upper() for p in (prerrequisitos or []) if p.strip()]

    @property
    def clave(self) -> str:
        """Clave unica de la asignatura."""
        return self._clave

    @clave.setter
    def clave(self, valor: str) -> None:
        limpio = valor.strip().upper()
        if not limpio:
            raise ValueError("La clave de la materia no puede estar vacia.")
        self._clave = limpio

    @property
    def nombre(self) -> str:
        """Nombre oficial de la asignatura."""
        return self._nombre

    @nombre.setter
    def nombre(self, valor: str) -> None:
        if not isinstance(valor, str):
            raise ValueError("El nombre de la materia debe ser texto.")
        limpio = valor.strip()
        if not limpio or any(ch.isdigit() for ch in limpio):
            raise ValueError("El nombre de la materia solo acepta letras (sin numeros ni vacio).")
        self._nombre = limpio

    @property
    def creditos(self) -> int:
        """Valor en creditos academicos."""
        return self._creditos

    @creditos.setter
    def creditos(self, valor: int) -> None:
        if isinstance(valor, bool) or not isinstance(valor, int):
            raise ValueError("Los creditos de la materia solo aceptan numeros enteros (no letras).")
        if valor <= 0 or valor > 20:
            raise ValueError("Los creditos de la materia deben estar entre 1 y 20.")
        self._creditos = int(valor)

    @property
    def cupo_maximo(self) -> int:
        """Capacidad maxima de estudiantes inscritos."""
        return self._cupo_maximo

    @cupo_maximo.setter
    def cupo_maximo(self, valor: int) -> None:
        if isinstance(valor, bool) or not isinstance(valor, int):
            raise ValueError("El cupo maximo solo acepta numeros enteros (no letras).")
        if valor <= 0:
            raise ValueError("El cupo maximo debe ser mayor a 0.")
        self._cupo_maximo = int(valor)

    @property
    def cupo_actual(self) -> int:
        """Numero de alumnos actualmente inscritos."""
        return self._cupo_actual

    @property
    def id_campus(self) -> CampusUAA:
        """Shard Key del campus donde se imparte la materia."""
        return self._id_campus

    @id_campus.setter
    def id_campus(self, valor: CampusUAA | int) -> None:
        self._id_campus = CampusUAA(int(valor))

    @property
    def periodo_semestral(self) -> str:
        """Periodo escolar vigente (ej. 2026-2)."""
        return self._periodo_semestral

    @periodo_semestral.setter
    def periodo_semestral(self, valor: str) -> None:
        limpio = valor.strip()
        if not limpio:
            raise ValueError("El periodo semestral no puede estar vacio.")
        self._periodo_semestral = limpio

    @property
    def prerrequisitos(self) -> list[str]:
        """Lista de claves de materias seriadas requeridas."""
        return list(self._prerrequisitos)

    @property
    def tiene_cupo_disponible(self) -> bool:
        """Indica si aún existen lugares disponibles en la materia."""
        return self._cupo_actual < self._cupo_maximo

    @property
    def lugares_disponibles(self) -> int:
        """Cantidad de asientos libres en el grupo."""
        return max(0, self._cupo_maximo - self._cupo_actual)

    def incrementar_cupo(self) -> None:
        """Ocupa un lugar en la materia si hay disponibilidad."""
        if not self.tiene_cupo_disponible:
            raise ValueError(f"La materia '{self._clave}' ha alcanzado su cupo maximo.")
        self._cupo_actual += 1

    def liberar_cupo(self) -> None:
        """Libera un lugar cuando una inscripcion se cancela."""
        if self._cupo_actual > 0:
            self._cupo_actual -= 1

    def to_dict(self) -> dict[str, Any]:
        """Representacion en diccionario de la materia."""
        return {
            "clave": self._clave,
            "nombre": self._nombre,
            "creditos": self._creditos,
            "id_campus": int(self._id_campus),
            "campus_nombre": self._id_campus.name,
            "periodo_semestral": self._periodo_semestral,
            "cupo_maximo": self._cupo_maximo,
            "cupo_actual": self._cupo_actual,
            "lugares_disponibles": self.lugares_disponibles,
            "tiene_cupo_disponible": self.tiene_cupo_disponible,
            "prerrequisitos": self.prerrequisitos,
        }


class Inscripcion:
    """Vincula a un Alumno con una Materia dentro de un periodo academico."""

    def __init__(
        self,
        folio: str,
        alumno: Alumno,
        materia: Materia,
        periodo: str = "2026-2",
        fecha_inscripcion: datetime | None = None,
        estado: EstadoInscripcion = EstadoInscripcion.PENDIENTE,
    ) -> None:
        limpio = folio.strip().upper()
        if not limpio:
            raise ValueError("El folio de inscripcion no puede estar vacio.")
        self._folio = limpio
        self._alumno = alumno
        self._materia = materia
        self._periodo = periodo.strip() or "2026-2"
        self._fecha_inscripcion = fecha_inscripcion or datetime.now(UTC)
        self._estado = EstadoInscripcion(estado)

    @property
    def folio(self) -> str:
        """Folio unico de la transaccion de inscripcion."""
        return self._folio

    @property
    def alumno(self) -> Alumno:
        """Alumno titular de la inscripcion."""
        return self._alumno

    @property
    def materia(self) -> Materia:
        """Materia a la que se inscribe el alumno."""
        return self._materia

    @property
    def periodo(self) -> str:
        """Periodo lectivo de la inscripcion."""
        return self._periodo

    @property
    def fecha_inscripcion(self) -> datetime:
        """Marca de tiempo UTC del registro."""
        return self._fecha_inscripcion

    @property
    def estado(self) -> EstadoInscripcion:
        """Estado actual de la inscripcion."""
        return self._estado

    def confirmar(self) -> None:
        """Cambia el estado de la inscripcion a CONFIRMADA."""
        if self._estado == EstadoInscripcion.CANCELADA:
            raise ValueError("No se puede confirmar una inscripcion previamente cancelada.")
        self._estado = EstadoInscripcion.CONFIRMADA

    def cancelar(self) -> None:
        """Cancela la inscripcion activa."""
        self._estado = EstadoInscripcion.CANCELADA

    def to_dict(self) -> dict[str, Any]:
        """Serializa la inscripcion a diccionario."""
        return {
            "folio": self._folio,
            "alumno_matricula": self._alumno.matricula,
            "alumno_nombre": self._alumno.nombre_completo,
            "materia_clave": self._materia.clave,
            "materia_nombre": self._materia.nombre,
            "id_campus": int(self._materia.id_campus),
            "periodo": self._periodo,
            "fecha_inscripcion": self._fecha_inscripcion.isoformat(),
            "estado": self._estado.value,
        }


class Calificacion:
    """Representa la evaluacion ponderada de un alumno en una materia y periodo."""

    def __init__(
        self,
        alumno_matricula: str,
        materia_clave: str,
        periodo: str,
        valor_ponderado: float,
        retroalimentacion: str = "",
    ) -> None:
        mat = alumno_matricula.strip().upper()
        if not mat:
            raise ValueError("La matricula del alumno es obligatoria en la calificacion.")
        clv = materia_clave.strip().upper()
        if not clv:
            raise ValueError("La clave de la materia es obligatoria en la calificacion.")
        self._alumno_matricula = mat
        self._materia_clave = clv
        self._periodo = periodo.strip() or "2026-2"
        self.valor_ponderado = valor_ponderado
        self._retroalimentacion = retroalimentacion.strip()

    @property
    def alumno_matricula(self) -> str:
        """Matricula del alumno evaluado."""
        return self._alumno_matricula

    @property
    def materia_clave(self) -> str:
        """Clave de la asignatura evaluada."""
        return self._materia_clave

    @property
    def periodo(self) -> str:
        """Periodo escolar de la evaluacion."""
        return self._periodo

    @property
    def valor_ponderado(self) -> float:
        """Calificacion numerica en escala de 0.0 a 10.0."""
        return self._valor_ponderado

    @valor_ponderado.setter
    def valor_ponderado(self, valor: float) -> None:
        if isinstance(valor, bool) or not isinstance(valor, (int, float)):
            raise ValueError("La calificacion solo acepta valores numericos (no letras).")
        numero = float(valor)
        if numero < 0.0 or numero > 10.0:
            raise ValueError("La calificacion debe encontrarse en la escala de 0.0 a 10.0.")
        self._valor_ponderado = round(numero, 2)

    @property
    def retroalimentacion(self) -> str:
        """Comentarios del docente sobre el desempeno."""
        return self._retroalimentacion

    @property
    def esta_aprobada(self) -> bool:
        """Indica si el valor ponderado alcanza el minimo aprobatorio institucional."""
        return self._valor_ponderado >= CALIFICACION_MINIMA_APROBATORIA

    def to_dict(self) -> dict[str, Any]:
        """Devuelve la representacion estructurada de la calificacion."""
        return {
            "alumno_matricula": self._alumno_matricula,
            "materia_clave": self._materia_clave,
            "periodo": self._periodo,
            "valor_ponderado": self._valor_ponderado,
            "esta_aprobada": self.esta_aprobada,
            "retroalimentacion": self._retroalimentacion,
        }


class Tarea:
    """Actividad evaluable publicada por un profesor con fecha limite y ponderacion."""

    def __init__(
        self,
        id_tarea: str,
        materia_clave: str,
        titulo: str,
        fecha_limite: datetime,
        ponderacion: float,
        descripcion: str = "",
    ) -> None:
        limpio = id_tarea.strip().upper()
        if not limpio:
            raise ValueError("El identificador de la tarea no puede estar vacio.")
        if ponderacion <= 0.0 or ponderacion > 100.0:
            raise ValueError("La ponderacion de la tarea debe estar entre 0.1 y 100.0.")
        self._id_tarea = limpio
        self._materia_clave = materia_clave.strip().upper()
        self._titulo = titulo.strip()
        self._descripcion = descripcion.strip()
        self._fecha_limite = fecha_limite
        self._ponderacion = float(ponderacion)

    @property
    def id_tarea(self) -> str:
        """Identificador unico de la tarea."""
        return self._id_tarea

    @property
    def materia_clave(self) -> str:
        """Clave de la materia a la que pertenece la tarea."""
        return self._materia_clave

    @property
    def titulo(self) -> str:
        """Titulo de la actividad."""
        return self._titulo

    @property
    def fecha_limite(self) -> datetime:
        """Fecha y hora limite de entrega."""
        return self._fecha_limite

    @property
    def ponderacion(self) -> float:
        """Peso porcentual sobre la calificacion."""
        return self._ponderacion

    def esta_vencida(self, fecha_referencia: datetime | None = None) -> bool:
        """Determina si la fecha de referencia supera la fecha limite."""
        referencia = fecha_referencia or datetime.now(UTC)
        return referencia > self._fecha_limite


class Entrega:
    """Entrega de tarea por un alumno con integridad SHA-256 y clasificacion de puntualidad."""

    def __init__(
        self,
        id_entrega: str,
        tarea: Tarea,
        alumno_matricula: str,
        archivo_url: str,
        contenido_bytes: bytes = b"contenido_sintetico_uaa",
        fecha_entrega: datetime | None = None,
    ) -> None:
        self._id_entrega = id_entrega.strip().upper()
        self._tarea = tarea
        self._alumno_matricula = alumno_matricula.strip().upper()
        self._archivo_url = archivo_url.strip()
        self._fecha_entrega = fecha_entrega or datetime.now(UTC)
        self._hash_sha256 = hashlib.sha256(contenido_bytes).hexdigest()
        self._estado_entrega = (
            EstadoEntrega.TARDIA
            if self._tarea.esta_vencida(self._fecha_entrega)
            else EstadoEntrega.A_TIEMPO
        )

    @property
    def id_entrega(self) -> str:
        """Identificador de la entrega."""
        return self._id_entrega

    @property
    def hash_sha256(self) -> str:
        """Resumen criptografico SHA-256 para garantizar integridad (Triada CIA)."""
        return self._hash_sha256

    @property
    def estado_entrega(self) -> EstadoEntrega:
        """Estado automatico (A_TIEMPO o TARDIA) para metricas analiticas en MongoDB."""
        return self._estado_entrega

    @property
    def es_entrega_a_tiempo(self) -> bool:
        """Indica si la entrega se realizo dentro del plazo establecido."""
        return self._estado_entrega == EstadoEntrega.A_TIEMPO

    def to_dict(self) -> dict[str, Any]:
        """Serializa la entrega incluyendo su hash SHA-256 y estado de puntualidad."""
        return {
            "id_entrega": self._id_entrega,
            "id_tarea": self._tarea.id_tarea,
            "alumno_matricula": self._alumno_matricula,
            "archivo_url": self._archivo_url,
            "fecha_entrega": self._fecha_entrega.isoformat(),
            "hash_sha256": self._hash_sha256,
            "estado_entrega": self._estado_entrega.value,
            "es_entrega_a_tiempo": self.es_entrega_a_tiempo,
        }
