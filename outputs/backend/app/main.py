import asyncio
import hashlib
import json
import re
import time
from contextlib import asynccontextmanager, contextmanager
from uuid import uuid4

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import delete, func, select, update
from sqlalchemy.exc import IntegrityError, OperationalError

from .admin import digest
from .ai import (
    LANGUAGE_VERSION,
    PROMPT_VERSION,
    TASK_SUPPORT_VERSION,
    AIUnavailable,
    GeminiProvider,
    MockProvider,
)
from .config import Settings
from .db import (
    AIJob,
    Invitation,
    LoginAccount,
    Participant,
    Record,
    TaskRow,
    database,
    now_iso,
    transaction,
)
from .schemas import (
    AcceptSuggestion,
    BehaviorEvent,
    ChatRequest,
    CheckIn,
    EraseDevelopmentData,
    EventBatch,
    Onboarding,
    Profile,
    RefineRequest,
    Task,
)


def fail(status, code, message):
    raise HTTPException(status, detail={"code": code, "message": message})


def create_app(settings: Settings | None = None, provider=None):
    settings = settings or Settings()
    engine, factory = database(settings.database_url)
    provider = provider or (
        GeminiProvider(settings) if settings.ai_provider == "gemini" else MockProvider()
    )
    # One local worker. Database CAS and unique keys remain the final write guard.
    ai_lock = asyncio.Lock()

    @asynccontextmanager
    async def lifespan(app):
        yield
        await provider.close()
        engine.dispose()

    app = FastAPI(
        title="Small Steps development API",
        version="0.1.0",
        lifespan=lifespan,
        description="Synthetic-data backend; not approved participant enrollment.",
    )
    app.state.factory = factory
    app.state.settings = settings
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
        allow_credentials=False,
    )

    @app.middleware("http")
    async def bounded_body(request: Request, call_next):
        body = bytearray()
        async for part in request.stream():
            body.extend(part)
            if len(body) > 65536:
                return JSONResponse(
                    {"error": {"code": "body_too_large", "message": "Request exceeds 64 KiB"}}, 413
                )
        request._body = bytes(body)
        result = await call_next(request)
        result.headers["Cache-Control"] = "no-store"
        result.headers["X-Content-Type-Options"] = "nosniff"
        return result

    @app.exception_handler(HTTPException)
    async def http_error(request, error):
        detail = error.detail
        if not isinstance(detail, dict):
            detail = {"code": "request_failed", "message": str(detail)}
        return JSONResponse({"error": detail}, status_code=error.status_code)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, error):
        # Pydantic's default response echoes input, which can contain sensitive text.
        return JSONResponse(
            {
                "error": {
                    "code": "invalid_request",
                    "message": "Request validation failed",
                    "fields": [".".join(map(str, e["loc"])) for e in error.errors()],
                }
            },
            status_code=422,
        )

    @app.exception_handler(IntegrityError)
    async def write_conflict(request, error):
        return JSONResponse(
            {"error": {"code": "conflict", "message": "Concurrent write; refresh before retrying"}},
            409,
        )

    @app.exception_handler(OperationalError)
    async def database_unavailable(request, error):
        return JSONResponse(
            {
                "error": {
                    "code": "storage_unavailable",
                    "message": "Storage is temporarily unavailable; refresh before retrying",
                }
            },
            503,
        )

    @app.exception_handler(Exception)
    async def unexpected_error(request, error):
        return JSONResponse(
            {"error": {"code": "internal_error", "message": "Request could not be completed"}}, 500
        )

    bearer = HTTPBearer(auto_error=False)

    def authenticated(credentials: HTTPAuthorizationCredentials | None = Depends(bearer)):
        if not credentials or credentials.scheme.lower() != "bearer":
            fail(401, "unauthorized", "A participant token is required")
        with transaction(factory) as session:
            p = session.scalar(
                select(Participant).where(Participant.token_hash == digest(credentials.credentials))
            )
            if not p or not p.active or p.expires_at <= time.time():
                fail(401, "unauthorized", "Participant token is invalid or expired")
            return p

    from .accounts import install_accounts

    install_accounts(app, factory, settings, authenticated)

    def enrolled(p: Participant = Depends(authenticated)):
        if p.consent_version != settings.consent_version:
            fail(
                403,
                "onboarding_required",
                "Acknowledge the current demonstration information first",
            )
        return p

    def agent(p: Participant = Depends(enrolled)):
        if p.condition == "standardControl":
            fail(403, "condition_restricted", "AI is unavailable for this assignment")
        return p

    @contextmanager
    def owned_transaction(p):
        # Lock the owner through each operation, including erasure. PostgreSQL
        # locks the row; SQLite rejects stale read-to-write upgrades atomically.
        with transaction(factory) as session:
            current = session.scalar(
                select(Participant).where(Participant.id == p.id).with_for_update()
            )
            if not current or not current.active or current.expires_at <= time.time():
                fail(401, "unauthorized", "Participant token is invalid or expired")
            if current.token_hash != p.token_hash or current.condition != p.condition:
                fail(401, "unauthorized", "Participant session changed")
            yield session

    def get_task(session, p, task_id, include_deleted=False):
        row = session.scalar(
            select(TaskRow).where(TaskRow.participant_id == p.id, TaskRow.task_id == task_id)
        )
        if not row or (row.deleted and not include_deleted):
            fail(404, "not_found", "Task not found")
        return row

    def audit(session, p, kind, task_id="", **details):
        session.add(
            Record(
                participant_id=p.id,
                kind="audit",
                record_id=str(uuid4()),
                data={
                    "kind": kind,
                    "taskId": task_id,
                    "at": now_iso(),
                    "condition": p.condition,
                    "protocolVersion": settings.protocol_version,
                    "source": "server",
                    **details,
                },
            )
        )

    def put_task(session, p, row, body: Task):
        data = body.model_dump(mode="json")
        replay = body.version == row.version and row.version > 1
        data["completedAt"] = (
            (data["completedAt"] or (row.data.get("completedAt") if replay else None) or now_iso())
            if body.done
            else None
        )
        if replay and Task.model_validate(row.data).model_dump(mode="json") == data:
            return row.data
        if body.version != row.version + 1:
            fail(409, "stale_task", "Send current task version plus one")
        before = dict(row.data)
        result = session.execute(
            update(TaskRow)
            .where(
                TaskRow.key == row.key, TaskRow.version == row.version, TaskRow.deleted.is_(False)
            )
            .values(data=data, version=body.version)
        )
        if result.rowcount != 1:
            fail(409, "stale_task", "Task changed; refresh first")
        audit(session, p, "task_updated", body.id, before=before, after=data)
        return data

    def current_participant(p):
        with transaction(factory) as session:
            current = session.get(Participant, p.id)
            if not current or not current.active or current.expires_at <= time.time():
                fail(401, "unauthorized", "Participant access is no longer valid")
            if current.token_hash != p.token_hash:
                fail(401, "unauthorized", "Participant session changed")
            if (
                current.condition != p.condition
                or current.consent_version != settings.consent_version
            ):
                fail(403, "assignment_changed", "Reconnect before continuing")
            p.profile = current.profile

    def request_key(value):
        if not value or not re.fullmatch(r"[A-Za-z0-9_.:-]{1,100}", value):
            fail(422, "idempotency_key_required", "Supply a unique Idempotency-Key header")
        return value

    def history_for(session, p, task_id):
        rows = session.scalars(
            select(Record)
            .where(Record.participant_id == p.id, Record.kind == "chat")
            .order_by(Record.key.desc())
            .limit(500)
        ).all()
        turns = [r.data for r in reversed(rows) if r.data.get("taskId") == task_id][-10:]
        return [item for turn in turns for item in (turn["userMessage"], turn["agentMessage"])]

    def support_context(session, p, task):
        # Bounded, owned data only. No new task store or client-supplied history.
        tasks = session.scalars(
            select(TaskRow)
            .where(TaskRow.participant_id == p.id, TaskRow.deleted.is_(False))
            .order_by(TaskRow.key)
            .limit(50)
        ).all()
        rows = session.scalars(
            select(Record)
            .where(Record.participant_id == p.id, Record.kind == "event")
            .order_by(Record.key.desc())
            .limit(100)
        ).all()
        decisions = [
            r.data
            for r in rows
            if r.data.get("taskId") == (task or {}).get("id")
            and r.data.get("kind")
            in {
                "task_recovery",
                "refinement_accepted",
                "refinement_rejected",
                "correction_accepted",
                "correction_rejected",
            }
        ][:10]
        summaries = [
            {
                **{
                    key: r.data.get(key)
                    for key in (
                        "id",
                        "title",
                        "priority",
                        "due",
                        "plannedStart",
                        "minutes",
                        "done",
                        "paused",
                    )
                },
                "description": r.data.get("description", "")[:300],
                "subtasks": r.data.get("subtasks", [])[:3],
            }
            for r in tasks
        ]
        context = {
            "tasks": summaries,
            "recentDecisions": [
                {
                    "kind": d.get("kind"),
                    "at": d.get("at"),
                    "taskVersion": d.get("taskVersion"),
                    "action": d.get("details", {}).get("action"),
                }
                for d in decisions
            ],
            "coverage": "at most 50 tasks and 100 recent events; not complete history",
        }
        result = (
            {**(task or {}), "supportContext": context} if task else {"supportContext": context}
        )
        if p.condition != "selfAgent":
            result.pop("futureNote", None)
        return result

    async def run_ai(p, key, operation, payload, work):
        key = request_key(key)
        fingerprint = hashlib.sha256(
            json.dumps({"operation": operation, "payload": payload}, sort_keys=True).encode()
        ).hexdigest()
        # Serialize the local provider path to enforce quota and conversation ordering.
        async with ai_lock:
            # Authentication may have expired/revoked while this request queued.
            current_participant(p)
            with transaction(factory) as session:
                existing = session.scalar(
                    select(AIJob).where(AIJob.participant_id == p.id, AIJob.request_id == key)
                )
                if existing:
                    if existing.fingerprint != fingerprint:
                        fail(
                            409,
                            "key_reused",
                            "Idempotency key already used for a different request",
                        )
                    if existing.status == "complete":
                        return existing.response
                    fail(
                        409,
                        "ai_request_unresolved",
                        "This request failed or is pending; inspect status before starting a new request",
                    )
                count = session.scalar(
                    select(func.count())
                    .select_from(AIJob)
                    .where(AIJob.participant_id == p.id, AIJob.created_at > time.time() - 3600)
                )
                if count >= settings.ai_requests_per_hour:
                    fail(429, "rate_limited", "Hourly AI request limit reached")
                session.add(
                    AIJob(
                        participant_id=p.id,
                        request_id=key,
                        fingerprint=fingerprint,
                        operation=operation,
                        created_at=time.time(),
                    )
                )
            try:
                result = await asyncio.wait_for(work(key), timeout=30)
            except (AIUnavailable, TimeoutError):
                with transaction(factory) as session:
                    job = session.scalar(
                        select(AIJob).where(AIJob.participant_id == p.id, AIJob.request_id == key)
                    )
                    job.status = "failed"
                fail(
                    503,
                    "ai_unavailable",
                    "AI request did not finish. No task was changed; a provider charge may still apply.",
                )
            except Exception:
                with transaction(factory) as session:
                    job = session.scalar(
                        select(AIJob).where(AIJob.participant_id == p.id, AIJob.request_id == key)
                    )
                    job.status = "failed"
                raise
            with transaction(factory) as session:
                job = session.scalar(
                    select(AIJob).where(AIJob.participant_id == p.id, AIJob.request_id == key)
                )
                job.status, job.response = "complete", result
            return result

    @app.get("/health")
    def health():
        with transaction(factory) as session:
            session.execute(select(1))
        return {
            "status": "ok",
            "mode": settings.app_mode,
            "aiProvider": provider.name,
            "model": provider.model,
            "participantEnrollment": False,
            "invitationAccounts": settings.account_enrollment,
        }

    @app.get("/api/participants/me")
    def me(p: Participant = Depends(authenticated)):
        return {
            "id": p.id,
            "condition": p.condition,
            "onboarded": p.consent_version == settings.consent_version,
            "consentVersion": settings.consent_version,
            "mode": "development",
        }

    @app.post("/api/participants/onboarding")
    def onboard(body: Onboarding, p: Participant = Depends(authenticated)):
        if body.consent_version != settings.consent_version:
            fail(409, "consent_version_changed", "Refresh the demonstration consent version")
        with owned_transaction(p) as session:
            row = session.get(Participant, p.id)
            if row.consent_version != settings.consent_version:
                row.consent_version, row.consent_at = settings.consent_version, now_iso()
                audit(
                    session,
                    p,
                    "demonstration_acknowledged",
                    consentVersion=settings.consent_version,
                )
        return {"acknowledged": True, "demonstration": True}

    @app.get("/api/participants/profile")
    def profile(p: Participant = Depends(enrolled)):
        return Profile.model_validate(p.profile).model_dump()

    @app.patch("/api/participants/profile")
    def save_profile(body: Profile, p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            session.get(Participant, p.id).profile = body.model_dump()
        return body

    @app.get("/api/tasks")
    def tasks(p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            return [
                t.data
                for t in session.scalars(
                    select(TaskRow)
                    .where(TaskRow.participant_id == p.id, TaskRow.deleted.is_(False))
                    .order_by(TaskRow.key)
                )
            ]

    @app.post("/api/tasks", status_code=201)
    def create_task(body: Task, p: Participant = Depends(enrolled)):
        if body.version != 1:
            fail(422, "invalid_version", "New tasks start at version 1")
        data = body.model_dump(mode="json")
        data["completedAt"] = (data["completedAt"] or now_iso()) if body.done else None
        with owned_transaction(p) as session:
            row = session.scalar(
                select(TaskRow).where(TaskRow.participant_id == p.id, TaskRow.task_id == body.id)
            )
            if row:
                # Compare the original request when completion time was server-assigned.
                if body.done and body.completedAt is None and row.version == 1:
                    data["completedAt"] = row.data.get("completedAt")
                if (
                    not row.deleted
                    and Task.model_validate(row.data).model_dump(mode="json") == data
                ):
                    return row.data
                fail(409, "task_id_exists", "Task ID already exists")
            session.add(TaskRow(participant_id=p.id, task_id=body.id, version=1, data=data))
            audit(session, p, "task_created", body.id, after=data)
        return data

    @app.get("/api/tasks/{task_id}")
    def task(task_id: str, p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            return get_task(session, p, task_id).data

    @app.patch("/api/tasks/{task_id}")
    def edit_task(task_id: str, body: Task, p: Participant = Depends(enrolled)):
        if body.id != task_id:
            fail(422, "task_id_mismatch", "Task ID must match route")
        with owned_transaction(p) as session:
            row = get_task(session, p, task_id)
            return put_task(session, p, row, body)

    @app.delete("/api/tasks/{task_id}")
    def delete_task(task_id: str, version: int = Query(ge=1), p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            row = get_task(session, p, task_id, include_deleted=True)
            if row.deleted:
                if row.version == version + 1:
                    return {"deleted": True, "historyRetained": True}
                fail(409, "stale_task", "Task changed; refresh first")
            result = session.execute(
                update(TaskRow)
                .where(
                    TaskRow.key == row.key, TaskRow.version == version, TaskRow.deleted.is_(False)
                )
                .values(deleted=True, version=version + 1)
            )
            if result.rowcount != 1:
                fail(409, "stale_task", "Task changed; refresh first")
            audit(session, p, "task_deleted", task_id, before=row.data)
        return {"deleted": True, "historyRetained": True}

    @app.post("/api/tasks/refine")
    async def refine(
        body: RefineRequest,
        idempotency_key: str | None = Header(default=None),
        p: Participant = Depends(agent),
    ):
        async def work(key):
            with owned_transaction(p) as session:
                row = get_task(session, p, body.task.id)
                if row.data.get("done"):
                    fail(409, "task_completed", "Reopen the task before requesting a breakdown")
                if Task.model_validate(row.data).model_dump(mode="json") != body.task.model_dump(
                    mode="json"
                ):
                    fail(409, "stale_task", "Refine the saved current task first")
                snapshot = row.data
                context = support_context(session, p, snapshot)
            if body.mode == "correction":
                correction = await provider.correct(context, p.condition, language=body.language)
                fields = {"correction": correction.model_dump()}
            else:
                proposal = await provider.refine(
                    context, body.variant, p.condition, language=body.language
                )
                fields = proposal.model_dump()
            data = {
                **fields,
                "mode": body.mode,
                "suggestionId": key,
                "taskId": body.task.id,
                "taskVersion": body.task.version,
                "snapshot": snapshot,
                "status": "proposed",
                "provider": provider.name,
                "model": provider.model,
                "promptVersion": PROMPT_VERSION,
                "taskSupportVersion": TASK_SUPPORT_VERSION,
                "language": body.language,
                "languageVersion": LANGUAGE_VERSION,
            }
            with owned_transaction(p) as session:
                session.add(
                    Record(
                        participant_id=p.id,
                        kind="suggestion",
                        record_id=key,
                        data=data,
                        state="proposed",
                    )
                )
            return data

        return await run_ai(p, idempotency_key, "refine", body.model_dump(mode="json"), work)

    @app.post("/api/refinements/{suggestion_id}/accept")
    def accept(suggestion_id: str, body: AcceptSuggestion, p: Participant = Depends(agent)):
        with owned_transaction(p) as session:
            proposal = session.scalar(
                select(Record)
                .where(
                    Record.participant_id == p.id,
                    Record.kind == "suggestion",
                    Record.record_id == suggestion_id,
                )
                .with_for_update()
            )
            if not proposal or proposal.data["status"] != "proposed":
                fail(409, "proposal_unavailable", "Suggestion no longer available")
            claimed = session.execute(
                update(Record)
                .where(Record.key == proposal.key, Record.state == "proposed")
                .values(state="accepted")
            )
            if claimed.rowcount != 1:
                fail(409, "proposal_unavailable", "Suggestion no longer available")
            data = proposal.data
            row = get_task(session, p, data["taskId"])
            if row.version != body.task_version or row.version != data["taskVersion"]:
                fail(409, "stale_task", "Task changed after this suggestion was generated")
            correction_mode = data.get("mode") == "correction"
            if correction_mode:
                if body.correction is None or body.subtasks is not None:
                    fail(422, "invalid_approval", "Approve an editable task correction only")
                changes = body.correction.model_dump(exclude={"reason"})
            else:
                if body.subtasks is None or body.correction is not None:
                    fail(422, "invalid_approval", "Approve editable subtasks only")
                changes = {"subtasks": [s.model_dump() for s in body.subtasks]}
            revised = Task.model_validate(
                {
                    **row.data,
                    "version": row.version + 1,
                    **changes,
                }
            )
            saved = put_task(session, p, row, revised)
            proposal.data = {
                **data,
                "status": "accepted",
                "acceptedAt": now_iso(),
                "acceptedTask": saved,
            }
            audit(
                session,
                p,
                "correction_accepted" if correction_mode else "refinement_accepted",
                data["taskId"],
                suggestionId=suggestion_id,
            )
            return saved

    @app.post("/api/refinements/{suggestion_id}/reject")
    def reject(suggestion_id: str, p: Participant = Depends(agent)):
        with owned_transaction(p) as session:
            row = session.scalar(
                select(Record)
                .where(
                    Record.participant_id == p.id,
                    Record.kind == "suggestion",
                    Record.record_id == suggestion_id,
                )
                .with_for_update()
            )
            if not row or row.data["status"] != "proposed":
                fail(409, "proposal_unavailable", "Suggestion no longer available")
            claimed = session.execute(
                update(Record)
                .where(Record.key == row.key, Record.state == "proposed")
                .values(state="rejected")
            )
            if claimed.rowcount != 1:
                fail(409, "proposal_unavailable", "Suggestion no longer available")
            row.data = {**row.data, "status": "rejected", "rejectedAt": now_iso()}
            audit(
                session,
                p,
                "correction_rejected"
                if row.data.get("mode") == "correction"
                else "refinement_rejected",
                row.data["taskId"],
                suggestionId=suggestion_id,
            )
        return {"rejected": True}

    @app.post("/api/chat")
    async def chat(
        body: ChatRequest,
        idempotency_key: str | None = Header(default=None),
        p: Participant = Depends(agent),
    ):
        async def work(key):
            with owned_transaction(p) as session:
                task = get_task(session, p, body.task_id).data if body.task_id else None
                history = history_for(session, p, body.task_id)
                context = support_context(session, p, task)
            submitted_at = now_iso()
            text = await provider.chat(
                p.condition, body.message, context, p.profile, history, language=body.language
            )
            reply = {
                "language": body.language,
                "id": str(uuid4()),
                "text": text,
                "user": False,
                "at": now_iso(),
                "taskId": body.task_id,
                "delivery": "sent",
            }
            with owned_transaction(p) as session:
                # If task was removed during generation, do not append a new visible turn.
                if body.task_id:
                    get_task(session, p, body.task_id)
                session.add(
                    Record(
                        participant_id=p.id,
                        kind="chat",
                        record_id=key,
                        data={
                            "taskId": body.task_id,
                            "condition": p.condition,
                            "userMessage": {
                                "language": body.language,
                                "id": key,
                                "text": body.message,
                                "user": True,
                                "at": submitted_at,
                                "taskId": body.task_id,
                            },
                            "agentMessage": reply,
                            "provider": provider.name,
                            "model": provider.model,
                            "promptVersion": PROMPT_VERSION,
                            "taskVersion": task["version"] if task else None,
                            "taskSupportVersion": TASK_SUPPORT_VERSION,
                            "language": body.language,
                            "languageVersion": LANGUAGE_VERSION,
                        },
                    )
                )
            return reply

        return await run_ai(p, idempotency_key, "chat", body.model_dump(), work)

    @app.get("/api/chat/history")
    def history(task_id: str | None = None, p: Participant = Depends(agent)):
        with owned_transaction(p) as session:
            if task_id:
                get_task(session, p, task_id, include_deleted=True)
            return history_for(session, p, task_id)

    @app.get("/api/ai-requests/{request_id}")
    def ai_status(request_id: str, p: Participant = Depends(agent)):
        with owned_transaction(p) as session:
            row = session.scalar(
                select(AIJob).where(AIJob.participant_id == p.id, AIJob.request_id == request_id)
            )
            if not row:
                fail(404, "not_found", "AI request not found")
            return {"status": row.status, "response": row.response}

    def store_event(session, p, body):
        if body.condition and body.condition != p.condition:
            fail(403, "assignment_mismatch", "Event condition does not match assignment")
        if body.taskId:
            get_task(session, p, body.taskId, include_deleted=True)
        data = {**body.model_dump(mode="json"), "condition": p.condition}
        if len(json.dumps(data)) > 16000:
            fail(422, "event_too_large", "Event exceeds storage limit")
        existing = session.scalar(
            select(Record).where(
                Record.participant_id == p.id, Record.kind == "event", Record.record_id == body.id
            )
        )
        if existing:
            if existing.data != data:
                fail(409, "event_id_exists", "Event ID already has different data")
            return
        session.add(Record(participant_id=p.id, kind="event", record_id=body.id, data=data))
        session.flush()

    @app.post("/api/events")
    def events(body: EventBatch, p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            for event in body.events:
                store_event(session, p, event)
        return {"accepted": [e.id for e in body.events]}

    @app.post("/api/focus-sessions")
    def focus(body: BehaviorEvent, p: Participant = Depends(enrolled)):
        if body.kind not in {
            "focus_started",
            "focus_paused",
            "focus_resumed",
            "focus_elapsed",
            "focus_ended_early",
        }:
            fail(422, "invalid_focus_event", "Use the events endpoint for non-focus events")
        with owned_transaction(p) as session:
            store_event(session, p, body)
        return {"accepted": body.id}

    @app.get("/api/progress")
    def progress(p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            return [
                r.data
                for r in session.scalars(
                    select(Record)
                    .where(Record.participant_id == p.id, Record.kind == "event")
                    .order_by(Record.key)
                    .limit(10000)
                )
            ]

    @app.post("/api/check-ins")
    def check_in(body: CheckIn, p: Participant = Depends(enrolled)):
        if body.condition and body.condition != p.condition:
            fail(403, "assignment_mismatch", "Check-in condition does not match assignment")
        data = {**body.model_dump(mode="json"), "condition": p.condition}
        with owned_transaction(p) as session:
            if body.taskId:
                get_task(session, p, body.taskId, include_deleted=True)
            row = session.scalar(
                select(Record).where(
                    Record.participant_id == p.id,
                    Record.kind == "check_in",
                    Record.record_id == body.id,
                )
            )
            if row and row.data != data:
                fail(409, "check_in_id_exists", "Check-in ID already has different data")
            if not row:
                session.add(
                    Record(participant_id=p.id, kind="check_in", record_id=body.id, data=data)
                )
        return {"accepted": body.id, "demonstration": True}

    @app.get("/api/state")
    def state_snapshot(p: Participant = Depends(enrolled)):
        # One read boundary for the development client, with server-owned assignment.
        with owned_transaction(p) as session:
            records = session.scalars(
                select(Record)
                .where(
                    Record.participant_id == p.id,
                    Record.kind.in_(["event", "check_in", "chat"]),
                )
                .order_by(Record.key)
            ).all()
            messages = []
            if p.condition != "standardControl":
                for row in records:
                    if row.kind == "chat":
                        messages.extend([row.data["userMessage"], row.data["agentMessage"]])
            return {
                "participant": {"id": p.id, "condition": p.condition},
                "tasks": [
                    row.data
                    for row in session.scalars(
                        select(TaskRow)
                        .where(TaskRow.participant_id == p.id, TaskRow.deleted.is_(False))
                        .order_by(TaskRow.key)
                    )
                ],
                "profile": p.profile,
                "events": [row.data for row in records if row.kind == "event"],
                "checkIns": [row.data for row in records if row.kind == "check_in"],
                "messages": messages,
            }

    @app.post("/api/participants/erase-development-data")
    async def erase_development_data(
        body: EraseDevelopmentData, p: Participant = Depends(authenticated)
    ):
        # This is a development-account tool, not an approved research withdrawal policy.
        async with ai_lock:
            with owned_transaction(p) as session:
                for model in (TaskRow, Record, AIJob, LoginAccount, Invitation):
                    session.execute(delete(model).where(model.participant_id == p.id))
                owner = session.get(Participant, p.id)
                owner.active = False
                owner.expires_at = 0
                owner.profile = {}
                owner.consent_at = None
                owner.consent_version = None
                owner.token_hash = digest(str(uuid4()))
        return {
            "dataErased": True,
            "credentialRevoked": True,
            "tombstoneRetained": True,
            "scope": "development_database_only",
            "backupsErased": False,
        }

    @app.get("/api/export")
    def export(p: Participant = Depends(enrolled)):
        with owned_transaction(p) as session:
            return {
                "schemaVersion": "development-v1",
                "exportedAt": now_iso(),
                "runtimeProvenance": {
                    "protocolVersion": settings.protocol_version,
                    "currentPromptVersion": PROMPT_VERSION,
                    "currentProvider": provider.name,
                    "currentModel": provider.model,
                    "note": "Current configuration only; historical AI records retain their own provenance.",
                },
                "participant": {
                    "id": p.id,
                    "condition": p.condition,
                    "consentVersion": p.consent_version,
                    "consentAt": p.consent_at,
                    "profile": p.profile,
                },
                "tasks": [
                    {**t.data, "deleted": t.deleted}
                    for t in session.scalars(select(TaskRow).where(TaskRow.participant_id == p.id))
                ],
                "records": [
                    {"type": r.kind, "id": r.record_id, "receivedAt": r.received_at, "data": r.data}
                    for r in session.scalars(
                        select(Record).where(Record.participant_id == p.id).order_by(Record.key)
                    )
                ],
            }

    return app
