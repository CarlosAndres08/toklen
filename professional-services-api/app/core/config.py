from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    # ── Base de datos ─────────────────────────────────────────────────────────
    DATABASE_URL: str  # postgresql+asyncpg://user:pass@host:port/dbname

    # ── Seguridad ─────────────────────────────────────────────────────────────
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # ── App ───────────────────────────────────────────────────────────────────
    APP_ENV: str = "development"
    DEBUG: bool = True

    model_config = SettingsConfigDict(
        env_file=".env",           # Busca el .env en la raíz del proyecto
        env_file_encoding="utf-8",
        case_sensitive=True,       # DATABASE_URL ≠ database_url
        extra="ignore",            # Ignora variables no declaradas
    )


@lru_cache
def get_settings() -> Settings:
    """
    Singleton: el .env se lee UNA sola vez y se cachea.
    Úsalo con FastAPI vía Depends(get_settings) o importando `settings` directamente.
    """
    return Settings()


# Instancia global lista para importar en cualquier módulo
settings = get_settings()
