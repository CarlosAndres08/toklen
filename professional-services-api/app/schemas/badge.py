import uuid
from pydantic import BaseModel, ConfigDict

class BadgeResponse(BaseModel):
    id: uuid.UUID
    name: str
    icon_url: str | None
    
    model_config = ConfigDict(from_attributes=True)