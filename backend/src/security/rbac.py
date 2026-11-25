"""Dependencias de autenticacion y autorizacion por roles."""

from collections.abc import Callable

import jwt
from fastapi import Depends, Header, HTTPException, status

from src.core.config import get_settings
from src.security.auth import decode_token
from src.security.models import AuthUser
from src.security.store import find_auth_user_by_id


def get_current_user(authorization: str | None = Header(default=None)) -> AuthUser:
    """Obtiene el usuario autenticado a partir del Bearer access token."""
    if authorization is None or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Se requiere autenticacion.")

    token = authorization.split(None, 1)[1].strip()
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token vacio.")

    try:
        payload = decode_token(get_settings(), token)
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalido o vencido.")

    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Se requiere un access token.")

    user_id = str(payload.get("sub", ""))
    role = str(payload.get("role", ""))
    user = find_auth_user_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario no encontrado.")
    if not user.activo:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Usuario inactivo.")
    if user.rol != role:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Rol del token invalido.")
    return user


def require_roles(*allowed_roles: str) -> Callable:
    """Construye una dependencia FastAPI que exige uno de los roles permitidos."""

    def dependency(user: AuthUser = Depends(get_current_user)) -> AuthUser:
        if user.rol not in allowed_roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Permiso denegado para este rol.")
        return user

    return dependency
