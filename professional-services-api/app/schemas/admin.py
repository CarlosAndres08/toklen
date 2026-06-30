import uuid
from datetime import datetime
from pydantic import AliasChoices, BaseModel, Field, ConfigDict
from typing import Optional
from app.models.user import UserRole


class AdminUserUpdate(BaseModel):
    nombre: str | None = Field(
        None, min_length=2, max_length=100,
        validation_alias=AliasChoices("name", "nombre"),
        serialization_alias="name",
    )
    apellido: str | None = Field(None, min_length=1, max_length=100)
    email: str | None = None
    rol: UserRole | None = Field(
        None,
        validation_alias=AliasChoices("role", "rol"),
        serialization_alias="role",
    )
    is_verified: bool | None = None
    is_active: bool | None = None
    is_suspended: bool | None = None
    suspension_reason: str | None = None
    phone: str | None = None
    bio: str | None = None
    address: str | None = None
    profile_picture_url: str | None = None
    is_available: bool | None = None

    model_config = ConfigDict(populate_by_name=True)


class AdminUserResponse(BaseModel):
    id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    apellido: str | None = None
    email: str
    rol: UserRole = Field(
        ...,
        validation_alias=AliasChoices("rol", "role"),
        serialization_alias="role",
    )
    is_verified: bool
    is_active: bool
    is_suspended: bool
    suspension_reason: str | None = None
    ban_date: datetime | None = None
    ban_reason: str | None = None
    is_available: bool = True
    phone: str | None = None
    bio: str | None = None
    address: str | None = None
    profile_picture_url: str | None = None
    id_document_url: str | None = None
    fecha_creacion: datetime = Field(
        ...,
        validation_alias=AliasChoices("fecha_creacion", "created_at"),
        serialization_alias="created_at",
    )
    last_login: datetime | None = None
    login_count: int = 0

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class SuspendRequest(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)


class BanRequest(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)
    duration_days: int = Field(default=30, ge=1, le=3650)


class VerificationRejectRequest(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)


class CategoryAdminUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = None
    image_url: str | None = None
    icon: str | None = None
    is_active: bool | None = None
    is_featured: bool | None = None
    is_approved: bool | None = None
    slug: str | None = None

    model_config = ConfigDict(populate_by_name=True)


class ServiceAdminAction(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)


class ProviderAdminResponse(AdminUserResponse):
    total_services: int = 0


class CategoryReorderItem(BaseModel):
    id: uuid.UUID
    sort_order: int


class ChangeRoleRequest(BaseModel):
    rol: UserRole
