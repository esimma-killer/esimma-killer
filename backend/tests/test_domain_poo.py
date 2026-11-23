"""Pruebas unitarias para el modelo POO: encapsulamiento, herencia, polimorfismo y SOLID."""

from datetime import UTC, datetime, timedelta

import pytest
from src.domain import (
    Administrativo,
    Alumno,
    Calificacion,
    CampusUAA,
    Entrega,
    EstadoEntrega,
    EstadoInscripcion,
    EstatusAcademico,
    EstatusPago,
    Inscripcion,
    Materia,
    Pago,
    Persona,
    Profesor,
    RolSistema,
    Tarea,
)


def test_persona_es_clase_abstracta() -> None:
    """Verifica que Persona no pueda ser instanciada directamente (Abstraccion)."""
    with pytest.raises(TypeError):
        Persona(  # type: ignore[abstract]
            nombre="Test",
            apellidos="Abstracto",
            curp="TEST040101HDFRNN01",
            email="test@edu.uaa.mx",
        )


def test_encapsulamiento_y_enmascaramiento_pii_en_alumno(alumno_central: Alumno) -> None:
    """Valida properties, setters y enmascaramiento LFPDPPP de la CURP."""
    assert alumno_central.nombre == "Gael Emiliano"
    assert alumno_central.apellidos == "Nefarole Lopez"
    assert alumno_central.nombre_completo == "Gael Emiliano Nefarole Lopez"
    assert alumno_central.curp_enmascarada == "NEFG************01"
    assert len(alumno_central.curp_enmascarada) == 18
    assert alumno_central.id_campus == CampusUAA.CENTRAL
    assert alumno_central.puede_inscribirse() is True

    alumno_central.estatus_academico = EstatusAcademico.BAJA_TEMPORAL
    assert alumno_central.puede_inscribirse() is False


def test_validaciones_encapsuladas_en_setters_de_persona_y_alumno(
    alumno_central: Alumno,
) -> None:
    """Comprueba que los setters rechacen valores invalidos."""
    with pytest.raises(ValueError, match="nombre"):
        alumno_central.nombre = "   "

    with pytest.raises(ValueError, match="apellidos"):
        alumno_central.apellidos = ""

    with pytest.raises(ValueError, match="CURP"):
        alumno_central.curp = "CURP_CORTA"

    with pytest.raises(ValueError, match="correo"):
        alumno_central.email = "correo_sin_arroba"

    with pytest.raises(ValueError, match="matricula"):
        alumno_central.matricula = " "

    with pytest.raises(ValueError, match="carrera"):
        alumno_central.carrera = ""

    with pytest.raises(ValueError, match="semestre"):
        alumno_central.semestre = 0


def test_rechazo_estricto_de_numeros_en_campos_de_letras_y_viceversa(
    alumno_central: Alumno,
    administrativo_coordinador: Administrativo,
    profesor_central: Profesor,
    materia_central: Materia,
    pago_pendiente: Pago,
) -> None:
    """Verifica que campos de letras rechacen numeros y campos numericos rechacen letras."""
    # 1. Campos de texto que NO deben aceptar numeros
    with pytest.raises(ValueError, match="solo acepta letras"):
        alumno_central.nombre = "Gael123"

    with pytest.raises(ValueError, match="solo acepta letras"):
        alumno_central.apellidos = "Nefarole99"

    with pytest.raises(ValueError, match="solo acepta letras"):
        alumno_central.carrera = "Ingenieria 123"

    with pytest.raises(ValueError, match="solo acepta letras"):
        administrativo_coordinador.departamento = "Control 404"

    with pytest.raises(ValueError, match="solo acepta letras"):
        profesor_central.departamento = "Sistemas 2026"

    with pytest.raises(ValueError, match="solo acepta letras"):
        materia_central.nombre = "Calculo 101"

    with pytest.raises(ValueError, match="debe contener letras"):
        pago_pendiente.concepto = "123456"

    # 2. Campos numericos que NO deben aceptar letras ni booleanos
    with pytest.raises(ValueError, match="solo acepta numeros"):
        alumno_central.semestre = "sexto"  # type: ignore[assignment]

    with pytest.raises(ValueError, match="solo acepta numeros"):
        alumno_central.id_campus = "central"  # type: ignore[assignment]

    with pytest.raises(ValueError, match="solo acepta numeros"):
        profesor_central.salario_base = "treinta mil"  # type: ignore[assignment]

    with pytest.raises(ValueError, match="solo aceptan numeros"):
        materia_central.creditos = "ocho"  # type: ignore[assignment]

    with pytest.raises(ValueError, match="solo acepta numeros"):
        materia_central.cupo_maximo = "treinta"  # type: ignore[assignment]

    with pytest.raises(ValueError, match="solo acepta valores numericos"):
        Calificacion("ID345678", "ISC-601", "2026-2", "diez")  # type: ignore[arg-type]

    with pytest.raises(ValueError, match="solo acepta numeros"):
        pago_pendiente.monto = "mil quinientos"  # type: ignore[assignment]


def test_herencia_y_polimorfismo_entre_subclases_de_persona(
    alumno_central: Alumno,
    administrativo_coordinador: Administrativo,
    profesor_central: Profesor,
) -> None:
    """Demuestra comportamiento polimorfico sobre una coleccion heterogenea list[Persona]."""
    comunidad: list[Persona] = [
        alumno_central,
        administrativo_coordinador,
        profesor_central,
    ]

    roles = [persona.obtener_rol() for persona in comunidad]
    assert roles == [
        RolSistema.ESTUDIANTE,
        RolSistema.COORDINADOR,
        RolSistema.PROFESOR,
    ]

    perfiles = [persona.obtener_perfil_institucional() for persona in comunidad]
    assert perfiles[0]["tipo_persona"] == "Alumno"
    assert perfiles[1]["tipo_persona"] == "Administrativo"
    assert perfiles[2]["tipo_persona"] == "Profesor"

    permisos_coord = administrativo_coordinador.obtener_permisos()
    assert "analitica:consultar_reportes_mongodb" in permisos_coord
    assert "entregas:subir" in alumno_central.obtener_permisos()
    assert "calificaciones:registrar" in profesor_central.obtener_permisos()


def test_fragmentacion_vertical_en_profesor_oculta_datos_sensibles(
    profesor_central: Profesor,
) -> None:
    """Verifica que obtener_perfil_publico no exponga RFC ni salario base (Triada CIA)."""
    perfil_publico = profesor_central.obtener_perfil_publico()
    assert perfil_publico["numero_empleado"] == "DOC-1001"
    assert "rfc_cifrado" not in perfil_publico
    assert "salario_base" not in perfil_publico
    assert profesor_central.salario_base == 32000.0
    assert profesor_central.rfc_cifrado == "ENC_RFC_MOND800101"

    with pytest.raises(ValueError, match="salario"):
        profesor_central.salario_base = -100.0


def test_validaciones_administrativo(administrativo_coordinador: Administrativo) -> None:
    """Verifica validaciones de rol y atributos en Administrativo."""
    with pytest.raises(ValueError, match="rol"):
        administrativo_coordinador.rol = RolSistema.ESTUDIANTE

    with pytest.raises(ValueError, match="numero de empleado"):
        administrativo_coordinador.numero_empleado = ""

    with pytest.raises(ValueError, match="departamento"):
        administrativo_coordinador.departamento = ""


def test_materia_control_de_cupo_y_serializacion(materia_central: Materia) -> None:
    """Valida incremento, agotamiento y liberacion de cupo en Materia."""
    assert materia_central.tiene_cupo_disponible is True
    assert materia_central.lugares_disponibles == 2

    materia_central.incrementar_cupo()
    materia_central.incrementar_cupo()
    assert materia_central.tiene_cupo_disponible is False
    assert materia_central.lugares_disponibles == 0

    with pytest.raises(ValueError, match="cupo maximo"):
        materia_central.incrementar_cupo()

    materia_central.liberar_cupo()
    assert materia_central.tiene_cupo_disponible is True
    assert materia_central.to_dict()["cupo_actual"] == 1


def test_inscripcion_ciclo_de_vida(
    alumno_central: Alumno,
    materia_central: Materia,
) -> None:
    """Verifica transiciones de estado en la entidad Inscripcion."""
    inscripcion = Inscripcion(
        folio="INS-001",
        alumno=alumno_central,
        materia=materia_central,
    )
    assert inscripcion.estado == EstadoInscripcion.PENDIENTE
    inscripcion.confirmar()
    assert inscripcion.estado == EstadoInscripcion.CONFIRMADA

    inscripcion.cancelar()
    assert inscripcion.estado == EstadoInscripcion.CANCELADA

    with pytest.raises(ValueError, match="cancelada"):
        inscripcion.confirmar()


def test_calificacion_escala_y_aprobacion() -> None:
    """Comprueba el calculo de aprobacion y limites 0.0 - 10.0 en Calificacion."""
    aprobada = Calificacion("ID345678", "ISC-601", "2026-2", 9.456, "Buen trabajo")
    assert aprobada.valor_ponderado == 9.46
    assert aprobada.esta_aprobada is True
    assert aprobada.to_dict()["esta_aprobada"] is True

    reprobada = Calificacion("ID345678", "ISC-601", "2026-2", 5.9)
    assert reprobada.esta_aprobada is False

    with pytest.raises(ValueError, match="escala"):
        Calificacion("ID345678", "ISC-601", "2026-2", 10.5)


def test_tarea_y_entrega_con_hash_sha256_y_puntualidad(tarea_vigente: Tarea) -> None:
    """Verifica hash SHA-256 e identificacion de entrega A_TIEMPO vs TARDIA."""
    entrega_puntual = Entrega(
        id_entrega="ENT-01",
        tarea=tarea_vigente,
        alumno_matricula="ID345678",
        archivo_url="https://uaa.mx/practica1.pdf",
        contenido_bytes=b"select * from alumnos where id_campus = 1;",
    )
    assert entrega_puntual.es_entrega_a_tiempo is True
    assert entrega_puntual.estado_entrega == EstadoEntrega.A_TIEMPO
    assert len(entrega_puntual.hash_sha256) == 64

    fecha_tardia = tarea_vigente.fecha_limite + timedelta(hours=2)
    entrega_tardia = Entrega(
        id_entrega="ENT-02",
        tarea=tarea_vigente,
        alumno_matricula="ID345678",
        archivo_url="https://uaa.mx/practica1_tarde.pdf",
        fecha_entrega=fecha_tardia,
    )
    assert entrega_tardia.es_entrega_a_tiempo is False
    assert entrega_tardia.estado_entrega == EstadoEntrega.TARDIA
    assert entrega_tardia.to_dict()["estado_entrega"] == "TARDIA"
    assert isinstance(datetime.now(UTC), datetime)


def test_pago_transiciones_y_validaciones(pago_pendiente: Pago) -> None:
    """Comprueba aprobacion, rechazo y validacion de montos en Pago."""
    assert pago_pendiente.esta_aprobado is False
    pago_pendiente.aprobar()
    assert pago_pendiente.esta_aprobado is True
    assert pago_pendiente.estatus == EstatusPago.APROBADO

    pago_rechazado = Pago("PAG-501", "ID345678", 500.0, "Examen Extraordinario")
    pago_rechazado.rechazar("Fondos insuficientes")
    assert pago_rechazado.estatus == EstatusPago.RECHAZADO
    assert pago_rechazado.motivo_rechazo == "Fondos insuficientes"

    with pytest.raises(ValueError, match="previamente rechazado"):
        pago_rechazado.aprobar()

    with pytest.raises(ValueError, match="mayor a 0.0"):
        Pago("PAG-502", "ID345678", 0.0, "Concepto")
