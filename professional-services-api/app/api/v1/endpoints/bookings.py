import uuid
from typing import List

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.v1.endpoints.auth import get_current_user
from app.repositories.booking_repository import BookingRepository
from app.repositories.service_repository import ServiceRepository
from app.repositories.schedule_repository import ScheduleRepository
from app.services.booking_manager import BookingManager, ServiceNotFoundError, SelfBookingNotAllowedError, ProviderNotAvailableError, BookingNotFoundError, NotBookingOwnerError, NotServiceProviderError
from app.schemas.booking import BookingCreate, BookingResponse, BookingStatusUpdate
from app.schemas.user import UserResponse

router = APIRouter()


async def get_booking_manager(
    db: AsyncSession = Depends(get_db_session),
) -> BookingManager:
    booking_repo = BookingRepository(db)
    service_repo = ServiceRepository(db)
    schedule_repo = ScheduleRepository(db)
    return BookingManager(booking_repo, service_repo, schedule_repo)


@router.post(
    "/", response_model=BookingResponse, status_code=status.HTTP_201_CREATED
)
async def create_booking(
    booking_data: BookingCreate,
    current_user: UserResponse = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager),
):
    try:
        return await booking_manager.create_booking(booking_data, current_user)
    except ServiceNotFoundError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)
    except SelfBookingNotAllowedError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)
    except ProviderNotAvailableError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)


@router.get(
    "/my-bookings", response_model=List[BookingResponse]
)
async def get_my_bookings(
    current_user: UserResponse = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager),
):
    return await booking_manager.get_my_bookings(current_user)


@router.get(
    "/requests", response_model=List[BookingResponse]
)
async def get_bookings_for_my_services(
    current_user: UserResponse = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager),
):
    try:
        return await booking_manager.get_bookings_for_my_services(current_user)
    except NotServiceProviderError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)


@router.patch(
    "/{booking_id}/status", response_model=BookingResponse
)
async def update_booking_status(
    booking_id: uuid.UUID,
    status_update: BookingStatusUpdate,
    current_user: UserResponse = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager),
):
    try:
        return await booking_manager.update_booking_status(booking_id, status_update, current_user)
    except BookingNotFoundError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)
    except NotServiceProviderError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)
