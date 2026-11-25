"""Repositorio sintetico en memoria para el desarrollo del Issue #19."""

from src.security.auth import hash_password
from src.security.models import AuthUser


_USERS: dict[str, AuthUser] = {
    "alumno.central@edu.uaa.mx": AuthUser(
        id_usuario="1001",
        correo_institucional="alumno.central@edu.uaa.mx",
        password_hash=hash_password("AlumnoCentral123!"),
        rol="estudiante",
        activo=True,
        id_campus=1,
    ),
    "profesor.central@edu.uaa.mx": AuthUser(
        id_usuario="2001",
        correo_institucional="profesor.central@edu.uaa.mx",
        password_hash=hash_password("ProfesorCentral123!"),
        rol="profesor",
        activo=True,
        id_campus=1,
    ),
    "coordinador@edu.uaa.mx": AuthUser(
        id_usuario="3001",
        correo_institucional="coordinador@edu.uaa.mx",
        password_hash=hash_password("Coordinador123!"),
        rol="coordinador",
        activo=True,
        id_campus=None,
    ),
}


def find_auth_user(correo: str) -> AuthUser | None:
    """Busca un usuario sintetico por correo institucional."""
    return _USERS.get(correo.strip().lower())


def find_auth_user_by_id(user_id: str) -> AuthUser | None:
    """Busca un usuario sintetico por su identificador."""
    return next(
        (user for user in _USERS.values() if user.id_usuario == user_id),
        None,
    )
