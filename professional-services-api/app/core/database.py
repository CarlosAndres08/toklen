"""
database.py — Motor async, fábrica de sesiones y Base declarativa.

Importado por:
  - app/models/*.py       → heredan de Base
  - app/api/**/*.py       → inyectan get_db_session vía Depends
  - main.py               → llama create_db_pool / close_db_pool en el lifespan
"""

import logging
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text

from app.core.config import settings

logger = logging.getLogger(__name__)


# ── 1. Base declarativa ───────────────────────────────────────────────────────
# TODOS los modelos ORM deben heredar de esta clase.
# Al importar los modelos antes de crear las tablas, Alembic los detecta
# automáticamente gracias al metadata centralizado aquí.

class Base(DeclarativeBase):
    pass


# ── 2. Singletons privados ────────────────────────────────────────────────────
# Se crean en startup y se destruyen en shutdown (ver lifespan en main.py).

_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


# ── 3. Lifecycle ──────────────────────────────────────────────────────────────

async def create_db_pool() -> None:
    """Crea el engine y el pool. Llamar UNA sola vez en el startup de FastAPI."""
    global _engine, _session_factory

    logger.info("📦 Conectando al pool de PostgreSQL...")

    _engine = create_async_engine(
        url=settings.DATABASE_URL,
        echo=settings.DEBUG,   # True → loggea cada query SQL (solo desarrollo)
        pool_size=10,
        max_overflow=20,
        pool_recycle=1800,     # Recicla conexiones cada 30 min (evita timeouts)
        pool_pre_ping=True,    # Verifica que la conexión esté viva antes de usarla
    )

    _session_factory = async_sessionmaker(
        bind=_engine,
        class_=AsyncSession,
        expire_on_commit=False,  # Evita lazy-loads inválidos en contextos async
        autoflush=False,
        autocommit=False,
    )

    # Smoke test: falla rápido si las credenciales son incorrectas
    async with _engine.connect() as conn:
        await conn.execute(text("SELECT 1"))

    logger.info("✅ Pool listo.")


async def close_db_pool() -> None:
    """Cierra el pool ordenadamente. Llamar en el shutdown de FastAPI."""
    global _engine
    if _engine:
        await _engine.dispose()
        logger.info("🔌 Pool cerrado.")


# ── 4. Dependency de sesión por request ──────────────────────────────────────

async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI Dependency — provee una AsyncSession aislada por cada request.

    Uso en endpoints:
        @router.get("/items")
        async def list_items(db: AsyncSession = Depends(get_db_session)):
            result = await db.execute(select(Item))

    Garantías:
      ✔ Commit automático si el handler termina sin excepciones.
      ✔ Rollback automático si ocurre cualquier excepción.
      ✔ Sesión cerrada siempre (bloque finally).
    """
    if _session_factory is None:
        raise RuntimeError(
            "Pool no inicializado. "
            "Asegúrate de llamar create_db_pool() en el lifespan de FastAPI."
        )

    async with _session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
