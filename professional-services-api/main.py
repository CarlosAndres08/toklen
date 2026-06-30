from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import logging
import os

from app.core.database import create_db_pool, close_db_pool
from app.api.v1.router import api_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
UPLOAD_DIR = os.path.join(STATIC_DIR, "uploads", "profiles")
os.makedirs(UPLOAD_DIR, exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await create_db_pool()
        logger.info("✅ Base de datos lista.")
    except Exception as e:
        logger.error(f"❌ Error al iniciar la base de datos: {e}")
        raise e
    yield
    try:
        await close_db_pool()
    except Exception as e:
        logger.error(f"Error al cerrar la conexión: {e}")


app = FastAPI(
    title="API de Servicios Profesionales",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS ampliado para WebSocket (ws:// y wss://)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
app.include_router(api_router, prefix="/api/v1")


@app.get("/health", tags=["Health"])
async def health():
    from app.services.connection_manager import manager
    return {
        "status": "ok",
        "version": "1.0.0",
        "ws_connections": manager.online_count(),   # ← útil para monitoreo
    }