"""Invite-only development identities. Existing participant ownership remains authoritative."""

import secrets
import threading
import time

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import Field, SecretStr
from sqlalchemy import select, update

from .admin import digest
from .db import Invitation, LoginAccount, Participant, Record, now_iso, transaction
from .schemas import StrictModel

passwords = PasswordHasher()


class SignIn(StrictModel):
    username: str = Field(min_length=3, max_length=64, pattern=r"^[a-zA-Z0-9_.-]+$")
    password: SecretStr = Field(min_length=12, max_length=128)


class Enroll(SignIn):
    invitation: SecretStr = Field(min_length=20, max_length=200)


def install_accounts(app, factory, settings, authenticated):
    router = APIRouter(prefix="/api/auth", tags=["accounts"])
    # Bounded, single-worker development limiter. Proxy/deployment limits remain required.
    attempts = {}
    lock = threading.Lock()
    dummy_hash = passwords.hash(secrets.token_urlsafe(32))

    def fail(status=401, code="invalid_credentials", message="Sign-in could not be completed"):
        raise HTTPException(status, detail={"code": code, "message": message})

    def limit(request, username):
        now = time.monotonic()
        peer = request.client.host if request.client else "unknown"
        with lock:
            for key in list(attempts):
                if attempts[key][0] < now - 600:
                    del attempts[key]
            keys = [("peer:" + peer, 30), ("name:" + username.lower(), 10)]
            if len(attempts) > 10000 or any(attempts.get(k, (now, 0))[1] >= n for k, n in keys):
                fail(429, "auth_rate_limited", "Too many attempts; wait ten minutes")
            for key, _ in keys:
                start, count = attempts.get(key, (now, 0))
                attempts[key] = (start, count + 1)

    def issue(session, participant, event):
        token = secrets.token_urlsafe(32)
        participant.token_hash = digest(token)
        participant.expires_at = time.time() + settings.token_ttl_days * 86400
        session.add(
            Record(
                participant_id=participant.id,
                kind="audit",
                record_id=secrets.token_hex(16),
                data={
                    "kind": event,
                    "at": now_iso(),
                    "source": "server",
                    "condition": participant.condition,
                },
            )
        )
        return {
            "token": token,
            "token_type": "bearer",
            "expires_at": participant.expires_at,
            "participant_id": participant.id,
            "condition": participant.condition,
        }

    @router.post("/enroll", status_code=201)
    def enroll(body: Enroll, request: Request):
        limit(request, body.username)
        if not settings.account_enrollment:
            fail(403, "enrollment_disabled", "Invitation enrollment is disabled")
        username = body.username.lower()
        hashed_password = passwords.hash(body.password.get_secret_value())
        with transaction(factory) as session:
            invite = session.get(Invitation, digest(body.invitation.get_secret_value()))
            if not invite or invite.used or invite.expires_at <= time.time():
                fail(400, "enrollment_failed", "Invitation or account details are unavailable")
            participant = session.scalar(
                select(Participant).where(Participant.id == invite.participant_id).with_for_update()
            )
            if not participant or not participant.active or session.get(LoginAccount, username):
                fail(400, "enrollment_failed", "Invitation or account details are unavailable")
            claimed = session.execute(
                update(Invitation)
                .where(Invitation.code_hash == invite.code_hash, Invitation.used.is_(False))
                .values(used=True)
            )
            if claimed.rowcount != 1:
                fail(409, "enrollment_failed", "Invitation or account details are unavailable")
            session.add(
                LoginAccount(
                    username=username, participant_id=participant.id, password_hash=hashed_password
                )
            )
            return issue(session, participant, "account_enrolled")

    @router.post("/login")
    def login(body: SignIn, request: Request):
        limit(request, body.username)
        with transaction(factory) as session:
            account = session.get(LoginAccount, body.username.lower())
            try:
                passwords.verify(
                    account.password_hash if account else dummy_hash,
                    body.password.get_secret_value(),
                )
            except (VerificationError, InvalidHashError):
                fail()
            if not account:
                fail()
            participant = session.scalar(
                select(Participant)
                .where(Participant.id == account.participant_id)
                .with_for_update()
            )
            if not participant or not participant.active:
                fail()
            if passwords.check_needs_rehash(account.password_hash):
                account.password_hash = passwords.hash(body.password.get_secret_value())
            return issue(session, participant, "account_signed_in")

    @router.post("/logout")
    def logout(p=Depends(authenticated)):
        with transaction(factory) as session:
            result = session.execute(
                update(Participant)
                .where(Participant.id == p.id, Participant.token_hash == p.token_hash)
                .values(token_hash=digest(secrets.token_urlsafe(32)), expires_at=0)
            )
            if result.rowcount != 1:
                fail()
        return {"signed_out": True}

    app.include_router(router)


def invite_account(factory, settings, participant_id, condition, hours=72):
    """Local trusted CLI only; assignment is fixed before enrollment."""
    from .admin import provision

    provision(factory, settings, participant_id, condition)
    code = secrets.token_urlsafe(32)
    with transaction(factory) as session:
        session.add(
            Invitation(
                code_hash=digest(code),
                participant_id=participant_id,
                expires_at=time.time() + hours * 3600,
            )
        )
    return code
