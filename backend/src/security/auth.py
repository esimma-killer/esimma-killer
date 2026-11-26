"""Utilidades de contrasenas bcrypt y tokens JWT para el Issue #19."""

from datetime import UTC, datetime, timedelta
from typing import Any

import bcrypt
import jwt

from src.core.config import Settings


_BCRYPT_MAX_PASSWORD_BYTES = 72


def _password_bytes(password: str) -> bytes:
    encoded = password.encode("utf-8")
    if len(encoded) > _BCRYPT_MAX_PASSWORD_BYTES:
        raise ValueError("La contrasena excede el limite seguro de bcrypt (72 bytes).")
    return encoded


def hash_password(password: str) -> str:
    """Genera un hash bcrypt seguro para una contrasena."""
    return bcrypt.hashpw(_password_bytes(password), bcrypt.gensalt()).decode("ascii")


def verify_password(password: str, password_hash: str) -> bool:
    """Verifica una contrasena sin exponer el valor original."""
    try:
        return bcrypt.checkpw(_password_bytes(password), password_hash.encode("ascii"))
    except (ValueError, TypeError):
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
