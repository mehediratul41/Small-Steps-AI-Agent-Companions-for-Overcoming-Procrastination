from contextlib import contextmanager
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy import JSON, Boolean, Float, Integer, String, UniqueConstraint, create_engine, event
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker


def now_iso():
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")


class Base(DeclarativeBase):
    pass


class Participant(Base):
    __tablename__ = "participants"
    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    condition: Mapped[str] = mapped_column(String(30))
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    expires_at: Mapped[float] = mapped_column(Float)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    consent_version: Mapped[str | None] = mapped_column(String(100), nullable=True)
    consent_at: Mapped[str | None] = mapped_column(String(50), nullable=True)
    profile: Mapped[dict] = mapped_column(JSON, default=dict)


class TaskRow(Base):
    __tablename__ = "tasks"
    __table_args__ = (UniqueConstraint("participant_id", "task_id"),)
    key: Mapped[int] = mapped_column(primary_key=True)
    participant_id: Mapped[str] = mapped_column(String(100), index=True)
    task_id: Mapped[str] = mapped_column(String(100))
    version: Mapped[int] = mapped_column(Integer)
    deleted: Mapped[bool] = mapped_column(Boolean, default=False)
    data: Mapped[dict] = mapped_column(JSON)


class Record(Base):
    """Owned append-only records for events, check-ins, and conversation history."""

    __tablename__ = "records"
    __table_args__ = (UniqueConstraint("participant_id", "kind", "record_id"),)
    key: Mapped[int] = mapped_column(primary_key=True)
    participant_id: Mapped[str] = mapped_column(String(100), index=True)
    kind: Mapped[str] = mapped_column(String(50))
    record_id: Mapped[str] = mapped_column(String(100))
    state: Mapped[str] = mapped_column(String(20), default="stored")
    received_at: Mapped[str] = mapped_column(String(50), default=now_iso)
    data: Mapped[dict] = mapped_column(JSON)


class AIJob(Base):
    __tablename__ = "ai_jobs"
    __table_args__ = (UniqueConstraint("participant_id", "request_id"),)
    key: Mapped[int] = mapped_column(primary_key=True)
    participant_id: Mapped[str] = mapped_column(String(100), index=True)
    request_id: Mapped[str] = mapped_column(String(100))
    fingerprint: Mapped[str] = mapped_column(String(64))
    operation: Mapped[str] = mapped_column(String(20))
    created_at: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    response: Mapped[dict | None] = mapped_column(JSON, nullable=True)


def database(url: str):
    if url.startswith("sqlite:///./"):
        Path(url.removeprefix("sqlite:///./")).parent.mkdir(parents=True, exist_ok=True)
    engine = create_engine(
        url,
        connect_args={"check_same_thread": False, "timeout": 20}
        if url.startswith("sqlite")
        else {},
        pool_pre_ping=True,
    )
    if url.startswith("sqlite"):

        @event.listens_for(engine, "connect")
        def sqlite_settings(connection, _):
            connection.execute("PRAGMA journal_mode=WAL")

    Base.metadata.create_all(engine)
    return engine, sessionmaker(engine, expire_on_commit=False)


@contextmanager
def transaction(factory):
    with factory() as session, session.begin():
        yield session
