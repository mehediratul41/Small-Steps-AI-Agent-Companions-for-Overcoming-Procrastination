"""Local interactive bootstrap; administrator password is never saved or printed."""

import getpass
import json
import os
import secrets
import sys
from pathlib import Path

import psycopg
from psycopg import sql
from sqlalchemy.engine import URL

ROOT = Path(__file__).resolve().parents[1]


def main():
    folder = ROOT / ".tmp"
    folder.mkdir(exist_ok=True)
    output = folder / "postgres-connection.json"
    if output.exists():
        print("Connection file already exists; no accounts or passwords were changed.")
        return
    print("Small Steps: local PostgreSQL connection setup")
    print(
        "Enter the postgres password chosen during installation. It will not be displayed or saved."
    )
    password = getpass.getpass("PostgreSQL administrator password: ")
    try:
        admin = psycopg.connect(
            host="127.0.0.1",
            port=5432,
            dbname="postgres",
            user="postgres",
            password=password,
            connect_timeout=5,
            autocommit=True,
        )
    except psycopg.OperationalError:
        print("Could not authenticate to local PostgreSQL. No password was saved. Rerun to retry.")
        return
    del password
    plans = [("small_steps_app", "small_steps"), ("small_steps_test_user", "small_steps_test")]
    credentials = {}
    try:
        # Refuse collisions rather than alter an existing database or role.
        for role, database in plans:
            if admin.execute("SELECT 1 FROM pg_roles WHERE rolname=%s", (role,)).fetchone():
                raise ValueError("A target role already exists; review it before retrying")
            if admin.execute("SELECT 1 FROM pg_database WHERE datname=%s", (database,)).fetchone():
                raise ValueError("A target database already exists; review it before retrying")
        for role, database in plans:
            secret = secrets.token_urlsafe(36)
            admin.execute(
                sql.SQL(
                    "CREATE ROLE {} LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD {}"
                ).format(sql.Identifier(role), sql.Literal(secret))
            )
            admin.execute(
                sql.SQL("CREATE DATABASE {} OWNER {} ENCODING 'UTF8' TEMPLATE template0").format(
                    sql.Identifier(database), sql.Identifier(role)
                )
            )
            admin.execute(
                sql.SQL("REVOKE ALL ON DATABASE {} FROM PUBLIC").format(sql.Identifier(database))
            )
            url = URL.create(
                "postgresql+psycopg",
                username=role,
                password=secret,
                host="127.0.0.1",
                port=5432,
                database=database,
            )
            credentials["application" if database == "small_steps" else "test"] = (
                url.render_as_string(hide_password=False)
            )
        # Only application/test credentials, never the administrator password.
        with output.open("x", encoding="utf-8") as handle:
            json.dump(credentials, handle)
        if os.name == "nt":
            import subprocess

            subprocess.run(
                [
                    "icacls",
                    str(output),
                    "/inheritance:r",
                    "/grant:r",
                    os.environ.get("USERNAME", "") + ":F",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
        print(
            "SUCCESS: separate application/test databases created; private connection file saved."
        )
        print(
            "Administrator access was not given to the application. Existing SQLite data is unchanged."
        )
    finally:
        admin.close()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Driver errors can contain connection details or SQL; never print them.
        print(
            "Setup did not finish. Existing roles/databases were not dropped. Review local setup before retrying."
        )
        sys.exit(1)
    finally:
        if sys.stdin.isatty():
            input("Press Enter to close this window...")
