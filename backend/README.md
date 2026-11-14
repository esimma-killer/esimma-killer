# E-SIIMA Killer — Backend (Python 3.11+ / FastAPI)

Módulo backend para el **Proyecto Final Integrador E-SIIMA Killer (E-SIIMA 3)**. Contiene la lógica de dominio orientada a objetos (POO), la jerarquía de excepciones personalizadas, los servicios transaccionales con auditoría para MongoDB y la exposición de la API REST con FastAPI y contratos OpenAPI.

---

## 1. Estructura de Paquetes

```text
backend/
├── .env.example              # Plantilla de variables de entorno
├── pyproject.toml            # Configuración unificada (setuptools, ruff, pytest, coverage, bandit)
├── requirements.txt          # Dependencias de producción
├── requirements-dev.txt      # Dependencias de desarrollo, pruebas y calidad
├── src/
│   ├── __init__.py
│   ├── main.py               # Aplicación FastAPI, CORS y manejadores globales de errores
│   ├── core/                 # Configuración de entorno y resolución de Shards (id_campus)
│   ├── domain/               # Clases POO (Persona, Alumno, Administrativo, Profesor, Materia, etc.)
│   ├── services/             # Reglas de negocio y patrón try-except-else-finally
│   └── api/                  # Esquemas Pydantic v2 y Routers modulares (/api/v1)
└── tests/                    # Suite de pruebas unitarias con Pytest (cobertura >= 60%)
```

---

## 2. Configuración del Entorno Virtual (`venv`)

### En Windows (PowerShell)
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
Copy-Item .env.example .env
```

### En Linux / macOS
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
cp .env.example .env
```

---

## 3. Verificación de Estilo PEP 8, Seguridad y Pruebas

```bash
# 1. Validar apego estricto a PEP 8 y formato con Ruff
ruff check .
ruff format --check .

# 2. Ejecutar suite de pruebas unitarias y cobertura mínima del 60%
pytest

# 3. Análisis estático de seguridad con Bandit
bandit -r src/

# 4. Auditoría de vulnerabilidades en dependencias
pip-audit -r requirements.txt
```
