"""Pruebas unitarias para el generador de datos sinteticos masivos (~100,000 registros)."""

from pathlib import Path

from src.services.synthetic_data_generator import SyntheticDataGenerator


def test_generacion_masiva_100k_registros_velocidad_y_balance() -> None:
    """Verifica que se generen >= 100,000 registros en menos de 120s con balance 50/50."""
    generador = SyntheticDataGenerator(seed=42)
    dataset, resumen = generador.generar_dataset()

    assert resumen.total_registros == 100700
    assert resumen.total_registros >= 100000
    assert resumen.tiempo_segundos < 120.0
    assert resumen.registros_campus_central == 50350
    assert resumen.registros_campus_sur == 50350
    assert len(dataset["alumnos"]) == 15000
    assert len(dataset["inscripciones"]) == 45000


def test_integridad_referencial_y_coherencia_de_shard_key() -> None:
    """Valida que no existan llaves foraneas huerfanas ni cruces invalidos de id_campus."""
    generador = SyntheticDataGenerator(seed=99)
    dataset, _ = generador.generar_dataset(
        num_profesores=20,
        num_materias=10,
        num_alumnos=200,
        num_inscripciones=500,
        num_entregas=300,
        num_pagos=200,
    )

    campus_por_alumno = {a["matricula"]: a["id_campus"] for a in dataset["alumnos"]}
    campus_por_materia = {m["clave"]: m["id_campus"] for m in dataset["materias"]}

    for alumno in dataset["alumnos"]:
        assert len(alumno["curp"]) == 18
        assert alumno["id_campus"] in {1, 2}

    for ins in dataset["inscripciones"]:
        mat_al = ins["alumno_matricula"]
        clv_mat = ins["materia_clave"]
        assert mat_al in campus_por_alumno
        assert clv_mat in campus_por_materia
        assert campus_por_alumno[mat_al] == ins["id_campus"]
        assert campus_por_materia[clv_mat] == ins["id_campus"]

    for ent in dataset["entregas"]:
        assert ent["alumno_matricula"] in campus_por_alumno
        assert ent["materia_clave"] in campus_por_materia
        assert len(ent["hash_sha256"]) == 64

    for pag in dataset["pagos"]:
        assert pag["alumno_matricula"] in campus_por_alumno
        assert pag["monto"] > 0


def test_exportacion_csv_json_y_sql_con_context_managers(tmp_path: Path) -> None:
    """Verifica la escritura de archivos CSV, JSON y SQL en disco."""
    generador = SyntheticDataGenerator(seed=7)
    dataset, resumen = generador.generar_dataset(
        num_profesores=10,
        num_materias=6,
        num_alumnos=40,
        num_inscripciones=80,
        num_entregas=40,
        num_pagos=40,
    )

    archivos_csv = generador.exportar_csv(dataset, tmp_path / "csv")
    assert len(archivos_csv) == 6
    assert (tmp_path / "csv" / "alumnos.csv").exists()

    ruta_json = generador.exportar_json(dataset, resumen, tmp_path / "json")
    assert ruta_json.exists()
    assert (tmp_path / "json" / "inscripciones.json").exists()

    ruta_sql = generador.exportar_sql(dataset, tmp_path / "sql" / "seed.sql", limite_por_tabla=5)
    assert ruta_sql.exists()
    contenido_sql = ruta_sql.read_text(encoding="utf-8")
    assert "INSERT INTO alumnos" in contenido_sql
    assert "COMMIT;" in contenido_sql
