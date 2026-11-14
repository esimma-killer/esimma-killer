"""Router de informacion publica para el Portal Institucional UAA (Landing Page)."""

from typing import Any

from fastapi import APIRouter

from src.api.schemas import AvisoInstitucionalModel, InformacionInstitucionalResponse
from src.core.config import get_settings
from src.domain.exceptions import RecursoNoEncontradoError

router = APIRouter(prefix="/informacion", tags=["Portal Institucional UAA"])


@router.get(
    "",
    response_model=InformacionInstitucionalResponse,
    summary="Informacion base del Portal Institucional UAA (Landing Page)",
    description=(
        "Provee los avisos por campus, calendario escolar y metadatos de nodos "
        "para la Landing Page multiplataforma en Flutter (lectura AP en replicas)."
    ),
)
def obtener_informacion_institucional() -> InformacionInstitucionalResponse:
    """Devuelve la cartelera informativa y metadatos de los campus UAA."""
    settings = get_settings()
    return InformacionInstitucionalResponse(
        institucion="Universidad Autonoma de Aguascalientes (UAA)",
        sistema="E-SIIMA Killer (E-SIIMA 3)",
        periodo_actual="2026-2",
        campus_activos=[
            settings.obtener_info_shard(1),
            settings.obtener_info_shard(2),
        ],
        avisos=[
            AvisoInstitucionalModel(
                id_aviso="AVI-2026-01",
                titulo="Periodo de Inscripciones y Reinscripciones 2026-2",
                resumen="El portal unificado se encuentra abierto para Campus Central y Sur.",
                id_campus=1,
                fecha_publicacion="2026-11-14",
            ),
            AvisoInstitucionalModel(
                id_aviso="AVI-2026-02",
                titulo="Cierre de Entregas de Fin de Ciclo sin Saturacion",
                resumen="Las entregas se enrutan por id_campus con verificacion SHA-256.",
                id_campus=2,
                fecha_publicacion="2026-11-14",
            ),
        ],
        calendario_escolar=[
            {"evento": "Inicio de Semestre 2026-2", "fecha": "2026-08-10"},
            {"evento": "Segunda Entrega Proyecto Integrador", "fecha": "2026-11-14"},
            {"evento": "Fin de Cursos", "fecha": "2026-12-11"},
        ],
    )


@router.get(
    "/campus/{id_campus}",
    summary="Consultar metadatos de enrutamiento de Shard por id_campus",
    description="Resuelve la topologia y postura CAP del nodo correspondiente a la Shard Key.",
)
def obtener_metadatos_campus(id_campus: int) -> dict[str, Any]:
    """Devuelve la informacion del Shard para id_campus=1 (Central) o id_campus=2 (Sur)."""
    settings = get_settings()
    try:
        return settings.obtener_info_shard(id_campus)
    except ValueError as exc:
        raise RecursoNoEncontradoError(
            recurso="CampusShard",
            identificador=str(id_campus),
        ) from exc
