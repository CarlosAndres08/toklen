import uuid
import os
import shutil
from fastapi import UploadFile
from app.models.service import Service, ServiceImage
from app.models.user import UserRole
from app.repositories.service_repository import ServiceRepository
from app.repositories.service_image_repository import ServiceImageRepository
from app.schemas.service import ServiceCreate, ServiceUpdate, ServiceResponse
from app.schemas.user import UserResponse

# ── Excepciones de dominio ────────────────────────────────────────────────────

class NotProviderError(Exception):
    pass

class ServiceNotFoundError(Exception):
    pass

class NotOwnerError(Exception):
    pass

# ── Service Manager ───────────────────────────────────────────────────────────

class ServiceManager:

    def __init__(self, repo: ServiceRepository, image_repo: ServiceImageRepository | None = None) -> None:
        self.repo = repo
        self.image_repo = image_repo

    async def create(self, data: ServiceCreate, current_user: UserResponse) -> ServiceResponse:
        if current_user.rol != UserRole.PROVIDER:
            raise NotProviderError("Solo los proveedores pueden publicar servicios.")

        service = Service(
            title=data.title,
            description=data.description,
            price=data.price,
            category_id=data.category_id,
            is_active=data.is_active,
            provider_id=current_user.id,
            latitude=data.latitude,
            longitude=data.longitude,
        )
        created = await self.repo.create(service)
        return ServiceResponse.model_validate(created)

    async def get_all(
        self,
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
        page: int = 1,
        page_size: int = 20,
    ) -> list[ServiceResponse]:
        services = await self.repo.get_all(
            only_active=True,
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
        return [ServiceResponse.model_validate(s) for s in services]

    async def get_by_id(self, service_id: uuid.UUID) -> ServiceResponse:
        service = await self.repo.get_by_id(service_id)
        if not service:
            raise ServiceNotFoundError(f"Servicio {service_id} no encontrado.")
        return ServiceResponse.model_validate(service)

    async def update(
        self, service_id: uuid.UUID, data: ServiceUpdate, current_user: UserResponse
    ) -> ServiceResponse:
        service = await self.repo.get_by_id(service_id)
        if not service:
            raise ServiceNotFoundError(f"Servicio {service_id} no encontrado.")

        if service.provider_id != current_user.id:
            raise NotOwnerError("No tienes permiso para editar este servicio.")

        updated = await self.repo.update(service, data.model_dump(exclude_none=True))
        return ServiceResponse.model_validate(updated)

    async def delete(self, service_id: uuid.UUID, current_user: UserResponse) -> None:
        service = await self.repo.get_by_id(service_id)
        if not service:
            raise ServiceNotFoundError(f"Servicio {service_id} no encontrado.")

        if service.provider_id != current_user.id:
            raise NotOwnerError("No tienes permiso para eliminar este servicio.")

        await self.repo.delete(service)

    async def get_by_provider(
        self, provider_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> tuple[list[ServiceResponse], int]:
        services, total = await self.repo.get_by_provider(
            provider_id, page=page, page_size=page_size
        )
        return [ServiceResponse.model_validate(s) for s in services], total

    async def upload_gallery_images(
        self, service_id: uuid.UUID, files: list[UploadFile], base_url: str, current_user: UserResponse
    ) -> ServiceResponse:
        service = await self.repo.get_by_id(service_id)
        if not service:
            raise ServiceNotFoundError(f"Servicio {service_id} no encontrado.")

        if service.provider_id != current_user.id:
            raise NotOwnerError("No tienes permiso para modificar esta galería.")

        upload_dir = os.path.join("static", "uploads", "services")
        os.makedirs(upload_dir, exist_ok=True)

        new_images = []
        for file in files:
            file_extension = file.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4()}.{file_extension}"
            file_path = os.path.join(upload_dir, unique_filename)

            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

            public_url = f"{base_url}/static/uploads/services/{unique_filename}"
            new_images.append(ServiceImage(service_id=service_id, url=public_url))

        if self.image_repo:
            await self.image_repo.create_many(new_images)
        
        updated_service = await self.repo.get_by_id(service_id)
        return ServiceResponse.model_validate(updated_service)

    async def delete_gallery_image(
        self, service_id: uuid.UUID, image_id: uuid.UUID, current_user: UserResponse
    ) -> None:
        service = await self.repo.get_by_id(service_id)
        if not service:
            raise ServiceNotFoundError(f"Servicio {service_id} no encontrado.")

        if service.provider_id != current_user.id:
            raise NotOwnerError("No tienes permiso para modificar esta galería.")

        if self.image_repo:
            image = await self.image_repo.get_by_id(image_id)
            if image and image.service_id == service_id:
                filename = image.url.split("/")[-1]
                file_path = os.path.join("static", "uploads", "services", filename)
                if os.path.exists(file_path):
                    os.remove(file_path)
                
                await self.image_repo.delete(image)