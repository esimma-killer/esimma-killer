"""Modelo sintetico de usuario usado por autenticacion hasta integrar PostgreSQL."""

from dataclasses import dataclass


@dataclass(frozen=True)
class AuthUser:
    """Representa el usuario necesario para emitir y validar JWT."""

    id_usuario: str
    correo_institucional: str
    password_hash: str
    rol: str
    activo: bool = True
    id_campus: int | None = None
