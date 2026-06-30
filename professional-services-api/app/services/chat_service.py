import uuid
from fastapi import HTTPException, status
from app.models.chat import ChatMessage
from app.models.notification import Notification
from app.repositories.chat_repository import ChatRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.booking_repository import BookingRepository
from app.repositories.service_repository import ServiceRepository
from app.repositories.user_repository import UserRepository
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse, ChatInboxItem
from app.schemas.notification import NotificationResponse

class ChatAccessDeniedError(HTTPException):
    def __init__(self, detail: str = "No tienes permiso para chatear con este usuario."):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)

class ChatService:
    def __init__(
        self, 
        chat_repo: ChatRepository, 
        notification_repo: NotificationRepository,
        booking_repo: BookingRepository,
        service_repo: ServiceRepository,
        user_repo: UserRepository,
    ) -> None:
        self.chat_repo = chat_repo
        self.notification_repo = notification_repo
        self.booking_repo = booking_repo
        self.service_repo = service_repo
        self.user_repo = user_repo

    async def send_message(self, sender_id: uuid.UUID, data: ChatMessageCreate) -> ChatMessageResponse:
        if sender_id == data.receiver_id:
            raise ChatAccessDeniedError("No puedes enviarte mensajes a ti mismo.")

        # Lógica de seguridad: Solo permitir si hay relación previa o consulta inicial
        can_chat = True # Implementación base permitida para el MVP
        
        if data.booking_id:
            booking = await self.booking_repo.get_by_id(data.booking_id)
            if booking:
                is_sender_part = (booking.client_id == sender_id or booking.service.provider_id == sender_id)
                is_receiver_part = (booking.client_id == data.receiver_id or booking.service.provider_id == data.receiver_id)
                if not (is_sender_part and is_receiver_part):
                    raise ChatAccessDeniedError("No perteneces a esta reserva.")

        message = ChatMessage(
            sender_id=sender_id,
            receiver_id=data.receiver_id,
            booking_id=data.booking_id,
            message=data.message
        )
        
        created_msg = await self.chat_repo.create(message)
        
        # Crear notificación con nombre y ID del remitente
        sender = await self.user_repo.get_by_id(sender_id)
        sender_name = sender.nombre if sender else "Alguien"
        notification = Notification(
            user_id=data.receiver_id,
            title=f"Nuevo mensaje de {sender_name}",
            content=f"{sender_name}: {data.message[:80]}",
            sender_id=sender_id,
        )
        await self.notification_repo.create(notification)
        
        return ChatMessageResponse.model_validate(created_msg)

    async def get_history(self, user_id: uuid.UUID, contact_id: uuid.UUID) -> list[ChatMessageResponse]:
        await self.chat_repo.mark_as_read(receiver_id=user_id, sender_id=contact_id)
        messages = await self.chat_repo.get_history(user_id, contact_id)
        return [ChatMessageResponse.model_validate(m) for m in messages]

    async def get_inbox(self, user_id: uuid.UUID) -> list[ChatInboxItem]:
        items = await self.chat_repo.get_inbox(user_id)
        return [ChatInboxItem.model_validate(item) for item in items]

    async def get_notifications(self, user_id: uuid.UUID) -> list[NotificationResponse]:
        notifications = await self.notification_repo.list_for_user(user_id)
        return [NotificationResponse.model_validate(n) for n in notifications]

    async def mark_notification_as_read(self, user_id: uuid.UUID, notification_id: uuid.UUID) -> bool:
        return await self.notification_repo.mark_as_read(notification_id, user_id)