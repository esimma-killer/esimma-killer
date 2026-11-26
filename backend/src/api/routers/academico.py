"""Router modular para operaciones academicas: Alumnos, Materias, Inscripciones y Entregas."""

from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, status

from src.api.dependencies import get_inscripcion_service
from src.api.schemas import (
    AlumnoCreateRequest,
    AlumnoResponse,
    EntregaTareaRequest,
    EntregaTareaResponse,
    InscripcionCreateRequest,
    InscripcionResponse,
    MateriaCreateRequest,
    MateriaResponse,
)
from src.domain.academico import Materia
from src.domain.enums import CampusUAA
from src.domain.exceptions import ValidacionDominioError
from src.domain.personas import Alumno
from src.security.models import AuthUser
from src.security.rbac import require_roles
from src.services.inscripcion_service import InscripcionService

router = APIRouter(prefix="/academico", tags=["Gestion Academica e Inscripciones"])

InscripcionServiceDep = Annotated[InscripcionService, Depends(get_inscripcion_service)]
CoordinadorDep = Annotated[AuthUser, Depends(require_roles("coordinador"))]


@router.get(
    "/alumnos",
    response_model=list[AlumnoResponse],
    summary="Listar alumnos registrados (filtrable por Shard Key id_campus)",
)
def listar_alumnos(
    service: InscripcionServiceDep,
    id_campus: Annotated[
        int | None,
        Query(ge=1, le=2, description="Filtrar por Shard Key (1=Central, 2=Sur)"),
    ] = None,
) -> list[dict[str, Any]]:
    """Devuelve los perfiles institucionales de los alumnos registrados."""
    alumnos = service.listar_alumnos(id_campus=id_campus)
    return [a.obtener_perfil_institucional() for a in alumnos]


@router.get(
    "/alumnos/{matricula}",
    response_model=AlumnoResponse,
    summary="Consultar perfil institucional de un Alumno por matricula",
)
def obtener_alumno(
    matricula: str,
    service: InscripcionServiceDep,
) -> dict[str, Any]:
    """Busca un alumno por matricula o responde HTTP 404 si no existe."""
    alumno = service.obtener_alumno(matricula)
    return alumno.obtener_perfil_institucional()


@router.post(
    "/alumnos",
    response_model=AlumnoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un nuevo Alumno en el dominio",
)
def crear_alumno(
    payload: AlumnoCreateRequest,
    service: InscripcionServiceDep,
) -> dict[str, Any]:
    """Instancia la clase POO Alumno validando CURP, correo y Shard Key id_campus."""
    try:
        nuevo_alumno = Alumno(
            nombre=payload.nombre,
            apellidos=payload.apellidos,
            curp=payload.curp,
            email=payload.email,
            matricula=payload.matricula,
            id_campus=CampusUAA(payload.id_campus),
            carrera=payload.carrera,
            semestre=payload.semestre,
        )
    except ValueError as exc:
        raise ValidacionDominioError(mensaje=str(exc)) from exc

    registrado = service.registrar_alumno(nuevo_alumno)
    return registrado.obtener_perfil_institucional()


@router.get(
    "/materias",
    response_model=list[MateriaResponse],
    summary="Listar materias ofertadas (filtrable por Shard Key id_campus)",
)
def listar_materias(
    service: InscripcionServiceDep,
    id_campus: Annotated[
        int | None,
        Query(ge=1, le=2, description="Filtrar por Shard Key (1=Central, 2=Sur)"),
    ] = None,
) -> list[dict[str, Any]]:
    """Devuelve las asignaturas ofertadas con su disponibilidad de cupo en tiempo real."""
    materias = service.listar_materias(id_campus=id_campus)
    return [m.to_dict() for m in materias]


@router.post(
    "/materias",
    response_model=MateriaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar una nueva Materia en el catalogo",
)
def crear_materia(
    payload: MateriaCreateRequest,
    service: InscripcionServiceDep,
) -> dict[str, Any]:
    """Instancia la clase POO Materia y la incorpora al catalogo del campus correspondiente."""
    try:
        nueva_materia = Materia(
            clave=payload.clave,
            nombre=payload.nombre,
            creditos=payload.creditos,
            cupo_maximo=payload.cupo_maximo,
            id_campus=CampusUAA(payload.id_campus),
            periodo_semestral=payload.periodo_semestral,
            prerrequisitos=payload.prerrequisitos,
        )
    except ValueError as exc:
        raise ValidacionDominioError(mensaje=str(exc)) from exc

    registrada = service.registrar_materia(nueva_materia)
    return registrada.to_dict()


@router.post(
    "/inscripciones",
    response_model=InscripcionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Solicitar inscripcion de Alumno a Materia (try-except-else-finally)",
)
def crear_inscripcion(
    payload: InscripcionCreateRequest,
    service: InscripcionServiceDep,
) -> dict[str, Any]:
    """Ejecuta el servicio de inscripcion validando cupo, campus y prerrequisitos."""
    return service.inscribir_alumno(
        folio=payload.folio,
        alumno_matricula=payload.alumno_matricula,
        materia_clave=payload.materia_clave,
        periodo=payload.periodo,
    )


@router.get(
    "/inscripciones",
    response_model=list[InscripcionResponse],
    summary="Listar todas las inscripciones confirmadas",
)
def listar_inscripciones(service: InscripcionServiceDep) -> list[dict[str, Any]]:
    """Devuelve la lista de inscripciones activas en el sistema."""
    return service.listar_inscripciones()


@router.post(
    "/entregas",
    response_model=EntregaTareaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Subir entrega de tarea con calculo de hash SHA-256",
)
def registrar_entrega(
    payload: EntregaTareaRequest,
    service: InscripcionServiceDep,
) -> dict[str, Any]:
    """Registra una entrega verificando integridad SHA-256 y puntualidad (A_TIEMPO/TARDIA)."""
    return service.registrar_entrega_tarea(
        id_entrega=payload.id_entrega,
        id_tarea=payload.id_tarea,
        alumno_matricula=payload.alumno_matricula,
        archivo_url=payload.archivo_url,
        contenido_texto=payload.contenido_texto,
    )


@router.get(
    "/auditoria",
    summary="Consultar bitacora de eventos logs_actividad (estructura MongoDB)",
)
def consultar_auditoria_academica(
    service: InscripcionServiceDep,
    _usuario: CoordinadorDep,
) -> list[dict[str, Any]]:
    """Devuelve la auditoria solo a coordinadores autenticados."""
    return service.logs_actividad
