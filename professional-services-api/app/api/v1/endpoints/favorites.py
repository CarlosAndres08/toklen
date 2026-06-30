import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db_session
from app.api.v1.endpoints.auth import get_current_user
from app.schemas.user import UserResponse
from app.schemas.favorite import FavoriteResponse
from app.repositories.favorite_repository import FavoriteRepository
from app.repositories.service_repository import ServiceRepository

router = APIRouter()


@router.post("/{service_id}", response_model=FavoriteResponse, status_code=status.HTTP_201_CREATED)
async def add_favorite(
    service_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    service_repo = ServiceRepository(db)
    service = await service_repo.get_by_id(service_id)
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado.")

    repo = FavoriteRepository(db)
    existing = await repo.is_favorited(current_user.id, service_id)
    if existing:
        raise HTTPException(status_code=409, detail="Ya está en favoritos.")

    fav = await repo.add(current_user.id, service_id)
    return fav


@router.delete("/{service_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    service_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    repo = FavoriteRepository(db)
    removed = await repo.remove(current_user.id, service_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Favorito no encontrado.")
    return None


@router.get("/", response_model=List[FavoriteResponse])
async def list_favorites(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    repo = FavoriteRepository(db)
    return await repo.list_by_user(current_user.id)


@router.get("/check/{service_id}", response_model=bool)
async def check_favorite(
    service_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    repo = FavoriteRepository(db)
    return await repo.is_favorited(current_user.id, service_id)
