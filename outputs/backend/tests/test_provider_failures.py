from unittest.mock import AsyncMock

import pytest
from google.genai.errors import APIError
from test_api import ai_headers, enroll

from app.ai import AIUnavailable


@pytest.mark.parametrize(
    "status,reason",
    [(503, "capacity"), (429, "quota"), (403, "access"), (504, "timeout"), (500, "unavailable")],
)
def test_provider_failure_classification_does_not_expose_secrets(status, reason):
    raw = APIError(status, {"message": "private-provider-key-and-url"})
    safe = AIUnavailable.from_provider(raw)
    assert safe.reason == reason
    assert "private-provider" not in str(safe)


def test_owned_failure_status_retains_safe_cause_without_regeneration(api):
    client, _, provider, tokens = api
    h = tokens["friendAgent"]
    enroll(client, h)
    provider.chat = AsyncMock(side_effect=AIUnavailable("capacity"))
    response = client.post(
        "/api/chat", headers=ai_headers(h, "capacity-check"), json={"message": "hello"}
    )
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "ai_capacity"
    status = client.get("/api/ai-requests/capacity-check", headers=h).json()
    assert status["status"] == "failed"
    assert status["response"]["error"]["code"] == "ai_capacity"
    assert (
        client.get("/api/ai-requests/capacity-check", headers=tokens["selfAgent"]).status_code
        == 403
    )
    assert (
        client.post(
            "/api/chat", headers=ai_headers(h, "capacity-check"), json={"message": "hello"}
        ).status_code
        == 409
    )
    assert provider.chat.await_count == 1
