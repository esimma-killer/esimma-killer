"""Endpoints de autenticacion JWT y renovacion de sesiones."""

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated

from src.api.schemas import AuthUserResponse, LoginRequest, RefreshTokenRequest, TokenResponse
from src.core.config import get_settings
from src.security.auth import create_access_token, create_refresh_token, decode_token, verify_password
from src.security.models import AuthUser
from src.security.rbac import get_current_user
from src.security.store import find_auth_user, find_auth_user_by_id

router = APIRouter(prefix="/auth", tags=["Autenticacion JWT"])


@router.post("/login", status_code=status.HTTP_200_OK)
async def login(credentials: LoginRequest) -> TokenResponse:
    """Valida credenciales sinteticas y devuelve tokens de acceso y renovacion."""
    user = find_auth_user(credentials.correo_institucional)
    if user is None or not user.activo:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales invalidas.")
    if not verify_password(credentials.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales invalidas.")

    settings = get_settings()
    return TokenResponse(
        access_token=create_access_token(settings, user.id_usuario, user.rol, user.id_campus),
        refresh_token=create_refresh_token(settings, user.id_usuario, user.rol),
    )


@router.post("/refresh")
async def refresh(request: RefreshTokenRequest) -> TokenResponse:
    """Renueva la sesion con un refresh token valido."""
    settings = get_settings()
    try:
        payload = decode_token(settings, request.refresh_token)
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token invalido o vencido.")

    if payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Se requiere un refresh token.")

    user_id = str(payload.get("sub", ""))
    role = str(payload.get("role", ""))
    user = find_auth_user_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario no encontrado.")
    if not user.activo:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Usuario inactivo.")
    if user.rol != role:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Rol del token invalido.")
    return TokenResponse(
        access_token=create_access_token(settings, user.id_usuario, user.rol, user.id_campus),
        refresh_token=create_refresh_token(settings, user.id_usuario, user.rol),
    )


@router.get("/me")
async def me(user: Annotated[AuthUser, Depends(get_current_user)]) -> AuthUserResponse:
    """Devuelve el perfil minimo del usuario autenticado."""
    return AuthUserResponse(
        id_usuario=user.id_usuario,
        correo_institucional=user.correo_institucional,
        rol=user.rol,
        activo=user.activo,
        id_campus=user.id_campus,
    )
