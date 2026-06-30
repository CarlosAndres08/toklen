import uuid
from datetime import datetime
from pydantic import AliasChoices, BaseModel, EmailStr, Field, ConfigDict
from app.models.user import UserRole
from app.schemas.badge import BadgeResponse

class UserRegisterRequest(BaseModel):
    nombre: str = Field(
        ...,
        min_length=2,
        max_length=100,
        validation_alias=AliasChoices("name", "nombre"),
        serialization_alias="name",
    )
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=64)
    rol: UserRole = Field(
        default=UserRole.CLIENT,
        validation_alias=AliasChoices("role", "rol"),
        serialization_alias="role",
    )

    model_config = ConfigDict(populate_by_name=True)

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    nombre: str | None = Field(
        None,
        min_length=2,
        max_length=100,
        validation_alias=AliasChoices("name", "nombre"),
        serialization_alias="name",
    )
    email: EmailStr | None = None
    phone: str | None = Field(None, max_length=20)
    bio: str | None = None
    address: str | None = Field(None, max_length=255)
    latitude: float | None = None
    longitude: float | None = None
    service_radius: float | None = Field(None, gt=0)
    profile_picture_url: str | None = Field(None, max_length=255)
    is_available: bool | None = None

    model_config = ConfigDict(populate_by_name=True)

class UserResponse(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    email: str
    rol: UserRole = Field(
        ...,
        validation_alias=AliasChoices("rol", "role"),
        serialization_alias="role",
    )
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )
    phone: str | None = None
    bio: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    service_radius: float | None = None
    profile_picture_url: str | None = None
    is_verified: bool
    is_available: bool = True
    id_document_url: str | None = None
    badges: list[BadgeResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ProviderProfileResponse(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    email: str
    profile_picture_url: str | None = None
    is_verified: bool
    bio: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    service_radius: float | None = None
    badges: list[BadgeResponse] = Field(default_factory=list)
    is_available: bool = True
    total_services: int = 0
    average_rating: float | None = None
    total_reviews: int = 0
    services: list["ServiceResponse"] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# Resolver forward reference circular import
from app.schemas.service import ServiceResponse
ProviderProfileResponse.model_rebuild()
