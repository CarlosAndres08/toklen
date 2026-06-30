import uuid
from datetime import datetime
from typing import Optional

from pydantic import AliasChoices, BaseModel, ConfigDict, Field

from app.schemas.booking import ClientBasic


class ReviewCreate(BaseModel):
    booking_id: uuid.UUID
    rating: int = Field(..., ge=1, le=5, description="Rating must be between 1 and 5")
    comment: Optional[str] = Field(None, max_length=1000)


class BookingBasicForReview(BaseModel):
    id: uuid.UUID
    start_time: datetime
    status: str
    client: ClientBasic

    model_config = ConfigDict(from_attributes=True)


class ReviewResponse(BaseModel):
    id: uuid.UUID
    booking_id: uuid.UUID
    rating: int
    comment: Optional[str] = None
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )

    booking: BookingBasicForReview

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
