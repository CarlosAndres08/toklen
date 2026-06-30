"""
endpoints/auth.py — Endpoints HTTP de autenticación.

Responsabilidades de esta capa:
  ✔ Recibir y validar la request HTTP (ya lo hace FastAPI con los schemas).
  ✔ Traducir excepciones de dominio → HTTPException con el status code correcto.
  ✔ Delegar TODA la lógica al AuthService.
  ✔ Retornar la response correcta.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserRegisterRequest, UserResponse, TokenResponse
from app.services.auth_service import (
    AuthService,
    EmailAlreadyExistsError,
    InvalidCredentialsError,
    UserNotFoundError,
)

router = APIRouter()

# Esquema OAuth2 — apunta al endpoint de login para que Swagger genere
# automáticamente el botón "Authorize" en /docs
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# ── Dependency factory ────────────────────────────────────────────────────────
# Construye el servicio con sus dependencias inyectadas.
# FastAPI resuelve get_db_session automáticamente.

def get_auth_service(db: AsyncSession = Depends(get_db_session)) -> AuthService:
    return AuthService(repo=UserRepository(db))


# ── Dependency de usuario autenticado ─────────────────────────────────────────
# Reutilizable en cualquier endpoint que requiera login.

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    try:
        return await service.get_current_user(token)
    except (InvalidCredentialsError, UserNotFoundError) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nuevo usuario",
)
async def register(
    data: UserRegisterRequest,
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    try:
        return await service.register(data)
    except EmailAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Iniciar sesión y obtener JWT",
)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),  # Estándar OAuth2 (username + password)
    service: AuthService = Depends(get_auth_service),
) -> TokenResponse:
    try:
        # OAuth2PasswordRequestForm usa "username" — lo mapeamos a email
        return await service.login(email=form.username, password=form.password)
    except InvalidCredentialsError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Obtener perfil del usuario autenticado",
)
async def get_me(
    current_user: UserResponse = Depends(get_current_user),
) -> UserResponse:
    return current_user