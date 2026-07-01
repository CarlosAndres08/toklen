import uuid
import os
import shutil
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List

from app.core.database import get_db_session
from app.api.v1.endpoints.auth import get_current_user
from app.repositories.notification_repository import NotificationRepository
from app.models.notification import Notification
from app.schemas.user import UserResponse, UserRole
from app.schemas.admin import (
    AdminUserUpdate,
    AdminUserResponse,
    ProviderAdminResponse,
    SuspendRequest,
    BanRequest,
    VerificationRejectRequest,
    CategoryAdminUpdate,
    ServiceAdminAction,
    CategoryReorderItem,
    ChangeRoleRequest,
)
from app.schemas.analytics import AdminDashboardResponse, TopProvider
from app.schemas.category import CategoryResponse, CategoryCreate
from app.schemas.service import ServiceResponse, ServiceUpdate
from app.services.analytics_service import AnalyticsService
from app.models.user import User
from app.models.badge import Badge
from app.models.category import Category
from app.models.service import Service

router = APIRouter()


def require_admin(current_user: UserResponse = Depends(get_current_user)):
    if current_user.rol != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado. Se requiere rol de administrador."
        )
    return current_user


def get_analytics_service(db: AsyncSession = Depends(get_db_session)) -> AnalyticsService:
    return AnalyticsService(db)


# ─── ADMIN AUTH ─────────────────────────────────────────────────────────────────

@router.get("/me", response_model=UserResponse)
async def get_admin_me(
    admin: UserResponse = Depends(require_admin),
):
    return admin


@router.post("/logout")
async def admin_logout(
    admin: UserResponse = Depends(require_admin),
):
    return {"message": "Sesión cerrada exitosamente"}


# ─── DASHBOARD / REPORTS ────────────────────────────────────────────────────────

@router.get("/dashboard/summary", response_model=AdminDashboardResponse)
async def get_dashboard_summary(
    admin: UserResponse = Depends(require_admin),
    service: AnalyticsService = Depends(get_analytics_service)
):
    return await service.get_admin_dashboard()


@router.get("/reports/top-providers", response_model=List[TopProvider])
async def get_top_providers_report(
    admin: UserResponse = Depends(require_admin),
    service: AnalyticsService = Depends(get_analytics_service)
):
    return await service.get_top_providers()


# ─── USER MANAGEMENT ────────────────────────────────────────────────────────────

@router.get("/users", response_model=List[AdminUserResponse])
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    rol: UserRole | None = None,
    is_verified: bool | None = None,
    is_active: bool | None = None,
    is_suspended: bool | None = None,
    q: str | None = None,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    query = select(User).options(selectinload(User.badges))

    if rol:
        query = query.where(User.rol == rol)
    if is_verified is not None:
        query = query.where(User.is_verified == is_verified)
    if is_active is not None:
        query = query.where(User.is_active == is_active)
    if is_suspended is not None:
        query = query.where(User.is_suspended == is_suspended)
    if q:
        search = f"%{q}%"
        query = query.where(
            (User.nombre.ilike(search)) | (User.email.ilike(search))
        )

    query = query.order_by(User.fecha_creacion.desc())
    query = query.limit(page_size).offset((page - 1) * page_size)

    result = await db.execute(query)
    users = list(result.scalars().all())
    return [AdminUserResponse.model_validate(u) for u in users]


@router.get("/users/{user_id}", response_model=AdminUserResponse)
async def get_user(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(User).options(selectinload(User.badges)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return AdminUserResponse.model_validate(user)


@router.put("/users/{user_id}", response_model=AdminUserResponse)
async def update_user(
    user_id: uuid.UUID,
    data: AdminUserUpdate,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(User).options(selectinload(User.badges)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(user, key, value)

    await db.flush()
    await db.refresh(user)
    return AdminUserResponse.model_validate(user)


@router.delete("/users/{user_id}")
async def delete_user(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if user.rol == UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="No puedes eliminar a otro administrador")

    await db.delete(user)
    await db.flush()
    return {"message": f"Usuario {user.nombre} eliminado correctamente"}


@router.post("/users/{user_id}/suspend")
async def suspend_user(
    user_id: uuid.UUID,
    body: SuspendRequest,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if user.rol == UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="No puedes suspender a otro administrador")

    user.is_suspended = True
    user.is_active = False
    user.suspension_reason = body.reason
    await db.flush()
    return {"message": f"Usuario {user.nombre} suspendido", "is_suspended": True}


@router.post("/users/{user_id}/unsuspend")
async def unsuspend_user(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.is_suspended = False
    user.is_active = True
    user.suspension_reason = None
    await db.flush()
    return {"message": f"Usuario {user.nombre} reactivado", "is_suspended": False}


@router.post("/users/{user_id}/ban")
async def ban_user(
    user_id: uuid.UUID,
    body: BanRequest,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if user.rol == UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="No puedes banear a otro administrador")

    user.is_suspended = True
    user.is_active = False
    user.ban_reason = body.reason
    user.ban_date = datetime.now(timezone.utc) + timedelta(days=body.duration_days)
    user.suspension_reason = body.reason
    await db.flush()
    return {
        "message": f"Usuario {user.nombre} baneado hasta {user.ban_date.isoformat()}",
        "ban_date": user.ban_date.isoformat(),
    }


@router.post("/users/{user_id}/change-role", response_model=AdminUserResponse)
async def change_user_role(
    user_id: uuid.UUID,
    body: ChangeRoleRequest,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(User).options(selectinload(User.badges)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.rol = body.rol
    await db.flush()
    await db.refresh(user)
    return AdminUserResponse.model_validate(user)


# ─── PROVIDER MANAGEMENT ────────────────────────────────────────────────────────

@router.get("/providers", response_model=List[ProviderAdminResponse])
async def list_providers(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    is_verified: bool | None = None,
    is_active: bool | None = None,
    q: str | None = None,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    service_count_subq = (
        select(Service.provider_id, func.count(Service.id).label("total_services"))
        .group_by(Service.provider_id)
        .subquery()
    )

    query = (
        select(User, service_count_subq.c.total_services)
        .select_from(User)
        .outerjoin(service_count_subq, User.id == service_count_subq.c.provider_id)
        .options(selectinload(User.badges))
        .where(User.rol == UserRole.PROVIDER)
    )

    if is_verified is not None:
        query = query.where(User.is_verified == is_verified)
    if is_active is not None:
        query = query.where(User.is_active == is_active)
    if q:
        search = f"%{q}%"
        query = query.where(
            (User.nombre.ilike(search)) | (User.email.ilike(search))
        )

    query = query.order_by(User.fecha_creacion.desc())
    query = query.limit(page_size).offset((page - 1) * page_size)

    result = await db.execute(query)
    rows = result.all()
    response = []
    for row in rows:
        user = row[0]
        total_services = row[1] or 0
        user_data = AdminUserResponse.model_validate(user).model_dump()
        user_data["total_services"] = total_services
        response.append(ProviderAdminResponse(**user_data))
    return response


@router.get("/providers/{user_id}", response_model=ProviderAdminResponse)
async def get_provider(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    service_count_subq = (
        select(Service.provider_id, func.count(Service.id).label("total_services"))
        .where(Service.provider_id == user_id)
        .group_by(Service.provider_id)
        .subquery()
    )

    query = (
        select(User, service_count_subq.c.total_services)
        .select_from(User)
        .outerjoin(service_count_subq, User.id == service_count_subq.c.provider_id)
        .options(selectinload(User.badges))
        .where(User.id == user_id, User.rol == UserRole.PROVIDER)
    )

    result = await db.execute(query)
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado")

    user = row[0]
    total_services = row[1] or 0
    user_data = AdminUserResponse.model_validate(user).model_dump()
    user_data["total_services"] = total_services
    return ProviderAdminResponse(**user_data)


@router.post("/providers/{user_id}/approve-verification")
async def approve_provider_verification(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    badge_result = await db.execute(select(Badge).where(Badge.name == "Identidad Verificada"))
    badge = badge_result.scalar_one_or_none()
    if not badge:
        badge = Badge(
            name="Identidad Verificada",
            icon_url="https://cdn-icons-png.flaticon.com/512/7595/7595571.png"
        )
        db.add(badge)
        await db.flush()

    user.is_verified = True
    if badge not in user.badges:
        user.badges.append(badge)

    # Notificar al proveedor
    notif_repo = NotificationRepository(db)
    await notif_repo.create(
        Notification(
            user_id=user_id,
            title="¡Cuenta Verificada!",
            content="Tu identidad ha sido verificada exitosamente por el equipo de Toklen. Ahora tienes la insignia de confianza en tu perfil."
        )
    )

    return {"message": f"Usuario {user.nombre} verificado exitosamente", "is_verified": True}


@router.post("/providers/{user_id}/reject-verification")
async def reject_provider_verification(
    user_id: uuid.UUID,
    body: VerificationRejectRequest,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    # Notificar al proveedor
    notif_repo = NotificationRepository(db)
    await notif_repo.create(
        Notification(
            user_id=user_id,
            title="Actualización de Verificación",
            content=f"Tu solicitud de verificación no ha sido aprobada por el siguiente motivo: {body.reason}. Por favor, revisa tus documentos e inténtalo nuevamente."
        )
    )

    return {
        "message": f"Verificación de {user.nombre} rechazada: {body.reason}",
        "is_verified": False,
        "reason": body.reason,
    }


@router.get("/providers/pending-verification", response_model=List[AdminUserResponse])
async def get_pending_provider_verifications(
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(User).options(selectinload(User.badges))
        .where(User.rol == UserRole.PROVIDER, User.is_verified == False)
        .order_by(User.fecha_creacion.desc())
    )
    users = list(result.scalars().all())
    return [AdminUserResponse.model_validate(u) for u in users]


@router.delete("/providers/{user_id}")
async def delete_provider(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id, User.rol == UserRole.PROVIDER))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado")

    await db.delete(user)
    await db.flush()
    return {"message": f"Proveedor {user.nombre} eliminado correctamente"}


# ─── VERIFICATION MANAGEMENT (legacy aliases) ────────────────────────────────────

@router.get("/users/pending-verification", response_model=List[AdminUserResponse])
async def get_pending_verifications(
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(User).options(selectinload(User.badges))
        .where(User.rol == UserRole.PROVIDER, User.is_verified == False)
        .order_by(User.fecha_creacion.desc())
    )
    users = list(result.scalars().all())
    return [AdminUserResponse.model_validate(u) for u in users]


@router.post("/users/{user_id}/approve-verification")
async def approve_verification(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    badge_result = await db.execute(select(Badge).where(Badge.name == "Identidad Verificada"))
    badge = badge_result.scalar_one_or_none()
    if not badge:
        badge = Badge(
            name="Identidad Verificada",
            icon_url="https://cdn-icons-png.flaticon.com/512/7595/7595571.png"
        )
        db.add(badge)
        await db.flush()

    user.is_verified = True
    if badge not in user.badges:
        user.badges.append(badge)

    return {"message": f"Usuario {user.nombre} verificado exitosamente", "is_verified": True}


@router.post("/users/{user_id}/reject-verification")
async def reject_verification(
    user_id: uuid.UUID,
    body: VerificationRejectRequest,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return {
        "message": f"Verificación de {user.nombre} rechazada: {body.reason}",
        "is_verified": False,
        "reason": body.reason,
    }


@router.post("/users/{user_id}/verify")
async def verify_provider_identity(
    user_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session)
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    badge_result = await db.execute(select(Badge).where(Badge.name == "Identidad Verificada"))
    badge = badge_result.scalar_one_or_none()
    if not badge:
        badge = Badge(
            name="Identidad Verificada",
            icon_url="https://cdn-icons-png.flaticon.com/512/7595/7595571.png"
        )
        db.add(badge)
        await db.flush()

    user.is_verified = True
    if badge not in user.badges:
        user.badges.append(badge)

    return {
        "message": f"El usuario {user.nombre} ha sido verificado exitosamente.",
        "is_verified": user.is_verified
    }


# ─── CATEGORY MANAGEMENT ────────────────────────────────────────────────────────

@router.put("/categories/reorder")
async def reorder_categories(
    items: List[CategoryReorderItem],
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    for item in items:
        result = await db.execute(select(Category).where(Category.id == item.id))
        category = result.scalar_one_or_none()
        if category:
            category.sort_order = item.sort_order
    await db.flush()
    return {"message": "Categorías reordenadas correctamente"}


@router.get("/categories", response_model=List[CategoryResponse])
async def list_categories(
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(Category).order_by(Category.sort_order, Category.name)
    )
    categories = list(result.scalars().all())
    return [CategoryResponse.model_validate(c) for c in categories]


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    data: CategoryCreate,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    category = Category(
        name=data.name,
        description=data.description,
        image_url=data.image_url,
        icon=data.icon,
        slug=data.slug,
    )
    db.add(category)
    await db.flush()
    await db.refresh(category)
    return CategoryResponse.model_validate(category)


@router.get("/categories/{category_id}", response_model=CategoryResponse)
async def get_category(
    category_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    return CategoryResponse.model_validate(category)


@router.put("/categories/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: uuid.UUID,
    data: CategoryAdminUpdate,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(category, key, value)

    await db.flush()
    await db.refresh(category)
    return CategoryResponse.model_validate(category)


@router.delete("/categories/{category_id}")
async def delete_category(
    category_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")

    await db.delete(category)
    await db.flush()
    return {"message": f"Categoría '{category.name}' eliminada correctamente"}


@router.post("/categories/{category_id}/image", response_model=CategoryResponse)
async def upload_category_image(
    category_id: uuid.UUID,
    file: UploadFile = File(...),
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")

    allowed_formats = ["image/jpeg", "image/png", "image/jpg", "image/webp"]
    if file.content_type not in allowed_formats:
        raise HTTPException(status_code=400, detail="Formato de imagen no permitido. Solo JPG, PNG, WebP.")

    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    upload_dir = os.path.join("static", "uploads", "categories")
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, unique_filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    public_url = f"/static/uploads/categories/{unique_filename}"
    category.image_url = public_url
    await db.flush()
    await db.refresh(category)
    return CategoryResponse.model_validate(category)


@router.post("/categories/{category_id}/approve", response_model=CategoryResponse)
async def approve_category(
    category_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    category.is_approved = True
    await db.flush()
    await db.refresh(category)
    return CategoryResponse.model_validate(category)


@router.post("/categories/{category_id}/reject")
async def reject_category(
    category_id: uuid.UUID,
    body: VerificationRejectRequest,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    category.is_approved = False
    await db.flush()
    return {"message": f"Categoría '{category.name}' rechazada", "reason": body.reason}


@router.get("/categories/pending-approval", response_model=List[CategoryResponse])
async def get_pending_categories(
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(Category).where(Category.is_approved == False).order_by(Category.sort_order, Category.name)
    )
    categories = list(result.scalars().all())
    return [CategoryResponse.model_validate(c) for c in categories]


# ─── SERVICE MANAGEMENT ─────────────────────────────────────────────────────────

@router.get("/services", response_model=List[ServiceResponse])
async def list_services(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    is_active: bool | None = None,
    is_approved: bool | None = None,
    category_id: uuid.UUID | None = None,
    q: str | None = None,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    query = (
        select(Service)
        .options(selectinload(Service.images), selectinload(Service.category), selectinload(Service.provider))
    )

    if is_active is not None:
        query = query.where(Service.is_active == is_active)
    if is_approved is not None:
        query = query.where(Service.is_approved == is_approved)
    if category_id:
        query = query.where(Service.category_id == category_id)
    if q:
        search = f"%{q}%"
        query = query.where(Service.title.ilike(search))

    query = query.order_by(Service.fecha_creacion.desc())
    query = query.limit(page_size).offset((page - 1) * page_size)

    result = await db.execute(query)
    services = list(result.scalars().all())
    return [ServiceResponse.model_validate(s) for s in services]


@router.get("/services/{service_id}", response_model=ServiceResponse)
async def get_service(
    service_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(Service)
        .options(selectinload(Service.images), selectinload(Service.category), selectinload(Service.provider))
        .where(Service.id == service_id)
    )
    service = result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    return ServiceResponse.model_validate(service)


@router.put("/services/{service_id}", response_model=ServiceResponse)
async def update_service(
    service_id: uuid.UUID,
    data: ServiceUpdate,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(Service)
        .options(selectinload(Service.images), selectinload(Service.category), selectinload(Service.provider))
        .where(Service.id == service_id)
    )
    service = result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(service, key, value)

    await db.flush()
    await db.refresh(service)
    return ServiceResponse.model_validate(service)


@router.delete("/services/{service_id}")
async def delete_service(
    service_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Service).where(Service.id == service_id))
    service = result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")

    await db.delete(service)
    await db.flush()
    return {"message": f"Servicio '{service.title}' eliminado correctamente"}


@router.post("/services/{service_id}/approve", response_model=ServiceResponse)
async def approve_service(
    service_id: uuid.UUID,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(Service)
        .options(selectinload(Service.images), selectinload(Service.category), selectinload(Service.provider))
        .where(Service.id == service_id)
    )
    service = result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    service.is_active = True
    service.is_featured = True
    await db.flush()
    await db.refresh(service)
    return ServiceResponse.model_validate(service)


@router.post("/services/{service_id}/reject")
async def reject_service(
    service_id: uuid.UUID,
    body: ServiceAdminAction,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Service).where(Service.id == service_id))
    service = result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    service.is_active = False
    await db.flush()
    return {"message": f"Servicio '{service.title}' rechazado", "reason": body.reason}


@router.post("/services/{service_id}/suspend")
async def suspend_service(
    service_id: uuid.UUID,
    body: ServiceAdminAction,
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(select(Service).where(Service.id == service_id))
    service = result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Servicio no encontrado")
    service.is_active = False
    await db.flush()
    return {"message": f"Servicio '{service.title}' suspendido", "reason": body.reason}


@router.get("/services/pending-approval", response_model=List[ServiceResponse])
async def get_pending_services(
    admin: UserResponse = Depends(require_admin),
    db: AsyncSession = Depends(get_db_session),
):
    result = await db.execute(
        select(Service)
        .options(selectinload(Service.images), selectinload(Service.category), selectinload(Service.provider))
        .where(Service.is_active == True)
        .order_by(Service.fecha_creacion.desc())
    )
    services = list(result.scalars().all())
    return [ServiceResponse.model_validate(s) for s in services]


# ─── FILE UPLOAD ────────────────────────────────────────────────────────────────

@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    admin: UserResponse = Depends(require_admin),
):
    allowed_formats = ["image/jpeg", "image/png", "image/jpg", "image/webp", "application/pdf"]
    if file.content_type not in allowed_formats:
        raise HTTPException(status_code=400, detail="Formato de archivo no permitido")

    file_extension = file.filename.split(".")[-1] if "." in file.filename else "bin"
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    upload_dir = os.path.join("static", "uploads", "categories")
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, unique_filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    public_url = f"/static/uploads/categories/{unique_filename}"
    return {"url": public_url, "filename": unique_filename}
