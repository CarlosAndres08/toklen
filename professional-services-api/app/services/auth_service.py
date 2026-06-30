"""
services/auth_service.py — Lógica de negocio para autenticación y usuarios.

Reglas de esta capa:
  ✔ No importa nada de FastAPI (Request, Response, status codes).
  ✔ No lanza HTTPException — lanza excepciones de dominio propias.
  ✔ Coordina repositorios; nunca ejecuta queries directamente.
"""

import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt, JWTError
from passlib.context import CryptContext

from app.core.config import settings
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserRegisterRequest, TokenResponse, UserResponse


# ── Excepciones de dominio ────────────────────────────────────────────────────
# Definidas aquí y traducidas a HTTPException en la capa de endpoints.

class EmailAlreadyExistsError(Exception):
    pass

class InvalidCredentialsError(Exception):
    pass

class UserNotFoundError(Exception):
    pass


# ── Hashing de contraseñas ────────────────────────────────────────────────────

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain: str) -> str:
    return _pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


# ── JWT ───────────────────────────────────────────────────────────────────────

def create_access_token(user_id: uuid.UUID) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> uuid.UUID:
    """Decodifica el JWT y retorna el user_id. Lanza JWTError si el token es inválido."""
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    user_id: str | None = payload.get("sub")
    if not user_id:
        raise JWTError("Token sin subject.")
    return uuid.UUID(user_id)


# ── Servicio ──────────────────────────────────────────────────────────────────

class AuthService:

    def __init__(self, repo: UserRepository) -> None:
        self.repo = repo

    async def register(self, data: UserRegisterRequest) -> UserResponse:
        """
        Registra un nuevo usuario.
        Lanza EmailAlreadyExistsError si el email ya está en uso.
        """
        if await self.repo.email_exists(data.email):
            raise EmailAlreadyExistsError(f"El email '{data.email}' ya está registrado.")

        user = User(
            nombre=data.nombre,
            email=data.email,
            password_hash=hash_password(data.password),
            rol=data.rol,
        )
        created = await self.repo.create(user)
        return UserResponse.model_validate(created)

    async def login(self, email: str, password: str) -> TokenResponse:
        """
        Valida credenciales y retorna un JWT.
        Lanza InvalidCredentialsError si email o contraseña son incorrectos.
        """
        user = await self.repo.get_by_email(email)

        # Mensaje genérico — nunca revelar si el email existe o no
        if not user or not verify_password(password, user.password_hash):
            raise InvalidCredentialsError("Credenciales inválidas.")

        token = create_access_token(user.id)
        return TokenResponse(
            access_token=token,
            user=UserResponse.model_validate(user),
        )

    async def get_current_user(self, token: str) -> UserResponse:
        """
        Valida el JWT y retorna el usuario correspondiente.
        Usado por el dependency de autenticación en los endpoints protegidos.
        """
        try:
            user_id = decode_access_token(token)
        except JWTError:
            raise InvalidCredentialsError("Token inválido o expirado.")

        user = await self.repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError("Usuario no encontrado.")

        return UserResponse.model_validate(user)