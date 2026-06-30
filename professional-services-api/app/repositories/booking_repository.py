import uuid
from datetime import datetime
from typing import List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload

from app.models.booking import Booking, BookingStatus
from app.models.service import Service
from app.models.user import User


class BookingRepository:

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self, booking: Booking) -> Booking:
        self.db.add(booking)
        await self.db.flush()
        result = await self.db.execute(
            select(Booking)
            .options(
                joinedload(Booking.service),
                selectinload(Booking.service, Service.provider),
                joinedload(Booking.client),
            )
            .where(Booking.id == booking.id)
        )
        return result.scalar_one()

    async def get_by_id(self, booking_id: uuid.UUID) -> Booking | None:
        result = await self.db.execute(
            select(Booking)
            .options(
                joinedload(Booking.service),
                selectinload(Booking.service, Service.provider),
                joinedload(Booking.client),
            )
            .where(Booking.id == booking_id)
        )
        return result.scalar_one_or_none()

    async def list_by_client(self, client_id: uuid.UUID) -> List[Booking]:
        result = await self.db.execute(
            select(Booking)
            .options(
                joinedload(Booking.service),
                selectinload(Booking.service, Service.provider),
                joinedload(Booking.client),
            )
            .where(Booking.client_id == client_id)
            .order_by(Booking.fecha_creacion.desc())
        )
        return list(result.scalars().all())

    async def list_by_provider(self, provider_id: uuid.UUID) -> List[Booking]:
        result = await self.db.execute(
            select(Booking)
            .options(
                joinedload(Booking.service),
                selectinload(Booking.service, Service.provider),
                joinedload(Booking.client),
            )
            .join(Service, Booking.service_id == Service.id)
            .where(Service.provider_id == provider_id)
            .order_by(Booking.fecha_creacion.desc())
        )
        return list(result.scalars().all())

    async def update_status(self, booking: Booking, new_status: BookingStatus) -> Booking:
        booking.status = new_status
        await self.db.flush()
        result = await self.db.execute(
            select(Booking)
            .options(
                joinedload(Booking.service),
                selectinload(Booking.service, Service.provider),
                joinedload(Booking.client),
            )
            .where(Booking.id == booking.id)
        )
        return result.scalar_one()
