import uuid
from datetime import datetime
from pydantic import AliasChoices, BaseModel, ConfigDict, Field

class ChatMessageCreate(BaseModel):
    receiver_id: uuid.UUID
    booking_id: uuid.UUID | None = None
    message: str = Field(..., min_length=1)

class UserBasic(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    profile_picture_url: str | None = None
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ChatMessageResponse(BaseModel):
    id: uuid.UUID
    booking_id: uuid.UUID | None
    sender_id: uuid.UUID
    receiver_id: uuid.UUID
    message: str
    is_read: bool
    fecha_envio: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_envio", "sent_at"),
        serialization_alias="sent_at",
    )
    
    sender: UserBasic
    receiver: UserBasic

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ChatInboxItem(BaseModel):
    user: UserBasic
    last_message: str
    last_message_date: datetime
    unread_count: int

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
