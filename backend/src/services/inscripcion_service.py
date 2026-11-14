"""Servicio de gestion academica e inscripciones con manejo try-except-else-finally."""

from datetime import UTC, datetime, timedelta
from typing import Any

from src.domain.academico import Calificacion, Entrega, Inscripcion, Materia, Tarea
from src.domain.enums import CampusUAA, EstatusAcademico, RolSistema
from src.domain.exceptions import (
    DominioError,
    InscripcionInvalidaError,
    RecursoNoEncontradoError,
    ValidacionDominioError,
)
from src.domain.personas import Administrativo, Alumno, Profesor


class InscripcionService:
    """Coordina reglas de negocio para alumnos, materias, inscripciones, tareas y calificaciones."""

    def __init__(self, cargar_semilla: bool = True) -> None:
        self._alumnos: dict[str, Alumno] = {}
        self._materias: dict[str, Materia] = {}
        self._inscripciones: dict[str, Inscripcion] = {}
        self._calificaciones: list[Calificacion] = []
        self._tareas: dict[str, Tarea] = {}
        self._entregas: dict[str, Entrega] = {}
        self._profesores: dict[str, Profesor] = {}
        self._administrativos: dict[str, Administrativo] = {}
        self._logs_actividad: list[dict[str, Any]] = []
        self._operaciones_en_curso: set[str] = set()

        if cargar_semilla:
            self._inicializar_datos_sinteticos()

    def _inicializar_datos_sinteticos(self) -> None:
        """Carga datos sinteticos iniciales para Campus Central (1) y Campus Sur (2)."""
        alumno_central = Alumno(
            nombre="Gael Emiliano",
            apellidos="Nefarole Lopez",
            curp="NEFG040101HDFRNN01",
            email="al345678@edu.uaa.mx",
            matricula="ID345678",
            id_campus=CampusUAA.CENTRAL,
            carrera="Ingenieria en Sistemas Computacionales",
            semestre=6,
            estatus_academico=EstatusAcademico.ACTIVO,
        )
        alumno_sur = Alumno(
            nombre="Angel Azael",
            apellidos="Fajardo Espino",
            curp="FAEA040202HDFRNN02",
            email="al345679@edu.uaa.mx",
            matricula="ID345679",
            id_campus=CampusUAA.SUR,
            carrera="Ingenieria en Sistemas Computacionales",
            semestre=6,
            estatus_academico=EstatusAcademico.ACTIVO,
        )
        self._alumnos[alumno_central.matricula] = alumno_central
        self._alumnos[alumno_sur.matricula] = alumno_sur

        prof_central = Profesor(
            nombre="David",
            apellidos="Montoya",
            curp="MOND800101HDFRNN03",
            email="dr.davidmontoya.dcat@gmail.com",
            numero_empleado="DOC-1001",
            departamento="Sistemas de Informacion",
            cubiculo="Edificio 48 - Cubiculo 12",
            id_campus=CampusUAA.CENTRAL,
        )
        self._profesores[prof_central.numero_empleado] = prof_central

        admin_lider = Administrativo(
            nombre="Francisco Javier",
            apellidos="Sanchez Vallin",
            curp="SAVF040303HDFRNN04",
            email="francisco.sanchez@edu.uaa.mx",
            numero_empleado="ADM-2001",
            departamento="Coordinacion de Sistemas Computacionales",
            rol=RolSistema.COORDINADOR,
            id_campus=CampusUAA.CENTRAL,
        )
        self._administrativos[admin_lider.numero_empleado] = admin_lider

        materia_dist = Materia(
            clave="ISC-601",
            nombre="Bases de Datos Distribuidas",
            creditos=8,
            cupo_maximo=30,
            id_campus=CampusUAA.CENTRAL,
            periodo_semestral="2026-2",
        )
        materia_seg = Materia(
            clave="ISC-602",
            nombre="Seguridad en Sistemas de Computo",
            creditos=8,
            cupo_maximo=25,
            id_campus=CampusUAA.CENTRAL,
            periodo_semestral="2026-2",
            prerrequisitos=["ISC-501"],
        )
        materia_flutter = Materia(
            clave="ISC-603",
            nombre="Programacion Web y Multiplataforma",
            creditos=8,
            cupo_maximo=30,
            id_campus=CampusUAA.SUR,
            periodo_semestral="2026-2",
        )
        self._materias[materia_dist.clave] = materia_dist
        self._materias[materia_seg.clave] = materia_seg
        self._materias[materia_flutter.clave] = materia_flutter

        tarea_shard = Tarea(
            id_tarea="TAR-001",
            materia_clave="ISC-601",
            titulo="Practica 01: Fragmentacion Horizontal por id_campus",
            descripcion="Implementar particionamiento por campus en PostgreSQL.",
            fecha_limite=datetime.now(UTC) + timedelta(days=7),
            ponderacion=20.0,
        )
        self._tareas[tarea_shard.id_tarea] = tarea_shard

    @property
    def logs_actividad(self) -> list[dict[str, Any]]:
        """Devuelve la bitacora de eventos con formato de la coleccion logs_actividad (MongoDB)."""
        return list(self._logs_actividad)

    def registrar_alumno(self, alumno: Alumno) -> Alumno:
        """Registra un nuevo alumno validando unicidad de matricula."""
        if alumno.matricula in self._alumnos:
            raise ValidacionDominioError(
                mensaje=f"El alumno con matricula '{alumno.matricula}' ya se encuentra registrado.",
                campo="matricula",
            )
        self._alumnos[alumno.matricula] = alumno
        return alumno

    def obtener_alumno(self, matricula: str) -> Alumno:
        """Busca un alumno por su matricula o lanza RecursoNoEncontradoError."""
        clave = matricula.strip().upper()
        alumno = self._alumnos.get(clave)
        if not alumno:
            raise RecursoNoEncontradoError(recurso="Alumno", identificador=clave)
        return alumno

    def listar_alumnos(self, id_campus: int | None = None) -> list[Alumno]:
        """Lista los alumnos registrados, opcionalmente filtrados por Shard Key id_campus."""
        alumnos = list(self._alumnos.values())
        if id_campus is not None:
            return [a for a in alumnos if int(a.id_campus) == int(id_campus)]
        return alumnos

    def registrar_materia(self, materia: Materia) -> Materia:
        """Registra una nueva materia validando unicidad de clave."""
        if materia.clave in self._materias:
            raise ValidacionDominioError(
                mensaje=f"La materia con clave '{materia.clave}' ya existe.",
                campo="clave",
            )
        self._materias[materia.clave] = materia
        return materia

    def obtener_materia(self, clave: str) -> Materia:
        """Obtiene una materia por su clave o lanza RecursoNoEncontradoError."""
        codigo = clave.strip().upper()
        materia = self._materias.get(codigo)
        if not materia:
            raise RecursoNoEncontradoError(recurso="Materia", identificador=codigo)
        return materia

    def listar_materias(self, id_campus: int | None = None) -> list[Materia]:
        """Lista las materias ofertadas, opcionalmente filtradas por id_campus."""
        materias = list(self._materias.values())
        if id_campus is not None:
            return [m for m in materias if int(m.id_campus) == int(id_campus)]
        return materias

    def registrar_calificacion(self, calificacion: Calificacion) -> Calificacion:
        """Registra una calificacion previa o final de un alumno."""
        self.obtener_alumno(calificacion.alumno_matricula)
        self._calificaciones.append(calificacion)
        return calificacion

    def obtener_materias_aprobadas(self, alumno_matricula: str) -> set[str]:
        """Devuelve el conjunto de claves de materias aprobadas por un alumno."""
        mat = alumno_matricula.strip().upper()
        return {
            c.materia_clave
            for c in self._calificaciones
            if c.alumno_matricula == mat and c.esta_aprobada
        }

    def inscribir_alumno(
        self,
        folio: str,
        alumno_matricula: str,
        materia_clave: str,
        periodo: str = "2026-2",
        ip_origen: str = "127.0.0.1",
    ) -> dict[str, Any]:
        """Procesa una inscripcion usando la estructura completa try-except-else-finally."""
        llave_operacion = f"{alumno_matricula.strip().upper()}:{materia_clave.strip().upper()}"
        self._operaciones_en_curso.add(llave_operacion)
        resultado_auditoria = "ERROR"
        detalle_auditoria = "Operacion iniciada"
        campus_detectado = int(CampusUAA.CENTRAL)

        try:
            folio_limpio = folio.strip().upper()
            if not folio_limpio:
                raise ValidacionDominioError(
                    mensaje="El folio de inscripcion es obligatorio.",
                    campo="folio",
                )
            if folio_limpio in self._inscripciones:
                raise InscripcionInvalidaError(
                    mensaje=f"El folio de inscripcion '{folio_limpio}' ya fue utilizado.",
                    alumno_matricula=alumno_matricula,
                    materia_clave=materia_clave,
                    motivo="FOLIO_DUPLICADO",
                )

            alumno = self.obtener_alumno(alumno_matricula)
            campus_detectado = int(alumno.id_campus)
            materia = self.obtener_materia(materia_clave)

            if not alumno.puede_inscribirse():
                raise InscripcionInvalidaError(
                    mensaje=(
                        f"El alumno '{alumno.matricula}' no puede inscribirse debido a su "
                        f"estatus '{alumno.estatus_academico.value}'."
                    ),
                    alumno_matricula=alumno.matricula,
                    materia_clave=materia.clave,
                    motivo="ALUMNO_NO_ELEGIBLE",
                )

            if alumno.id_campus != materia.id_campus:
                raise InscripcionInvalidaError(
                    mensaje=(
                        f"Conflicto de Shard Key (id_campus): el alumno pertenece a "
                        f"{alumno.id_campus.name} ({int(alumno.id_campus)}) y la materia "
                        f"se imparte en {materia.id_campus.name} ({int(materia.id_campus)})."
                    ),
                    alumno_matricula=alumno.matricula,
                    materia_clave=materia.clave,
                    motivo="SHARD_CAMPUS_MISMATCH",
                )

            if not materia.tiene_cupo_disponible:
                raise InscripcionInvalidaError(
                    mensaje=f"La materia '{materia.clave}' no cuenta con cupo disponible.",
                    alumno_matricula=alumno.matricula,
                    materia_clave=materia.clave,
                    motivo="SIN_CUPO",
                )

            for ins_existente in self._inscripciones.values():
                if (
                    ins_existente.alumno.matricula == alumno.matricula
                    and ins_existente.materia.clave == materia.clave
                    and ins_existente.periodo == periodo
                ):
                    raise InscripcionInvalidaError(
                        mensaje=(
                            f"El alumno '{alumno.matricula}' ya esta inscrito en "
                            f"'{materia.clave}' para el periodo '{periodo}'."
                        ),
                        alumno_matricula=alumno.matricula,
                        materia_clave=materia.clave,
                        motivo="INSCRIPCION_DUPLICADA",
                    )

            if materia.prerrequisitos:
                aprobadas = self.obtener_materias_aprobadas(alumno.matricula)
                faltantes = [req for req in materia.prerrequisitos if req not in aprobadas]
                if faltantes:
                    raise InscripcionInvalidaError(
                        mensaje=(
                            f"El alumno '{alumno.matricula}' no ha acreditado los "
                            f"prerrequisitos de '{materia.clave}': {', '.join(faltantes)}."
                        ),
                        alumno_matricula=alumno.matricula,
                        materia_clave=materia.clave,
                        motivo="PRERREQUISITOS_NO_ACREDITADOS",
                        detalles={"prerrequisitos_faltantes": faltantes},
                    )

            nueva_inscripcion = Inscripcion(
                folio=folio_limpio,
                alumno=alumno,
                materia=materia,
                periodo=periodo,
            )

        except DominioError as exc:
            detalle_auditoria = f"{exc.codigo_error}: {exc.mensaje}"
            raise
        except (ValueError, TypeError) as exc:
            detalle_auditoria = f"Error de validacion en datos de inscripcion: {exc}"
            raise InscripcionInvalidaError(
                mensaje=str(exc),
                alumno_matricula=alumno_matricula,
                materia_clave=materia_clave,
                motivo="DATOS_INVALIDOS",
            ) from exc
        else:
            materia.incrementar_cupo()
            nueva_inscripcion.confirmar()
            self._inscripciones[nueva_inscripcion.folio] = nueva_inscripcion
            resultado_auditoria = "EXITO"
            detalle_auditoria = (
                f"Inscripcion confirmada con folio {nueva_inscripcion.folio} en {materia.clave}."
            )
            resumen = nueva_inscripcion.to_dict()
            resumen["cupo_restante"] = materia.lugares_disponibles
            return resumen
        finally:
            self._operaciones_en_curso.discard(llave_operacion)
            self._logs_actividad.append(
                {
                    "id_usuario": alumno_matricula.strip().upper(),
                    "rol": RolSistema.ESTUDIANTE.value,
                    "campus": campus_detectado,
                    "accion": "inscripcion_materia",
                    "ip_origen": ip_origen,
                    "timestamp": datetime.now(UTC).isoformat(),
                    "resultado": resultado_auditoria,
                    "detalle": detalle_auditoria,
                }
            )

    def registrar_entrega_tarea(
        self,
        id_entrega: str,
        id_tarea: str,
        alumno_matricula: str,
        archivo_url: str,
        contenido_texto: str = "entrega_sintetica_uaa",
    ) -> dict[str, Any]:
        """Registra la entrega de una tarea calculando su hash SHA-256 y puntualidad."""
        alumno = self.obtener_alumno(alumno_matricula)
        codigo_tarea = id_tarea.strip().upper()
        tarea = self._tareas.get(codigo_tarea)
        if not tarea:
            raise RecursoNoEncontradoError(recurso="Tarea", identificador=codigo_tarea)

        entrega = Entrega(
            id_entrega=id_entrega,
            tarea=tarea,
            alumno_matricula=alumno.matricula,
            archivo_url=archivo_url,
            contenido_bytes=contenido_texto.encode("utf-8"),
        )
        self._entregas[entrega.id_entrega] = entrega
        self._logs_actividad.append(
            {
                "id_usuario": alumno.matricula,
                "rol": RolSistema.ESTUDIANTE.value,
                "campus": int(alumno.id_campus),
                "accion": "subir_entrega_tarea",
                "ip_origen": "127.0.0.1",
                "timestamp": datetime.now(UTC).isoformat(),
                "resultado": "EXITO",
                "detalle": f"Entrega {entrega.id_entrega} ({entrega.estado_entrega.value})",
            }
        )
        return entrega.to_dict()

    def listar_inscripciones(self) -> list[dict[str, Any]]:
        """Devuelve todas las inscripciones confirmadas o registradas."""
        return [ins.to_dict() for ins in self._inscripciones.values()]
