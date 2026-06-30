import uuid
from datetime import datetime
from typing import Optional
from pydantic import AliasChoices, BaseModel, ConfigDict, Field, model_validator
from app.models.quote import QuoteStatus


class QuoteCreate(BaseModel):
    service_id: uuid.UUID
    description: str = Field(..., min_length=10)


class QuoteRespond(BaseModel):
    """
    Body para responder una cotización.
    - OFFERED / proposed_price → solo proveedor dueño del servicio
    - ACCEPTED                 → solo el cliente que solicitó (requiere start_time)
    - DECLINED / CANCELLED     → cualquier participante
    """
    status: Optional[QuoteStatus] = None
    proposed_price: Optional[float] = Field(default=None, gt=0)
    start_time: Optional[datetime] = None

    @model_validator(mode="after")
    def validate_accept(self) -> "QuoteRespond":
        if self.status == QuoteStatus.ACCEPTED:
            if self.proposed_price is not None:
                raise ValueError(
                    "Al aceptar no se puede modificar el precio. "
                    "Envía solo 'status: accepted'."
                )
            if self.start_time is None:
                raise ValueError(
                    "Al aceptar una cotización debes proporcionar "
                    "una fecha y hora (start_time) para la reserva."
                )
        return self


class QuoteResponse(BaseModel):
    id: uuid.UUID
    service_id: uuid.UUID
    client_id: uuid.UUID
    description: str
    proposed_price: float | None = None
    status: QuoteStatus
    booking_id: uuid.UUID | None = None
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
