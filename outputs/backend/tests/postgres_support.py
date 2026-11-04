"""Opt-in PostgreSQL fixture isolation. Never operate on an application database."""

import os
from contextlib import contextmanager
from uuid import uuid4

from sqlalchemy import create_engine
from sqlalchemy.engine import make_url


@contextmanager
def test_database_url(sqlite_url):
    configured = os.environ.get("SMALL_STEPS_TEST_POSTGRES_URL")
    if not configured:
        yield sqlite_url
        return
    url = make_url(configured)
    if url.drivername != "postgresql+psycopg" or url.database != "small_steps_test":
        raise ValueError("PostgreSQL tests require the dedicated small_steps_test database")
    if url.host not in {"127.0.0.1", "localhost"}:
        raise ValueError("These development tests require a local PostgreSQL server")
    if url.query:
        raise ValueError("Test base URL must not contain driver options")
    schema = "qa_" + uuid4().hex
    engine = create_engine(url, connect_args={"connect_timeout": 5})
    try:
        with engine.begin() as connection:
            connection.exec_driver_sql(f'CREATE SCHEMA "{schema}"')
        try:
            # Name is generated exclusively above; separate schema for each test.
            scoped = url.update_query_dict({"options": f"-csearch_path={schema}"})
            yield scoped.render_as_string(hide_password=False)
        finally:
            with engine.begin() as connection:
                connection.exec_driver_sql(f'DROP SCHEMA "{schema}" CASCADE')
    finally:
        engine.dispose()
