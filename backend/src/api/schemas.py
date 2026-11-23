"""Esquemas Pydantic v2 para validacion de entrada y contratos OpenAPI (/docs)."""

from typing import Any

from pydantic import BaseModel, Field, StrictFloat, StrictInt


class ErrorResponseModel(BaseModel):
    """Estructura estandarizada de error devuelta por la API ante excepciones del dominio."""

    error: str = Field(..., description="Nombre de la clase de excepcion del dominio.")
    codigo_error: str = Field(..., description="Codigo identificador del error.")
    mensaje: str = Field(..., description="Descripcion legible de la causa del error.")
    detalles: dict[str, Any] = Field(
        default_factory=dict,
        description="Metadatos contextuales adicionales del error.",
    )


class HealthResponseModel(BaseModel):
    """Contrato de respuesta del endpoint de monitoreo /api/v1/health."""

    status: str = Field(default="ok", description="Estado operativo del servicio API.")
    app_name: str = Field(..., description="Nombre oficial del servicio.")
    version: str = Field(..., description="Version semantica de la API.")
    environment: str = Field(..., description="Entorno de ejecucion actual.")
    timestamp: str = Field(..., description="Marca de tiempo UTC en formato ISO-8601.")
    shards_status: dict[str, str] = Field(
        ...,
        description="Estado de conectividad simulado de los Shards por id_campus.",
    )


class AvisoInstitucionalModel(BaseModel):
    """Representa un aviso o noticia publicada en el Portal Institucional UAA."""

    id_aviso: str = Field(..., description="Identificador del aviso.")
    titulo: str = Field(..., description="Titulo del aviso institucional.")
    resumen: str = Field(..., description="Contenido breve del comunicado.")
    id_campus: int = Field(..., description="Shard Key del campus (1=Central, 2=Sur).")
    fecha_publicacion: str = Field(..., description="Fecha del aviso.")


class InformacionInstitucionalResponse(BaseModel):
    """Contrato para poblar la Landing Page Institucional UAA (Bosquejo 1)."""

    institucion: str = Field(..., description="Nombre de la institucion educativa.")
    sistema: str = Field(..., description="Nombre del prototipo integrador.")
    periodo_actual: str = Field(..., description="Periodo escolar activo.")
    campus_activos: list[dict[str, Any]] = Field(
        ...,
        description="Metadatos de los campus y nodos distribuidos.",
    )
    avisos: list[AvisoInstitucionalModel] = Field(
        ...,
        description="Cartelera de avisos institucionales.",
    )
    calendario_escolar: list[dict[str, str]] = Field(
        ...,
        description="Fechas clave del calendario academico.",
    )


class AlumnoCreateRequest(BaseModel):
    """Datos de entrada para registrar un nuevo Alumno en el dominio."""

    nombre: str = Field(
        ...,
        min_length=2,
        max_length=80,
        pattern=r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s'-]+$",
        description="Nombre del alumno (solo letras y espacios, sin numeros).",
        examples=["Gael Emiliano"],
    )
    apellidos: str = Field(
        ...,
        min_length=2,
        max_length=100,
        pattern=r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s'-]+$",
        description="Apellidos del alumno (solo letras y espacios, sin numeros).",
        examples=["Nefarole Lopez"],
    )
    curp: str = Field(
        ...,
        min_length=18,
        max_length=18,
        pattern=r"^[A-Za-z0-9]{18}$",
        description="CURP sintetica de 18 caracteres alfanumericos.",
        examples=["NEFG040101HDFRNN09"],
    )
    email: str = Field(..., examples=["al999999@edu.uaa.mx"])
    matricula: str = Field(..., min_length=3, max_length=20, examples=["ID999999"])
    id_campus: StrictInt = Field(
        default=1,
        ge=1,
        le=2,
        description="Shard Key del campus (solo numero entero: 1 = Central, 2 = Sur).",
    )
    carrera: str = Field(
        ...,
        min_length=3,
        pattern=r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s'-]+$",
        description="Carrera (solo letras y espacios, sin numeros).",
        examples=["Ingenieria en Sistemas Computacionales"],
    )
    semestre: StrictInt = Field(default=6, ge=1, le=15, description="Solo numeros enteros (1-15).")


class AlumnoResponse(BaseModel):
    """Representacion publica e institucional de un Alumno."""

    tipo_persona: str
    rol: str
    matricula: str
    nombre_completo: str
    curp_enmascarada: str
    email: str
    id_campus: int
    campus_nombre: str
    carrera: str
    semestre: int
    estatus_academico: str
    activo: bool


class MateriaCreateRequest(BaseModel):
    """Datos de entrada para dar de alta una Materia ofertada en un campus."""

    clave: str = Field(..., min_length=3, max_length=20, examples=["ISC-604"])
    nombre: str = Field(
        ...,
        min_length=3,
        max_length=120,
        pattern=r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s'-]+$",
        description="Nombre de la materia (solo letras y espacios, sin numeros).",
        examples=["Arquitectura de Software Distribuido"],
    )
    creditos: StrictInt = Field(..., ge=1, le=20, examples=[8])
    cupo_maximo: StrictInt = Field(..., ge=1, le=200, examples=[30])
    id_campus: StrictInt = Field(default=1, ge=1, le=2, description="Shard Key (1=Central, 2=Sur).")
    periodo_semestral: str = Field(default="2026-2", examples=["2026-2"])
    prerrequisitos: list[str] = Field(default_factory=list, examples=[[]])


class MateriaResponse(BaseModel):
    """Contrato de respuesta con los detalles y disponibilidad de una Materia."""

    clave: str
    nombre: str
    creditos: int
    id_campus: int
    campus_nombre: str
    periodo_semestral: str
    cupo_maximo: int
    cupo_actual: int
    lugares_disponibles: int
    tiene_cupo_disponible: bool
    prerrequisitos: list[str]


class InscripcionCreateRequest(BaseModel):
    """Solicitud para inscribir a un Alumno en una Materia."""

    folio: str = Field(..., min_length=3, max_length=30, examples=["INS-2026-001"])
    alumno_matricula: str = Field(..., min_length=3, examples=["ID345678"])
    materia_clave: str = Field(..., min_length=3, examples=["ISC-601"])
    periodo: str = Field(default="2026-2", examples=["2026-2"])


class InscripcionResponse(BaseModel):
    """Confirmacion estructurada de una Inscripcion procesada."""

    folio: str
    alumno_matricula: str
    alumno_nombre: str
    materia_clave: str
    materia_nombre: str
    id_campus: int
    periodo: str
    fecha_inscripcion: str
    estado: str
    cupo_restante: int | None = None


class EntregaTareaRequest(BaseModel):
    """Solicitud de carga de entrega de tarea con calculo de hash SHA-256."""

    id_entrega: str = Field(..., min_length=3, examples=["ENT-2026-001"])
    id_tarea: str = Field(..., min_length=3, examples=["TAR-001"])
    alumno_matricula: str = Field(..., min_length=3, examples=["ID345678"])
    archivo_url: str = Field(
        ...,
        min_length=5,
        examples=["https://storage.uaa.mx/entregas/practica01_sharding.pdf"],
    )
    contenido_texto: str = Field(
        default="contenido_sintetico_entrega_uaa",
        description="Contenido sintetico para calculo de hash SHA-256 de integridad.",
    )


class EntregaTareaResponse(BaseModel):
    """Respuesta con el hash SHA-256 y estado de puntualidad de la entrega."""

    id_entrega: str
    id_tarea: str
    alumno_matricula: str
    archivo_url: str
    fecha_entrega: str
    hash_sha256: str
    estado_entrega: str
    es_entrega_a_tiempo: bool


class PagoCreateRequest(BaseModel):
    """Solicitud de procesamiento de pago institucional simulado."""

    folio: str = Field(..., min_length=3, max_length=30, examples=["PAG-2026-001"])
    alumno_matricula: str = Field(..., min_length=3, examples=["ID345678"])
    monto: StrictFloat | StrictInt = Field(..., gt=0, examples=[2450.00])
    concepto: str = Field(..., min_length=3, examples=["Inscripcion Semestral"])
    referencia_bancaria: str = Field(
        default="REF-BBVA-UAA-001",
        examples=["REF-BBVA-UAA-001"],
    )
    id_campus: StrictInt = Field(default=1, ge=1, le=2)


class PagoResponse(BaseModel):
    """Respuesta del procesamiento de un Pago simulado."""

    folio: str
    alumno_matricula: str
    monto: float
    concepto: str
    estatus: str
    esta_aprobado: bool
    referencia_bancaria: str
    fecha_creacion: str
    motivo_rechazo: str | None = None
