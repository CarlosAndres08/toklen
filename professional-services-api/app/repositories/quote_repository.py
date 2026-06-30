import uuid
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.quote import ServiceQuote, QuoteStatus
from app.models.service import Service
from app.models.booking import Booking, BookingStatus


class QuoteRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, quote: ServiceQuote) -> ServiceQuote:
        self.db.add(quote)
        await self.db.flush()
        await self.db.refresh(quote)
        return quote

    async def get_by_id(self, quote_id: uuid.UUID) -> ServiceQuote | None:
        """Carga básica sin relaciones."""
        result = await self.db.execute(
            select(ServiceQuote).where(ServiceQuote.id == quote_id)
        )
        return result.scalar_one_or_none()

    async def get_by_id_with_service(self, quote_id: uuid.UUID) -> ServiceQuote | None:
        """
        Carga la cotización + su Service en una sola query (selectinload).
        Necesario para leer quote.service.provider_id sin lazy load async.
        """
        result = await self.db.execute(
            select(ServiceQuote)
            .options(selectinload(ServiceQuote.service))
            .where(ServiceQuote.id == quote_id)
        )
        return result.scalar_one_or_none()

    async def update_status(
        self,
        quote: ServiceQuote,
        status: QuoteStatus,
        price: float | None = None,
    ) -> ServiceQuote:
        quote.status = status
        if price is not None:
            quote.proposed_price = price
        await self.db.flush()
        return quote

    async def list_by_client(self, client_id: uuid.UUID) -> list[ServiceQuote]:
        result = await self.db.execute(
            select(ServiceQuote)
            .options(selectinload(ServiceQuote.service))
            .where(ServiceQuote.client_id == client_id)
            .order_by(ServiceQuote.fecha_creacion.desc())
        )
        return result.scalars().all()

    async def list_by_service_provider(self, provider_id: uuid.UUID) -> list[ServiceQuote]:
        result = await self.db.execute(
            select(ServiceQuote)
            .options(selectinload(ServiceQuote.service))
            .join(ServiceQuote.service)
            .where(Service.provider_id == provider_id)
            .order_by(ServiceQuote.fecha_creacion.desc())
        )
        return result.scalars().all()

    async def accept_and_book(self, quote: ServiceQuote, start_time) -> Booking:
        new_booking = Booking(
            service_id=quote.service_id,
            client_id=quote.client_id,
            start_time=start_time,
            status=BookingStatus.CONFIRMED,
            negotiated_price=quote.proposed_price,
            notes=f"Generado desde cotización. Descripción original: {quote.description}",
        )
        self.db.add(new_booking)
        await self.db.flush()
        quote.status = QuoteStatus.ACCEPTED
        quote.booking_id = new_booking.id
        return new_booking