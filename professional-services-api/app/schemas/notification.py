import uuid
from datetime import datetime
from pydantic import AliasChoices, BaseModel, ConfigDict, Field

class NotificationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    content: str
    sender_id: uuid.UUID | None = None
    is_read: bool
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
