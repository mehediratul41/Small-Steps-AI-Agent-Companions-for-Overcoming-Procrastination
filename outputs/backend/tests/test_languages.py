import asyncio
from unittest.mock import AsyncMock, Mock

import pytest
from test_api import ai_headers, enroll, task

from app.ai import LANGUAGE_VERSION, PERSONALITY, GeminiProvider
from app.config import Settings


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
def test_japanese_chat_preserves_assignment_and_english_history(api, condition):
    client, _, _, tokens = api
    h = tokens[condition]
    enroll(client, h)
    task(client, h)
    first = client.post(
        "/api/chat",
        headers=ai_headers(h, "english"),
        json={"message": "Help me begin", "task_id": "t1"},
    )
    assert first.status_code == 200
    result = client.post(
        "/api/chat",
        headers=ai_headers(h, "japanese"),
        json={"message": "始めるのを手伝って", "task_id": "t1", "language": "ja"},
    )
    assert result.status_code == 200, result.text
    assert result.json()["language"] == "ja"
    assert ("ご自身の目標" if condition == "selfAgent" else "一緒に") in result.json()["text"]
    history = client.get("/api/chat/history", headers=h, params={"task_id": "t1"}).json()
    assert history[1]["text"] == first.json()["text"]
    assert history[1]["language"] == "en"
    export = client.get("/api/export", headers=h).json()
    turns = [r["data"] for r in export["records"] if r["type"] == "chat"]
    assert turns[-1]["languageVersion"] == LANGUAGE_VERSION
    assert turns[-1]["language"] == "ja"
    assert turns[-1]["condition"] == condition


@pytest.mark.parametrize("mode", ["breakdown", "correction"])
def test_japanese_proposal_requires_approval(api, mode):
    client, _, _, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    original = task(client, h)
    response = client.post(
        "/api/tasks/refine",
        headers=ai_headers(h),
        json={"task": original, "mode": mode, "language": "ja"},
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["language"] == "ja"
    assert client.get("/api/tasks/t1", headers=h).json() == original
    body = {"task_version": 1}
    if mode == "breakdown":
        assert "小さく" in data["subtasks"][0]["title"]
        body["subtasks"] = data["subtasks"]
    else:
        assert "ご自身" in data["correction"]["reason"]
        body["correction"] = data["correction"]
    assert (
        client.post(
            f"/api/refinements/{data['suggestionId']}/accept", headers=h, json=body
        ).status_code
        == 200
    )


def test_language_validation_retry_identity_and_control_restriction(api):
    client, _, _, tokens = api
    for h in tokens.values():
        enroll(client, h)
    h = tokens["selfAgent"]
    body = {"message": "手伝って", "language": "ja"}
    response = client.post("/api/chat", headers=ai_headers(h), json=body)
    assert response.status_code == 200
    assert client.post("/api/chat", headers=ai_headers(h), json=body).json() == response.json()
    assert (
        client.post("/api/chat", headers=ai_headers(h), json={**body, "language": "en"}).status_code
        == 409
    )
    assert (
        client.post(
            "/api/chat", headers=ai_headers(h, "invalid"), json={**body, "language": "zh"}
        ).status_code
        == 422
    )
    assert (
        client.post(
            "/api/chat", headers=ai_headers(tokens["standardControl"]), json=body
        ).status_code
        == 403
    )


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
def test_sdk_japanese_instruction_keeps_persona_without_live_call(condition):
    provider = GeminiProvider(
        Settings(
            _env_file=None,
            ai_provider="gemini",
            gemini_api_key="synthetic-only",
            gemini_model="synthetic-only",
        )
    )
    generate = AsyncMock(return_value=Mock(text="無理のない一歩を選べます。"))
    provider.client.aio.models.generate_content = generate
    try:
        result = asyncio.run(provider.chat(condition, "Help", None, {}, [], language="ja"))
        assert result == "無理のない一歩を選べます。"
        instruction = generate.call_args.kwargs["config"].system_instruction
        assert PERSONALITY[condition] in instruction
        assert "natural Japanese" in instruction
    finally:
        provider.client.close()
