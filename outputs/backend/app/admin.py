import argparse
import hashlib
import json
import secrets
import time
from pathlib import Path

from pydantic import TypeAdapter
from sqlalchemy import select

from .config import Settings
from .db import Participant, database, transaction
from .schemas import Condition, Identifier


def digest(token: str):
    return hashlib.sha256(token.encode()).hexdigest()


def provision(factory, settings, participant_id, condition):
    TypeAdapter(Identifier).validate_python(participant_id)
    TypeAdapter(Condition).validate_python(condition)
    token = secrets.token_urlsafe(32)
    with transaction(factory) as session:
        if session.get(Participant, participant_id):
            raise ValueError("Participant already exists; assignment cannot be changed")
        session.add(
            Participant(
                id=participant_id,
                condition=condition,
                token_hash=digest(token),
                expires_at=time.time() + settings.token_ttl_days * 86400,
            )
        )
    return token


def main():
    parser = argparse.ArgumentParser(
        description="Local synthetic-account administration; no public admin API"
    )
    parser.add_argument("action", choices=["create", "invite", "revoke", "rotate"])
    parser.add_argument("--id", required=True)
    parser.add_argument("--condition", choices=["selfAgent", "friendAgent", "standardControl"])
    parser.add_argument("--token-file", help="New file for credential; no token printed to stdout")
    args = parser.parse_args()
    settings = Settings()
    engine, factory = database(settings.database_url)
    try:
        if args.action in ("create", "invite", "rotate"):
            if not args.token_file:
                parser.error("--token-file is required")
            # Reserve the file before modifying the database; never overwrite credentials.
            with Path(args.token_file).open("x", encoding="utf-8") as output:
                if args.action in ("create", "invite"):
                    if not args.condition:
                        parser.error("--condition is required for create")
                    if args.action == "invite":
                        from .accounts import invite_account

                        token = invite_account(factory, settings, args.id, args.condition)
                    else:
                        token = provision(factory, settings, args.id, args.condition)
                else:
                    token = secrets.token_urlsafe(32)
                    with transaction(factory) as session:
                        row = session.get(Participant, args.id)
                        if not row or not row.active:
                            raise ValueError("Active participant not found")
                        row.token_hash = digest(token)
                        row.expires_at = time.time() + settings.token_ttl_days * 86400
                json.dump(
                    {
                        "participant_id": args.id,
                        "invitation" if args.action == "invite" else "token": token,
                    },
                    output,
                )
            print("Credential written to the requested local file. Keep it private.")
        else:
            with transaction(factory) as session:
                row = session.scalar(select(Participant).where(Participant.id == args.id))
                if not row:
                    raise ValueError("Participant not found")
                row.active = False
            print("Participant access revoked.")
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
