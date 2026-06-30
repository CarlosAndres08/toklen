"""
services/connection_manager.py — Registro y entrega de WebSockets activos.

Responsabilidades:
  ✔ Mantener el mapa  {user_id: WebSocket}  en memoria.
  ✔ Conectar / desconectar sockets de forma limpia.
  ✔ Enviar mensajes privados a un usuario específico.
  ✔ Ser stateless respecto a la BD — solo conoce sockets vivos.

Ciclo de vida:
  El singleton `manager` se importa en el endpoint de WS y en cualquier
  otro lugar que necesite notificar a usuarios conectados (ej: al aceptar
  una cotización).
"""

import uuid
import logging
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Gestiona conexiones WebSocket activas.

    Diseño de un socket por usuario:
      Si el mismo usuario abre una segunda pestaña, la conexión anterior
      se reemplaza limpiamente. Para multi-tab real usarías list[WebSocket]
      por user_id, pero para este MVP un socket activo por usuario es suficiente.
    """

    def __init__(self) -> None:
        # { user_id (UUID) : WebSocket }
        self._active: dict[uuid.UUID, WebSocket] = {}

    # ── Ciclo de vida de la conexión ──────────────────────────────────────────

    async def connect(self, user_id: uuid.UUID, websocket: WebSocket) -> None:
        """
        Acepta el handshake y registra la conexión.
        Si el usuario ya tenía un socket abierto (otra pestaña), lo cierra
        primero para no acumular conexiones huérfanas.
        """
        # Cerrar socket anterior si existe
        if user_id in self._active:
            try:
                await self._active[user_id].close(code=1001)
            except Exception:
                pass  # Ya estaba cerrado — ignorar

        await websocket.accept()
        self._active[user_id] = websocket
        logger.info(f"🟢 WS conectado   user_id={user_id}  activos={len(self._active)}")

    def disconnect(self, user_id: uuid.UUID) -> None:
        """
        Elimina al usuario del registro.
        Llamar desde el bloque finally del endpoint para garantizar limpieza.
        """
        removed = self._active.pop(user_id, None)
        if removed:
            logger.info(
                f"🔴 WS desconectado user_id={user_id}  activos={len(self._active)}"
            )

    # ── Envío de mensajes ─────────────────────────────────────────────────────

    async def send_to(self, user_id: uuid.UUID, payload: dict) -> bool:
        """
        Envía un payload JSON al usuario si está conectado.

        Retorna:
          True  → mensaje entregado.
          False → usuario offline (sin error — el mensaje ya fue persistido en BD).
        """
        websocket = self._active.get(user_id)
        if not websocket:
            return False
        try:
            await websocket.send_json(payload)
            return True
        except Exception as exc:
            # Socket roto (cliente cayó sin hacer close limpio)
            logger.warning(f"⚠️  Error enviando a {user_id}: {exc} — desconectando")
            self.disconnect(user_id)
            return False

    async def broadcast_to_pair(
        self,
        sender_id: uuid.UUID,
        receiver_id: uuid.UUID,
        payload: dict,
    ) -> None:
        """
        Entrega el mensaje a ambos participantes del chat si están conectados.
        El remitente lo recibe para confirmar que fue persistido (eco controlado).
        """
        await self.send_to(receiver_id, payload)
        await self.send_to(sender_id, payload)

    # ── Utilidades ────────────────────────────────────────────────────────────

    def is_online(self, user_id: uuid.UUID) -> bool:
        return user_id in self._active

    def online_count(self) -> int:
        return len(self._active)


# Singleton global — importar este objeto, no la clase
manager = ConnectionManager()