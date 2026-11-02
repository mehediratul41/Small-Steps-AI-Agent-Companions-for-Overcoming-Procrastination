import pytest
from sqlalchemy import func, select
from test_api import ai_headers, enroll, task

from app.db import AIJob, Participant, Record, TaskRow, transaction


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent", "standardControl"])
def test_erasure_requires_confirmation_and_erases_only_owner(api, condition):
    client, app, provider, tokens = api
    own = tokens[condition]
    other = tokens["friendAgent" if condition != "friendAgent" else "selfAgent"]
    enroll(client, own)
    enroll(client, other)
    task(client, own, "private")
    task(client, other, "retained")
    client.patch("/api/participants/profile", headers=own, json={"goal": "Private goal"})
    if condition != "standardControl":
        assert (
            client.post(
                "/api/chat", headers=ai_headers(own), json={"message": "Synthetic private text"}
            ).status_code
            == 200
        )
    endpoint = "/api/participants/erase-development-data"
    assert (
        client.post(endpoint, json={"confirmation": "ERASE MY DEVELOPMENT DATA"}).status_code == 401
    )
    assert client.post(endpoint, headers=own, json={"confirmation": "yes"}).status_code == 422
    assert client.get("/api/tasks", headers=own).json()[0]["id"] == "private"
    result = client.post(endpoint, headers=own, json={"confirmation": "ERASE MY DEVELOPMENT DATA"})
    assert result.status_code == 200
    assert result.json() == {
        "dataErased": True,
        "credentialRevoked": True,
        "tombstoneRetained": True,
        "scope": "development_database_only",
        "backupsErased": False,
    }
    assert client.get("/api/export", headers=own).status_code == 401
    assert (
        client.post(
            "/api/tasks", headers=own, json={"id": "no", "title": "Cannot recreate"}
        ).status_code
        == 401
    )
    assert client.get("/api/tasks", headers=other).json()[0]["id"] == "retained"
    owner_id = "p" + str(("selfAgent", "friendAgent", "standardControl").index(condition))
    with transaction(app.state.factory) as session:
        marker = session.get(Participant, owner_id)
        assert marker.active is False and marker.profile == {} and marker.consent_at is None
        for model in (TaskRow, Record, AIJob):
            assert (
                session.scalar(
                    select(func.count()).select_from(model).where(model.participant_id == owner_id)
                )
                == 0
            )


def test_complete_export_has_runtime_provenance_and_retained_audit(api):
    client, app, provider, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    saved = task(client, h)
    assert (
        client.delete("/api/tasks/t1", headers=h, params={"version": saved["version"]}).status_code
        == 200
    )
    exported = client.get("/api/export", headers=h).json()
    assert exported["tasks"][0]["deleted"] is True
    assert any(r["type"] == "audit" for r in exported["records"])
    assert exported["runtimeProvenance"]["currentPromptVersion"] == "small-steps-agents-v3"
    assert exported["runtimeProvenance"]["currentProvider"] == "mock"
