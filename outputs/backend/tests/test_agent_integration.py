import asyncio
from unittest.mock import AsyncMock, Mock

import pytest
from test_api import ai_headers, enroll, task

from app.ai import PERSONALITY, TASK_SUPPORT_VERSION, AIUnavailable, GeminiProvider
from app.config import Settings


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
def test_correction_requires_explicit_owned_versioned_approval(api, condition):
    client, app, provider, tokens = api
    h = tokens[condition]
    enroll(client, h)
    original = task(client, h)
    proposal = client.post(
        "/api/tasks/refine", headers=ai_headers(h), json={"task": original, "mode": "correction"}
    )
    assert proposal.status_code == 200, proposal.text
    data = proposal.json()
    assert data["taskSupportVersion"] == TASK_SUPPORT_VERSION
    assert client.get("/api/tasks/t1", headers=h).json() == original
    correction = {**data["correction"], "title": "Read one HAI paper", "minutes": 10}
    route = f"/api/refinements/{data['suggestionId']}/accept"
    accepted = client.post(route, headers=h, json={"task_version": 1, "correction": correction})
    assert accepted.status_code == 200, accepted.text
    saved = accepted.json()
    assert saved["title"] == correction["title"] and saved["minutes"] == 10
    for field in ("due", "plannedStart", "reminder", "priority", "done", "subtasks"):
        assert saved[field] == original[field]
    assert (
        client.post(
            route, headers=h, json={"task_version": 2, "correction": correction}
        ).status_code
        == 409
    )
    assert client.get("/api/tasks/t1", headers=h).json()["version"] == 2


def test_correction_rejection_stale_data_and_forbidden_fields(api):
    client, _, _, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    original = task(client, h)
    data = client.post(
        "/api/tasks/refine", headers=ai_headers(h), json={"task": original, "mode": "correction"}
    ).json()
    route = f"/api/refinements/{data['suggestionId']}"
    invalid = {**data["correction"], "done": True}
    assert (
        client.post(
            route + "/accept", headers=h, json={"task_version": 1, "correction": invalid}
        ).status_code
        == 422
    )
    assert client.post(route + "/accept", headers=h, json={"task_version": 1}).status_code == 422
    assert client.post(route + "/reject", headers=h).status_code == 200
    assert client.get("/api/tasks/t1", headers=h).json() == original
    data = client.post(
        "/api/tasks/refine",
        headers=ai_headers(h, "second"),
        json={"task": original, "mode": "correction"},
    ).json()
    client.patch("/api/tasks/t1", headers=h, json={**original, "title": "Later edit", "version": 2})
    assert (
        client.post(
            f"/api/refinements/{data['suggestionId']}/accept",
            headers=h,
            json={"task_version": 1, "correction": data["correction"]},
        ).status_code
        == 409
    )
    assert client.get("/api/tasks/t1", headers=h).json()["title"] == "Later edit"


def test_control_and_cross_account_cannot_generate_or_approve_corrections(api):
    client, _, _, tokens = api
    for h in tokens.values():
        enroll(client, h)
    original = task(client, tokens["selfAgent"])
    data = client.post(
        "/api/tasks/refine",
        headers=ai_headers(tokens["selfAgent"]),
        json={"task": original, "mode": "correction"},
    ).json()
    for condition, expected in [("friendAgent", 409), ("standardControl", 403)]:
        assert (
            client.post(
                f"/api/refinements/{data['suggestionId']}/accept",
                headers=tokens[condition],
                json={"task_version": 1, "correction": data["correction"]},
            ).status_code
            == expected
        )
    assert (
        client.post(
            "/api/tasks/refine",
            headers=ai_headers(tokens["standardControl"]),
            json={"task": original, "mode": "correction"},
        ).status_code
        == 403
    )
    assert (
        client.post(
            "/api/chat",
            headers=ai_headers(tokens["selfAgent"], "override"),
            json={"message": "hello", "condition": "friendAgent"},
        ).status_code
        == 422
    )


def test_task_context_includes_owned_tasks_and_decisions_only(api):
    client, _, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    enroll(client, tokens["friendAgent"])
    task(client, h)
    task(client, tokens["friendAgent"], "private-other")
    client.post(
        "/api/events",
        headers=h,
        json={
            "events": [
                {
                    "id": "deferral-1",
                    "kind": "task_recovery",
                    "taskId": "t1",
                    "at": "2026-10-30T10:00:00Z",
                    "condition": "selfAgent",
                    "details": {"action": "reschedule"},
                }
            ]
        },
    )
    assert (
        client.post(
            "/api/chat",
            headers=ai_headers(h),
            json={"message": "Which task should I do now?", "task_id": "t1"},
        ).status_code
        == 200
    )
    context = provider.calls[-1][2]["supportContext"]
    assert [t["id"] for t in context["tasks"]] == ["t1"]
    assert context["recentDecisions"][0]["kind"] == "task_recovery"
    assert (
        client.post(
            "/api/chat",
            headers=ai_headers(h, "general"),
            json={"message": "Suggest something productive"},
        ).status_code
        == 200
    )


def test_failed_correction_does_not_change_task_or_retry_automatically(api):
    client, _, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    original = task(client, h)
    provider.correct = AsyncMock(side_effect=AIUnavailable())
    payload = {"task": original, "mode": "correction"}
    assert client.post("/api/tasks/refine", headers=ai_headers(h), json=payload).status_code == 503
    assert client.post("/api/tasks/refine", headers=ai_headers(h), json=payload).status_code == 409
    assert provider.correct.await_count == 1
    assert client.get("/api/tasks/t1", headers=h).json() == original


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
def test_sdk_correction_uses_assigned_persona_and_validates_output(condition):
    provider = GeminiProvider(
        Settings(
            _env_file=None,
            ai_provider="gemini",
            gemini_api_key="synthetic-test-key",
            gemini_model="synthetic-model",
        )
    )
    generate = AsyncMock(
        return_value=Mock(
            text='{"title":"Read one paper","description":"Make a note","minutes":10,"reason":"One manageable step"}'
        )
    )
    provider.client.aio.models.generate_content = generate
    try:
        result = asyncio.run(provider.correct({"title": "Read"}, condition))
        assert result.minutes == 10
        assert PERSONALITY[condition] in generate.call_args.kwargs["config"].system_instruction
        generate.return_value = Mock(text='{"title":"","minutes":-10}')
        with pytest.raises(AIUnavailable):
            asyncio.run(provider.correct({"title": "Read"}, condition))
    finally:
        provider.client.close()
