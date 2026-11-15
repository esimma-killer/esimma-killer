# ==============================================================================
# Dockerfile Optimizado — E-SIIMA Killer Backend API (Python 3.11 + FastAPI)
# Buenas practicas: python:3.11-slim, cache de capas, usuario sin privilegios y
# healthcheck nativo sin dependencias adicionales del sistema operativo.
# ==============================================================================

FROM python:3.11-slim

LABEL maintainer="Gael Emiliano Nefarole Lopez <@Gael1435>"
LABEL project="E-SIIMA Killer (E-SIIMA 3) - UAA"

# Variables de entorno para optimizar Python en contenedores
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONPATH=/app

WORKDIR /app

# Crear grupo y usuario del sistema sin privilegios de root (Seguridad CIA)
RUN groupadd --gid 10001 appgroup && \
    useradd --uid 10001 --gid appgroup --shell /bin/false --create-home appuser

# 1. Copiar e instalar dependencias primero para aprovechar la cache de capas de Docker
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 2. Copiar metadatos y codigo fuente de la aplicacion
COPY pyproject.toml ./
COPY src/ ./src/

# Asignar permisos al usuario sin privilegios
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8000

# Healthcheck apuntando a /api/v1/health usando la libreria estandar de Python
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/v1/health', timeout=3)" || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
