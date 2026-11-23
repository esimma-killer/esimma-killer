"""Servicio analitico con Pandas: lectura, limpieza, transformacion y estadistica descriptiva."""

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pandas as pd

from src.domain.exceptions import RecursoNoEncontradoError, ValidacionDominioError


@dataclass(frozen=True)
class ReporteAnaliticoPandas:
    """Estructura formal del proceso analitico: Pregunta, Datos, Limpieza, Calculo y Conclusion."""

    pregunta: str
    datos_entrada: dict[str, int]
    metricas_limpieza: dict[str, int]
    calculos_descriptivos: dict[str, Any]
    conclusion: str

    def to_dict(self) -> dict[str, Any]:
        """Convierte el reporte analitico en un diccionario serializable a JSON."""
        return {
            "1_pregunta": self.pregunta,
            "2_datos": self.datos_entrada,
            "3_limpieza": self.metricas_limpieza,
            "4_calculo": self.calculos_descriptivos,
            "5_conclusion": self.conclusion,
        }


class PandasAnalyticsService:
    """Ejecuta pipelines de lectura con context managers (with), depuracion y analisis en Pandas."""

    @staticmethod
    def cargar_csv(ruta_archivo: str | Path) -> pd.DataFrame:
        """Lee un archivo CSV utilizando un administrador de contexto (with open)."""
        ruta = Path(ruta_archivo)
        if not ruta.exists():
            raise RecursoNoEncontradoError(recurso="ArchivoCSV", identificador=str(ruta))
        try:
            with open(ruta, encoding="utf-8") as archivo:
                df = pd.read_csv(archivo)
        except Exception as exc:
            raise ValidacionDominioError(
                mensaje=f"Error al parsear el archivo CSV '{ruta.name}': {exc}",
                campo="archivo_csv",
            ) from exc
        else:
            return df

    @staticmethod
    def cargar_json(ruta_archivo: str | Path) -> pd.DataFrame:
        """Lee un archivo JSON utilizando un administrador de contexto (with open)."""
        ruta = Path(ruta_archivo)
        if not ruta.exists():
            raise RecursoNoEncontradoError(recurso="ArchivoJSON", identificador=str(ruta))
        try:
            with open(ruta, encoding="utf-8") as archivo:
                df = pd.read_json(archivo)
        except Exception as exc:
            raise ValidacionDominioError(
                mensaje=f"Error al parsear el archivo JSON '{ruta.name}': {exc}",
                campo="archivo_json",
            ) from exc
        else:
            return df

    @staticmethod
    def guardar_csv(df: pd.DataFrame, ruta_destino: str | Path) -> Path:
        """Escribe un DataFrame limpio en formato CSV mediante administrador de contexto."""
        ruta = Path(ruta_destino)
        ruta.parent.mkdir(parents=True, exist_ok=True)
        with open(ruta, mode="w", encoding="utf-8", newline="") as archivo:
            df.to_csv(archivo, index=False)
        return ruta

    @staticmethod
    def limpiar_dataframe_alumnos(df_crudo: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
        """Depura matrículas, elimina duplicados y trata valores nulos en alumnos."""
        if "matricula" not in df_crudo.columns:
            raise ValidacionDominioError(
                mensaje="El DataFrame de alumnos requiere la columna 'matricula'.",
                campo="matricula",
            )

        df = df_crudo.copy()
        filas_iniciales = len(df)

        # 1. Tratamiento de valores nulos criticos en matricula
        nulos_matricula = int(df["matricula"].isna().sum())
        df = df.dropna(subset=["matricula"]).copy()

        # 2. Normalizacion de matriculas (mayusculas, sin espacios ni guiones internos)
        df["matricula"] = (
            df["matricula"]
            .astype(str)
            .str.strip()
            .str.upper()
            .str.replace(" ", "", regex=False)
            .str.replace("-", "", regex=False)
        )
        df = df[df["matricula"].str.len() >= 3].copy()

        # 3. Eliminacion de duplicados por matricula
        antes_dedup = len(df)
        df = df.drop_duplicates(subset=["matricula"], keep="first").copy()
        duplicados_eliminados = antes_dedup - len(df)

        # 4. Tratamiento e imputacion de valores nulos y fuera de rango en campos secundarios
        if "nombre" in df.columns:
            df["nombre"] = df["nombre"].fillna("Sin Nombre").astype(str).str.strip().str.title()
        if "apellidos" in df.columns:
            df["apellidos"] = (
                df["apellidos"].fillna("Sin Apellido").astype(str).str.strip().str.title()
            )
        if "carrera" in df.columns:
            df["carrera"] = (
                df["carrera"]
                .fillna("Ingenieria en Sistemas Computacionales")
                .astype(str)
                .str.strip()
            )
            df.loc[df["carrera"] == "", "carrera"] = "Ingenieria en Sistemas Computacionales"
        if "semestre" in df.columns:
            semestres_num = pd.to_numeric(df["semestre"], errors="coerce").fillna(1)
            df["semestre"] = semestres_num.clip(lower=1, upper=15).astype(int)
        if "id_campus" in df.columns:
            campus_num = pd.to_numeric(df["id_campus"], errors="coerce").fillna(1).astype(int)
            df["id_campus"] = campus_num.where(campus_num.isin([1, 2]), 1)
        if "estatus_academico" in df.columns:
            df["estatus_academico"] = (
                df["estatus_academico"].fillna("ACTIVO").astype(str).str.strip().str.upper()
            )

        metricas = {
            "filas_iniciales": filas_iniciales,
            "filas_limpias": len(df),
            "nulos_matricula_descartados": nulos_matricula,
            "duplicados_eliminados": duplicados_eliminados,
        }
        return df.reset_index(drop=True), metricas

    @staticmethod
    def limpiar_dataframe_materias(df_crudo: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
        """Sanea claves de materia, elimina duplicados y normaliza creditos y cupos."""
        if "clave" not in df_crudo.columns:
            raise ValidacionDominioError(
                mensaje="El DataFrame de materias requiere la columna 'clave'.",
                campo="clave",
            )

        df = df_crudo.copy()
        filas_iniciales = len(df)

        nulos_clave = int(df["clave"].isna().sum())
        df = df.dropna(subset=["clave"]).copy()
        df["clave"] = (
            df["clave"].astype(str).str.strip().str.upper().str.replace(" ", "", regex=False)
        )
        df = df[df["clave"].str.len() >= 3].copy()

        antes_dedup = len(df)
        df = df.drop_duplicates(subset=["clave"], keep="first").copy()
        duplicados_eliminados = antes_dedup - len(df)

        if "nombre" in df.columns:
            df["nombre"] = df["nombre"].fillna("Asignatura General").astype(str).str.strip()
        if "creditos" in df.columns:
            cred = pd.to_numeric(df["creditos"], errors="coerce").fillna(8)
            df["creditos"] = cred.clip(lower=1, upper=20).astype(int)
        if "cupo_maximo" in df.columns:
            cupo = pd.to_numeric(df["cupo_maximo"], errors="coerce").fillna(30)
            df["cupo_maximo"] = cupo.clip(lower=1, upper=200).astype(int)
        if "id_campus" in df.columns:
            campus_num = pd.to_numeric(df["id_campus"], errors="coerce").fillna(1).astype(int)
            df["id_campus"] = campus_num.where(campus_num.isin([1, 2]), 1)

        metricas = {
            "filas_iniciales": filas_iniciales,
            "filas_limpias": len(df),
            "nulos_clave_descartados": nulos_clave,
            "duplicados_eliminados": duplicados_eliminados,
        }
        return df.reset_index(drop=True), metricas

    @staticmethod
    def limpiar_dataframe_entregas(df_crudo: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
        """Depura registros de entregas/calificaciones, tratando nulos y valores atipicos."""
        columnas_requeridas = {"id_entrega", "alumno_matricula", "materia_clave", "calificacion"}
        faltantes = columnas_requeridas - set(df_crudo.columns)
        if faltantes:
            raise ValidacionDominioError(
                mensaje=f"Faltan columnas requeridas en entregas: {sorted(faltantes)}",
                campo="entregas",
            )

        df = df_crudo.copy()
        filas_iniciales = len(df)
        df = df.dropna(subset=["id_entrega", "alumno_matricula", "materia_clave"]).copy()

        df["id_entrega"] = df["id_entrega"].astype(str).str.strip().str.upper()
        df["alumno_matricula"] = (
            df["alumno_matricula"]
            .astype(str)
            .str.strip()
            .str.upper()
            .str.replace(" ", "", regex=False)
            .str.replace("-", "", regex=False)
        )
        df["materia_clave"] = (
            df["materia_clave"]
            .astype(str)
            .str.strip()
            .str.upper()
            .str.replace(" ", "", regex=False)
        )

        antes_dedup = len(df)
        df = df.drop_duplicates(subset=["id_entrega"], keep="first").copy()
        duplicados_eliminados = antes_dedup - len(df)

        calif_num = pd.to_numeric(df["calificacion"], errors="coerce")
        nulos_calif = int(calif_num.isna().sum())
        outliers_calif = int(((calif_num < 0.0) | (calif_num > 10.0)).sum())

        promedio_valido = float(calif_num[(calif_num >= 0.0) & (calif_num <= 10.0)].mean())
        if pd.isna(promedio_valido):
            promedio_valido = 7.0

        df["calificacion"] = calif_num.fillna(promedio_valido).clip(0.0, 10.0).round(2)

        if "id_campus" in df.columns:
            campus_num = pd.to_numeric(df["id_campus"], errors="coerce").fillna(1).astype(int)
            df["id_campus"] = campus_num.where(campus_num.isin([1, 2]), 1)
        if "estado_entrega" in df.columns:
            estado_norm = (
                df["estado_entrega"].fillna("A_TIEMPO").astype(str).str.strip().str.upper()
            )
            df["estado_entrega"] = estado_norm.where(
                estado_norm.isin(["A_TIEMPO", "TARDIA"]),
                "A_TIEMPO",
            )

        metricas = {
            "filas_iniciales": filas_iniciales,
            "filas_limpias": len(df),
            "duplicados_eliminados": duplicados_eliminados,
            "calificaciones_nulas_imputadas": nulos_calif,
            "calificaciones_atipicas_ajustadas": outliers_calif,
        }
        return df.reset_index(drop=True), metricas

    def ejecutar_proceso_analitico(
        self,
        df_alumnos_crudo: pd.DataFrame,
        df_materias_crudo: pd.DataFrame,
        df_entregas_crudo: pd.DataFrame,
    ) -> ReporteAnaliticoPandas:
        """Aplica la metodologia formal: Pregunta -> Datos -> Limpieza -> Calculo -> Conclusion."""
        pregunta = (
            "¿Cual es la distribucion de matricula, el promedio de desempeno academico y la "
            "tasa de puntualidad de entregas entre Campus Central (id_campus=1) y Campus Sur "
            "(id_campus=2) tras sanear duplicados, valores nulos y datos atipicos?"
        )

        datos_entrada = {
            "alumnos_crudos": len(df_alumnos_crudo),
            "materias_crudas": len(df_materias_crudo),
            "entregas_crudas": len(df_entregas_crudo),
        }

        df_alumnos, met_al = self.limpiar_dataframe_alumnos(df_alumnos_crudo)
        df_materias, met_mat = self.limpiar_dataframe_materias(df_materias_crudo)
        df_entregas, met_ent = self.limpiar_dataframe_entregas(df_entregas_crudo)

        metricas_limpieza = {
            "alumnos_limpios": met_al["filas_limpias"],
            "alumnos_duplicados_eliminados": met_al["duplicados_eliminados"],
            "materias_limpias": met_mat["filas_limpias"],
            "materias_duplicadas_eliminadas": met_mat["duplicados_eliminados"],
            "entregas_limpias": met_ent["filas_limpias"],
            "calificaciones_nulas_imputadas": met_ent["calificaciones_nulas_imputadas"],
            "calificaciones_atipicas_ajustadas": met_ent["calificaciones_atipicas_ajustadas"],
        }

        alumnos_por_campus = {
            str(k): int(v) for k, v in df_alumnos["id_campus"].value_counts().sort_index().items()
        }
        materias_por_campus = {
            str(k): int(v) for k, v in df_materias["id_campus"].value_counts().sort_index().items()
        }
        promedio_general = round(float(df_entregas["calificacion"].mean()), 2)
        promedios_por_campus = {
            str(k): round(float(v), 2)
            for k, v in df_entregas.groupby("id_campus")["calificacion"].mean().items()
        }

        total_entregas = max(1, len(df_entregas))
        entregas_a_tiempo = int((df_entregas["estado_entrega"] == "A_TIEMPO").sum())
        tasa_puntualidad = round((entregas_a_tiempo / total_entregas) * 100.0, 2)
        tasa_aprobacion = round(
            float((df_entregas["calificacion"] >= 6.0).mean() * 100.0),
            2,
        )

        distribucion_carreras: dict[str, int] = {}
        if "carrera" in df_alumnos.columns:
            distribucion_carreras = {
                str(k): int(v) for k, v in df_alumnos["carrera"].value_counts().items()
            }

        calculos = {
            "alumnos_por_campus": alumnos_por_campus,
            "materias_por_campus": materias_por_campus,
            "distribucion_por_carrera": distribucion_carreras,
            "promedio_calificacion_general": promedio_general,
            "promedio_calificacion_por_campus": promedios_por_campus,
            "tasa_puntualidad_entregas_pct": tasa_puntualidad,
            "tasa_aprobacion_pct": tasa_aprobacion,
        }

        conclusion = (
            f"Tras depurar {datos_entrada['alumnos_crudos']} registros de alumnos y "
            f"{datos_entrada['entregas_crudas']} entregas, se obtuvo una base limpia de "
            f"{met_al['filas_limpias']} alumnos distribuidos por Shard Key id_campus "
            f"{alumnos_por_campus}. El promedio general de calificacion es {promedio_general}/10 "
            f"(aprobacion del {tasa_aprobacion}%) con una puntualidad de entrega del "
            f"{tasa_puntualidad}%."
        )

        return ReporteAnaliticoPandas(
            pregunta=pregunta,
            datos_entrada=datos_entrada,
            metricas_limpieza=metricas_limpieza,
            calculos_descriptivos=calculos,
            conclusion=conclusion,
        )
