import uuid
from typing import List, Tuple

from fastapi import HTTPException, status

from app.models.booking import Booking, BookingStatus
from app.models.review import Review
from app.schemas.review import ReviewCreate, ReviewResponse
from app.schemas.user import UserResponse
from app.repositories.booking_repository import BookingRepository
from app.repositories.review_repository import ReviewRepository


class ReviewManagerException(HTTPException):
    pass


class BookingNotFoundError(ReviewManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found"
        )


class NotBookingClientError(ReviewManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN, detail="Only the booking client can leave a review"
        )


class BookingNotCompletedError(ReviewManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot review a booking that is not completed"
        )


class ReviewAlreadyExistsError(ReviewManagerException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST, detail="A review for this booking already exists"
        )


class ReviewManager:

    def __init__(
        self, booking_repo: BookingRepository, review_repo: ReviewRepository
    ) -> None:
        self.booking_repo = booking_repo
        self.review_repo = review_repo

    async def create_review(
        self, review_data: ReviewCreate, current_user: UserResponse
    ) -> ReviewResponse:
        booking = await self.booking_repo.get_by_id(review_data.booking_id)
        if not booking:
            raise BookingNotFoundError()

        if booking.client_id != current_user.id:
            raise NotBookingClientError()

        if booking.status != BookingStatus.COMPLETED:
            raise BookingNotCompletedError()

        existing_review = await self.review_repo.get_by_booking_id(review_data.booking_id)
        if existing_review:
            raise ReviewAlreadyExistsError()

        review = Review(
            booking_id=review_data.booking_id,
            rating=review_data.rating,
            comment=review_data.comment,
        )
        created_review = await self.review_repo.create(review)
        return ReviewResponse.model_validate(created_review)

    async def get_service_reviews(
        self, service_id: uuid.UUID
    ) -> Tuple[List[ReviewResponse], float | None]:
        reviews = await self.review_repo.list_by_service_id(service_id)
        average_rating = await self.review_repo.get_average_rating_for_service(service_id)
        return [ReviewResponse.model_validate(review) for review in reviews], average_rating
