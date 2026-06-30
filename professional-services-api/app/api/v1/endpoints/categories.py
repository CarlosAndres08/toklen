from typing import List
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.repositories.category_repository import CategoryRepository
from app.services.category_manager import CategoryManager
from app.schemas.category import CategoryCreate, CategoryResponse
from app.schemas.user import UserResponse, UserRole
from app.api.v1.endpoints.auth import get_current_user

router = APIRouter()


def get_category_manager(db: AsyncSession = Depends(get_db_session)) -> CategoryManager:
    return CategoryManager(repo=CategoryRepository(db))


@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED, summary="Crear categoría")
async def create_category(
    data: CategoryCreate,
    current_user: UserResponse = Depends(get_current_user),
    manager: CategoryManager = Depends(get_category_manager),
) -> CategoryResponse:
    if current_user.rol != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Only admins can create categories")
    return await manager.create(data)


@router.get("/", response_model=List[CategoryResponse], summary="Listar todas las categorías")
async def list_categories(
    manager: CategoryManager = Depends(get_category_manager),
) -> List[CategoryResponse]:
    return await manager.get_all()
