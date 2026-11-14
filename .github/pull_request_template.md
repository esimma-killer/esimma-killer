## Descripción del Cambio

<!-- Explica brevemente qué implementa, corrige o documenta este Pull Request -->

## Issue Relacionado

<!-- Vincula el issue que resuelve o avanza este PR, por ejemplo: Closes #7 o Relacionado a #15 -->
- Issue: #
- Épica relacionada: #

## Tipo de Cambio

- [ ] `feat`: Nueva funcionalidad (Dominio POO, Servicios, API REST, Frontend Flutter)
- [ ] `fix`: Corrección de error o manejo de excepciones
- [ ] `docs`: Documentación técnica, reportes de entrega o estándares
- [ ] `test`: Pruebas unitarias o de integración (`pytest` / `flutter test`)
- [ ] `ci` / `devops`: Configuración de GitHub Actions, Docker o infraestructura
- [ ] `refactor`: Mejora de código sin cambio de comportamiento externo

## Checklist Obligatorio de Calidad (Definition of Done)

- [ ] **PEP 8 y Formato:** El código cumple estrictamente con PEP 8 (`ruff check .` y `ruff format --check .` sin errores ni advertencias).
- [ ] **Tipado y SOLID:** Todas las clases, funciones y métodos incluyen *Type Hints* y docstrings descriptivos.
- [ ] **Pruebas Unitarias:** La suite de pruebas se ejecuta exitosamente de forma local (`pytest`).
- [ ] **Cobertura Mínima (>= 60%):** Se verificó que la cobertura de código en servicios y dominio alcanza o supera el 60% (`pytest --cov=src --cov-fail-under=60`).
- [ ] **Seguridad Estática y Dependencias:** Sin vulnerabilidades críticas/altas en `bandit -r src/` ni en `pip-audit`.
- [ ] **Privacidad y Datos Sintéticos (LFPDPPP):** No se incluyen credenciales reales, archivos `.env` ni datos personales reales (solo datos sintéticos).
- [ ] **Integración Continua (CI):** Todos los jobs del pipeline de GitHub Actions pasan en verde.

## Declaración de Transparencia sobre Uso de IA (Anexo A)

<!-- De acuerdo con el compromiso #4 de la Carta Compromiso de IA del equipo -->
- [ ] **Sin asistencia de IA:** Código y documentación redactados íntegramente de forma manual.
- [ ] **Con asistencia de IA (Antigravity / Gemini / Claude):** Se utilizó IA como apoyo técnico; el autor revisó, probó, validó y puede defender cada línea incluida en este PR.
  - *Detalle de partes apoyadas con IA:* <!-- Ej. Estructura base de esquemas Pydantic / plantillas de pruebas -->

## Evidencia de Pruebas / Capturas

<!-- Adjunta salida de consola de pytest, cobertura o capturas de Swagger (/docs) si aplica -->
```text
Pegar aquí el resumen de salida de pytest / ruff
```
