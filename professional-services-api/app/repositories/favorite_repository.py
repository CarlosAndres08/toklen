import uuid
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.favorite import Favorite


class FavoriteRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def add(self, user_id: uuid.UUID, service_id: uuid.UUID) -> Favorite:
        fav = Favorite(user_id=user_id, service_id=service_id)
        self.db.add(fav)
        await self.db.flush()
        await self.db.refresh(fav)
        return fav

    async def remove(self, user_id: uuid.UUID, service_id: uuid.UUID) -> bool:
        result = await self.db.execute(
            delete(Favorite).where(
                Favorite.user_id == user_id,
                Favorite.service_id == service_id,
            )
        )
        return result.rowcount > 0

    async def list_by_user(self, user_id: uuid.UUID) -> list[Favorite]:
        result = await self.db.execute(
            select(Favorite)
            .where(Favorite.user_id == user_id)
            .order_by(Favorite.fecha_creacion.desc())
        )
        return result.scalars().all()

    async def is_favorited(self, user_id: uuid.UUID, service_id: uuid.UUID) -> bool:
        result = await self.db.execute(
            select(Favorite).where(
                Favorite.user_id == user_id,
                Favorite.service_id == service_id,
            )
        )
        return result.scalar_one_or_none() is not None
