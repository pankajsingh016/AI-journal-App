"""Application configuration from environment variables."""
from functools import lru_cache
from pydantic_settings import BaseSettings
from pydantic import Field, field_validator


def _strip(v: str) -> str:
    """Strip whitespace, CRLF, and surrounding quotes so Docker --env-file values are valid."""
    if not isinstance(v, str):
        return v
    s = v.strip().strip("\r")
    # Docker --env-file often passes quoted values with quotes included; remove them
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        s = s[1:-1]
    return s


class Settings(BaseSettings):
    """App settings loaded from env."""

    app_name: str = "AI Journal API"
    debug: bool = Field(False, env="DEBUG")
    api_v1_prefix: str = "/api/v1"

    # Supabase (set in .env for real use; defaults let the app start for /health, /docs)
    supabase_url: str = Field("https://placeholder.supabase.co", env="SUPABASE_URL")
    supabase_service_key: str = Field("placeholder-service-key", env="SUPABASE_SERVICE_KEY")
    supabase_anon_key: str = Field("placeholder-anon-key", env="SUPABASE_ANON_KEY")

    # JWT (set JWT_SECRET in .env for production)
    jwt_secret: str = Field("change-me-in-env-dev-only", env="JWT_SECRET")

    @field_validator("supabase_url", "supabase_service_key", "supabase_anon_key", "jwt_secret", mode="before")
    @classmethod
    def strip_secrets(cls, v: str) -> str:
        return _strip(v) if v else v

    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    # AI: Groq only (free tier at console.groq.com)
    groq_api_key: str | None = Field(None, env="GROQ_API_KEY")
    groq_model: str = Field("llama-3.1-8b-instant", env="GROQ_MODEL")

    # Optional services
    openweather_api_key: str | None = Field(None, env="OPENWEATHER_API_KEY")
    sentry_dsn: str | None = Field(None, env="SENTRY_DSN")

    # Rate limiting
    rate_limit_requests: int = 100
    rate_limit_window_seconds: int = 60
    ai_rate_limit_per_user_per_day: int = 50

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache
def get_settings() -> Settings:
    return Settings()
