"""Generador determinista de datos sinteticos masivos (~100,000 registros) por campus."""

import argparse
import csv
import hashlib
import json
import random
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from src.domain.enums import (
    CampusUAA,
    EstadoEntrega,
    EstadoInscripcion,
    EstatusAcademico,
    EstatusPago,
)

NOMBRES_SINTETICOS: tuple[str, ...] = (
    "Gael",
    "Francisco",
    "Azael",
    "Lucia",
    "Mariana",
    "Diego",
    "Valeria",
    "Alejandro",
    "Sofia",
    "Daniel",
    "Camila",
    "Mateo",
    "Fernanda",
    "Sebastian",
    "Ximena",
    "Emiliano",
    "Regina",
    "Santiago",
    "carolina",
    "Leonardo",
)

APELLIDOS_SINTETICOS: tuple[str, ...] = (
    "Nefarole",
    "Sanchez",
    "Fajardo",
    "Vallin",
    "Lopez",
    "Espino",
    "Montoya",
    "Salazar",
    "Cardona",
    "Hernandez",
    "Garcia",
    "Martinez",
    "Gonzalez",
    "Rodriguez",
    "Perez",
    "Ramirez",
    "Torres",
    "Flores",
    "Rivera",
    "Gomez",
)

CARRERAS_UAA: tuple[str, ...] = (
    "Ingenieria en Sistemas Computacionales",
    "Ingenieria en Computacion Inteligente",
    "Licenciatura en Informatica y Tecnologias Computacionales",
    "Ingenieria Industrial Estadistica",
    "Matematicas Aplicadas",
)

DEPARTAMENTOS_UAA: tuple[str, ...] = (
    "Sistemas de Informacion",
    "Ciencias de la Computacion",
    "Redes y Telecomunicaciones",
    "Ingenieria de Software",
    "Matematicas y Fisica",
)

CONCEPTOS_PAGO: tuple[str, ...] = (
    "Colegiatura Mensual",
    "Inscripcion Semestral 2026-2",
    "Reinscripcion Ordinaria",
    "Derecho a Examen Extraordinario",
    "Seguro Facultativo Estudiantil",
)


@dataclass(frozen=True)
class DatasetSinteticoResumen:
    """Metricas de volumen, balance por campus y rendimiento del dataset generado."""

    total_registros: int
    total_profesores: int
    total_materias: int
    total_alumnos: int
    total_inscripciones: int
    total_entregas: int
    total_pagos: int
    registros_campus_central: int
    registros_campus_sur: int
    tiempo_segundos: float

    def to_dict(self) -> dict[str, Any]:
        """Serializa el resumen estadistico del generador."""
        return {
            "total_registros": self.total_registros,
            "desglose_entidades": {
                "profesores": self.total_profesores,
                "materias": self.total_materias,
                "alumnos": self.total_alumnos,
                "inscripciones": self.total_inscripciones,
                "entregas": self.total_entregas,
                "pagos": self.total_pagos,
            },
            "balance_por_campus": {
                "campus_central_id_1": self.registros_campus_central,
                "campus_sur_id_2": self.registros_campus_sur,
            },
            "tiempo_ejecucion_segundos": round(self.tiempo_segundos, 4),
        }


class SyntheticDataGenerator:
    """Genera lotes masivos (~100,000 registros) con integridad referencial por Shard Key."""

    def __init__(self, seed: int = 42) -> None:
        self._seed = int(seed)
        self._rng = random.Random(self._seed)  # nosec B311

    @staticmethod
    def _construir_curp_sintetica(nombre: str, paterno: str, materno: str, indice: int) -> str:
        """Construye una CURP sintetica anonimizada de 18 caracteres alfanumericos."""
        prefijo = (
            f"{paterno[:2].upper():<2}{materno[:1].upper():<1}{nombre[:1].upper():<1}"
        ).replace(" ", "X")
        anio = 2000 + (indice % 8)
        mes = 1 + (indice % 12)
        dia = 1 + (indice % 28)
        fecha = f"{anio % 100:02d}{mes:02d}{dia:02d}"
        sexo = "H" if indice % 2 == 0 else "M"
        entidad = "AS"
        consonantes = "BCDFGHJKLMNPQRSTVWXYZ"
        c1 = consonantes[indice % len(consonantes)]
        c2 = consonantes[(indice // 3) % len(consonantes)]
        c3 = consonantes[(indice // 7) % len(consonantes)]
        homoclave = f"{indice % 100:02d}"
        curp = f"{prefijo}{fecha}{sexo}{entidad}{c1}{c2}{c3}{homoclave}"
        return curp[:18]

    def generar_dataset(
        self,
        num_profesores: int = 500,
        num_materias: int = 200,
        num_alumnos: int = 15000,
        num_inscripciones: int = 45000,
        num_entregas: int = 20000,
        num_pagos: int = 20000,
    ) -> tuple[dict[str, list[dict[str, Any]]], DatasetSinteticoResumen]:
        """Genera las 6 colecciones relacionales coherentes (~100,700 registros por defecto)."""
        inicio = time.perf_counter()
        self._rng.seed(self._seed)

        profesores: list[dict[str, Any]] = []
        materias: list[dict[str, Any]] = []
        alumnos: list[dict[str, Any]] = []
        inscripciones: list[dict[str, Any]] = []
        entregas: list[dict[str, Any]] = []
        pagos: list[dict[str, Any]] = []

        conteo_central = 0
        conteo_sur = 0

        # 1. Generar Profesores balanceados entre Campus Central (1) y Campus Sur (2)
        for i in range(1, num_profesores + 1):
            id_campus = int(CampusUAA.CENTRAL if i % 2 == 1 else CampusUAA.SUR)
            nombre = NOMBRES_SINTETICOS[i % len(NOMBRES_SINTETICOS)].title()
            paterno = APELLIDOS_SINTETICOS[i % len(APELLIDOS_SINTETICOS)]
            materno = APELLIDOS_SINTETICOS[(i + 5) % len(APELLIDOS_SINTETICOS)]
            depto = DEPARTAMENTOS_UAA[i % len(DEPARTAMENTOS_UAA)]
            profesores.append(
                {
                    "numero_empleado": f"DOC-{i:05d}",
                    "nombre": nombre,
                    "apellidos": f"{paterno} {materno}",
                    "curp": self._construir_curp_sintetica(nombre, paterno, materno, i),
                    "email": f"docente{i:05d}@edu.uaa.mx",
                    "departamento": depto,
                    "cubiculo": f"Edificio {40 + (i % 15)} - Cubiculo {(i % 20) + 1}",
                    "id_campus": id_campus,
                    "rfc_cifrado": f"ENC_RFC_DOC_{i:05d}",
                    "salario_base": round(22000.0 + ((i % 15) * 1250.0), 2),
                }
            )
            if id_campus == 1:
                conteo_central += 1
            else:
                conteo_sur += 1

        # 2. Generar Materias separadas por campus
        materias_por_campus: dict[int, list[dict[str, Any]]] = {1: [], 2: []}
        for i in range(1, num_materias + 1):
            id_campus = int(CampusUAA.CENTRAL if i % 2 == 1 else CampusUAA.SUR)
            depto = DEPARTAMENTOS_UAA[i % len(DEPARTAMENTOS_UAA)]
            prof_campus = profesores[(i - 1) % len(profesores)]
            materia = {
                "clave": f"ISC-{100 + i:04d}",
                "nombre": f"Asignatura {depto} Nivel {((i - 1) % 9) + 1}",
                "creditos": 6 + ((i % 3) * 2),
                "cupo_maximo": 40,
                "cupo_actual": 0,
                "id_campus": id_campus,
                "periodo_semestral": "2026-2",
                "departamento": depto,
                "docente_empleado": prof_campus["numero_empleado"],
            }
            materias.append(materia)
            materias_por_campus[id_campus].append(materia)
            if id_campus == 1:
                conteo_central += 1
            else:
                conteo_sur += 1

        # 3. Generar Alumnos balanceados por campus
        alumnos_por_campus: dict[int, list[dict[str, Any]]] = {1: [], 2: []}
        for i in range(1, num_alumnos + 1):
            id_campus = int(CampusUAA.CENTRAL if i % 2 == 1 else CampusUAA.SUR)
            nombre = NOMBRES_SINTETICOS[i % len(NOMBRES_SINTETICOS)].title()
            paterno = APELLIDOS_SINTETICOS[(i * 3) % len(APELLIDOS_SINTETICOS)]
            materno = APELLIDOS_SINTETICOS[(i * 7 + 2) % len(APELLIDOS_SINTETICOS)]
            alumno = {
                "matricula": f"ID{300000 + i:06d}",
                "nombre": nombre,
                "apellidos": f"{paterno} {materno}",
                "curp": self._construir_curp_sintetica(nombre, paterno, materno, i + 1000),
                "email": f"al{300000 + i:06d}@edu.uaa.mx",
                "id_campus": id_campus,
                "carrera": CARRERAS_UAA[i % len(CARRERAS_UAA)],
                "semestre": (i % 9) + 1,
                "estatus_academico": EstatusAcademico.ACTIVO.value,
            }
            alumnos.append(alumno)
            alumnos_por_campus[id_campus].append(alumno)
            if id_campus == 1:
                conteo_central += 1
            else:
                conteo_sur += 1

        # 4. Generar Inscripciones respetando estrictamente la Shard Key id_campus
        total_al_c1 = len(alumnos_por_campus[1])
        total_al_c2 = len(alumnos_por_campus[2])
        total_mat_c1 = len(materias_por_campus[1])
        total_mat_c2 = len(materias_por_campus[2])

        for i in range(1, num_inscripciones + 1):
            id_campus = 1 if i % 2 == 1 else 2
            if id_campus == 1:
                al = alumnos_por_campus[1][(i // 2) % total_al_c1]
                mat = materias_por_campus[1][((i // 2) * 3 + (i % 7)) % total_mat_c1]
                conteo_central += 1
            else:
                al = alumnos_por_campus[2][(i // 2) % total_al_c2]
                mat = materias_por_campus[2][((i // 2) * 3 + (i % 7)) % total_mat_c2]
                conteo_sur += 1

            dia = 1 + (i % 28)
            hora = 8 + (i % 12)
            minuto = i % 60
            inscripciones.append(
                {
                    "folio": f"INS-2026-{i:06d}",
                    "alumno_matricula": al["matricula"],
                    "materia_clave": mat["clave"],
                    "id_campus": id_campus,
                    "periodo": "2026-2",
                    "fecha_inscripcion": f"2026-08-{dia:02d}T{hora:02d}:{minuto:02d}:00+00:00",
                    "estado": EstadoInscripcion.CONFIRMADA.value,
                }
            )

        # 5. Generar Entregas y Calificaciones vinculadas a inscripciones existentes
        total_ins = len(inscripciones)
        hashes_precalculados = [
            hashlib.sha256(f"entrega_sintetica_uaa_lote_{k}".encode()).hexdigest()
            for k in range(256)
        ]
        for i in range(1, num_entregas + 1):
            ins = inscripciones[(i - 1) % total_ins]
            id_campus = ins["id_campus"]
            es_tardia = (i % 5) == 0  # 80% a tiempo, 20% tardias
            estado_ent = EstadoEntrega.TARDIA.value if es_tardia else EstadoEntrega.A_TIEMPO.value
            hora_entrega = 23 if es_tardia else (10 + (i % 12))
            minuto_entrega = i % 60
            calificacion = round(6.0 + ((i * 7) % 41) / 10.0, 2)
            entregas.append(
                {
                    "id_entrega": f"ENT-2026-{i:06d}",
                    "id_tarea": f"TAR-{(i % 500) + 1:04d}",
                    "materia_clave": ins["materia_clave"],
                    "alumno_matricula": ins["alumno_matricula"],
                    "id_campus": id_campus,
                    "fecha_limite": "2026-11-15T23:59:00+00:00",
                    "fecha_entrega": (
                        f"2026-11-{15 if not es_tardia else 16:02d}"
                        f"T{hora_entrega:02d}:{minuto_entrega:02d}:00+00:00"
                    ),
                    "estado_entrega": estado_ent,
                    "ponderacion": 20.0,
                    "calificacion": calificacion,
                    "hash_sha256": hashes_precalculados[i % 256],
                }
            )
            if id_campus == 1:
                conteo_central += 1
            else:
                conteo_sur += 1

        # 6. Generar Pagos simulados vinculados a alumnos existentes
        total_al = len(alumnos)
        for i in range(1, num_pagos + 1):
            al = alumnos[(i - 1) % total_al]
            id_campus = al["id_campus"]
            estatus_pago = (
                EstatusPago.RECHAZADO.value if (i % 20 == 0) else EstatusPago.APROBADO.value
            )
            pagos.append(
                {
                    "folio": f"PAG-2026-{i:06d}",
                    "alumno_matricula": al["matricula"],
                    "id_campus": id_campus,
                    "monto": round(1250.0 + ((i % 10) * 250.0), 2),
                    "concepto": CONCEPTOS_PAGO[i % len(CONCEPTOS_PAGO)],
                    "estatus": estatus_pago,
                    "referencia_bancaria": f"REF-UAA-{id_campus}-{i:06d}",
                    "fecha_creacion": f"2026-09-{(i % 28) + 1:02d}T12:00:00+00:00",
                }
            )
            if id_campus == 1:
                conteo_central += 1
            else:
                conteo_sur += 1

        duracion = time.perf_counter() - inicio
        dataset = {
            "profesores": profesores,
            "materias": materias,
            "alumnos": alumnos,
            "inscripciones": inscripciones,
            "entregas": entregas,
            "pagos": pagos,
        }
        resumen = DatasetSinteticoResumen(
            total_registros=(
                len(profesores)
                + len(materias)
                + len(alumnos)
                + len(inscripciones)
                + len(entregas)
                + len(pagos)
            ),
            total_profesores=len(profesores),
            total_materias=len(materias),
            total_alumnos=len(alumnos),
            total_inscripciones=len(inscripciones),
            total_entregas=len(entregas),
            total_pagos=len(pagos),
            registros_campus_central=conteo_central,
            registros_campus_sur=conteo_sur,
            tiempo_segundos=duracion,
        )
        return dataset, resumen

    def exportar_csv(
        self,
        dataset: dict[str, list[dict[str, Any]]],
        directorio_salida: str | Path,
    ) -> dict[str, Path]:
        """Exporta cada coleccion del dataset a archivos CSV usando bloques with."""
        base_dir = Path(directorio_salida)
        base_dir.mkdir(parents=True, exist_ok=True)
        archivos_generados: dict[str, Path] = {}

        for nombre_entidad, registros in dataset.items():
            if not registros:
                continue
            ruta_csv = base_dir / f"{nombre_entidad}.csv"
            columnas = list(registros[0].keys())
            with open(ruta_csv, mode="w", encoding="utf-8", newline="") as archivo_csv:
                writer = csv.DictWriter(archivo_csv, fieldnames=columnas)
                writer.writeheader()
                writer.writerows(registros)
            archivos_generados[nombre_entidad] = ruta_csv

        return archivos_generados

    def exportar_json(
        self,
        dataset: dict[str, list[dict[str, Any]]],
        resumen: DatasetSinteticoResumen,
        directorio_salida: str | Path,
    ) -> Path:
        """Exporta el resumen y las entidades a archivos JSON con administradores de contexto."""
        base_dir = Path(directorio_salida)
        base_dir.mkdir(parents=True, exist_ok=True)

        ruta_resumen = base_dir / "resumen_dataset.json"
        with open(ruta_resumen, mode="w", encoding="utf-8") as archivo_resumen:
            json.dump(resumen.to_dict(), archivo_resumen, indent=2)

        for nombre_entidad, registros in dataset.items():
            ruta_entidad = base_dir / f"{nombre_entidad}.json"
            with open(ruta_entidad, mode="w", encoding="utf-8") as archivo_json:
                json.dump(registros, archivo_json)

        return ruta_resumen

    def exportar_sql(
        self,
        dataset: dict[str, list[dict[str, Any]]],
        ruta_archivo_sql: str | Path,
        limite_por_tabla: int | None = None,
    ) -> Path:
        """Genera sentencias SQL INSERT para sembrado en PostgreSQL particionado por id_campus."""
        ruta_sql = Path(ruta_archivo_sql)
        ruta_sql.parent.mkdir(parents=True, exist_ok=True)

        with open(ruta_sql, mode="w", encoding="utf-8") as archivo_sql:
            archivo_sql.write(
                "-- =====================================================================\n"
                "-- Script de Sembrado Sintetico (Seeding) — E-SIIMA Killer (E-SIIMA 3)\n"
                "-- Fragmentacion Horizontal por Shard Key: id_campus (1=Central, 2=Sur)\n"
                "-- =====================================================================\n\n"
                "BEGIN;\n\n"
            )

            for tabla, registros in dataset.items():
                lote = registros[:limite_por_tabla] if limite_por_tabla else registros
                if not lote:
                    continue
                columnas = ", ".join(lote[0].keys())
                archivo_sql.write(f"-- Sembrado de tabla: {tabla} ({len(lote)} registros)\n")
                for fila in lote:
                    valores_formateados: list[str] = []
                    for valor in fila.values():
                        if isinstance(valor, (int, float)):
                            valores_formateados.append(str(valor))
                        else:
                            texto = str(valor).replace("'", "''")
                            valores_formateados.append(f"'{texto}'")
                    valores_sql = ", ".join(valores_formateados)
                    sentencia = f"INSERT INTO {tabla} ({columnas}) VALUES ({valores_sql});\n"  # nosec B608
                    archivo_sql.write(sentencia)
                archivo_sql.write("\n")

            archivo_sql.write("COMMIT;\n")

        return ruta_sql


def main() -> None:
    """Punto de entrada CLI para generar y exportar los ~100,000 registros sinteticos."""
    parser = argparse.ArgumentParser(
        description="Generador de datos sinteticos masivos para E-SIIMA Killer (UAA)."
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="data/synthetic",
        help="Directorio de salida para archivos CSV, JSON y SQL.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Semilla pseudoaleatoria determinista.",
    )
    args = parser.parse_args()

    generador = SyntheticDataGenerator(seed=args.seed)
    dataset, resumen = generador.generar_dataset()
    out_dir = Path(args.output_dir)
    generador.exportar_csv(dataset, out_dir)
    generador.exportar_json(dataset, resumen, out_dir)
    generador.exportar_sql(dataset, out_dir / "seed_campus.sql")

    print(json.dumps(resumen.to_dict(), indent=2))


if __name__ == "__main__":
    main()
