from pydantic_settings import BaseSettings
from pydantic import field_validator

class Settings(BaseSettings):
    SECRET_KEY: str = "replace_this_with_a_strong_key"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    DATABASE_URL: str = "sqlite:///./vaidra.db"
    GEMINI_API_KEY: str = ""
    PERPLEXITY_API_KEY: str = ""
    PERPLEXITY_ENDPOINT: str = "https://api.perplexity.ai/analyze"
    USE_S3: bool = False
    S3_ENDPOINT: str = ""
    S3_REGION: str = ""
    S3_BUCKET: str = ""
    S3_ACCESS_KEY: str = ""
    S3_SECRET_KEY: str = ""
    UPLOAD_DIR: str = "uploads"

    # Render provides postgres:// but SQLAlchemy requires postgresql://
    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def fix_postgres_url(cls, v: str) -> str:
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql://", 1)
        return v

    class Config:
        env_file = (".env", "../.env", "../../.env")

settings = Settings()
