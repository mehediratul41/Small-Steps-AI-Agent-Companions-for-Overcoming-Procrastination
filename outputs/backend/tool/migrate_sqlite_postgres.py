"""Explicit local cutover; never overwrites a populated PostgreSQL database."""

import argparse
import json
import sqlite3
import sys
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy import create_engine, func, inspect, select, text
from sqlalchemy.engine import make_url

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from app.config import Settings  # noqa: E402
from app.db import Base, SchemaRevision, database  # noqa: E402


def migrate():
    settings = Settings()
    source_url = make_url(settings.database_url)
    if source_url.drivername != "sqlite":
        raise ValueError("Current source must still be SQLite")
    source_path = Path(source_url.database).resolve()
    if not source_path.is_file():
        raise ValueError("Source database does not exist")
    credentials = json.loads((ROOT / ".tmp/postgres-connection.json").read_text(encoding="utf-8"))
    target_url = make_url(credentials["application"])
    if target_url.host != "127.0.0.1" or target_url.database != "small_steps":
        raise ValueError("Unexpected cutover target")
    stamp = datetime.now(UTC).strftime("%Y%m%d-%H%M%S")
    backup = ROOT / ".tmp" / f"sqlite-before-postgres-{stamp}.sqlite3"
    with sqlite3.connect(source_path.as_uri() + "?mode=ro", uri=True) as source:
        with sqlite3.connect(backup) as destination:
            source.backup(destination)
    source_engine = create_engine("sqlite:///" + backup.as_posix())
    target_engine, _ = database(credentials["application"])
    counts = {}
    try:
        existing = set(inspect(source_engine).get_table_names())
        with source_engine.connect() as source, target_engine.begin() as destination:
            tables = [t for t in Base.metadata.sorted_tables if t is not SchemaRevision.__table__]
            # Refuse before inserting anything if any application table has data.
            for table in tables:
                if destination.scalar(select(func.count()).select_from(table)):
                    raise ValueError("Target has application data; refusing to overwrite")
            for table in tables:
                if table.name not in existing:
                    counts[table.name] = 0
                    continue
                rows = [dict(row) for row in source.execute(select(table)).mappings()]
                if rows:
                    destination.execute(table.insert(), rows)
                counts[table.name] = len(rows)
                if "key" in table.c and rows:
                    # Use bound regclass name; sequence name comes from PostgreSQL.
                    destination.execute(
                        text(
                            "SELECT setval(pg_get_serial_sequence(:table, 'key'), "
                            "(SELECT MAX(key) FROM " + table.name + "), true)"
                        ),
                        {"table": table.name},
                    )
        # Preserve original .env and replace only DATABASE_URL after committed copy.
        env_file = ROOT / ".env"
        old = env_file.read_text(encoding="utf-8")
        env_backup = ROOT / ".tmp" / f"env-before-postgres-{stamp}.txt"
        env_backup.write_text(old, encoding="utf-8")
        lines = old.splitlines()
        replacement = "DATABASE_URL=" + credentials["application"]
        changed = False
        for index, line in enumerate(lines):
            if line.startswith("DATABASE_URL="):
                lines[index] = replacement
                changed = True
        if not changed:
            lines.append(replacement)
        temporary = ROOT / ".tmp/env-postgres-new.txt"
        temporary.write_text("\n".join(lines) + "\n", encoding="utf-8")
        temporary.replace(env_file)
        (ROOT / ".tmp/postgres-cutover-receipt.json").write_text(
            json.dumps(
                {
                    "at": datetime.now(UTC).isoformat(),
                    "counts": counts,
                    "sqliteBackup": backup.name,
                    "environmentBackup": env_backup.name,
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        print("SUCCESS: copied row counts:", counts)
        print(
            "Backend configuration now selects PostgreSQL. Original SQLite and private backups are retained."
        )
    finally:
        source_engine.dispose()
        target_engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--server-stopped", action="store_true", required=True)
    parser.parse_args()
    try:
        migrate()
    except Exception:
        print(
            "Cutover failed; no existing PostgreSQL records were overwritten. Review before retrying; do not print credentials."
        )
        sys.exit(1)
