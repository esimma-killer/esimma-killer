# E-SIIMA Killer (E-SIIMA 3) — Proyecto Final Integrador UAA

[![Backend CI Pipeline](https://github.com/esimma-killer/esimma-killer/actions/workflows/ci.yml/badge.svg)](https://github.com/esimma-killer/esimma-killer/actions/workflows/ci.yml)

Repositorio oficial del **Proyecto Final Integrador E-SIIMA Killer (E-SIIMA 3)** del Centro de Ciencias Básicas de la **Universidad Autónoma de Aguascalientes (UAA)**.

---

## Integrantes del Equipo

| Integrante | Usuario GitHub | Rol y Componentes Liderados |
| :--- | :--- | :--- |
| **Francisco Javier Sánchez Vallin** | `@FranciscoJavierSV` | **Líder del Proyecto / Full Stack** — PostgreSQL Distribuido (Sharding `id_campus`, Fragmentación Vertical, Réplicas) y Co-diseño de API REST. |
| **Gael Emiliano Nefarole López** | `@Gael1435` | **Full Stack / DevOps & Analytics** — Infraestructura Docker, CI/CD en GitHub Actions, Red Cifrada, Monitoreo y Analítica en MongoDB + Matplotlib. |
| **Ángel Azael Fajardo Espino** | `@AzaelFajardo` | **Frontend Multiplataforma** — Aplicación Flutter (*Single Codebase*: Web, Móvil y Escritorio) y Consumo de API REST. |

---

## Administración y Seguimiento Docente

Profesores con permisos de administrador:
- **Dr. David Montoya** (`dr.davidmontoya.dcat@gmail.com`)
- **Prof. Gerardo Salazar** (`gerardo.salazar@edu.uaa.mx`)
- **Prof. Irving Cardona** (`@Irving2355`)

---

## Estructura del Repositorio

- [`backend/`](./backend/README.md): Paquete modular en Python 3.11+ y FastAPI (Modelo POO con SOLID, Excepciones del Dominio, Servicios `try-except-else-finally`, Routers OpenAPI `/docs` y Suite Pytest con cobertura `> 95%`).
- [`docs/entregas/segunda_entrega.md`](./docs/entregas/segunda_entrega.md): Reporte técnico de la Segunda Entrega, justificación de postura CAP, cumplimiento LFPDPPP / Tríada CIA y bitácora de uso responsable de IA.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md): Estrategia de ramas Git (`main` $\leftarrow$ `entrega-2` $\leftarrow$ `sub-ramas por issue`), *Conventional Commits* y estándares de calidad.
- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml): Pipeline automatizado de Integración Continua (`Ruff`, `Pytest >= 60%`, `Bandit` y `Pip-Audit`).
