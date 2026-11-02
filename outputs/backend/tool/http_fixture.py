"""Temporary mock-AI HTTP fixture. Never loads .env or existing account data."""

import json
import sys
import tempfile
from pathlib import Path

import uvicorn

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from app.admin import provision  # noqa: E402
from app.ai import MockProvider  # noqa: E402
from app.config import Settings  # noqa: E402
from app.main import create_app  # noqa: E402


def main():
    folder = ROOT / ".tmp"
    folder.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="http-fixture-", dir=folder) as temporary:
        settings = Settings(
            _env_file=None,
            ai_provider="mock",
            database_url=f"sqlite:///{Path(temporary) / 'fixture.db'}",
        )
        app = create_app(settings, MockProvider())
        accounts = {}
        for condition in ["selfAgent", "friendAgent", "standardControl"]:
            accounts[condition] = provision(
                app.state.factory, settings, "DEV-HTTP-" + condition, condition
            )
        account_file = folder / "http-fixture-accounts.json"
        account_file.write_text(json.dumps(accounts), encoding="utf-8")
        print("Synthetic mock HTTP fixture: http://127.0.0.1:8766", flush=True)
        try:
            uvicorn.run(app, host="127.0.0.1", port=8766, access_log=False, log_level="warning")
        finally:
            account_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
