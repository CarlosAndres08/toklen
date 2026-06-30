from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, 
    services, 
    bookings, 
    reviews, 
    categories, 
    users, 
    chat, 
    admin, 
    quotes,
    schedules,
    favorites,
)

api_router = APIRouter()

api_router.include_router(auth.router,       prefix="/auth",       tags=["Auth"])
api_router.include_router(users.router,      prefix="/users",      tags=["Users"])
api_router.include_router(services.router,   prefix="/services",   tags=["Services"])
api_router.include_router(bookings.router,   prefix="/bookings",   tags=["Bookings"])
api_router.include_router(reviews.router,    prefix="/reviews",    tags=["Reviews"])
api_router.include_router(categories.router, prefix="/categories", tags=["Categories"])
api_router.include_router(chat.router,       prefix="/chat",       tags=["Chat & Notifications"])
api_router.include_router(admin.router,      prefix="/admin",      tags=["Admin Analytics"])
api_router.include_router(quotes.router,     prefix="/quotes",     tags=["Quotes & Negotiation"])
api_router.include_router(schedules.router,  prefix="/schedules",  tags=["Schedules"])
api_router.include_router(favorites.router,  prefix="/favorites",  tags=["Favorites"])