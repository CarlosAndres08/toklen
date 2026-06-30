import uuid
from datetime import datetime
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.schedule import ProviderSchedule
from app.models.booking import Booking

class ScheduleRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_provider_schedule(self, provider_id: uuid.UUID):
        result = await self.db.execute(select(ProviderSchedule).where(ProviderSchedule.provider_id == provider_id))
        return result.scalars().all()

    async def check_availability(self, provider_id: uuid.UUID, start_time: datetime) -> tuple[bool, str]:
        day = start_time.weekday()
        time_val = start_time.time()
        
        schedule_stmt = select(ProviderSchedule).where(
            and_(
                ProviderSchedule.provider_id == provider_id,
                ProviderSchedule.day_of_week == day,
                ProviderSchedule.start_time <= time_val,
                ProviderSchedule.end_time >= time_val,
                ProviderSchedule.is_active == True
            )
        )
        schedule = (await self.db.execute(schedule_stmt)).scalar_one_or_none()
        if not schedule:
            return False, "El proveedor no atiende en ese horario."

        booking_stmt = select(Booking).where(
            and_(
                Booking.service.has(provider_id=provider_id),
                Booking.start_time == start_time,
                Booking.status != "cancelled"
            )
        )
        existing_booking = (await self.db.execute(booking_stmt)).scalar_one_or_none()
        if existing_booking:
            return False, "El proveedor ya tiene una reserva a esta hora."

        return True, "Disponible"