import uuid
from typing import List

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.v1.endpoints.auth import get_current_user
from app.repositories.booking_repository import BookingRepository
from app.repositories.review_repository import ReviewRepository
from app.services.review_manager import (
    ReviewManager,
    BookingNotFoundError,
    NotBookingClientError,
    BookingNotCompletedError,
    ReviewAlreadyExistsError,
)
from app.schemas.review import ReviewCreate, ReviewUpdate, ReviewResponse
from app.schemas.user import UserResponse

router = APIRouter()


async def get_review_manager(
    db: AsyncSession = Depends(get_db_session),
) -> ReviewManager:
    booking_repo = BookingRepository(db)
    review_repo = ReviewRepository(db)
    return ReviewManager(booking_repo, review_repo)


@router.post(
    "/", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED
)
async def create_review(
    review_data: ReviewCreate,
    current_user: UserResponse = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager),
):
    try:
        return await review_manager.create_review(review_data, current_user)
    except (BookingNotFoundError, NotBookingClientError, BookingNotCompletedError, ReviewAlreadyExistsError) as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)


@router.put("/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: uuid.UUID,
    review_data: ReviewUpdate,
    current_user: UserResponse = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager),
):
    try:
        return await review_manager.update_review(review_id, review_data, current_user)
    except (ReviewNotFoundError, ReviewNotOwnedError) as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager),
):
    try:
        await review_manager.delete_review(review_id, current_user)
    except (ReviewNotFoundError, ReviewNotOwnedError) as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)


@router.get(
    "/service/{service_id}", response_model=List[ReviewResponse]
)
async def get_service_reviews(
    service_id: uuid.UUID,
    review_manager: ReviewManager = Depends(get_review_manager),
):
    reviews, average_rating = await review_manager.get_service_reviews(service_id)
    # Puedes optar por devolver la calificación promedio en los headers o en un modelo de respuesta personalizado.
    # Por simplicidad, por ahora solo se devuelve la lista de reseñas según el esquema.
    return reviews
