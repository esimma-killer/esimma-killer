# Guía de Contribución y Flujo de Trabajo Git — E-SIIMA Killer (E-SIIMA 3)

Bienvenido al repositorio oficial del **Proyecto Final Integrador E-SIIMA Killer (E-SIIMA 3)** de la Universidad Autónoma de Aguascalientes (UAA). Este documento establece las reglas obligatorias de ramas, commits, calidad de código e integración mediante Pull Requests para todos los integrantes del equipo.

---

## 1. Integrantes y Responsabilidades por Épica

| Integrante | Usuario GitHub | Rol | Épicas a Cargo |
| :--- | :--- | :--- | :--- |
| **Francisco Javier Sánchez Vallin** | `@FranciscoJavierSV` | Líder del Proyecto / Full Stack | **Épica #1** (Documentación, Riesgos, Legal) · **Épica #3** (PostgreSQL Distribuido) · **Épica #6** (Backend API REST) |
| **Gael Emiliano Nefarole López** | `@Gael1435` | Full Stack / DevOps & Analytics | **Épica #4** (MongoDB Analítica y Matplotlib) · **Épica #5** (Docker, CI/CD, Red Cifrada y Monitoreo) |
| **Ángel Azael Fajardo Espino** | `@AzaelFajardo` | Frontend Multiplataforma | **Épica #2** (Flutter Single Codebase) · **Épica #6** (Co-diseño Backend API REST) |

---

## 2. Estrategia de Ramas (Git Flow por Entrega y Sub-Ramas)

Utilizamos un flujo jerárquico de tres niveles (**`main` $\leftarrow$ `entrega-2` $\leftarrow$ `sub-ramas por issue`**):

```text
main (Rama principal protegida)
 └── entrega-2 (Rama de integración de la Segunda Entrega — se une a main vía PR)
      ├── docs/issue-15-estategia-git        (Sub-rama Paso 1 -> merge a entrega-2)
      ├── feat/issue-7-estructura-backend    (Sub-rama Paso 2 -> merge a entrega-2)
      ├── feat/issue-8-clases-dominio-poo    (Sub-rama Paso 3 -> merge a entrega-2)
      ├── feat/issue-9-excepciones-dominio   (Sub-rama Paso 4 -> merge a entrega-2)
      ├── feat/issue-10-api-rest-fastapi     (Sub-rama Paso 5 -> merge a entrega-2)
      ├── test/issue-11-suite-pytest         (Sub-rama Paso 6 -> merge a entrega-2)
      ├── devops/issue-12-pipeline-ci        (Sub-rama Paso 7 -> merge a entrega-2)
      ├── devops/issue-13-docker-compose     (Sub-rama Paso 8 -> merge a entrega-2)
      └── feat/issue-14-estructura-flutter   (Sub-rama Paso 9 -> merge a entrega-2)
```

1. **`main` (Rama Principal):**
   - Contiene únicamente las entregas cerradas y estables.
   - Recibe los cambios al concluir la entrega mediante un **Pull Request desde `entrega-2` hacia `main`**.
2. **`entrega-2` (Rama Auxiliar de Integración):**
   - Rama donde convergen todas las implementaciones de la Segunda Entrega.
3. **Sub-ramas de Trabajo por Issue:**
   - Cada implementación sale desde `entrega-2` y, una vez validada, se integra mediante `git merge --no-ff` hacia `entrega-2`:
     - `docs/issue-<N>-<descripcion-corta>`
     - `feat/issue-<N>-<descripcion-corta>`
     - `test/issue-<N>-<descripcion-corta>`
     - `devops/issue-<N>-<descripcion-corta>`

### Comandos Estándar para Desarrollar un Issue

```bash
# 1. Posicionarse en la rama de la entrega actualizada
git checkout entrega-2
git pull origin entrega-2

# 2. Crear la sub-rama para el issue especifico
git checkout -b feat/issue-7-estructura-backend

# 3. Hacer commits siguiendo Conventional Commits
git add .
git commit -m "feat(backend): configurar estructura modular de paquetes (#7)"
git push -u origin feat/issue-7-estructura-backend

# 4. Integrar la sub-rama de vuelta a entrega-2
git checkout entrega-2
git merge --no-ff feat/issue-7-estructura-backend -m "merge: integrar feat/issue-7-estructura-backend en entrega-2 (#7)"
git push origin entrega-2
```

---

## 3. Convención de Mensajes de Commit (Conventional Commits)

Todos los mensajes de commit deben seguir el formato de **Conventional Commits** en minúsculas y haciendo referencia al issue cuando aplique:

```text
<tipo>(<alcance>): <descripción breve en imperativo> (#<issue>)
```

### Tipos Permitidos
- `feat`: Nueva característica o módulo (`feat(domain): implementar jerarquia Persona, Alumno y Administrativo (#8)`).
- `fix`: Corrección de error o control de excepciones (`fix(services): manejar InscripcionInvalidaError con try-except-else-finally (#9)`).
- `docs`: Cambios exclusivos de documentación (`docs(entrega-2): agregar plantilla de PR y reporte tecnico (#15)`).
- `test`: Adición o ajuste de pruebas unitarias (`test(domain): verificar cobertura mayor al 60% en servicios (#11)`).
- `ci`: Configuración de GitHub Actions (`ci(actions): agregar jobs de ruff, pytest, bandit y pip-audit (#12)`).
- `chore` / `build`: Dependencias, Docker o configuración de proyecto (`build(docker): crear Dockerfile multi-etapa y docker-compose (#13)`).
- `refactor`: Reestructuración de código sin alterar funcionalidad.

---

## 4. Estándares de Calidad y Validación Local

Antes de abrir un Pull Request, el autor debe ejecutar las herramientas de verificación en su entorno local:

### Backend (Python 3.11+)
1. **Estilo y Formato (PEP 8):**
   ```bash
   cd backend
   ruff check .
   ruff format --check .
   ```
2. **Pruebas Unitarias y Cobertura (>= 60%):**
   ```bash
   cd backend
   pytest --cov=src --cov-report=term-missing --cov-fail-under=60
   ```
3. **Seguridad Estática y Auditoría de Dependencias:**
   ```bash
   cd backend
   bandit -r src/
   pip-audit -r requirements.txt
   ```

### Frontend (Flutter)
```bash
cd frontend
flutter analyze
flutter test
```

---

## 5. Proceso de Pull Request (PR)

1. Subir la rama al repositorio remoto:
   ```bash
   git push -u origin <nombre-de-rama>
   ```
2. Abrir un **Pull Request** hacia `main` en GitHub.
3. Completar **todos los campos** de la plantilla `.github/pull_request_template.md`, incluyendo:
   - Enlace al issue (`Closes #<N>`).
   - Checklist de verificación de calidad (`ruff`, `pytest >= 60%`, `bandit`, `pip-audit`).
   - Declaración de transparencia de uso de IA.
4. Esperar a que el pipeline de **GitHub Actions CI** finalice en verde y contar con la revisión del equipo antes de fusionar (*Squash and merge* o *Merge commit*).

---

## 6. Reglas de Privacidad (LFPDPPP) y Uso Responsable de IA

De conformidad con la **Propuesta Técnica** y la **Carta Compromiso sobre Uso de IA (Anexo A)**:
- **Cero Datos Reales:** Queda estrictamente prohibido subir al repositorio o introducir en herramientas externas datos personales reales de alumnos o docentes de la UAA (CURP, RFC, matrículas reales, cuentas bancarias o contraseñas). Todo desarrollo y prueba utiliza exclusivamente **datos sintéticos**.
- **Sin Secretos en Git:** Ningún archivo `.env`, llave privada o certificado real debe versionarse; solo se versionan plantillas como `.env.example`.
- **Transparencia de IA:** El uso de asistentes (Google Antigravity / Gemini / Claude) debe declararse en cada Pull Request y cada integrante es responsable de comprender, validar, probar y defender individualmente su código.
