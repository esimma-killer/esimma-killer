# Reporte Técnico — Tercera Entrega (Datos Sintéticos, Analítica Pandas y Esquema NoSQL MongoDB)

**Universidad Autónoma de Aguascalientes (UAA)**  
**Centro de Ciencias Básicas — Proyecto Integrador de Sistemas Computacionales**

- **Integrante Responsable de Ingeniería Analítica, Datos Masivos y NoSQL:**
  - Gael Emiliano Nefarole López (`@Gael1435`)
- **Integrantes del Equipo:**
  - Francisco Javier Sánchez Vallin (`@FranciscoJavierSV`) — Líder del Proyecto / PostgreSQL Distribuido & Autenticación JWT
  - Ángel Azael Fajardo Espino (`@AzaelFajardo`) — Frontend Multiplataforma Flutter (Landing UAA y Login JWT)
- **Repositorio Oficial:** https://github.com/esimma-killer/esimma-killer

---

## 1. Generador de Datos Sintéticos Masivos (~100,000 Registros) (Issue #16)

Para poblar y estresar los nodos de **Campus Central (`id_campus = 1`)** y **Campus Sur (`id_campus = 2`)** sin comprometer datos personales reales (cumplimiento estricto de la **LFPDPPP**), se desarrolló el motor determinista `SyntheticDataGenerator` en `backend/src/services/synthetic_data_generator.py`.

### Volumen y Balance por Shard Key (`id_campus`)
- **Total generado por ejecución:** **`100,700` registros** (`50,350` para Campus Central y `50,350` para Campus Sur):
  - `500` profesores (`DOC-00001` a `DOC-00500`)
  - `200` materias (`ISC-0101` a `ISC-0300`)
  - `15,000` alumnos (`ID300001` a `ID315000`) con CURP sintética de 18 caracteres
  - `45,000` inscripciones respetando que `alumno.id_campus == materia.id_campus`
  - `20,000` entregas/calificaciones con `hash_sha256` y puntualidad (`A_TIEMPO` / `TARDIA`)
  - `20,000` pagos institucionales simulados
- **Formatos exportados con administradores de contexto (`with open`):** CSV, JSON y sentencias SQL transaccionales (`BEGIN; INSERT INTO ...; COMMIT;`).

---

## 2. Proceso Analítico de Carga y Limpieza de Datos con Pandas (Issue #17)

Se implementó el servicio `PandasAnalyticsService` en `backend/src/services/pandas_analytics_service.py` y el Jupyter Notebook reproducible en `backend/notebooks/proceso_analitico_pandas.ipynb`, estructurados bajo las 5 etapas de la metodología analítica formal:

1. **Pregunta:** *¿Cuál es la distribución de matrícula, el promedio de desempeño académico y la tasa de puntualidad de entregas entre Campus Central (`id_campus=1`) y Campus Sur (`id_campus=2`) tras sanear duplicados, valores nulos y datos atípicos?*
2. **Datos:** Lectura de archivos CSV y JSON utilizando administradores de contexto (`with open(...)`) y captura controlada de errores hacia `RecursoNoEncontradoError` y `ValidacionDominioError`.
3. **Limpieza:**
   - **Normalización de matrículas y claves:** `str.strip().str.upper()`, eliminación de espacios/guiones internos y descarte de filas sin llave primaria.
   - **Eliminación de duplicados:** `drop_duplicates(subset=["matricula"], keep="first")`.
   - **Tratamiento de valores nulos y atípicos (*outliers*):** Imputación de carreras/semestres faltantes, validación de `id_campus` $\in \{1, 2\}$, imputación de calificaciones nulas con la media válida y recorte (`clip(0.0, 10.0)`) de calificaciones fuera de escala.
4. **Cálculo:** Estadística descriptiva agrupada por `id_campus` (conteo de alumnos y materias por campus, distribución por carrera, promedio general y por campus, tasa de puntualidad `A_TIEMPO` vs `TARDIA` y tasa de aprobación).
5. **Conclusión:** Síntesis cuantitativa generada automáticamente a partir de los indicadores depurados.

---

## 3. Diseño del Esquema de Colecciones Documentales NoSQL en MongoDB (Issue #20)

*(Sección en progreso — se completará en el Paso 3).*

---

## 4. Declaración y Bitácora de Uso Responsable de Inteligencia Artificial — Entrega 3 (Anexo A)

En cumplimiento con el punto 4 de la **Carta Compromiso sobre el Uso de Inteligencia Artificial** firmada el 10 de noviembre de 2026:

| Paso / Issue | Archivos Involucrados | Qué se realizó con apoyo de IA (Antigravity / Gemini) | Revisión y Validación de `@Gael1435` |
| :--- | :--- | :--- | :--- |
| **Paso 1 — Issue #16** (`[E3-DATA]`) | `backend/src/services/synthetic_data_generator.py`, `backend/data/README.md`, `backend/tests/test_synthetic_generator.py` | Implementación asistida del generador determinista de `100,700` registros distribuidos 50/50 por `id_campus`, algoritmo de CURP sintética y exportadores CSV, JSON y SQL con `with open`. | Verificación de integridad referencial sin llaves foráneas huérfanas, tiempo de ejecución (`0.23 segundos`, muy por debajo del límite de 2 minutos) y suite `pytest`. |
| **Paso 2 — Issue #17** (`[E3-ANALYTICS]`) | `backend/src/services/pandas_analytics_service.py`, `backend/notebooks/proceso_analitico_pandas.ipynb`, `backend/tests/test_pandas_analytics.py` | Diseño asistido de los pipelines de limpieza en Pandas (normalización de matrículas/claves, `drop_duplicates`, imputación de nulos y `clip` de outliers) bajo las 5 etapas analíticas (Pregunta, Datos, Limpieza, Cálculo y Conclusión). | Validación con pruebas unitarias inyectando datos corruptos, nulos, duplicados y calificaciones fuera de rango (`-3.0`, `15.5`). |
| **Paso 3 — Issue #20** (`[E3-ANALYTICS]`) | *(Pendiente)* | *(Se actualizará al concluir el Paso 3)* | *(Pendiente)* |
