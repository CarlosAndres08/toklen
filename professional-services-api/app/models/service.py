import uuid
from datetime import datetime

from sqlalchemy import String, Text, Float, Boolean, ForeignKey, DateTime, func, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID

from app.core.database import Base


class Service(Base):
    __tablename__ = "services"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True,
    )
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_featured: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)

    # --- ADMIN / MODERATION ---
    is_approved: Mapped[bool] = mapped_column(Boolean, default=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    reported_count: Mapped[int] = mapped_column(Integer, default=0)

    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("categories.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    provider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    # Relationships
    provider: Mapped["User"] = relationship("User", back_populates="services", lazy="selectin")  # type: ignore
    category: Mapped["Category"] = relationship("Category", back_populates="services", lazy="selectin") # type: ignore
    bookings: Mapped[list["Booking"]] = relationship("Booking", back_populates="service", cascade="all, delete-orphan") # type: ignore
    
    # Nueva relación para la galería de imágenes
    images: Mapped[list["ServiceImage"]] = relationship(
        "ServiceImage", back_populates="service", cascade="all, delete-orphan", lazy="selectin"
    )

    fecha_creacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    def __repr__(self) -> str:
        return f"<Service id={self.id} title={self.title!r}>"


class ServiceImage(Base):
    __tablename__ = "service_images"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True,
    )
    service_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("services.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    url: Mapped[str] = mapped_column(String(255), nullable=False)
    
    # Relationship
    service: Mapped["Service"] = relationship("Service", back_populates="images")

    fecha_creacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    def __repr__(self) -> str:
        return f"<ServiceImage id={self.id} service_id={self.service_id} url={self.url!r}>"
