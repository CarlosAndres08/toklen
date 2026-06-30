import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.service import ServiceImage

class ServiceImageRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_many(self, images: list[ServiceImage]) -> list[ServiceImage]:
        """Guarda múltiples imágenes de una vez en la base de datos."""
        self.db.add_all(images)
        await self.db.flush()
        return images

    async def get_by_id(self, image_id: uuid.UUID) -> ServiceImage | None:
        """Busca una imagen específica por su ID."""
        stmt = select(ServiceImage).where(ServiceImage.id == image_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def delete(self, image: ServiceImage) -> None:
        """Elimina la imagen de la base de datos y confirma el borrado."""
        await self.db.delete(image)
        await self.db.flush()