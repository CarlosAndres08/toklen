import uuid
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Request, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.repositories.user_repository import UserRepository
from app.repositories.service_repository import ServiceRepository
from app.schemas.user import UserResponse, UserUpdate, ProviderProfileResponse
from app.schemas.badge import BadgeResponse
from app.schemas.service import ServiceResponse
from app.services.user_manager import UserManager, UserNotFoundError, InvalidImageFormatError
from app.services.service_manager import ServiceManager
from app.api.v1.endpoints.auth import get_current_user

router = APIRouter()

def get_user_manager(db: AsyncSession = Depends(get_db_session)) -> UserManager:
    return UserManager(repo=UserRepository(db))

def get_service_manager(db: AsyncSession = Depends(get_db_session)) -> ServiceManager:
    return ServiceManager(repo=ServiceRepository(db))


@router.get("/{provider_id}/profile", response_model=ProviderProfileResponse, summary="Perfil público de un proveedor")
async def get_provider_profile(
    provider_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user_manager: UserManager = Depends(get_user_manager),
    service_manager: ServiceManager = Depends(get_service_manager),
) -> ProviderProfileResponse:
    user = await user_manager.repo.get_by_id(provider_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proveedor no encontrado.")
    services, total = await service_manager.get_by_provider(provider_id, page=page, page_size=page_size)
    # Compute average rating across provider's services
    ratings = [s.average_rating for s in services if s.average_rating is not None]
    avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else None
    total_reviews = sum(s.reviews_count for s in services)
    return ProviderProfileResponse(
        id=user.id,
        nombre=user.nombre,
        email=user.email,
        profile_picture_url=user.profile_picture_url,
        is_verified=user.is_verified,
        bio=user.bio,
        latitude=user.latitude,
        longitude=user.longitude,
        service_radius=user.service_radius,
        badges=[BadgeResponse.model_validate(b) for b in (user.badges or [])],
        total_services=total,
        average_rating=avg_rating,
        total_reviews=total_reviews,
        services=services,
    )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Obtener perfil del usuario autenticado",
)
async def get_my_profile(
    current_user: UserResponse = Depends(get_current_user),
    manager: UserManager = Depends(get_user_manager),
) -> UserResponse:
    try:
        return await manager.get_profile(current_user.id)
    except UserNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.put("/me/availability", response_model=UserResponse, summary="Alternar disponibilidad del proveedor")
async def toggle_availability(
    current_user: UserResponse = Depends(get_current_user),
    manager: UserManager = Depends(get_user_manager),
) -> UserResponse:
    user = await manager.repo.get_by_id(current_user.id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado.")
    user.is_available = not user.is_available
    updated = await manager.repo.update(user)
    return UserResponse.model_validate(updated)


@router.put(
    "/me",
    response_model=UserResponse,
    summary="Actualizar perfil del usuario autenticado",
)
async def update_my_profile(
    data: UserUpdate,
    current_user: UserResponse = Depends(get_current_user),
    manager: UserManager = Depends(get_user_manager),
) -> UserResponse:
    try:
        return await manager.update_profile(current_user.id, data)
    except UserNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post(
    "/me/profile-picture",
    response_model=UserResponse,
    summary="Subir foto de perfil del usuario autenticado",
    status_code=status.HTTP_200_OK,
)
async def upload_my_profile_picture(
    
    request: Request , # Corrección: Inyección correcta del objeto Request
    file: UploadFile = File(...),
    current_user: UserResponse = Depends(get_current_user),
    manager: UserManager = Depends(get_user_manager),
) -> UserResponse:
    try:
        # Construir la base URL dinámicamente
        base_url = str(request.base_url).rstrip("/")
        return await manager.upload_profile_picture(current_user.id, file, base_url)
    except UserNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidImageFormatError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error al subir la imagen: {e}")
