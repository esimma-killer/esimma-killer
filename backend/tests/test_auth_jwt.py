"""Pruebas permanentes de autenticacion JWT y control RBAC (Issue #19)."""

from datetime import UTC, datetime, timedelta

import jwt

from src.core.config import Settings
from src.security.auth import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from src.security.models import AuthUser
from src.security.rbac import get_current_user, require_roles


def test_argon2_hash_never_stores_plain_password() -> None:
    password = "AlumnoCentral123!"
    password_hash = hash_password(password)

    assert password not in password_hash
    assert verify_password(password, password_hash) is True
    assert verify_password("PasswordIncorrecta123!", password_hash) is False


def test_access_and_refresh_tokens_include_roles_and_expiration() -> None:
    settings = Settings(
        jwt_secret="test-secret",
        jwt_algorithm="HS256",
        jwt_access_minutes=30,
        jwt_refresh_days=7,
    )

    access = decode_token(settings, create_access_token(settings, "1001", "estudiante", 1))
    refresh = decode_token(settings, create_refresh_token(settings, "1001", "estudiante"))

    assert access["sub"] == "1001"
    assert access["role"] == "estudiante"
    assert access["campus_id"] == 1
    assert access["type"] == "access"
    assert refresh["type"] == "refresh"

    remaining_access = access["exp"] - datetime.now(UTC).timestamp()
    remaining_refresh = refresh["exp"] - datetime.now(UTC).timestamp()
    assert 1700 <= remaining_access <= 1800
    assert 600_000 <= remaining_refresh <= 610_000


def test_expired_token_is_rejected() -> None:
    settings = Settings(jwt_secret="test-secret", jwt_algorithm="HS256")
    expired = jwt.encode(
        {
            "sub": "1001",
            "role": "estudiante",
            "type": "access",
            "exp": datetime.now(UTC) - timedelta(minutes=1),
        },
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )

    try:
        decode_token(settings, expired)
        raise AssertionError("El token vencido debio ser rechazado")
    except jwt.ExpiredSignatureError:
        pass


def test_require_roles_allows_and_denies_by_role() -> None:
    alumno = AuthUser(
        id_usuario="1001",
        correo_institucional="alumno.central@edu.uaa.mx",
        password_hash="HASH_SINTETICO",
        rol="estudiante",
        activo=True,
        id_campus=1,
    )

    estudiante_permission = require_roles("estudiante")
    coordinator_permission = require_roles("coordinador")

    assert estudiante_permission(alumno) is alumno

    try:
        coordinator_permission(alumno)
        raise AssertionError("El estudiante no debe tener permiso de coordinador")
    except Exception as exc:
        assert getattr(exc, "status_code", None) == 403
