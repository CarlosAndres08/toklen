import uuid
from datetime import datetime
from pydantic import AliasChoices, BaseModel, Field, ConfigDict
from app.schemas.category import CategoryBasic
from app.schemas.badge import BadgeResponse

class ProviderBasic(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    email: str
    profile_picture_url: str | None = None
    is_verified: bool
    is_available: bool = True
    latitude: float | None = None
    longitude: float | None = None
    badges: list[BadgeResponse] = Field(default_factory=list)
    
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ServiceImageResponse(BaseModel):
    id: uuid.UUID
    url: str
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ServiceCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=150)
    description: str = Field(..., min_length=10)
    price: float = Field(..., gt=0)
    category_id: uuid.UUID
    is_active: bool = Field(default=True)
    is_featured: bool = Field(default=False)
    latitude: float | None = None
    longitude: float | None = None

class ServiceUpdate(BaseModel):
    title: str | None = Field(None, min_length=3, max_length=150)
    description: str | None = Field(None, min_length=10)
    price: float | None = Field(None, gt=0)
    is_active: bool | None = None
    is_featured: bool | None = None
    latitude: float | None = None
    longitude: float | None = None

class ServiceResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    price: float
    is_active: bool
    is_featured: bool = False
    is_approved: bool = True
    rejection_reason: str | None = None
    reported_count: int = 0
    latitude: float | None = None
    longitude: float | None = None
    distance: float | None = None
    average_rating: float | None = None
    reviews_count: int = 0
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )
    provider: ProviderBasic
    category: CategoryBasic
    images: list[ServiceImageResponse] = Field(default_factory=list)
    
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
