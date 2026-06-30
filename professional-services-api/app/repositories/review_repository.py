import uuid
from typing import List, Tuple

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.review import Review
from app.models.booking import Booking
from app.models.service import Service


class ReviewRepository:

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self, review: Review) -> Review:
        self.db.add(review)
        await self.db.flush()
        await self.db.refresh(review, attribute_names=["booking"])
        return review

    async def get_by_booking_id(self, booking_id: uuid.UUID) -> Review | None:
        result = await self.db.execute(
            select(Review)
            .options(joinedload(Review.booking).joinedload(Booking.client))
            .where(Review.booking_id == booking_id)
        )
        return result.scalar_one_or_none()

    async def list_by_service_id(self, service_id: uuid.UUID) -> List[Review]:
        result = await self.db.execute(
            select(Review)
            .options(joinedload(Review.booking).joinedload(Booking.client))
            .join(Booking, Review.booking_id == Booking.id)
            .where(Booking.service_id == service_id)
            .order_by(Review.fecha_creacion.desc())
        )
        return list(result.scalars().all())

    async def get_average_rating_for_service(self, service_id: uuid.UUID) -> float | None:
        result = await self.db.execute(
            select(func.avg(Review.rating))
            .join(Booking, Review.booking_id == Booking.id)
            .where(Booking.service_id == service_id)
        )
        avg_rating = result.scalar_one_or_none()
        return float(avg_rating) if avg_rating is not None else None
