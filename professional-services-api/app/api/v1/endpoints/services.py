import uuid
import traceback
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Request, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.repositories.service_repository import ServiceRepository
from app.repositories.service_image_repository import ServiceImageRepository
from app.services.service_manager import ServiceManager, NotProviderError, ServiceNotFoundError, NotOwnerError
from app.schemas.service import ServiceCreate, ServiceUpdate, ServiceResponse
from app.schemas.user import UserResponse
from app.api.v1.endpoints.auth import get_current_user

router = APIRouter()

def get_service_manager(db: AsyncSession = Depends(get_db_session)) -> ServiceManager:
    return ServiceManager(
        repo=ServiceRepository(db),
        image_repo=ServiceImageRepository(db)
    )

@router.post("/", response_model=ServiceResponse, status_code=status.HTTP_201_CREATED, summary="Crear servicio")
async def create_service(
    data: ServiceCreate,
    current_user: UserResponse = Depends(get_current_user),
    manager: ServiceManager = Depends(get_service_manager),
) -> ServiceResponse:
    try:
        return await manager.create(data, current_user)
    except NotProviderError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))

@router.get("/", response_model=list[ServiceResponse], summary="Listar y buscar servicios")
async def list_services(
    category_id: uuid.UUID | None = None,
    min_price: float | None = None,
    max_price: float | None = None,
    min_rating: float | None = None,
    q: str | None = None,
    lat: float | None = None,
    lng: float | None = None,
    radius: float | None = None,
    sort_by: str | None = None,
    featured: bool | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    manager: ServiceManager = Depends(get_service_manager),
) -> list[ServiceResponse]:
    return await manager.get_all(
        category_id=category_id,
        min_price=min_price,
        max_price=max_price,
        min_rating=min_rating,
        q=q,
        lat=lat,
        lng=lng,
        radius=radius,
        sort_by=sort_by,
        featured=featured,
        page=page,
        page_size=page_size,
    )

@router.get("/{service_id}", response_model=ServiceResponse, summary="Detalle de un servicio")
async def get_service(
    service_id: uuid.UUID,
    manager: ServiceManager = Depends(get_service_manager),
) -> ServiceResponse:
    try:
        return await manager.get_by_id(service_id)
    except ServiceNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.put("/{service_id}", response_model=ServiceResponse, summary="Editar servicio")
async def update_service(
    service_id: uuid.UUID,
    data: ServiceUpdate,
    current_user: UserResponse = Depends(get_current_user),
    manager: ServiceManager = Depends(get_service_manager),
) -> ServiceResponse:
    try:
        return await manager.update(service_id, data, current_user)
    except ServiceNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except NotOwnerError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))

@router.delete("/{service_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Eliminar servicio")
async def delete_service(
    service_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    manager: ServiceManager = Depends(get_service_manager),
) -> None:
    try:
        await manager.delete(service_id, current_user)
    except ServiceNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except NotOwnerError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))

@router.post("/{service_id}/gallery", response_model=ServiceResponse, summary="Subir imágenes a la galería")
async def upload_gallery(
    service_id: uuid.UUID,
    request: Request,
    files: list[UploadFile] = File(...),
    current_user: UserResponse = Depends(get_current_user),
    manager: ServiceManager = Depends(get_service_manager),
) -> ServiceResponse:
    try:
        base_url = str(request.base_url).rstrip("/")
        return await manager.upload_gallery_images(service_id, files, base_url, current_user)
    except ServiceNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except NotOwnerError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error al subir imágenes: {e}")

@router.delete("/{service_id}/gallery/{image_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Eliminar imagen de la galería")
async def delete_gallery_image_endpoint(
    service_id: uuid.UUID,
    image_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    manager: ServiceManager = Depends(get_service_manager),
) -> None:
    try:
        await manager.delete_gallery_image(service_id, image_id, current_user)
    except ServiceNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except NotOwnerError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except Exception as e:
        # 🔥 AQUÍ ESTÁ LA ALARMA QUE NOS DIRÁ QUÉ FALLA EXACTAMENTE
        print(f"\n💥 ERROR FATAL AL BORRAR: {e}\n")
        traceback.print_exc()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error interno: {e}")