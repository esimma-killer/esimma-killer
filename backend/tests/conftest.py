"""Fixtures compartidas de Pytest para instancias sinteticas del dominio y servicios."""

from datetime import UTC, datetime, timedelta

import pytest
from src.api.dependencies import reset_services_for_testing
from src.domain import (
    Administrativo,
    Alumno,
    CampusUAA,
    EstatusAcademico,
    Materia,
    Pago,
    Profesor,
    RolSistema,
    Tarea,
)
from src.services import InscripcionService, PagoService


@pytest.fixture(autouse=True)
def reset_estado_api() -> None:
    """Reinicia el estado en memoria de las dependencias antes de cada prueba."""
    reset_services_for_testing()


@pytest.fixture
def alumno_central() -> Alumno:
    """Genera una instancia sintetica de Alumno adscrito al Campus Central (Shard 1)."""
    return Alumno(
        nombre="Gael Emiliano",
        apellidos="Nefarole Lopez",
        curp="NEFG040101HDFRNN01",
        email="gael.nefarole@edu.uaa.mx",
        matricula="ID345678",
        id_campus=CampusUAA.CENTRAL,
        carrera="Ingenieria en Sistemas Computacionales",
        semestre=6,
        estatus_academico=EstatusAcademico.ACTIVO,
    )


@pytest.fixture
def alumno_sur() -> Alumno:
    """Genera una instancia sintetica de Alumno adscrito al Campus Sur (Shard 2)."""
    return Alumno(
        nombre="Angel Azael",
        apellidos="Fajardo Espino",
        curp="FAEA040202HDFRNN02",
        email="azael.fajardo@edu.uaa.mx",
        matricula="ID345679",
        id_campus=CampusUAA.SUR,
        carrera="Ingenieria en Sistemas Computacionales",
        semestre=6,
        estatus_academico=EstatusAcademico.ACTIVO,
    )


@pytest.fixture
def administrativo_coordinador() -> Administrativo:
    """Genera una instancia sintetica de Administrativo con rol de coordinador."""
    return Administrativo(
        nombre="Francisco Javier",
        apellidos="Sanchez Vallin",
        curp="SAVF040303HDFRNN04",
        email="francisco.sanchez@edu.uaa.mx",
        numero_empleado="EMP-9001",
        departamento="Coordinacion de Sistemas Computacionales",
        rol=RolSistema.COORDINADOR,
        id_campus=CampusUAA.CENTRAL,
    )


@pytest.fixture
def profesor_central() -> Profesor:
    """Genera una instancia sintetica de Profesor con datos publicos y sensibles."""
    return Profesor(
        nombre="David",
        apellidos="Montoya",
        curp="MOND800101HDFRNN03",
        email="dr.davidmontoya.dcat@gmail.com",
        numero_empleado="DOC-1001",
        departamento="Sistemas de Informacion",
        cubiculo="Edificio 48 - Cubiculo 12",
        id_campus=CampusUAA.CENTRAL,
        rfc_cifrado="ENC_RFC_MOND800101",
        salario_base=32000.0,
    )


@pytest.fixture
def materia_central() -> Materia:
    """Genera una Materia del Campus Central con cupo disponible y sin prerrequisitos."""
    return Materia(
        clave="ISC-601",
        nombre="Bases de Datos Distribuidas",
        creditos=8,
        cupo_maximo=2,
        id_campus=CampusUAA.CENTRAL,
        periodo_semestral="2026-2",
    )


@pytest.fixture
def materia_con_prerrequisito() -> Materia:
    """Genera una Materia seriada que requiere aprobar ISC-501."""
    return Materia(
        clave="ISC-602",
        nombre="Seguridad en Sistemas de Computo",
        creditos=8,
        cupo_maximo=10,
        id_campus=CampusUAA.CENTRAL,
        periodo_semestral="2026-2",
        prerrequisitos=["ISC-501"],
    )


@pytest.fixture
def tarea_vigente() -> Tarea:
    """Genera una Tarea cuya fecha limite es en el futuro."""
    return Tarea(
        id_tarea="TAR-100",
        materia_clave="ISC-601",
        titulo="Practica Sharding Horizontal",
        fecha_limite=datetime.now(UTC) + timedelta(days=3),
        ponderacion=25.0,
        descripcion="Configurar nodos maestros por id_campus.",
    )


@pytest.fixture
def pago_pendiente() -> Pago:
    """Genera una instancia sintetica de Pago en estado PENDIENTE."""
    return Pago(
        folio="PAG-2026-500",
        alumno_matricula="ID345678",
        monto=1850.50,
        concepto="Colegiatura Mensual",
    )


@pytest.fixture
def inscripcion_service() -> InscripcionService:
    """Devuelve una instancia limpia del servicio de inscripciones con datos semilla."""
    return InscripcionService(cargar_semilla=True)


@pytest.fixture
def pago_service() -> PagoService:
    """Devuelve una instancia limpia del servicio de pagos simulados."""
    return PagoService()
