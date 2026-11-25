"""Utilidades de contrasenas Argon2 y tokens JWT para el Issue #19."""

from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

from src.core.config import Settings


_password_hasher = PasswordHasher()


def hash_password(password: str) -> str:
    """Genera un hash Argon2 seguro para una contrasena."""
    return _password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    """Verifica una contrasena sin exponer el valor original."""
    try:
        return _password_hasher.verify(password_hash, password)
    except VerifyMismatchError:
        return False


def create_access_token(
    settings: Settings,
    subject: str,
    role: str,
    campus_id: int | None = None,
) -> str:
    """Crea un token JWT de acceso con vigencia de 30 minutos por defecto."""
    now = datetime.now(UTC)
    payload: dict[str, Any] = {
        "sub": subject,
        "role": role,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=settings.jwt_access_minutes),
    }
    if campus_id is not None:
        payload["campus_id"] = campus_id
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(settings: Settings, subject: str, role: str) -> str:
    """Crea un token JWT de renovacion con vigencia de 7 dias por defecto."""
    now = datetime.now(UTC)
    payload: dict[str, Any] = {
        "sub": subject,
        "role": role,
        "type": "refresh",
        "iat": now,
        "exp": now + timedelta(days=settings.jwt_refresh_days),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(settings: Settings, token: str) -> dict[str, Any]:
    """Valida firma y expiracion de un JWT."""
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
