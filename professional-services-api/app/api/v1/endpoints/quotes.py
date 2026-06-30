import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.v1.endpoints.auth import get_current_user
from app.schemas.quote import QuoteCreate, QuoteRespond, QuoteResponse
from app.repositories.quote_repository import QuoteRepository
from app.repositories.chat_repository import ChatRepository
from app.repositories.notification_repository import NotificationRepository
from app.models.quote import ServiceQuote, QuoteStatus
from app.models.notification import Notification
from app.models.user import UserRole
from app.services.connection_manager import manager   # ← singleton WS

router = APIRouter()


# ── Helpers de seguridad ──────────────────────────────────────────────────────

def _is_provider_of_quote(current_user, quote: ServiceQuote) -> bool:
    return (
        current_user.rol == UserRole.PROVIDER
        and quote.service.provider_id == current_user.id
    )

def _is_client_of_quote(current_user, quote: ServiceQuote) -> bool:
    return (
        current_user.rol == UserRole.CLIENT
        and quote.client_id == current_user.id
    )

def _is_participant(current_user, quote: ServiceQuote) -> bool:
    return _is_provider_of_quote(current_user, quote) or _is_client_of_quote(current_user, quote)

def _forbidden(detail: str):
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/my-quotes", response_model=list[QuoteResponse])
async def get_my_quotes(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    repo = QuoteRepository(db)
    return await repo.list_by_client(current_user.id)


@router.get("/received", response_model=list[QuoteResponse])
async def get_received_quotes(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    if current_user.rol != UserRole.PROVIDER:
        raise HTTPException(status_code=403, detail="Solo los proveedores pueden ver cotizaciones recibidas.")
    repo = QuoteRepository(db)
    return await repo.list_by_service_provider(current_user.id)


@router.post("/", response_model=QuoteResponse, status_code=status.HTTP_201_CREATED)
async def request_quote(
    data: QuoteCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    repo = QuoteRepository(db)
    quote = ServiceQuote(
        service_id=data.service_id,
        client_id=current_user.id,
        description=data.description,
    )
    quote = await repo.create(quote)
    return quote


@router.patch("/{quote_id}/respond", response_model=QuoteResponse)
async def patch_respond_quote(
    quote_id: uuid.UUID,
    body: QuoteRespond,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    quote_repo = QuoteRepository(db)
    chat_repo  = ChatRepository(db)
    notif_repo = NotificationRepository(db)

    # ── 1. Cargar cotización con su servicio ──────────────────────────────────
    quote = await quote_repo.get_by_id_with_service(quote_id)
    if not quote:
        raise HTTPException(status_code=404, detail="Cotización no encontrada")

    provider_id = quote.service.provider_id

    # ── 2. Solo participantes directos ────────────────────────────────────────
    if not _is_participant(current_user, quote):
        _forbidden("No eres parte de esta negociación.")

    # ── 3. Cotización cerrada no se puede reabrir ─────────────────────────────
    CLOSED = {QuoteStatus.ACCEPTED, QuoteStatus.DECLINED, QuoteStatus.CANCELLED}
    if quote.status in CLOSED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"La cotización ya está cerrada con estado '{quote.status.value}'.",
        )

    # ── 4. Permisos por acción ────────────────────────────────────────────────
    wants_to_offer = body.status == QuoteStatus.OFFERED
    wants_to_price = body.proposed_price is not None

    if (wants_to_offer or wants_to_price) and not _is_provider_of_quote(current_user, quote):
        _forbidden(
            "Solo el proveedor dueño del servicio puede proponer un precio "
            "o cambiar el estado a 'offered'."
        )

    if wants_to_price and quote.status == QuoteStatus.ACCEPTED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El precio de una cotización aceptada no puede modificarse.",
        )

    if body.status == QuoteStatus.ACCEPTED:
        if not _is_client_of_quote(current_user, quote):
            _forbidden("Solo el cliente que solicitó esta cotización puede aceptarla.")
        if quote.proposed_price is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="No se puede aceptar una cotización sin precio propuesto.",
            )

    # ── 5. Aplicar cambios en la cotización ───────────────────────────────────
    new_status = body.status if body.status is not None else quote.status
    quote = await quote_repo.update_status(quote, new_status, body.proposed_price)

    # ── 6. Flujo automático al aceptar ────────────────────────────────────────
    if new_status == QuoteStatus.ACCEPTED:
        monto = f"S/ {quote.proposed_price:,.2f}"
        system_text = (
            f"¡Trato hecho! 🎉 La cotización ha sido aceptada "
            f"por un monto de {monto}. "
            f"Ya pueden coordinar los detalles finales aquí."
        )

        # 6a. Crear la reserva automáticamente
        if body.start_time is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Se requiere start_time para crear la reserva.",
            )
        booking = await quote_repo.accept_and_book(quote, body.start_time)

        # 6b. Persistir mensaje en BD
        system_msg = await chat_repo.create_system_message(
            client_id=quote.client_id,
            provider_id=provider_id,
            text=system_text,
        )

        # 6c. Entregar en tiempo real al proveedor si está conectado por WS
        ws_payload = {
            "event": "quote_accepted",
            "data": {
                "id":          str(system_msg.id),
                "sender_id":   str(quote.client_id),
                "receiver_id": str(provider_id),
                "booking_id":  str(booking.id),
                "message":     system_text,
                "is_read":     False,
                "monto":       monto,
            },
        }
        await manager.broadcast_to_pair(
            sender_id=quote.client_id,
            receiver_id=provider_id,
            payload=ws_payload,
        )

        # 6d. Notificación persistente en BD para el proveedor
        await notif_repo.create(
            Notification(
                user_id=provider_id,
                title="Cotización aceptada — Reserva creada",
                content=(
                    f"El cliente aceptó tu cotización por {monto}. "
                    f"Se ha creado una reserva automáticamente. "
                    f"Revisa el chat para coordinar los detalles."
                ),
            )
        )

    return quote