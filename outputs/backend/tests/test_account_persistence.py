"""Returning users recover server records, including after API reconstruction."""

from fastapi.testclient import TestClient
from postgres_support import test_database_url as isolated_database
from test_accounts import PASSWORD, headers, register
from test_api import SpyProvider, ai_headers, enroll, task

from app.config import Settings
from app.main import create_app


def test_three_users_logout_restart_and_owned_history(tmp_path):
    with isolated_database(f"sqlite:///{tmp_path / 'returning.db'}") as url:
        settings = Settings(_env_file=None, database_url=url)
        provider = SpyProvider()
        first = create_app(settings, provider)
        before = {}
        old_headers = {}
        conditions = ("selfAgent", "friendAgent", "standardControl")
        with TestClient(first) as client:
            for index, condition in enumerate(conditions):
                name = f"returning{index}"
                account, _ = register(client, first, condition, name)
                h = headers(account)
                old_headers[name] = h
                assert enroll(client, h).status_code == 200
                task(client, h, f"private-{index}")
                assert (
                    client.patch(
                        "/api/participants/profile",
                        headers=h,
                        json={"goal": f"private goal {index}", "brief": bool(index)},
                    ).status_code
                    == 200
                )
                if condition != "standardControl":
                    response = client.post(
                        "/api/chat",
                        headers=ai_headers(h, "owned-turn"),
                        json={"message": f"private message {index}", "task_id": f"private-{index}"},
                    )
                    assert response.status_code == 200
                    # Same ID/body returns the committed turn without a second model call.
                    count = len(provider.calls)
                    assert (
                        client.post(
                            "/api/chat",
                            headers=ai_headers(h, "owned-turn"),
                            json={
                                "message": f"private message {index}",
                                "task_id": f"private-{index}",
                            },
                        ).status_code
                        == 200
                    )
                    assert len(provider.calls) == count
                    assert all(
                        f"private message {other}" not in str(provider.calls[-1])
                        for other in range(index)
                    )
                else:
                    assert (
                        client.post(
                            "/api/chat",
                            headers=ai_headers(h),
                            json={"message": "hello"},
                        ).status_code
                        == 403
                    )
                before[name] = client.get("/api/state", headers=h).json()
                assert client.post("/api/auth/logout", headers=h).status_code == 200
                assert client.get("/api/state", headers=h).status_code == 401
        first.state.factory.kw["bind"].dispose()

        # New app/engine, same database: no in-memory provider/session can restore records.
        second = create_app(settings, SpyProvider())
        with TestClient(second) as client:
            for index, condition in enumerate(conditions):
                name = f"returning{index}"
                assert client.get("/api/state", headers=old_headers[name]).status_code == 401
                response = client.post(
                    "/api/auth/login",
                    json={"username": name, "password": PASSWORD},
                )
                assert response.status_code == 200
                h = headers(response.json())
                restored = client.get("/api/state", headers=h)
                assert restored.status_code == 200
                assert restored.json() == before[name]
                assert restored.json()["participant"]["condition"] == condition
                assert len(restored.json()["messages"]) == (0 if index == 2 else 2)
                other = f"private-{(index + 1) % 3}"
                assert client.get(f"/api/tasks/{other}", headers=h).status_code == 404
                exported = client.get("/api/export", headers=h).json()
                assert [t["id"] for t in exported["tasks"]] == [f"private-{index}"]
        second.state.factory.kw["bind"].dispose()
