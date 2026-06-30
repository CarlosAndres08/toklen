"""
endpoints/chat.py — HTTP REST + WebSocket para mensajería en tiempo real.

Flujo WebSocket:
  1. Cliente conecta a  ws://.../chat/ws/{user_id}?token=<JWT>
  2. El servidor valida el token → autentica al usuario.
  3. El socket queda registrado en ConnectionManager.
  4. Al recibir un mensaje JSON, el servidor:
       a. Persiste en BD  (ChatRepository / ChatService)
       b. Entrega en vivo al receptor si está online  (ConnectionManager)
       c. Hace eco al emisor como confirmación de entrega
  5. Al desconectarse (normal o por error), se limpia el registro.
"""

import uuid
import json
import logging

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from jose import JWTError

from app.api.v1.endpoints.auth import get_current_user
from app.core.database import get_db_session
from app.core.config import settings
from app.repositories.chat_repository import ChatRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.booking_repository import BookingRepository
from app.repositories.service_repository import ServiceRepository
from app.repositories.user_repository import UserRepository
from app.services.auth_service import decode_access_token
from app.services.chat_service import ChatService
from app.services.connection_manager import manager
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse, ChatInboxItem
from app.schemas.notification import NotificationResponse
from app.schemas.user import UserResponse
from app.models.notification import Notification

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Dependency factory (HTTP) ─────────────────────────────────────────────────

def get_chat_service(db: AsyncSession = Depends(get_db_session)) -> ChatService:
    return ChatService(
        ChatRepository(db),
        NotificationRepository(db),
        BookingRepository(db),
        ServiceRepository(db),
        UserRepository(db),
    )


# ── Helpers internos ──────────────────────────────────────────────────────────

async def _get_db_session_direct() -> AsyncSession:
    """
    Abre una sesión manualmente para el contexto WebSocket.
    Los WebSockets no pueden usar Depends(get_db_session) de FastAPI
    porque el ciclo de vida de la sesión no está ligado a un HTTP request.
    """
    from app.core.database import _session_factory
    if _session_factory is None:
        raise RuntimeError("Pool de BD no inicializado.")
    return _session_factory()


async def _authenticate_ws(token: str) -> uuid.UUID:
    """
    Valida el JWT recibido por query param en el handshake WebSocket.
    Retorna el user_id si es válido, lanza ValueError si no lo es.
    WebSockets no soportan headers custom en el browser — query param es el estándar.
    """
    try:
        return decode_access_token(token)
    except (JWTError, ValueError) as exc:
        raise ValueError(f"Token inválido: {exc}")


def _build_message_payload(msg, event: str = "new_message") -> dict:
    """
    Serializa un ChatMessage ORM a dict JSON-safe para enviarlo por WebSocket.
    """
    return {
        "event": event,
        "data": {
            "id": str(msg.id),
            "sender_id": str(msg.sender_id),
            "receiver_id": str(msg.receiver_id),
            "booking_id": str(msg.booking_id) if msg.booking_id else None,
            "message": msg.message,
            "is_read": msg.is_read,
            "fecha_envio": msg.fecha_envio.isoformat(),
        },
    }


# ── WebSocket endpoint ────────────────────────────────────────────────────────

@router.websocket("/ws/{user_id}")
async def websocket_chat(
    websocket: WebSocket,
    user_id: uuid.UUID,
    token: str = Query(..., description="JWT del usuario autenticado"),
):
    """
    Endpoint WebSocket de chat en tiempo real.

    Conexión:
        ws://localhost:8000/api/v1/chat/ws/<user_id>?token=<JWT>

    Formato del mensaje entrante (JSON):
        {
            "receiver_id": "<uuid>",
            "message":     "Hola!",
            "booking_id":  "<uuid | null>"   ← opcional
        }

    Formato del mensaje saliente (JSON):
        {
            "event": "new_message",
            "data": {
                "id":          "<uuid>",
                "sender_id":   "<uuid>",
                "receiver_id": "<uuid>",
                "booking_id":  "<uuid | null>",
                "message":     "Hola!",
                "is_read":     false,
                "fecha_envio": "2025-05-15T12:00:00"
            }
        }

    Errores de autenticación se cierran con código 4001 (custom).
    Errores de payload se cierran con código 4002 (custom).
    """

    # ── Paso 1: Autenticar ANTES de aceptar el socket ─────────────────────────
    try:
        authenticated_id = await _authenticate_ws(token)
    except ValueError as exc:
        # Rechazar el handshake con código WS estándar más cercano a 401
        await websocket.close(code=4001, reason="Token inválido o expirado.")
        logger.warning(f"🚫 WS rechazado (auth) user_id={user_id}: {exc}")
        return

    # El token debe coincidir con el user_id de la URL para evitar suplantación
    if authenticated_id != user_id:
        await websocket.close(code=4001, reason="Token no corresponde al user_id.")
        logger.warning(
            f"🚫 WS suplantación detectada: token={authenticated_id} url={user_id}"
        )
        return

    # ── Paso 2: Registrar la conexión ─────────────────────────────────────────
    await manager.connect(user_id, websocket)

    # ── Paso 3: Bucle principal de mensajes ───────────────────────────────────
    try:
        while True:
            # Esperar datos del cliente (bloqueo async — no consume CPU)
            raw = await websocket.receive_text()

            # Parsear JSON del mensaje
            try:
                payload = json.loads(raw)
                receiver_id = uuid.UUID(payload["receiver_id"])
                message_text = str(payload["message"]).strip()
                booking_id = (
                    uuid.UUID(payload["booking_id"])
                    if payload.get("booking_id")
                    else None
                )
            except (KeyError, ValueError, json.JSONDecodeError) as exc:
                # Payload malformado — avisar al cliente sin cerrar la conexión
                await websocket.send_json({
                    "event": "error",
                    "data": {
                        "code": 4002,
                        "detail": f"Payload inválido: {exc}. "
                                  "Se esperan: receiver_id, message, booking_id (opcional).",
                    },
                })
                continue

            if not message_text:
                await websocket.send_json({
                    "event": "error",
                    "data": {"code": 4002, "detail": "El mensaje no puede estar vacío."},
                })
                continue

            # ── Paso 4: Persistir en BD ───────────────────────────────────────
            async with await _get_db_session_direct() as db:
                try:
                    chat_repo  = ChatRepository(db)
                    notif_repo = NotificationRepository(db)

                    # Reutiliza ChatService para consistencia con el REST endpoint
                    chat_svc = ChatService(
                        chat_repo,
                        notif_repo,
                        BookingRepository(db),
                        ServiceRepository(db),
                        UserRepository(db),
                    )
                    data = ChatMessageCreate(
                        receiver_id=receiver_id,
                        message=message_text,
                        booking_id=booking_id,
                    )
                    saved_msg = await chat_svc.send_message(user_id, data)

                    logger.info(
                        f"💬 Mensaje persistido  "
                        f"from={user_id}  to={receiver_id}  "
                        f"online_receptor={manager.is_online(receiver_id)}"
                    )

                except Exception as exc:
                    await db.rollback()
                    logger.error(f"❌ Error persistiendo mensaje WS: {exc}")
                    await websocket.send_json({
                        "event": "error",
                        "data": {"code": 5000, "detail": "Error interno al guardar el mensaje."},
                    })
                    continue

            # ── Paso 5: Entregar en tiempo real ───────────────────────────────
            # saved_msg es ChatMessageResponse (Pydantic) — serializar a dict
            msg_payload = {
                "event": "new_message",
                "data": {
                    "id":          str(saved_msg.id),
                    "sender_id":   str(saved_msg.sender_id),
                    "receiver_id": str(saved_msg.receiver_id),
                    "booking_id":  str(saved_msg.booking_id) if saved_msg.booking_id else None,
                    "message":     saved_msg.message,
                    "is_read":     saved_msg.is_read,
                    "fecha_envio": saved_msg.fecha_envio.isoformat(),
                },
            }

            # Entregar al receptor (si está online) y al emisor (confirmación)
            await manager.broadcast_to_pair(
                sender_id=user_id,
                receiver_id=receiver_id,
                payload=msg_payload,
            )

    except WebSocketDisconnect:
        # Desconexión limpia del cliente (navegador cerró pestaña, etc.)
        logger.info(f"👋 WS desconexión limpia  user_id={user_id}")

    except Exception as exc:
        # Error inesperado — registrar y limpiar
        logger.error(f"💥 Error inesperado en WS user_id={user_id}: {exc}")

    finally:
        # Garantizado: siempre eliminar del registro aunque haya excepción
        manager.disconnect(user_id)


# ── REST endpoints (sin cambios) ──────────────────────────────────────────────

@router.post("/send", response_model=ChatMessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    data: ChatMessageCreate,
    current_user: UserResponse = Depends(get_current_user),
    service: ChatService = Depends(get_chat_service),
):
    msg = await service.send_message(current_user.id, data)
    msg_payload = {
        "event": "new_message",
        "data": {
            "id":          str(msg.id),
            "sender_id":   str(msg.sender_id),
            "receiver_id": str(msg.receiver_id),
            "booking_id":  str(msg.booking_id) if msg.booking_id else None,
            "message":     msg.message,
            "is_read":     msg.is_read,
            "fecha_envio": msg.fecha_envio.isoformat(),
        },
    }
    await manager.broadcast_to_pair(
        sender_id=current_user.id,
        receiver_id=data.receiver_id,
        payload=msg_payload,
    )
    return msg


@router.get("/history/{contact_id}", response_model=list[ChatMessageResponse])
async def get_chat_history(
    contact_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    service: ChatService = Depends(get_chat_service),
):
    return await service.get_history(current_user.id, contact_id)


@router.get("/inbox", response_model=list[ChatInboxItem])
async def get_inbox(
    current_user: UserResponse = Depends(get_current_user),
    service: ChatService = Depends(get_chat_service),
):
    return await service.get_inbox(current_user.id)


@router.get("/notifications", response_model=list[NotificationResponse])
async def get_notifications(
    current_user: UserResponse = Depends(get_current_user),
    service: ChatService = Depends(get_chat_service),
):
    return await service.get_notifications(current_user.id)


@router.patch("/notifications/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_notification_as_read(
    notification_id: uuid.UUID,
    current_user: UserResponse = Depends(get_current_user),
    service: ChatService = Depends(get_chat_service),
):
    success = await service.mark_notification_as_read(current_user.id, notification_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notificación no encontrada.",
        )
    return None