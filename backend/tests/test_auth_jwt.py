"""Pruebas permanentes de autenticacion JWT y control RBAC (Issue #19)."""

from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from types import SimpleNamespace

import jwt
import pytest
from fastapi.testclient import TestClient

from src.api.dependencies import get_inscripcion_service
from src.api.routers import auth as auth_router
from src.core.config import Settings
from src.main import create_app
from src.security import rbac as rbac_module
from src.security.auth import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from src.security.models import AuthUser
from src.security.rbac import require_roles


def test_bcrypt_hash_never_stores_plain_password() -> None:
    password = "AlumnoCentral123!"
    password_hash = hash_password(password)

    assert password_hash.startswith(("$2a$", "$2b$", "$2y$"))
    assert password not in password_hash
    assert verify_password(password, password_hash) is True
    assert verify_password("PasswordIncorrecta123!", password_hash) is False
    assert verify_password(password, "hash-malformado") is False


def test_bcrypt_rechaza_contrasena_mayor_a_72_bytes() -> None:
    with pytest.raises(ValueError, match="72 bytes"):
        hash_password("x" * 73)


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


@pytest.fixture
def auth_client(
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[tuple[TestClient, Settings, dict[str, AuthUser]]]:
    """Construye un cliente HTTP aislado con usuario sintético y clave de prueba."""
    settings = Settings(
        jwt_secret="test-secret-for-issue-19",
        jwt_algorithm="HS256",
        jwt_access_minutes=30,
        jwt_refresh_days=7,
    )
    alumno = AuthUser(
        id_usuario="1001",
        correo_institucional="alumno.central@edu.uaa.mx",
        password_hash=hash_password("AlumnoCentral123!"),
        rol="estudiante",
        activo=True,
        id_campus=1,
    )
    coordinador = AuthUser(
        id_usuario="3001",
        correo_institucional="coordinador@edu.uaa.mx",
        password_hash=hash_password("Coordinador123!"),
        rol="coordinador",
        activo=True,
        id_campus=None,
    )
    usuarios = {alumno.id_usuario: alumno, coordinador.id_usuario: coordinador}

    monkeypatch.setattr(auth_router, "get_settings", lambda: settings)
    monkeypatch.setattr(auth_router, "find_auth_user", lambda _correo: alumno)
    monkeypatch.setattr(
        rbac_module,
        "get_settings",
        lambda: settings,
    )
    monkeypatch.setattr(
        rbac_module,
        "find_auth_user_by_id",
        lambda user_id: usuarios.get(user_id),
    )

    app = create_app()
    app.dependency_overrides[get_inscripcion_service] = lambda: SimpleNamespace(
        logs_actividad=[]
    )
    try:
        with TestClient(app) as client:
            yield client, settings, usuarios
    finally:
        app.dependency_overrides.clear()


def test_login_emite_tokens_y_perfil_me_requiere_token(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, _settings, _usuarios = auth_client
    response = client.post(
        "/api/v1/auth/login",
        json={
            "correo_institucional": "alumno.central@edu.uaa.mx",
            "password": "AlumnoCentral123!",
        },
    )

    assert response.status_code == 200
    access_token = response.json()["access_token"]
    perfil = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert perfil.status_code == 200
    assert perfil.json()["rol"] == "estudiante"

    sin_token = client.get("/api/v1/auth/me")
    assert sin_token.status_code == 401


def test_login_rechaza_credenciales_invalidas_con_401(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, _settings, _usuarios = auth_client
    response = client.post(
        "/api/v1/auth/login",
        json={
            "correo_institucional": "alumno.central@edu.uaa.mx",
            "password": "Incorrecta123!",
        },
    )

    assert response.status_code == 401


def test_login_rechaza_usuario_inexistente_o_inactivo_con_401(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    client, _settings, usuarios = auth_client
    monkeypatch.setattr(auth_router, "find_auth_user", lambda _correo: None)
    inexistente = client.post(
        "/api/v1/auth/login",
        json={
            "correo_institucional": "no-existe@edu.uaa.mx",
            "password": "AlumnoCentral123!",
        },
    )
    assert inexistente.status_code == 401

    alumno = usuarios["1001"]
    usuario_inactivo = AuthUser(
        id_usuario=alumno.id_usuario,
        correo_institucional=alumno.correo_institucional,
        password_hash=alumno.password_hash,
        rol=alumno.rol,
        activo=False,
        id_campus=alumno.id_campus,
    )
    monkeypatch.setattr(auth_router, "find_auth_user", lambda _correo: usuario_inactivo)
    inactivo = client.post(
        "/api/v1/auth/login",
        json={
            "correo_institucional": usuario_inactivo.correo_institucional,
            "password": "AlumnoCentral123!",
        },
    )
    assert inactivo.status_code == 401


def test_endpoint_por_rol_rechaza_estudiante_con_403(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, _usuarios = auth_client
    token = create_access_token(settings, "1001", "estudiante", 1)

    response = client.get(
        "/api/v1/academico/auditoria",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403


def test_endpoint_por_rol_permite_coordinador(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, _usuarios = auth_client
    token = create_access_token(settings, "3001", "coordinador")

    response = client.get(
        "/api/v1/academico/auditoria",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.parametrize(
    ("authorization", "expected_status"),
    [
        (None, 401),
        ("Basic credencial", 401),
        ("Bearer ", 401),
        ("Bearer token-invalido", 401),
    ],
)
def test_perfil_me_rechaza_solicitudes_sin_access_token_valido(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
    authorization: str | None,
    expected_status: int,
) -> None:
    client, _settings, _usuarios = auth_client
    headers = {} if authorization is None else {"Authorization": authorization}

    response = client.get("/api/v1/auth/me", headers=headers)

    assert response.status_code == expected_status


def test_perfil_me_rechaza_refresh_token_como_access_token(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, _usuarios = auth_client
    refresh = create_refresh_token(settings, "1001", "estudiante")

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {refresh}"},
    )

    assert response.status_code == 401


def test_perfil_me_rechaza_usuario_inexistente_inactivo_y_rol_alterado(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, usuarios = auth_client
    token_usuario_inexistente = create_access_token(settings, "9999", "estudiante")
    respuesta = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token_usuario_inexistente}"},
    )
    assert respuesta.status_code == 401

    alumno = usuarios["1001"]
    usuarios["1001"] = AuthUser(
        id_usuario=alumno.id_usuario,
        correo_institucional=alumno.correo_institucional,
        password_hash=alumno.password_hash,
        rol=alumno.rol,
        activo=False,
        id_campus=alumno.id_campus,
    )
    token_alumno_inactivo = create_access_token(settings, "1001", "estudiante")
    respuesta = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token_alumno_inactivo}"},
    )
    assert respuesta.status_code == 403

    usuarios["1001"] = alumno
    token_rol_alterado = create_access_token(settings, "1001", "coordinador")
    respuesta = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token_rol_alterado}"},
    )
    assert respuesta.status_code == 401


def test_refresh_rechaza_token_invalido_o_de_tipo_access(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, _usuarios = auth_client
    respuestas = [
        client.post("/api/v1/auth/refresh", json={"refresh_token": "token-invalido"}),
        client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": create_access_token(settings, "1001", "estudiante")},
        ),
    ]

    assert [respuesta.status_code for respuesta in respuestas] == [401, 401]


def test_refresh_valido_emite_un_nuevo_access_token(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, _usuarios = auth_client
    refresh = create_refresh_token(settings, "1001", "estudiante")

    response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})

    assert response.status_code == 200
    payload = decode_token(settings, response.json()["access_token"])
    assert payload["sub"] == "1001"
    assert payload["type"] == "access"


def test_refresh_rechaza_usuario_inexistente_inactivo_y_rol_alterado(
    auth_client: tuple[TestClient, Settings, dict[str, AuthUser]],
) -> None:
    client, settings, usuarios = auth_client
    token_inexistente = create_refresh_token(settings, "9999", "estudiante")
    assert client.post(
        "/api/v1/auth/refresh", json={"refresh_token": token_inexistente}
    ).status_code == 401

    alumno = usuarios["1001"]
    usuarios["1001"] = AuthUser(
        id_usuario=alumno.id_usuario,
        correo_institucional=alumno.correo_institucional,
        password_hash=alumno.password_hash,
        rol=alumno.rol,
        activo=False,
        id_campus=alumno.id_campus,
    )
    token_inactivo = create_refresh_token(settings, "1001", "estudiante")
    assert client.post(
        "/api/v1/auth/refresh", json={"refresh_token": token_inactivo}
    ).status_code == 403

    usuarios["1001"] = alumno
    token_rol_alterado = create_refresh_token(settings, "1001", "coordinador")
    assert client.post(
        "/api/v1/auth/refresh", json={"refresh_token": token_rol_alterado}
    ).status_code == 401
