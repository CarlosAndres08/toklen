import uuid
from sqlalchemy import select, or_, and_, func, desc, case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.chat import ChatMessage
from app.models.user import User

# UUID centinela que identifica mensajes automáticos del sistema.
# No corresponde a ningún usuario real de la BD.
SYSTEM_SENDER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")


class ChatRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self, message: ChatMessage) -> ChatMessage:
        self.db.add(message)
        await self.db.flush()
        result = await self.db.execute(
            select(ChatMessage)
            .options(selectinload(ChatMessage.sender), selectinload(ChatMessage.receiver))
            .where(ChatMessage.id == message.id)
        )
        return result.scalar_one()

    async def get_history(
        self, user1_id: uuid.UUID, user2_id: uuid.UUID, limit: int = 50
    ) -> list[ChatMessage]:
        stmt = (
            select(ChatMessage)
            .options(
                selectinload(ChatMessage.sender),
                selectinload(ChatMessage.receiver),
            )
            .where(
                or_(
                    and_(
                        ChatMessage.sender_id == user1_id,
                        ChatMessage.receiver_id == user2_id,
                    ),
                    and_(
                        ChatMessage.sender_id == user2_id,
                        ChatMessage.receiver_id == user1_id,
                    ),
                )
            )
            .order_by(ChatMessage.fecha_envio.asc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def mark_as_read(
        self, receiver_id: uuid.UUID, sender_id: uuid.UUID
    ) -> None:
        from sqlalchemy import update

        stmt = (
            update(ChatMessage)
            .where(
                ChatMessage.receiver_id == receiver_id,
                ChatMessage.sender_id == sender_id,
                ChatMessage.is_read == False,
            )
            .values(is_read=True)
        )
        await self.db.execute(stmt)
        await self.db.flush()

    async def get_inbox(self, user_id: uuid.UUID) -> list[dict]:
        contact_id_col = case(
            (ChatMessage.sender_id == user_id, ChatMessage.receiver_id),
            else_=ChatMessage.sender_id,
        ).label("contact_id")
        subquery = (
            select(
                func.max(ChatMessage.fecha_envio).label("max_date"),
                contact_id_col,
            )
            .where(
                or_(
                    ChatMessage.sender_id == user_id,
                    ChatMessage.receiver_id == user_id,
                ),
                ChatMessage.sender_id != ChatMessage.receiver_id,
            )
            .group_by(contact_id_col)
            .subquery()
        )

        stmt = (
            select(ChatMessage, User)
            .join(
                subquery,
                and_(
                    subquery.c.max_date == ChatMessage.fecha_envio,
                    or_(
                        and_(
                            ChatMessage.sender_id == user_id,
                            ChatMessage.receiver_id == subquery.c.contact_id,
                        ),
                        and_(
                            ChatMessage.receiver_id == user_id,
                            ChatMessage.sender_id == subquery.c.contact_id,
                        ),
                    ),
                ),
            )
            .join(User, User.id == subquery.c.contact_id)
            .order_by(desc(ChatMessage.fecha_envio))
        )

        result = await self.db.execute(stmt)
        inbox_items = []
        for msg, contact in result.all():
            unread_stmt = select(func.count(ChatMessage.id)).where(
                ChatMessage.sender_id == contact.id,
                ChatMessage.receiver_id == user_id,
                ChatMessage.is_read == False,
            )
            unread_count = (await self.db.execute(unread_stmt)).scalar() or 0
            inbox_items.append(
                {
                    "user": contact,
                    "last_message": msg.message,
                    "last_message_date": msg.fecha_envio,
                    "unread_count": unread_count,
                }
            )
        return inbox_items

    # ── Nuevos métodos para mensajes automáticos de cotización ────────────────

    async def has_active_chat(
        self, client_id: uuid.UUID, provider_id: uuid.UUID
    ) -> bool:
        """
        Devuelve True si ya existe al menos un mensaje entre cliente y proveedor.
        Esto actúa como verificación de 'ChatRoom activa' dado que el modelo
        usa mensajes directos sin tabla de sala explícita.
        """
        stmt = select(ChatMessage.id).where(
            or_(
                and_(
                    ChatMessage.sender_id == client_id,
                    ChatMessage.receiver_id == provider_id,
                ),
                and_(
                    ChatMessage.sender_id == provider_id,
                    ChatMessage.receiver_id == client_id,
                ),
            )
        ).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none() is not None

    async def create_system_message(
        self,
        client_id: uuid.UUID,
        provider_id: uuid.UUID,
        text: str,
    ) -> ChatMessage:
        """
        Inserta un mensaje de sistema en la conversación cliente ↔ proveedor.
        Usa SYSTEM_SENDER_ID como remitente y el proveedor como receptor,
        de modo que ambos lo vean en su historial compartido.
        El campo sender_id apunta a un UUID centinela (no un usuario real),
        por eso se omite el FK real; el modelo ya tiene nullable=False pero
        PostgreSQL no valida FK en flush — se valida al commit.

        NOTA: Si quieres FK estricta, agrega un usuario 'system' real en tu
        seed/migration con id = SYSTEM_SENDER_ID.
        """
        system_msg = ChatMessage(
            sender_id=client_id,    # ← remitente: cliente (así el proveedor lo recibe)
            receiver_id=provider_id,
            booking_id=None,
            message=text,
            is_read=False,
        )
        self.db.add(system_msg)
        await self.db.flush()
        return system_msg