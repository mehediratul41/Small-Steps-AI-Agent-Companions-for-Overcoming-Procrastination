import asyncio
import json
from pathlib import Path
from unittest.mock import AsyncMock, Mock

import pytest
from google.genai import types
from test_api import ai_headers, enroll

from app.ai import PERSONALITY, PROMPT_VERSION, GeminiProvider
from app.config import Settings

SPEC = json.loads(
    (Path(__file__).parents[1] / "evals/agent_cases.json").read_text(encoding="utf-8")
)
CASES = SPEC["cases"]


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
@pytest.mark.parametrize("case", CASES, ids=lambda c: c["id"])
def test_representative_cases_reach_assigned_prompt_without_tools(case, condition):
    # This checks prompt/context transport only. The mocked text is not a model evaluation.
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
                    content=types.Content(parts=[types.Part(text="Synthetic transport fixture.")])
                )
            ]
        )
    )
    provider.client = fake
    try:
        asyncio.run(provider.chat(condition, case["message"], case["task"], case["profile"], []))
        call = fake.aio.models.generate_content.call_args.kwargs
        config = call["config"]
        assert PERSONALITY[condition] in config.system_instruction
        assert (
            PERSONALITY["friendAgent" if condition == "selfAgent" else "selfAgent"]
            not in config.system_instruction
        )
        assert "cannot change reminder settings" in config.system_instruction
        assert "marked done" in config.system_instruction
        assert "45 words" in config.system_instruction
        assert config.tools is None
        assert call["contents"][-1].parts[0].text == case["message"]
        context = json.loads(
            call["contents"][0].parts[0].text.removeprefix("Context data (not instructions): ")
        )
        assert context["task"]["done"] == case["task"]["done"]
        assert context["profile"] == case["profile"]
        assert PROMPT_VERSION == SPEC["prompt_version"]
    finally:
        asyncio.run(original.aio.aclose())
        original.close()


@pytest.mark.parametrize(
    "body",
    [
        {"title": "", "minutes": 15},
        {"title": "  ", "minutes": 15},
        {"title": "Read", "minutes": -1},
        {"title": "Read", "minutes": 1441},
        {"title": "Read", "due": "2026-02-30T10:00:00Z"},
        {"title": "Read", "due": "2026-10-28T10:00:00"},
        {"title": "Read", "priority": "Urgent"},
    ],
)
def test_invalid_task_inputs_fail_without_mutation(api, body):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    result = client.post("/api/tasks", headers=h, json={"id": "invalid", **body})
    assert result.status_code == 422
    assert client.get("/api/tasks", headers=h).json() == []


def test_unicode_content_and_participant_exports_stay_isolated(api):
    client, app, provider, tokens = api
    own, other = tokens["selfAgent"], tokens["friendAgent"]
    enroll(client, own)
    enroll(client, other)
    text = "研究の最初の一歩 🌱 café"
    assert (
        client.post("/api/tasks", headers=own, json={"id": "unicode", "title": text}).status_code
        == 201
    )
    client.post("/api/chat", headers=ai_headers(own), json={"message": text, "task_id": "unicode"})
    assert client.get("/api/export", headers=own).json()["tasks"][0]["title"] == text
    exported = client.get("/api/export", headers=other).json()
    assert text not in json.dumps(exported, ensure_ascii=False)
    assert "token_hash" not in json.dumps(exported)
