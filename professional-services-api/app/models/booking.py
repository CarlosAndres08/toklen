import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import String, Text, ForeignKey, DateTime, func, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID

from app.core.database import Base
from app.models.user import User


class BookingStatus(str, PyEnum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


class Booking(Base):
    __tablename__ = "bookings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True,
    )
    service_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("services.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, name="booking_status_enum"), nullable=False, default=BookingStatus.PENDING,
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    negotiated_price: Mapped[float | None] = mapped_column(nullable=True)

    # Relationships
    service: Mapped["Service"] = relationship("Service", back_populates="bookings", lazy="selectin") # type: ignore
    client: Mapped["User"] = relationship("User", back_populates="bookings", lazy="selectin") # type: ignore
    review: Mapped["Review"] = relationship("Review", back_populates="booking", uselist=False, cascade="all, delete-orphan") # type: ignore


    fecha_creacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    @property
    def provider(self) -> "User | None":  # type: ignore
        return self.service.provider if self.service else None

    def __repr__(self) -> str:
        return f"<Booking id={self.id} service_id={self.service_id} client_id={self.client_id} status={self.status.value}>"
