import uuid
from pydantic import BaseModel
from datetime import datetime


class FavoriteResponse(BaseModel):
    id: uuid.UUID
    service_id: uuid.UUID
    fecha_creacion: datetime

    class Config:
        from_attributes = True
