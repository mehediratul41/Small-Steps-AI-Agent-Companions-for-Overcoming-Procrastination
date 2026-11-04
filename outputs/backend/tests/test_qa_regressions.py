import asyncio
import threading
from concurrent.futures import ThreadPoolExecutor

from test_api import ai_headers, enroll

from app.ai import MockProvider
from app.db import Participant, transaction


def test_database_unavailability_returns_safe_error_and_recovers(api):
    from sqlalchemy import event
    from sqlalchemy.exc import OperationalError

    client, app, _, tokens = api
    engine = app.state.factory.kw["bind"]

    def unavailable(*_):
        raise OperationalError("synthetic offline", {}, Exception("synthetic failure"))

    event.listen(engine, "before_cursor_execute", unavailable)
    try:
        for path in ["/health", "/api/tasks"]:
            response = client.get(path, headers=tokens["selfAgent"])
            assert response.status_code == 503
            assert response.json()["error"]["code"] == "storage_unavailable"
            assert "synthetic" not in response.text
    finally:
        event.remove(engine, "before_cursor_execute", unavailable)
    assert client.get("/health").status_code == 200


def test_completed_create_retry_returns_original_receipt(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    body = {"id": "done", "title": "Already finished", "done": True}
    first = client.post("/api/tasks", headers=h, json=body)
    second = client.post("/api/tasks", headers=h, json=body)
    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json() == first.json()


def test_blank_unicode_subtask_is_rejected(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    result = client.post(
        "/api/tasks",
        headers=h,
        json={"id": "blank", "title": "Read 日本語 🌱", "subtasks": [{"title": "　  "}]},
    )
    assert result.status_code == 422


def test_completed_task_refinement_is_rejected_before_model_call(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    saved = client.post(
        "/api/tasks",
        headers=h,
        json={"id": "done", "title": "Done", "done": True, "completedAt": "2026-10-27T00:00:00Z"},
    ).json()
    result = client.post("/api/tasks/refine", headers=ai_headers(h), json={"task": saved})
    assert result.status_code == 409
    assert result.json()["error"]["code"] == "task_completed"


def test_queued_request_rechecks_revoked_participant(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    entered = threading.Event()
    release = threading.Event()
    calls = []

    async def slow_chat(condition, message, task, profile, history, language="en"):
        calls.append(message)
        if message == "first":
            entered.set()
            while not release.is_set():
                await asyncio.sleep(0.01)
        return "Your choice."

    provider.chat = slow_chat
    with ThreadPoolExecutor(max_workers=2) as executor:
        first = executor.submit(
            client.post, "/api/chat", headers=ai_headers(h, "first"), json={"message": "first"}
        )
        assert entered.wait(5)
        # The second request waits behind the provider lock after its initial auth.
        second = executor.submit(
            client.post, "/api/chat", headers=ai_headers(h, "second"), json={"message": "second"}
        )
        import time

        time.sleep(0.15)
        with transaction(app.state.factory) as session:
            session.get(Participant, "p0").active = False
        release.set()
        first.result(timeout=5)
        assert second.result(timeout=5).status_code == 401
    assert calls == ["first"]


def test_mock_completed_task_does_not_suggest_starting():
    provider = MockProvider()
    for condition in ("selfAgent", "friendAgent"):
        reply = asyncio.run(
            provider.chat(
                condition, "I already finished this task", {"title": "Read", "done": True}, {}, []
            )
        ).lower()
        assert "start" not in reply and "begin" not in reply
        assert any(word in reply for word in ("complete", "finished", "done"))
