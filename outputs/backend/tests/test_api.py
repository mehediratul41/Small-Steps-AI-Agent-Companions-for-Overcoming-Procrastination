import json
import time
from unittest.mock import AsyncMock, Mock

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.admin import provision
from app.ai import PROMPT_VERSION, AIUnavailable, GeminiProvider, MockProvider
from app.config import Settings
from app.db import Participant, transaction
from app.main import create_app
from app.schemas import Suggestion


class SpyProvider(MockProvider):
    def __init__(self):
        self.calls = []
        self.fail = False

    async def chat(self, condition, message, task, profile, history, language="en"):
        self.calls.append((condition, message, task, profile, history))
        if self.fail:
            raise AIUnavailable()
        return await super().chat(condition, message, task, profile, history, language=language)


@pytest.fixture
def api(tmp_path):
    settings = Settings(_env_file=None, database_url=f"sqlite:///{tmp_path / 'test.db'}")
    provider = SpyProvider()
    app = create_app(settings, provider)
    with TestClient(app) as client:
        tokens = {}
        for index, condition in enumerate(("selfAgent", "friendAgent", "standardControl")):
            token = provision(app.state.factory, settings, f"p{index}", condition)
            tokens[condition] = {"Authorization": f"Bearer {token}"}
        yield client, app, provider, tokens


def enroll(client, headers):
    return client.post(
        "/api/participants/onboarding",
        headers=headers,
        json={
            "acknowledged": True,
            "consent_version": "demo-consent-v1",
            "demonstration": True,
        },
    )


def task(client, headers, id="t1"):
    result = client.post("/api/tasks", headers=headers, json={"id": id, "title": "Review research"})
    assert result.status_code == 201, result.text
    return result.json()


def ai_headers(headers, key="req1"):
    return {**headers, "Idempotency-Key": key}


def test_health_auth_and_consent_gate(api):
    client, app, provider, tokens = api
    assert client.get("/health").json()["aiProvider"] == "mock"
    assert client.get("/api/tasks").status_code == 401
    h = tokens["selfAgent"]
    assert client.get("/api/participants/me", headers=h).json()["condition"] == "selfAgent"
    assert client.get("/api/tasks", headers=h).status_code == 403
    assert (
        client.post(
            "/api/participants/onboarding",
            headers=h,
            json={
                "acknowledged": False,
                "consent_version": "demo-consent-v1",
                "demonstration": True,
            },
        ).status_code
        == 422
    )
    assert enroll(client, h).status_code == 200
    assert client.get("/api/tasks", headers=h).json() == []


def test_assignment_and_ownership(api):
    client, app, provider, tokens = api
    own, other = tokens["selfAgent"], tokens["friendAgent"]
    enroll(client, own)
    enroll(client, other)
    saved = task(client, own)
    assert client.get("/api/tasks/t1", headers=other).status_code == 404
    assert (
        client.patch("/api/tasks/t1", headers=other, json={**saved, "version": 2}).status_code
        == 404
    )
    assert (
        client.post(
            "/api/chat", headers=ai_headers(other), json={"message": "Help", "task_id": "t1"}
        ).status_code
        == 404
    )
    assert (
        client.post(
            "/api/chat",
            headers=ai_headers(own),
            json={"message": "Help", "condition": "friendAgent"},
        ).status_code
        == 422
    )
    assert (
        client.patch(
            "/api/participants/me", headers=own, json={"condition": "friendAgent"}
        ).status_code
        == 405
    )


def test_task_revisions_completion_and_persistence(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    saved = task(client, h)
    assert client.patch("/api/tasks/t1", headers=h, json=saved).status_code == 409
    completed = client.patch(
        "/api/tasks/t1", headers=h, json={**saved, "version": 2, "done": True}
    ).json()
    assert completed["done"] and completed["completedAt"]
    assert client.patch("/api/tasks/t1", headers=h, json={**saved, "version": 2}).status_code == 409
    assert client.delete("/api/tasks/t1?version=1", headers=h).status_code == 409
    app2 = create_app(app.state.settings)
    with TestClient(app2) as second:
        assert second.get("/api/tasks/t1", headers=h).json()["done"]
    exported = client.get("/api/export", headers=h).json()
    audit = next(r for r in exported["records"] if r["data"].get("kind") == "task_updated")
    assert audit["data"]["before"]["done"] is False
    assert audit["data"]["after"]["done"] is True
    assert client.delete("/api/tasks/t1?version=2", headers=h).status_code == 200
    assert client.get("/api/tasks", headers=h).json() == []


def test_control_blocks_all_ai_but_keeps_tasks(api):
    client, app, provider, tokens = api
    h = tokens["standardControl"]
    enroll(client, h)
    saved = task(client, h)
    routes = [
        ("/api/chat", {"message": "Help"}),
        ("/api/tasks/refine", {"task": saved}),
        ("/api/refinements/x/accept", {"task_version": 1, "subtasks": [{"title": "Read"}]}),
        ("/api/refinements/x/reject", {}),
    ]
    for route, body in routes:
        assert client.post(route, headers=ai_headers(h), json=body).status_code == 403
    assert client.get("/api/chat/history", headers=h).status_code == 403
    assert client.get("/api/ai-requests/x", headers=h).status_code == 403
    assert provider.calls == []


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
def test_chat_context_profile_history_and_idempotency(api, condition):
    client, app, provider, tokens = api
    h = tokens[condition]
    enroll(client, h)
    task(client, h)
    client.patch("/api/participants/profile", headers=h, json={"goal": "Finish my degree"})
    body = {"message": "I feel stuck", "task_id": "t1"}
    first = client.post("/api/chat", headers=ai_headers(h), json=body)
    assert first.status_code == 200, first.text
    assert first.json()["user"] is False
    assert client.post("/api/chat", headers=ai_headers(h), json=body).json() == first.json()
    assert len(provider.calls) == 1
    assert provider.calls[0][0] == condition
    assert provider.calls[0][3]["goal"] == "Finish my degree"
    assert (
        client.post("/api/chat", headers=ai_headers(h), json={"message": "different"}).status_code
        == 409
    )
    client.post("/api/chat", headers=ai_headers(h, "req2"), json=body)
    assert len(provider.calls[-1][-1]) == 2
    assert len(client.get("/api/chat/history?task_id=t1", headers=h).json()) == 4
    assert client.get("/api/chat/history", headers=h).json() == []
    assert client.get("/api/ai-requests/req1", headers=h).json()["status"] == "complete"


def test_refinement_accept_reject_and_staleness(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    saved = task(client, h)
    proposal = client.post("/api/tasks/refine", headers=ai_headers(h), json={"task": saved}).json()
    assert proposal["promptVersion"] == PROMPT_VERSION
    assert client.get("/api/tasks/t1", headers=h).json()["subtasks"] == []
    assert client.post("/api/refinements/req1/reject", headers=h).status_code == 200
    assert client.get("/api/tasks/t1", headers=h).json()["subtasks"] == []
    client.post("/api/tasks/refine", headers=ai_headers(h, "req2"), json={"task": saved})
    edited = client.patch(
        "/api/tasks/t1", headers=h, json={**saved, "version": 2, "title": "Changed"}
    ).json()
    body = {"task_version": 1, "subtasks": proposal["subtasks"]}
    assert client.post("/api/refinements/req2/accept", headers=h, json=body).status_code == 409
    client.post("/api/tasks/refine", headers=ai_headers(h, "req3"), json={"task": edited})
    accepted = client.post(
        "/api/refinements/req3/accept", headers=h, json={**body, "task_version": 2}
    )
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["version"] == 3
    assert len(accepted.json()["subtasks"]) == 4


def test_events_deduplicate_and_never_complete_from_timer(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    task(client, h)
    event = {
        "id": "e1",
        "kind": "focus_elapsed",
        "taskId": "t1",
        "at": "2026-10-27T08:00:00Z",
        "seconds": 600,
    }
    for _ in range(2):
        assert client.post("/api/focus-sessions", headers=h, json=event).status_code == 200
    assert (
        client.post("/api/focus-sessions", headers=h, json={**event, "seconds": 500}).status_code
        == 409
    )
    assert (
        client.post(
            "/api/events",
            headers=h,
            json={"events": [{**event, "id": "e2", "condition": "friendAgent"}]},
        ).status_code
        == 403
    )
    assert len(client.get("/api/progress", headers=h).json()) == 1
    assert not client.get("/api/tasks/t1", headers=h).json()["done"]
    assert "token" not in json.dumps(client.get("/api/export", headers=h).json())


def test_provider_error_and_quota(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    provider.fail = True
    body = {"message": "Help"}
    assert client.post("/api/chat", headers=ai_headers(h), json=body).status_code == 503
    assert client.post("/api/chat", headers=ai_headers(h), json=body).status_code == 409
    assert client.get("/api/chat/history", headers=h).json() == []
    app.state.settings.ai_requests_per_hour = 1
    assert client.post("/api/chat", headers=ai_headers(h, "new"), json=body).status_code == 429


def test_expired_revoked_and_duplicate_assignment(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    with pytest.raises(ValueError):
        provision(app.state.factory, app.state.settings, "p0", "friendAgent")
    with transaction(app.state.factory) as session:
        session.get(Participant, "p0").expires_at = time.time() - 1
    assert client.get("/api/participants/me", headers=h).status_code == 401
    with transaction(app.state.factory) as session:
        session.get(Participant, "p1").active = False
    assert client.get("/api/participants/me", headers=tokens["friendAgent"]).status_code == 401


def test_validation_limits_timezone_and_secret_redaction(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    assert client.post("/api/chat", headers=h, json={"message": "Hello"}).status_code == 422
    assert (
        client.post(
            "/api/tasks", headers=h, json={"id": "bad", "title": " ", "due": "2026-10-27T10:00:00"}
        ).status_code
        == 422
    )
    bad = client.post("/api/chat", headers=h, json={"message": "secret-text", "unknown": True})
    assert "secret-text" not in bad.text
    assert client.post("/api/chat", headers=h, content="x" * 65537).status_code == 413
    assert client.get("/health").headers["cache-control"] == "no-store"


def test_check_ins_and_batch_atomicity(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    body = {
        "id": "check1",
        "phase": "daily",
        "at": "2026-10-27T08:00:00Z",
        "offsetMinutes": 540,
        "answers": {"burden": "Low"},
    }
    assert client.post("/api/check-ins", headers=h, json=body).status_code == 200
    assert client.post("/api/check-ins", headers=h, json=body).status_code == 200
    assert client.post("/api/check-ins", headers=h, json={**body, "answers": {}}).status_code == 409
    event = {"id": "e1", "kind": "task_started", "at": "2026-10-27T08:00:00Z"}
    assert (
        client.post(
            "/api/events",
            headers=h,
            json={"events": [event, {**event, "id": "e2", "taskId": "missing"}]},
        ).status_code
        == 404
    )
    assert client.get("/api/progress", headers=h).json() == []


def test_configuration_fails_closed():
    with pytest.raises(ValidationError):
        Settings(_env_file=None, ai_provider="gemini", gemini_api_key="", gemini_model="")
    with pytest.raises(ValidationError):
        Settings(_env_file=None, app_mode="production")


def test_google_sdk_config_and_structured_validation():
    import asyncio

    from google.genai import types

    settings = Settings(
        _env_file=None,
        ai_provider="gemini",
        gemini_api_key="synthetic-not-real",
        gemini_model="test-model",
    )
    provider = GeminiProvider(settings)
    original = provider.client
    response = types.GenerateContentResponse(
        candidates=[
            types.Candidate(
                content=types.Content(
                    parts=[
                        types.Part(text='{"subtasks":[{"title":"Read one paragraph","done":true}]}')
                    ]
                )
            )
        ]
    )
    fake = Mock()
    fake.aio.models.generate_content = AsyncMock(return_value=response)
    provider.client = fake
    result = asyncio.run(provider.refine({"id": "t1", "title": "Read"}, 0))
    assert not result.subtasks[0].done
    config = fake.aio.models.generate_content.call_args.kwargs["config"]
    assert config.response_mime_type == "application/json"
    assert config.response_json_schema == Suggestion.model_json_schema()
    asyncio.run(original.aio.aclose())
    original.close()


def test_rejected_proposal_cannot_be_accepted(api):
    client, app, provider, tokens = api
    h = tokens["friendAgent"]
    enroll(client, h)
    saved = task(client, h)
    proposal = client.post("/api/tasks/refine", headers=ai_headers(h), json={"task": saved}).json()
    assert client.post("/api/refinements/req1/reject", headers=h).status_code == 200
    result = client.post(
        "/api/refinements/req1/accept",
        headers=h,
        json={"task_version": 1, "subtasks": proposal["subtasks"]},
    )
    assert result.status_code == 409
    assert client.get("/api/tasks/t1", headers=h).json()["version"] == 1


def test_both_google_personalities_share_generation_settings():
    import asyncio

    from google.genai import types

    provider = GeminiProvider(
        Settings(
            _env_file=None,
            ai_provider="gemini",
            gemini_api_key="synthetic-not-real",
            gemini_model="test-model",
        )
    )
    original = provider.client
    fake = Mock()
    fake.aio.models.generate_content = AsyncMock(
        return_value=types.GenerateContentResponse(
            candidates=[
                types.Candidate(
                    content=types.Content(parts=[types.Part(text="A small step is your choice.")])
                )
            ]
        )
    )
    provider.client = fake
    for condition in ("selfAgent", "friendAgent"):
        assert asyncio.run(provider.chat(condition, "Hello", None, {}, []))
    calls = fake.aio.models.generate_content.call_args_list
    left, right = [c.kwargs["config"] for c in calls]
    assert left.system_instruction != right.system_instruction
    assert left.temperature == right.temperature
    assert left.max_output_tokens == right.max_output_tokens
    assert calls[0].kwargs["model"] == calls[1].kwargs["model"]
    fake.aio.models.generate_content = AsyncMock(
        side_effect=RuntimeError("private-provider-details")
    )
    with pytest.raises(AIUnavailable) as error:
        asyncio.run(provider.chat("selfAgent", "Hello", None, {}, []))
    assert "private-provider-details" not in str(error.value)
    asyncio.run(original.aio.aclose())
    original.close()


def test_state_snapshot_is_owned_and_control_has_no_messages(api):
    client, app, provider, tokens = api
    self_headers = tokens["selfAgent"]
    control_headers = tokens["standardControl"]
    assert client.get("/api/state", headers=self_headers).status_code == 403
    enroll(client, self_headers)
    enroll(client, control_headers)
    task(client, self_headers, id="owned")
    result = client.get("/api/state", headers=self_headers)
    assert result.status_code == 200
    assert result.json()["tasks"][0]["id"] == "owned"
    other = client.get("/api/state", headers=control_headers).json()
    assert other["tasks"] == []
    assert other["messages"] == []
    assert other["participant"]["condition"] == "standardControl"
