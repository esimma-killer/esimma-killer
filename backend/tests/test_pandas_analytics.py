"""Pruebas unitarias para el proceso analitico de carga y limpieza con Pandas (Issue #17)."""

from pathlib import Path

import pandas as pd
import pytest
from src.domain.exceptions import RecursoNoEncontradoError, ValidacionDominioError
from src.services.pandas_analytics_service import PandasAnalyticsService


def test_limpieza_alumnos_normaliza_matriculas_duplicados_y_nulos() -> None:
    """Valida depuracion de matriculas corruptas, duplicados y valores nulos en alumnos."""
    df_sucio = pd.DataFrame(
        [
            {
                "matricula": "  id-300001 ",
                "nombre": "gael emiliano ",
                "apellidos": " nefarole lopez",
                "carrera": None,
                "semestre": None,
                "id_campus": 1,
                "estatus_academico": "activo",
            },
            {
                "matricula": "ID300001",
                "nombre": "Duplicado",
                "apellidos": "Ignorado",
                "carrera": "ISC",
                "semestre": 6,
                "id_campus": 1,
                "estatus_academico": "ACTIVO",
            },
            {
                "matricula": None,
                "nombre": "Sin Matricula",
                "apellidos": "Invalido",
                "carrera": "ISC",
                "semestre": 3,
                "id_campus": 2,
                "estatus_academico": "ACTIVO",
            },
            {
                "matricula": "id 300002",
                "nombre": "azael",
                "apellidos": "fajardo",
                "carrera": "",
                "semestre": 99,
                "id_campus": 999,
                "estatus_academico": None,
            },
        ]
    )

    servicio = PandasAnalyticsService()
    df_limpio, metricas = servicio.limpiar_dataframe_alumnos(df_sucio)

    assert metricas["filas_iniciales"] == 4
    assert metricas["nulos_matricula_descartados"] == 1
    assert metricas["duplicados_eliminados"] == 1
    assert metricas["filas_limpias"] == 2

    assert list(df_limpio["matricula"]) == ["ID300001", "ID300002"]
    assert df_limpio.loc[0, "nombre"] == "Gael Emiliano"
    assert df_limpio.loc[0, "carrera"] == "Ingenieria en Sistemas Computacionales"
    assert df_limpio.loc[0, "semestre"] == 1
    assert df_limpio.loc[1, "semestre"] == 15
    assert df_limpio.loc[1, "id_campus"] == 1


def test_limpieza_materias_y_entregas_con_valores_atipicos() -> None:
    """Valida saneamiento de claves de materia y correccion de outliers en calificaciones."""
    servicio = PandasAnalyticsService()

    df_materias_sucio = pd.DataFrame(
        [
            {"clave": " isc 601 ", "nombre": "BD Distribuidas", "creditos": -4, "id_campus": 1},
            {"clave": "ISC601", "nombre": "Duplicada", "creditos": 8, "id_campus": 1},
            {"clave": None, "nombre": "Sin Clave", "creditos": 8, "id_campus": 2},
            {"clave": "isc-602", "nombre": None, "creditos": None, "id_campus": 2},
        ]
    )
    df_mat_limpio, met_mat = servicio.limpiar_dataframe_materias(df_materias_sucio)
    assert met_mat["filas_limpias"] == 2
    assert met_mat["duplicados_eliminados"] == 1
    assert df_mat_limpio.loc[0, "creditos"] == 1
    assert df_mat_limpio.loc[1, "creditos"] == 8

    df_entregas_sucio = pd.DataFrame(
        [
            {
                "id_entrega": " ent-01 ",
                "alumno_matricula": " id-300001 ",
                "materia_clave": " isc-601 ",
                "calificacion": 9.0,
                "id_campus": 1,
                "estado_entrega": "a_tiempo",
            },
            {
                "id_entrega": "ENT-01",
                "alumno_matricula": "ID300001",
                "materia_clave": "ISC-601",
                "calificacion": 8.0,
                "id_campus": 1,
                "estado_entrega": "A_TIEMPO",
            },
            {
                "id_entrega": "ent-02",
                "alumno_matricula": "ID300002",
                "materia_clave": "ISC-602",
                "calificacion": 15.5,
                "id_campus": 2,
                "estado_entrega": "TARDIA",
            },
            {
                "id_entrega": "ent-03",
                "alumno_matricula": "ID300002",
                "materia_clave": "ISC-602",
                "calificacion": -3.0,
                "id_campus": 2,
                "estado_entrega": "ESTADO_CORRUPTO",
            },
            {
                "id_entrega": "ent-04",
                "alumno_matricula": "ID300001",
                "materia_clave": "ISC-601",
                "calificacion": None,
                "id_campus": 1,
                "estado_entrega": None,
            },
        ]
    )
    df_ent_limpio, met_ent = servicio.limpiar_dataframe_entregas(df_entregas_sucio)
    assert met_ent["filas_limpias"] == 4
    assert met_ent["duplicados_eliminados"] == 1
    assert met_ent["calificaciones_nulas_imputadas"] == 1
    assert met_ent["calificaciones_atipicas_ajustadas"] == 2
    assert df_ent_limpio["calificacion"].max() <= 10.0
    assert df_ent_limpio["calificacion"].min() >= 0.0


def test_lectura_escritura_y_proceso_analitico_completo(tmp_path: Path) -> None:
    """Verifica carga/escritura CSV/JSON con with open y las 5 etapas analiticas."""
    servicio = PandasAnalyticsService()

    df_al = pd.DataFrame(
        [
            {"matricula": "ID300001", "nombre": "Gael", "carrera": "ISC", "id_campus": 1},
            {"matricula": "ID300002", "nombre": "Azael", "carrera": "ISC", "id_campus": 2},
        ]
    )
    df_mat = pd.DataFrame(
        [
            {"clave": "ISC-601", "nombre": "BDD", "creditos": 8, "id_campus": 1},
            {"clave": "ISC-602", "nombre": "Flutter", "creditos": 8, "id_campus": 2},
        ]
    )
    df_ent = pd.DataFrame(
        [
            {
                "id_entrega": "ENT-1",
                "alumno_matricula": "ID300001",
                "materia_clave": "ISC-601",
                "calificacion": 9.5,
                "id_campus": 1,
                "estado_entrega": "A_TIEMPO",
            },
            {
                "id_entrega": "ENT-2",
                "alumno_matricula": "ID300002",
                "materia_clave": "ISC-602",
                "calificacion": 8.5,
                "id_campus": 2,
                "estado_entrega": "TARDIA",
            },
        ]
    )

    ruta_csv = servicio.guardar_csv(df_al, tmp_path / "alumnos_test.csv")
    df_cargado_csv = servicio.cargar_csv(ruta_csv)
    assert len(df_cargado_csv) == 2

    ruta_json = tmp_path / "materias_test.json"
    df_mat.to_json(ruta_json, orient="records")
    df_cargado_json = servicio.cargar_json(ruta_json)
    assert len(df_cargado_json) == 2

    reporte = servicio.ejecutar_proceso_analitico(df_cargado_csv, df_cargado_json, df_ent)
    diccionario = reporte.to_dict()

    assert "1_pregunta" in diccionario
    assert diccionario["4_calculo"]["promedio_calificacion_general"] == 9.0
    assert diccionario["4_calculo"]["tasa_puntualidad_entregas_pct"] == 50.0
    assert "9.0/10" in diccionario["5_conclusion"]

    with pytest.raises(RecursoNoEncontradoError):
        servicio.cargar_csv(tmp_path / "no_existe.csv")

    with pytest.raises(RecursoNoEncontradoError):
        servicio.cargar_json(tmp_path / "no_existe.json")

    with pytest.raises(ValidacionDominioError):
        servicio.limpiar_dataframe_alumnos(pd.DataFrame([{"sin_matricula": 1}]))
