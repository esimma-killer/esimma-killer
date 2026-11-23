"""Jerarquia de clases POO para personas de la institucion (Persona, Alumno, Administrativo)."""

from abc import ABC, abstractmethod
from typing import Any

from src.domain.enums import CampusUAA, EstatusAcademico, RolSistema


def _validar_solo_letras(valor: str, nombre_campo: str) -> str:
    """Valida que un campo de texto contenga unicamente letras y espacios (sin numeros)."""
    if not isinstance(valor, str):
        raise ValueError(f"El campo '{nombre_campo}' debe ser una cadena de texto.")
    limpio = " ".join(valor.strip().split())
    if not limpio:
        raise ValueError(f"El campo '{nombre_campo}' no puede estar vacio.")
    if any(ch.isdigit() for ch in limpio) or not all(
        ch.isalpha() or ch in {" ", "-", "'"} for ch in limpio
    ):
        raise ValueError(
            f"El campo '{nombre_campo}' solo acepta letras (no se permiten numeros ni simbolos)."
        )
    return limpio


def _validar_entero_estricto(valor: object, nombre_campo: str) -> int:
    """Valida que un valor sea exclusivamente un numero entero (rechaza letras y booleanos)."""
    if isinstance(valor, bool) or not isinstance(valor, int):
        raise ValueError(
            f"El campo '{nombre_campo}' solo acepta numeros enteros (no letras ni otro tipo)."
        )
    return int(valor)


class Persona(ABC):
    """Clase base abstracta que encapsula los datos personales e identidad institucional."""

    def __init__(
        self,
        nombre: str,
        apellidos: str,
        curp: str,
        email: str,
        activo: bool = True,
    ) -> None:
        self.nombre = nombre
        self.apellidos = apellidos
        self.curp = curp
        self.email = email
        self._activo = bool(activo)

    @property
    def nombre(self) -> str:
        """Devuelve el nombre de pila validado."""
        return self._nombre

    @nombre.setter
    def nombre(self, valor: str) -> None:
        self._nombre = _validar_solo_letras(valor, "nombre")

    @property
    def apellidos(self) -> str:
        """Devuelve los apellidos validados."""
        return self._apellidos

    @apellidos.setter
    def apellidos(self, valor: str) -> None:
        self._apellidos = _validar_solo_letras(valor, "apellidos")

    @property
    def nombre_completo(self) -> str:
        """Devuelve el nombre completo concatenado."""
        return f"{self._nombre} {self._apellidos}"

    @property
    def curp(self) -> str:
        """Devuelve la CURP normalizada en mayusculas."""
        return self._curp

    @curp.setter
    def curp(self, valor: str) -> None:
        normalizada = valor.strip().upper()
        if len(normalizada) != 18 or not normalizada.isalnum():
            raise ValueError("La CURP debe contener exactamente 18 caracteres alfanumericos.")
        self._curp = normalizada

    @property
    def curp_enmascarada(self) -> str:
        """Devuelve la CURP parcialmente oculta para proteger PII (LFPDPPP)."""
        return f"{self._curp[:4]}{'*' * 12}{self._curp[-2:]}"

    @property
    def email(self) -> str:
        """Devuelve el correo electronico institucional."""
        return self._email

    @email.setter
    def email(self, valor: str) -> None:
        limpio = valor.strip().lower()
        if "@" not in limpio or "." not in limpio.split("@")[-1]:
            raise ValueError(f"Formato de correo electronico invalido: '{valor}'.")
        self._email = limpio

    @property
    def activo(self) -> bool:
        """Indica si la cuenta de la persona se encuentra activa."""
        return self._activo

    @activo.setter
    def activo(self, valor: bool) -> None:
        self._activo = bool(valor)

    @abstractmethod
    def obtener_rol(self) -> RolSistema:
        """Devuelve el rol institucional de la subclase (Polimorfismo)."""

    @abstractmethod
    def obtener_permisos(self) -> list[str]:
        """Devuelve la lista de permisos minimos asociados a la subclase (Polimorfismo)."""

    @abstractmethod
    def obtener_perfil_institucional(self) -> dict[str, Any]:
        """Genera la representacion institucional polimorfica de la persona."""


class Alumno(Persona):
    """Entidad de dominio que representa a un estudiante asociado a un campus (Shard Key)."""

    def __init__(
        self,
        nombre: str,
        apellidos: str,
        curp: str,
        email: str,
        matricula: str,
        id_campus: CampusUAA,
        carrera: str,
        semestre: int = 1,
        estatus_academico: EstatusAcademico = EstatusAcademico.ACTIVO,
        activo: bool = True,
    ) -> None:
        super().__init__(
            nombre=nombre,
            apellidos=apellidos,
            curp=curp,
            email=email,
            activo=activo,
        )
        self.matricula = matricula
        self.id_campus = id_campus
        self.carrera = carrera
        self.semestre = semestre
        self.estatus_academico = estatus_academico

    @property
    def matricula(self) -> str:
        """Identificador unico estudiantil."""
        return self._matricula

    @matricula.setter
    def matricula(self, valor: str) -> None:
        limpio = valor.strip().upper()
        if not limpio:
            raise ValueError("La matricula del alumno no puede estar vacia.")
        self._matricula = limpio

    @property
    def id_campus(self) -> CampusUAA:
        """Shard Key que determina el nodo de base de datos del alumno."""
        return self._id_campus

    @id_campus.setter
    def id_campus(self, valor: CampusUAA | int) -> None:
        numero = _validar_entero_estricto(valor, "id_campus")
        self._id_campus = CampusUAA(numero)

    @property
    def carrera(self) -> str:
        """Programa educativo al que pertenece el alumno."""
        return self._carrera

    @carrera.setter
    def carrera(self, valor: str) -> None:
        self._carrera = _validar_solo_letras(valor, "carrera")

    @property
    def semestre(self) -> int:
        """Semestre actual que cursa el alumno."""
        return self._semestre

    @semestre.setter
    def semestre(self, valor: int) -> None:
        numero = _validar_entero_estricto(valor, "semestre")
        if numero < 1 or numero > 15:
            raise ValueError("El semestre debe estar entre 1 y 15.")
        self._semestre = numero

    @property
    def estatus_academico(self) -> EstatusAcademico:
        """Estatus academico vigente del alumno."""
        return self._estatus_academico

    @estatus_academico.setter
    def estatus_academico(self, valor: EstatusAcademico | str) -> None:
        self._estatus_academico = EstatusAcademico(valor)

    def puede_inscribirse(self) -> bool:
        """Verifica si el alumno cumple condiciones administrativas para inscribir materias."""
        return self.activo and self._estatus_academico == EstatusAcademico.ACTIVO

    def obtener_rol(self) -> RolSistema:
        """Implementacion polimorfica del rol de estudiante."""
        return RolSistema.ESTUDIANTE

    def obtener_permisos(self) -> list[str]:
        """Permisos minimos otorgados al rol de estudiante."""
        return [
            "cursos:consultar",
            "inscripciones:solicitar",
            "tareas:consultar",
            "entregas:subir",
            "calificaciones:consultar_propias",
            "pagos:realizar",
        ]

    def obtener_perfil_institucional(self) -> dict[str, Any]:
        """Devuelve el perfil estructurado del alumno con su Shard Key id_campus."""
        return {
            "tipo_persona": "Alumno",
            "rol": self.obtener_rol().value,
            "matricula": self._matricula,
            "nombre_completo": self.nombre_completo,
            "curp_enmascarada": self.curp_enmascarada,
            "email": self.email,
            "id_campus": int(self._id_campus),
            "campus_nombre": self._id_campus.name,
            "carrera": self._carrera,
            "semestre": self._semestre,
            "estatus_academico": self._estatus_academico.value,
            "activo": self.activo,
        }


class Administrativo(Persona):
    """Entidad de dominio que representa al personal administrativo o coordinador."""

    def __init__(
        self,
        nombre: str,
        apellidos: str,
        curp: str,
        email: str,
        numero_empleado: str,
        departamento: str,
        rol: RolSistema = RolSistema.ADMINISTRATIVO,
        id_campus: CampusUAA = CampusUAA.CENTRAL,
        activo: bool = True,
    ) -> None:
        super().__init__(
            nombre=nombre,
            apellidos=apellidos,
            curp=curp,
            email=email,
            activo=activo,
        )
        self.numero_empleado = numero_empleado
        self.departamento = departamento
        self.rol = rol
        self.id_campus = id_campus

    @property
    def numero_empleado(self) -> str:
        """Identificador laboral del administrativo."""
        return self._numero_empleado

    @numero_empleado.setter
    def numero_empleado(self, valor: str) -> None:
        limpio = valor.strip().upper()
        if not limpio:
            raise ValueError("El numero de empleado no puede estar vacio.")
        self._numero_empleado = limpio

    @property
    def departamento(self) -> str:
        """Departamento o unidad organizacional."""
        return self._departamento

    @departamento.setter
    def departamento(self, valor: str) -> None:
        self._departamento = _validar_solo_letras(valor, "departamento")

    @property
    def rol(self) -> RolSistema:
        """Rol asignado dentro del sistema."""
        return self._rol

    @rol.setter
    def rol(self, valor: RolSistema | str) -> None:
        rol_enum = RolSistema(valor)
        if rol_enum not in {RolSistema.ADMINISTRATIVO, RolSistema.COORDINADOR}:
            raise ValueError(
                "Un Administrativo solo puede tener rol 'administrativo' o 'coordinador'."
            )
        self._rol = rol_enum

    @property
    def id_campus(self) -> CampusUAA:
        """Campus de adscripcion del personal administrativo."""
        return self._id_campus

    @id_campus.setter
    def id_campus(self, valor: CampusUAA | int) -> None:
        self._id_campus = CampusUAA(int(valor))

    def obtener_rol(self) -> RolSistema:
        """Implementacion polimorfica del rol administrativo/coordinador."""
        return self._rol

    def obtener_permisos(self) -> list[str]:
        """Permisos extendidos de gestion y auditoria analitica."""
        permisos = [
            "alumnos:gestionar",
            "materias:gestionar",
            "inscripciones:auditar",
            "pagos:conciliar",
        ]
        if self._rol == RolSistema.COORDINADOR:
            permisos.append("analitica:consultar_reportes_mongodb")
        return permisos

    def obtener_perfil_institucional(self) -> dict[str, Any]:
        """Devuelve el perfil estructurado del administrativo."""
        return {
            "tipo_persona": "Administrativo",
            "rol": self._rol.value,
            "numero_empleado": self._numero_empleado,
            "nombre_completo": self.nombre_completo,
            "curp_enmascarada": self.curp_enmascarada,
            "email": self.email,
            "departamento": self._departamento,
            "id_campus": int(self._id_campus),
            "campus_nombre": self._id_campus.name,
            "activo": self.activo,
        }


class Profesor(Persona):
    """Entidad docente con separacion explicita entre datos publicos y sensibles (PII/nomina)."""

    def __init__(
        self,
        nombre: str,
        apellidos: str,
        curp: str,
        email: str,
        numero_empleado: str,
        departamento: str,
        cubiculo: str,
        id_campus: CampusUAA = CampusUAA.CENTRAL,
        rfc_cifrado: str = "ENC_RFC_SYNTHETIC",
        salario_base: float = 0.0,
        activo: bool = True,
    ) -> None:
        super().__init__(
            nombre=nombre,
            apellidos=apellidos,
            curp=curp,
            email=email,
            activo=activo,
        )
        self.numero_empleado = numero_empleado
        self.departamento = departamento
        self.cubiculo = cubiculo
        self.id_campus = id_campus
        self.rfc_cifrado = rfc_cifrado
        self.salario_base = salario_base

    @property
    def numero_empleado(self) -> str:
        """Identificador de docente."""
        return self._numero_empleado

    @numero_empleado.setter
    def numero_empleado(self, valor: str) -> None:
        limpio = valor.strip().upper()
        if not limpio:
            raise ValueError("El numero de empleado docente no puede estar vacio.")
        self._numero_empleado = limpio

    @property
    def departamento(self) -> str:
        """Departamento academico de adscripcion."""
        return self._departamento

    @departamento.setter
    def departamento(self, valor: str) -> None:
        self._departamento = _validar_solo_letras(valor, "departamento docente")

    @property
    def cubiculo(self) -> str:
        """Ubicacion fisica del docente en el campus."""
        return self._cubiculo

    @cubiculo.setter
    def cubiculo(self, valor: str) -> None:
        self._cubiculo = valor.strip() or "S/N"

    @property
    def id_campus(self) -> CampusUAA:
        """Shard Key del campus al que pertenece el profesor."""
        return self._id_campus

    @id_campus.setter
    def id_campus(self, valor: CampusUAA | int) -> None:
        self._id_campus = CampusUAA(int(valor))

    @property
    def rfc_cifrado(self) -> str:
        """Dato fiscal sensible (almacenado en fragmento vertical profesores_sensible)."""
        return self._rfc_cifrado

    @rfc_cifrado.setter
    def rfc_cifrado(self, valor: str) -> None:
        limpio = valor.strip()
        if not limpio:
            raise ValueError("El RFC cifrado no puede estar vacio.")
        self._rfc_cifrado = limpio

    @property
    def salario_base(self) -> float:
        """Dato patrimonial sensible restringido."""
        return self._salario_base

    @salario_base.setter
    def salario_base(self, valor: float) -> None:
        if isinstance(valor, bool) or not isinstance(valor, (int, float)):
            raise ValueError("El salario base solo acepta numeros (no letras).")
        if valor < 0:
            raise ValueError("El salario base no puede ser negativo.")
        self._salario_base = float(valor)

    def obtener_rol(self) -> RolSistema:
        """Implementacion polimorfica del rol docente."""
        return RolSistema.PROFESOR

    def obtener_permisos(self) -> list[str]:
        """Permisos para gestion de cursos, asignacion de tareas y evaluacion."""
        return [
            "cursos:crear",
            "tareas:publicar",
            "entregas:descargar",
            "calificaciones:registrar",
        ]

    def obtener_perfil_publico(self) -> dict[str, Any]:
        """Proyeccion exclusiva de profesores_publico (sin exponer RFC, CURP ni nomina)."""
        return {
            "numero_empleado": self._numero_empleado,
            "nombre_completo": self.nombre_completo,
            "departamento": self._departamento,
            "cubiculo": self._cubiculo,
            "email_contacto": self.email,
            "id_campus": int(self._id_campus),
        }

    def obtener_perfil_institucional(self) -> dict[str, Any]:
        """Implementacion polimorfica del perfil institucional del profesor."""
        perfil = self.obtener_perfil_publico()
        perfil["tipo_persona"] = "Profesor"
        perfil["rol"] = self.obtener_rol().value
        perfil["curp_enmascarada"] = self.curp_enmascarada
        perfil["activo"] = self.activo
        return perfil
