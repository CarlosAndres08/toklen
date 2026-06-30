import uuid
from datetime import datetime
from enum import Enum as PyEnum
from sqlalchemy import String, Text, Float, ForeignKey, DateTime, func, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class QuoteStatus(str, PyEnum):
    REQUESTED = "requested"
    OFFERED   = "offered"
    ACCEPTED  = "accepted"
    DECLINED  = "declined"
    CANCELLED = "cancelled"   # ← NUEVO: para cancelaciones explícitas


class ServiceQuote(Base):
    __tablename__ = "service_quotes"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    service_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("services.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    proposed_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[QuoteStatus] = mapped_column(
        Enum(QuoteStatus), default=QuoteStatus.REQUESTED
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("bookings.id", ondelete="SET NULL"), nullable=True,
    )
    fecha_creacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    service: Mapped["Service"] = relationship("Service")
    client: Mapped["User"] = relationship("User")
