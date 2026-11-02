"""Credential-safe connection diagnostics. Never prints keys or provider errors."""

import argparse

from google import genai
from google.genai import types

from app.config import Settings

parser = argparse.ArgumentParser()
parser.add_argument("--list-models", action="store_true")
args = parser.parse_args()
settings = Settings()
client = genai.Client(
    api_key=settings.gemini_api_key.get_secret_value(),
    http_options=types.HttpOptions(timeout=60000, retry_options=types.HttpRetryOptions(attempts=1)),
)
try:
    if args.list_models:
        models = [
            m.name for m in client.models.list() if "generateContent" in (m.supported_actions or [])
        ]
        print("Available generation models:")
        for name in models:
            print(name)
    else:
        response = client.models.generate_content(
            model=settings.gemini_model,
            contents="Reply with exactly: Small Steps connection OK",
            config=types.GenerateContentConfig(max_output_tokens=512),
        )
        if response.text:
            print("Gemini generation succeeded.")
        else:
            print("Gemini returned no visible text.")
except Exception as error:
    print(
        "Gemini connection failed; exception type:",
        type(error).__name__,
        "status:",
        getattr(error, "code", "unavailable"),
    )
    safe_message = str(getattr(error, "message", "No additional message")).replace(
        settings.gemini_api_key.get_secret_value(), "[redacted]"
    )
    print("Provider message:", safe_message[:500])
    raise SystemExit(1) from None
finally:
    client.close()
