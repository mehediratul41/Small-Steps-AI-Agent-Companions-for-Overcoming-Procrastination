import pytest
from postgres_support import test_database_url as isolated_database


@pytest.mark.parametrize(
    "url",
    [
        "postgresql+psycopg://tester:synthetic@127.0.0.1/small_steps",
        "postgresql+psycopg://tester:synthetic@external.invalid/small_steps_test",
        "postgresql+psycopg://tester:synthetic@127.0.0.1/small_steps_test?options=unsafe",
    ],
)
def test_postgres_runner_refuses_application_remote_or_overridden_target(monkeypatch, url):
    monkeypatch.setenv("SMALL_STEPS_TEST_POSTGRES_URL", url)
    with pytest.raises(ValueError):
        with isolated_database("sqlite:///:memory:"):
            pytest.fail("Unsafe target was accepted")


def test_default_runner_remains_sqlite(monkeypatch):
    monkeypatch.delenv("SMALL_STEPS_TEST_POSTGRES_URL", raising=False)
    with isolated_database("sqlite:///:memory:") as url:
        assert url == "sqlite:///:memory:"
