import uuid
from datetime import datetime
from typing import Optional

from pydantic import AliasChoices, BaseModel, ConfigDict, Field

from app.models.booking import BookingStatus
from app.schemas.service import ServiceResponse
from app.schemas.user import UserResponse


class BookingCreate(BaseModel):
    service_id: uuid.UUID
    start_time: datetime
    notes: Optional[str] = Field(None, max_length=1000)
class BookingStatusUpdate(BaseModel):
    status: BookingStatus


class ClientBasic(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    email: str

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ServiceBasic(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    price: float

    model_config = ConfigDict(from_attributes=True)


class ProviderBasic(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    email: str
    profile_picture_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class BookingResponse(BaseModel):
    id: uuid.UUID
    service_id: uuid.UUID
    client_id: uuid.UUID
    start_time: datetime
    status: BookingStatus
    notes: Optional[str] = None
    negotiated_price: Optional[float] = None
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )

    service: ServiceBasic
    client: ClientBasic
    provider: ProviderBasic

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
