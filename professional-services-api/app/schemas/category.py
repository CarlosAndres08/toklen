import uuid
from typing import Optional
from pydantic import BaseModel, ConfigDict


class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    icon: Optional[str] = None
    slug: Optional[str] = None


class CategoryResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    icon: Optional[str] = None
    slug: Optional[str] = None
    is_active: bool = True
    is_featured: bool = False
    is_approved: bool = True

    model_config = ConfigDict(from_attributes=True)


class CategoryBasic(BaseModel):
    id: uuid.UUID
    name: str

    model_config = ConfigDict(from_attributes=True)
