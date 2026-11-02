"""Exercise the complete HTTP path with a synthetic account; never prints tokens."""

import argparse
import json
from pathlib import Path
from uuid import uuid4

import httpx


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--account", required=True)
    parser.add_argument("--url", default="http://127.0.0.1:8000")
    args = parser.parse_args()
    account = json.loads(Path(args.account).read_text())
    with httpx.Client(
        base_url=args.url, headers={"Authorization": f"Bearer {account['token']}"}, timeout=40
    ) as client:

        def checked(method, path, **kwargs):
            result = client.request(method, path, **kwargs)
            result.raise_for_status()
            return result.json()

        participant = checked("GET", "/api/participants/me")
        checked(
            "POST",
            "/api/participants/onboarding",
            json={
                "acknowledged": True,
                "demonstration": True,
                "consent_version": participant["consentVersion"],
            },
        )
        task = checked(
            "POST", "/api/tasks", json={"id": str(uuid4()), "title": "Review one research paper"}
        )
        if participant["condition"] != "standardControl":
            proposal = checked(
                "POST",
                "/api/tasks/refine",
                json={"task": task},
                headers={"Idempotency-Key": str(uuid4())},
            )
            task = checked(
                "POST",
                f"/api/refinements/{proposal['suggestionId']}/accept",
                json={
                    "task_version": task["version"],
                    "subtasks": proposal["subtasks"],
                },
            )
            reply = checked(
                "POST",
                "/api/chat",
                json={"message": "Help me take a small first step", "task_id": task["id"]},
                headers={"Idempotency-Key": str(uuid4())},
            )
            print("Agent reply:", reply["text"])
        checked(
            "PATCH",
            f"/api/tasks/{task['id']}",
            json={**task, "version": task["version"] + 1, "done": True},
        )
        print(
            "Synthetic workflow passed: onboarding, task persistence, AI if assigned, reported completion."
        )


if __name__ == "__main__":
    main()
