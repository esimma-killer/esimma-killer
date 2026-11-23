# Generador de Datos Sintéticos Masivos (~100,000 Registros) — E-SIIMA Killer

Este directorio contiene la documentación y salida del motor generador determinista (`src/services/synthetic_data_generator.py`) desarrollado para el **Issue #16 (`[E3-DATA]`)** de la Tercera Entrega.

---

## 1. Volumen Generado y Balance por Campus (`Shard Key: id_campus`)

El generador produce por defecto **`100,700` registros sintéticos anonimizados** (en cumplimiento con la **LFPDPPP**), distribuidos equitativamente (`50% / 50%`) entre los dos nodos del sistema distribuido:
- **`id_campus = 1` (Campus Central — Nodo Maestro Local):** `50,350` registros.
- **`id_campus = 2` (Campus Sur — Nodo Maestro Remoto):** `50,350` registros.

| Entidad / Tabla | Registros Generados | Campus Central (`1`) | Campus Sur (`2`) | Integridad Referencial |
| :--- | :---: | :---: | :---: | :--- |
| **`profesores`** | `500` | `250` | `250` | Llave primaria `numero_empleado` (`DOC-00001`..`DOC-00500`) |
| **`materias`** | `200` | `100` | `100` | FK a `profesores.numero_empleado` |
| **`alumnos`** | `15,000` | `7,500` | `7,500` | Matrícula única (`ID300001`..`ID315000`) y CURP de 18 caracteres |
| **`inscripciones`** | `45,000` | `22,500` | `22,500` | FK a `alumnos.matricula` y `materias.clave` **del mismo `id_campus`** |
| **`entregas`** | `20,000` | `10,000` | `10,000` | FK a inscripción válida + `hash_sha256` + puntualidad (`A_TIEMPO`/`TARDIA`) |
| **`pagos`** | `20,000` | `10,000` | `10,000` | FK a `alumnos.matricula` con montos y referencias bancarias sintéticas |
| **TOTAL** | **`100,700`** | **`50,350`** | **`50,350`** | **100% consistente sin huérfanos** |

---

## 2. Rendimiento y Tiempo de Ejecución

- **Criterio de aceptación del Issue #16:** `< 120 segundos` (2 minutos) para 100,000 registros.
- **Tiempo real medido:**
  - Generación en memoria de los `100,700` registros: **`~0.25 a 0.60 segundos`**.
  - Exportación completa a **CSV + JSON + SQL**: **`~1.5 a 3.0 segundos`**.

---

## 3. Comando de Ejecución Reproducible

Desde el directorio `backend/` con el entorno virtual activo:

```bash
python -m src.services.synthetic_data_generator --output-dir data/synthetic --seed 42
```

### Archivos Exportados en `backend/data/synthetic/`
1. **Formato CSV (para carga y limpieza analítica con Pandas — Issue #17):**
   - `profesores.csv`, `materias.csv`, `alumnos.csv`, `inscripciones.csv`, `entregas.csv`, `pagos.csv`
2. **Formato JSON (para ingesta documental y API):**
   - `resumen_dataset.json`, `profesores.json`, `materias.json`, `alumnos.json`, `inscripciones.json`, `entregas.json`, `pagos.json`
3. **Formato SQL (para sembrado en PostgreSQL — Issue #18):**
   - `seed_campus.sql` (bloques transaccionales `BEGIN; INSERT INTO ...; COMMIT;`).
