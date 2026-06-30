import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db_session
from app.api.v1.endpoints.auth import get_current_user
from app.schemas.user import UserResponse, UserRole
from app.schemas.schedule import ScheduleCreate, ScheduleResponse
from app.repositories.schedule_repository import ScheduleRepository
from app.models.schedule import ProviderSchedule

router = APIRouter()

def require_provider(current_user: UserResponse = Depends(get_current_user)):
    if current_user.rol != UserRole.PROVIDER:
        raise HTTPException(status_code=403, detail="Solo los proveedores pueden gestionar horarios.")
    return current_user

@router.post("/", response_model=ScheduleResponse, summary="Configurar horario de disponibilidad")
async def create_schedule(
    data: ScheduleCreate,
    provider: UserResponse = Depends(require_provider),
    db: AsyncSession = Depends(get_db_session)
):
    schedule = ProviderSchedule(
        provider_id=provider.id,
        day_of_week=data.day_of_week,
        start_time=data.start_time,
        end_time=data.end_time,
        is_active=True
    )
    db.add(schedule)
    await db.flush()
    await db.refresh(schedule)
    return schedule

@router.get("/{provider_id}", response_model=List[ScheduleResponse], summary="Ver horario de un proveedor")
async def get_schedule(
    provider_id: uuid.UUID,
    db: AsyncSession = Depends(get_db_session)
):
    repo = ScheduleRepository(db)
    return await repo.get_provider_schedule(provider_id)


@router.delete("/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Eliminar horario")
async def delete_schedule(
    schedule_id: uuid.UUID,
    provider: UserResponse = Depends(require_provider),
    db: AsyncSession = Depends(get_db_session),
):
    from sqlalchemy import select
    from app.models.schedule import ProviderSchedule
    result = await db.execute(
        select(ProviderSchedule).where(
            ProviderSchedule.id == schedule_id,
            ProviderSchedule.provider_id == provider.id,
        )
    )
    schedule = result.scalar_one_or_none()
    if not schedule:
        raise HTTPException(status_code=404, detail="Horario no encontrado.")
    await db.delete(schedule)
    return None