import uuid
from datetime import datetime
from typing import List

from fastapi import HTTPException, status

from app.models.booking import Booking, BookingStatus
from app.models.user import User, UserRole
from app.repositories.booking_repository import BookingRepository
from app.repositories.service_repository import ServiceRepository
from app.repositories.schedule_repository import ScheduleRepository
from app.schemas.booking import BookingCreate, BookingResponse, BookingStatusUpdate
from app.schemas.user import UserResponse


class BookingManagerException(HTTPException):
    pass


class ServiceNotFoundError(BookingManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND, detail="Service not found"
        )


class SelfBookingNotAllowedError(BookingManagerException):
    def __init__(
        self,
    ):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Providers cannot book their own services",
        )


class BookingNotFoundError(BookingManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found"
        )


class NotBookingOwnerError(BookingManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not owner of this booking"
        )


class NotServiceProviderError(BookingManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not the provider of the service for this booking",
        )


class ProviderNotAvailableError(BookingManagerException):
    def __init__(self, reason: str):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=reason,
        )


class BookingManager:

    def __init__(
        self, booking_repo: BookingRepository, service_repo: ServiceRepository, schedule_repo: ScheduleRepository | None = None
    ) -> None:
        self.booking_repo = booking_repo
        self.service_repo = service_repo
        self.schedule_repo = schedule_repo

    async def create_booking(
        self, booking_data: BookingCreate, current_user: UserResponse
    ) -> BookingResponse:
        service = await self.service_repo.get_by_id(booking_data.service_id)
        if not service:
            raise ServiceNotFoundError()

        if service.provider_id == current_user.id:
            raise SelfBookingNotAllowedError()

        # Verificar disponibilidad del proveedor
        if self.schedule_repo:
            available, reason = await self.schedule_repo.check_availability(
                service.provider_id, booking_data.start_time
            )
            if not available:
                raise ProviderNotAvailableError(reason)

        booking = Booking(
            service_id=booking_data.service_id,
            client_id=current_user.id,
            start_time=booking_data.start_time,
            notes=booking_data.notes,
        )
        created_booking = await self.booking_repo.create(booking)
        return BookingResponse.model_validate(created_booking)

    async def get_my_bookings(
        self, current_user: UserResponse
    ) -> List[BookingResponse]:
        bookings = await self.booking_repo.list_by_client(current_user.id)
        return [BookingResponse.model_validate(booking) for booking in bookings]

    async def get_bookings_for_my_services(
        self, current_user: UserResponse
    ) -> List[BookingResponse]:
        if current_user.rol != UserRole.PROVIDER:
            raise NotServiceProviderError()
        bookings = await self.booking_repo.list_by_provider(current_user.id)
        return [BookingResponse.model_validate(booking) for booking in bookings]

    async def update_booking_status(
        self, booking_id: uuid.UUID, status_update: BookingStatusUpdate, current_user: UserResponse
    ) -> BookingResponse:
        booking = await self.booking_repo.get_by_id(booking_id)
        if not booking:
            raise BookingNotFoundError()

        # Only the service provider can update the status
        service = await self.service_repo.get_by_id(booking.service_id)
        if not service or service.provider_id != current_user.id:
            raise NotServiceProviderError()

        updated_booking = await self.booking_repo.update_status(booking, status_update.status)
        return BookingResponse.model_validate(updated_booking)
