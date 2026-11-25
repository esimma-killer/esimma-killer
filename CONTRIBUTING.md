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

## 2. Estrategia de Ramas (Git Flow con Rama `dev` y Sub-Ramas)

Utilizamos el flujo **Git Flow** basado en tres niveles (**`main` $\leftarrow$ `dev` $\leftarrow$ `sub-ramas por issue`**):

```text
main (Rama de producción / entregas cerradas y aprobadas)
 └── dev (Rama principal de integración continua del equipo — siempre tiene lo más reciente)
      ├── docs/issue-15-estategia-git              (Sub-rama -> merge a dev)
      ├── feat/issue-7-estructura-backend          (Sub-rama -> merge a dev)
      ├── feat/issue-8-clases-dominio-poo          (Sub-rama -> merge a dev)
      ├── feat/issue-9-excepciones-dominio         (Sub-rama -> merge a dev)
      ├── feat/issue-10-api-rest-fastapi           (Sub-rama -> merge a dev)
      ├── test/issue-11-suite-pytest               (Sub-rama -> merge a dev)
      ├── devops/issue-12-pipeline-ci              (Sub-rama -> merge a dev)
      ├── devops/issue-13-docker-compose           (Sub-rama -> merge a dev)
      ├── feat/issue-16-generador-datos-sinteticos (Sub-rama -> merge a dev)
      ├── feat/issue-17-limpieza-datos-pandas      (Sub-rama -> merge a dev)
      └── feat/issue-20-esquema-nosql-mongodb      (Sub-rama -> merge a dev)
```

1. **`main` (Rama Principal Protegida):**
   - Contiene únicamente las entregas cerradas y estables para evaluación docente.
   - Solo recibe cambios mediante un **Pull Request desde `dev` hacia `main`** al cierre de cada entrega.
2. **`dev` (Rama Central de Desarrollo):**
   - Es el punto de encuentro de todo el equipo. Aquí viven los cambios más recientes que ya fueron terminados y probados.
   - **Ningún integrante programa directo sobre `dev`**: desde `dev` se crean las sub-ramas de cada issue y hacia `dev` se integran cuando están listas.
3. **Sub-ramas de Trabajo por Issue:**
   - Cada tarea individual sale desde `dev` actualizada y, una vez validada con pruebas y linters, se integra mediante `git merge --no-ff` (o Pull Request) de vuelta a `dev`:
     - `feat/issue-<N>-<descripcion>`
     - `backend/issue-<N>-<descripcion>`
     - `database/issue-<N>-<descripcion>`
     - `frontend/issue-<N>-<descripcion>`
     - `devops/issue-<N>-<descripcion>`
     - `docs/issue-<N>-<descripcion>`

### Comandos Estándar para Trabajar con la Rama `dev`

```bash
# 1. Posicionarse en la rama dev y descargar los cambios más recientes del equipo
git checkout dev
git pull origin dev

# 2. Crear tu sub-rama para el issue que vas a trabajar
git checkout -b feat/issue-21-landing-flutter

# 3. Guardar tus avances en tu sub-rama con Conventional Commits
git add .
git commit -m "feat(frontend): maquetar landing page institucional UAA (#21)"
git push -u origin feat/issue-21-landing-flutter

# 4. Cuando tu issue esté terminado y probado, integrarlo a dev
git checkout dev
git pull origin dev
git merge --no-ff feat/issue-21-landing-flutter -m "merge: integrar feat/issue-21-landing-flutter en dev (#21)"
git push origin dev

# 5. Al cierre de cada entrega: abrir Pull Request en GitHub desde `dev` hacia `main`
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
