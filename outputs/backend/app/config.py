from typing import Literal

from pydantic import SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    app_mode: Literal["development"] = "development"
    database_url: str = "sqlite:///./data/small_steps.db"
    ai_provider: Literal["mock", "gemini"] = "mock"
    gemini_api_key: SecretStr = SecretStr("")
    gemini_model: str = ""
    cors_origins: list[str] = ["http://127.0.0.1:8787", "http://localhost:8787"]
    protocol_version: str = "development-v1"
    consent_version: str = "demo-consent-v1"
    account_enrollment: bool = True
    token_ttl_days: int = 7
    ai_requests_per_hour: int = 30

    @model_validator(mode="after")
    def validate_configuration(self):
        if self.ai_provider == "gemini" and (
            not self.gemini_api_key.get_secret_value() or not self.gemini_model.strip()
        ):
            raise ValueError("Gemini requires GEMINI_API_KEY and GEMINI_MODEL")
        if not 1 <= self.token_ttl_days <= 90:
            raise ValueError("TOKEN_TTL_DAYS must be between 1 and 90")
        if not 1 <= self.ai_requests_per_hour <= 1000:
            raise ValueError("AI_REQUESTS_PER_HOUR must be between 1 and 1000")
        return self
