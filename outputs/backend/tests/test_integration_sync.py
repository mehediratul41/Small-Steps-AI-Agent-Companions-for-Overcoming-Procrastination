import pytest
from sqlalchemy import select
from test_api import ai_headers, enroll, task

from app.db import Record, TaskRow, transaction
from app.schemas import Task


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent"])
def test_future_self_note_is_only_in_self_agent_context(api, condition):
    client, _, provider, tokens = api
    h = tokens[condition]
    enroll(client, h)
    original = task(client, h)
    updated = client.patch(
        "/api/tasks/t1",
        headers=h,
        json={**original, "version": 2, "futureNote": "Synthetic future note"},
    )
    assert updated.status_code == 200
    response = client.post(
        "/api/chat",
        headers=ai_headers(h),
        json={"message": "Synthetic context test", "task_id": "t1"},
    )
    assert response.status_code == 200
    context = provider.calls[-1][2]
    assert context.get("futureNote") == (
        "Synthetic future note" if condition == "selfAgent" else None
    )


def test_legacy_optional_fields_do_not_make_refinement_stale(api):
    client, app, _, tokens = api
    h = tokens["selfAgent"]
    enroll(client, h)
    original = task(client, h)
    with transaction(app.state.factory) as session:
        row = session.scalar(select(TaskRow).where(TaskRow.task_id == "t1"))
        row.data = {
            k: v
            for k, v in row.data.items()
            if k not in {"startCue", "startAction", "futureNote", "difficulty"}
        }
    current = Task.model_validate(original).model_dump(mode="json")
    response = client.post("/api/tasks/refine", headers=ai_headers(h), json={"task": current})
    assert response.status_code == 200, response.text


def test_identical_task_update_replay_keeps_version_and_one_audit(api):
    client, _, _, tokens = api
    h = tokens["friendAgent"]
    enroll(client, h)
    original = task(client, h)
    request = {**original, "version": 2, "done": True, "completedAt": None}
    first = client.patch("/api/tasks/t1", headers=h, json=request)
    assert first.status_code == 200
    replay = client.patch("/api/tasks/t1", headers=h, json=request)
    assert replay.status_code == 200, replay.text
    assert replay.json() == first.json()
    assert (
        client.patch(
            "/api/tasks/t1", headers=h, json={**request, "title": "A different edit"}
        ).status_code
        == 409
    )
    records = client.get("/api/export", headers=h).json()["records"]
    assert sum(r["type"] == "audit" and r["data"]["kind"] == "task_updated" for r in records) == 1


def test_delete_response_loss_can_be_retried_without_duplicate_audit(api):
    client, app, _, tokens = api
    h = tokens["standardControl"]
    enroll(client, h)
    task(client, h)
    assert client.delete("/api/tasks/t1?version=1", headers=h).status_code == 200
    assert client.delete("/api/tasks/t1?version=1", headers=h).status_code == 200
    assert client.get("/api/tasks/t1", headers=h).status_code == 404
    with transaction(app.state.factory) as session:
        rows = session.scalars(select(Record).where(Record.kind == "audit")).all()
        assert sum(r.data["kind"] == "task_deleted" for r in rows) == 1
