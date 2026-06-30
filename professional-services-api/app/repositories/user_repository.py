"""
repositories/user_repository.py — Única capa que habla con la BD para User.

Reglas de esta capa:
  ✔ Solo recibe y retorna modelos ORM (User) o tipos primitivos.
  ✔ No conoce nada de HTTP, schemas Pydantic ni lógica de negocio.
  ✔ Toda query usa la AsyncSession inyectada — nunca crea sus propias sesiones.
"""

import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepository:

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ── Lecturas ──────────────────────────────────────────────────────────────

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def list_all(self, limit: int = 20, offset: int = 0) -> list[User]:
        result = await self.db.execute(
            select(User).order_by(User.fecha_creacion.desc()).limit(limit).offset(offset)
        )
        return list(result.scalars().all())

    # ── Escrituras ────────────────────────────────────────────────────────────

    async def create(self, user: User) -> User:
        """
        Persiste un User ya construido.
        El commit lo hace la sesión en get_db_session() al finalizar el request.
        """
        self.db.add(user)
        await self.db.flush()   # Envía el INSERT a PG y obtiene el ID generado,
                                # pero sin confirmar la transacción todavía.
        await self.db.refresh(user)  # Recarga server_defaults (fecha_creacion, etc.)
        return user

    async def update(self, user: User) -> User:
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def delete(self, user: User) -> None:
        await self.db.delete(user)
        await self.db.flush()

    # ── Utilidades ────────────────────────────────────────────────────────────

    async def email_exists(self, email: str) -> bool:
        result = await self.db.execute(
            select(User.id).where(User.email == email)
        )
        return result.scalar_one_or_none() is not None