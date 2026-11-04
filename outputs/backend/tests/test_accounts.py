import time

import pytest
from sqlalchemy import select
from test_api import ai_headers, enroll, task

from app.accounts import invite_account
from app.admin import digest
from app.db import Invitation, LoginAccount, Participant, SchemaRevision, transaction

PASSWORD = "synthetic-test-passphrase!"


def register(client, app, condition="selfAgent", name="alpha"):
    code = invite_account(app.state.factory, app.state.settings, "TEST-" + name, condition)
    response = client.post(
        "/api/auth/enroll",
        json={
            "username": name,
            "password": PASSWORD,
            "invitation": code,
        },
    )
    assert response.status_code == 201, response.text
    return response.json(), code


def headers(session):
    return {"Authorization": "Bearer " + session["token"]}


@pytest.mark.parametrize("condition", ["selfAgent", "friendAgent", "standardControl"])
def test_enroll_login_expiry_revocation_and_consent(api, condition):
    client, app, _, _ = api
    account, code = register(client, app, condition)
    h = headers(account)
    assert account["condition"] == condition
    assert client.get("/api/tasks", headers=h).status_code == 403
    assert enroll(client, h).status_code == 200
    task(client, h)
    assert (
        client.post(
            "/api/auth/enroll",
            json={
                "username": "other",
                "password": PASSWORD,
                "invitation": code,
            },
        ).status_code
        == 400
    )
    logged_in = client.post("/api/auth/login", json={"username": "ALPHA", "password": PASSWORD})
    assert logged_in.status_code == 200
    assert client.get("/api/state", headers=h).status_code == 401
    h = headers(logged_in.json())
    assert len(client.get("/api/state", headers=h).json()["tasks"]) == 1
    if condition == "standardControl":
        assert (
            client.post("/api/chat", headers=ai_headers(h), json={"message": "hello"}).status_code
            == 403
        )
    with transaction(app.state.factory) as db:
        row = db.get(LoginAccount, "alpha")
        assert row.password_hash.startswith("$argon2id$")
        assert PASSWORD not in row.password_hash
        assert db.get(Invitation, digest(code)).used
        db.get(Participant, account["participant_id"]).expires_at = time.time() - 1
    assert client.get("/api/state", headers=h).status_code == 401
    renewed = client.post("/api/auth/login", json={"username": "alpha", "password": PASSWORD})
    h = headers(renewed.json())
    assert client.post("/api/auth/logout", headers=h).json()["signed_out"]
    assert client.get("/api/participants/me", headers=h).status_code == 401


def test_cross_account_nested_ids_and_export_isolation(api):
    client, app, provider, _ = api
    a, _ = register(client, app, name="alpha")
    b, _ = register(client, app, "friendAgent", name="bravo")
    ah, bh = headers(a), headers(b)
    enroll(client, ah)
    enroll(client, bh)
    t = task(client, ah, "private-a")
    for index, (verb, path, body) in enumerate(
        [
            ("get", "/api/tasks/private-a", None),
            ("patch", "/api/tasks/private-a", {**t, "version": 2}),
            ("delete", "/api/tasks/private-a?version=1", None),
            ("post", "/api/chat", {"message": "guess", "task_id": "private-a"}),
            ("post", "/api/tasks/refine", {"task": t}),
            (
                "post",
                "/api/focus-sessions",
                {
                    "id": "f",
                    "kind": "focus_started",
                    "at": "2026-11-02T00:00:00Z",
                    "taskId": "private-a",
                },
            ),
        ]
    ):
        kw = {"headers": ai_headers(bh, f"cross-{index}")}
        if body is not None:
            kw["json"] = body
        assert getattr(client, verb)(path, **kw).status_code == 404, path
    proposal = client.post(
        "/api/tasks/refine", headers=ai_headers(ah, "p"), json={"task": t}
    ).json()
    assert (
        client.post(f"/api/refinements/{proposal['suggestionId']}/reject", headers=bh).status_code
        == 409
    )
    assert client.get("/api/ai-requests/p", headers=bh).status_code == 404
    assert client.get("/api/state", headers=bh).json()["tasks"] == []
    assert client.get("/api/export", headers=bh).json()["participant"]["id"] == b["participant_id"]
    assert (
        client.post(
            "/api/chat", headers=ai_headers(bh, "chat"), json={"message": "hello"}
        ).status_code
        == 200
    )
    assert provider.calls[-1][2]["supportContext"]["tasks"] == []
    assert "private-a" not in str(provider.calls[-1])
    assert (
        client.post(
            "/api/participants/erase-development-data",
            headers=bh,
            json={"confirmation": "ERASE MY DEVELOPMENT DATA"},
        ).status_code
        == 200
    )
    assert len(client.get("/api/tasks", headers=ah).json()) == 1
    assert (
        client.post("/api/auth/login", json={"username": "bravo", "password": PASSWORD}).status_code
        == 401
    )


def test_invalid_invitation_assignment_injection_and_rate_limit(api):
    client, app, _, _ = api
    code = invite_account(app.state.factory, app.state.settings, "TEST-expired", "selfAgent")
    with transaction(app.state.factory) as db:
        db.get(Invitation, digest(code)).expires_at = 0
    body = {"username": "alpha", "password": PASSWORD, "invitation": code}
    assert client.post("/api/auth/enroll", json=body).status_code == 400
    assert (
        client.post("/api/auth/enroll", json={**body, "condition": "friendAgent"}).status_code
        == 422
    )
    assert (
        client.post("/api/auth/login", json={"username": "alpha", "password": "short"}).status_code
        == 422
    )
    for _ in range(10):
        assert (
            client.post(
                "/api/auth/login", json={"username": "missing", "password": PASSWORD}
            ).status_code
            == 401
        )
    assert (
        client.post(
            "/api/auth/login", json={"username": "missing", "password": PASSWORD}
        ).status_code
        == 429
    )
    with transaction(app.state.factory) as db:
        assert db.scalars(select(SchemaRevision.version)).all() == [2]


def test_disabled_account_cannot_renew_and_errors_are_generic(api):
    client, app, _, _ = api
    account, _ = register(client, app)
    with transaction(app.state.factory) as db:
        db.get(Participant, account["participant_id"]).active = False
    disabled = client.post("/api/auth/login", json={"username": "alpha", "password": PASSWORD})
    missing = client.post("/api/auth/login", json={"username": "missing", "password": PASSWORD})
    wrong = client.post("/api/auth/login", json={"username": "alpha", "password": PASSWORD + "x"})
    assert disabled.status_code == missing.status_code == wrong.status_code == 401
    assert disabled.json() == missing.json() == wrong.json()


def test_additive_migration_preserves_legacy_account(tmp_path):
    import sqlite3

    from sqlalchemy import inspect

    from app.db import database

    path = tmp_path / "legacy.db"
    with sqlite3.connect(path) as old:
        old.execute(
            "CREATE TABLE participants (id VARCHAR(100) PRIMARY KEY, condition VARCHAR(30), "
            "token_hash VARCHAR(64) UNIQUE, expires_at FLOAT, active BOOLEAN, "
            "consent_version VARCHAR(100), consent_at VARCHAR(50), profile JSON)"
        )
        old.execute(
            "INSERT INTO participants VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                "legacy",
                "friendAgent",
                digest("synthetic-legacy"),
                time.time() + 500,
                1,
                None,
                None,
                "{}",
            ),
        )
    for _ in range(2):
        engine, factory = database(f"sqlite:///{path}")
        with transaction(factory) as db:
            assert db.get(Participant, "legacy").condition == "friendAgent"
            assert db.get(Participant, "legacy").token_hash == digest("synthetic-legacy")
            assert db.scalars(select(SchemaRevision.version)).all() == [2]
        assert (
            inspect(engine).get_foreign_keys("login_accounts")[0]["referred_table"]
            == "participants"
        )
        engine.dispose()
