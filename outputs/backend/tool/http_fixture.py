"""Temporary mock-AI HTTP fixture. Never loads .env or existing account data."""

import json
import sys
import tempfile
from pathlib import Path

import uvicorn

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tests"))
from postgres_support import test_database_url as isolated_database  # noqa: E402

from app.accounts import invite_account  # noqa: E402
from app.admin import provision  # noqa: E402
from app.ai import MockProvider  # noqa: E402
from app.config import Settings  # noqa: E402
from app.main import create_app  # noqa: E402


def main():
    folder = ROOT / ".tmp"
    folder.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="http-fixture-", dir=folder) as temporary:
        with isolated_database(f"sqlite:///{Path(temporary) / 'fixture.db'}") as database_url:
            settings = Settings(
                _env_file=None,
                ai_provider="mock",
                database_url=database_url,
            )
            app = create_app(settings, MockProvider())
            accounts = {}
            for condition in ["selfAgent", "friendAgent", "standardControl"]:
                accounts[condition] = provision(
                    app.state.factory, settings, "DEV-HTTP-" + condition, condition
                )
            accounts["invitations"] = {
                condition: invite_account(
                    app.state.factory, settings, "HTTP-USER-" + condition, condition
                )
                for condition in ["selfAgent", "friendAgent", "standardControl"]
            }
            account_file = folder / "http-fixture-accounts.json"
            account_file.write_text(json.dumps(accounts), encoding="utf-8")
            print("Synthetic mock HTTP fixture: http://127.0.0.1:8766", flush=True)
            try:
                uvicorn.run(app, host="127.0.0.1", port=8766, access_log=False, log_level="warning")
            finally:
                account_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
