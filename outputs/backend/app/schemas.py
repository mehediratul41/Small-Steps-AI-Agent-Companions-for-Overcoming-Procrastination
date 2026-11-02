from datetime import UTC, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

Condition = Literal["selfAgent", "friendAgent", "standardControl"]
Language = Literal["en", "ja"]
Identifier = Annotated[str, Field(min_length=1, max_length=100, pattern=r"^[A-Za-z0-9_.:-]+$")]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class Subtask(StrictModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    title: str = Field(min_length=1, max_length=300)
    done: bool = False


class Task(StrictModel):
    id: Identifier
    title: str = Field(min_length=1, max_length=300)
    description: str = Field(default="", max_length=5000)
    startCue: str = Field(default="", max_length=300)
    startAction: str = Field(default="", max_length=300)
    futureNote: str = Field(default="", max_length=1000)
    difficulty: Literal["", "unclear", "overwhelming", "worried", "distracted", "tired"] = ""
    priority: Literal["Low", "Normal", "High"] = "Normal"
    due: datetime | None = None
    plannedStart: datetime | None = None
    firstStartedAt: datetime | None = None
    completedAt: datetime | None = None
    reminder: datetime | None = None
    minutes: int = Field(default=15, ge=1, le=1440)
    version: int = Field(default=1, ge=1)
    done: bool = False
    paused: bool = False
    subtasks: list[Subtask] = Field(default_factory=list, max_length=30)

    @field_validator("title")
    @classmethod
    def nonblank(cls, value):
        if not value.strip():
            raise ValueError("Title cannot be blank")
        return value.strip()

    @field_validator("due", "plannedStart", "firstStartedAt", "completedAt", "reminder")
    @classmethod
    def aware(cls, value):
        if value is not None and value.tzinfo is None:
            raise ValueError("Timestamp requires a timezone offset; send UTC from Flutter")
        return value.astimezone(UTC) if value else None


class Onboarding(StrictModel):
    acknowledged: Literal[True]
    consent_version: str = Field(max_length=100)
    demonstration: Literal[True]


class EraseDevelopmentData(StrictModel):
    confirmation: Literal["ERASE MY DEVELOPMENT DATA"]


class Profile(StrictModel):
    values: str = Field(default="", max_length=1000)
    goal: str = Field(default="", max_length=1000)
    brief: bool = False
    invitations: bool = False


class ChatRequest(StrictModel):
    language: Language = "en"
    message: str = Field(min_length=1, max_length=4000)
    task_id: Identifier | None = None

    @field_validator("message")
    @classmethod
    def nonblank(cls, value):
        if not value.strip():
            raise ValueError("Message cannot be blank")
        return value.strip()


class RefineRequest(StrictModel):
    language: Language = "en"
    task: Task
    variant: int = Field(default=0, ge=0, le=100)
    mode: Literal["breakdown", "correction"] = "breakdown"


class TaskCorrection(StrictModel):
    title: str = Field(min_length=1, max_length=300)
    description: str = Field(max_length=5000)
    minutes: int = Field(ge=1, le=1440)
    reason: str = Field(min_length=1, max_length=1000)

    @field_validator("title", "reason")
    @classmethod
    def nonblank(cls, value):
        return Task.nonblank(value)


class Suggestion(StrictModel):
    subtasks: list[Subtask] = Field(min_length=1, max_length=8)


class AcceptSuggestion(StrictModel):
    task_version: int = Field(ge=1)
    subtasks: list[Subtask] | None = Field(default=None, min_length=1, max_length=30)
    correction: TaskCorrection | None = None


class BehaviorEvent(StrictModel):
    id: Identifier
    kind: str = Field(min_length=1, max_length=80, pattern=r"^[a-z_]+$")
    taskId: str = Field(default="", max_length=100)
    at: datetime
    offsetMinutes: int | None = Field(default=None, ge=-840, le=840)
    condition: Condition | None = None
    taskVersion: int | None = Field(default=None, ge=1)
    seconds: int | None = Field(default=None, ge=0, le=86400)
    reflection: str | None = Field(default=None, max_length=4000)
    details: dict = Field(default_factory=dict)
    protocolVersion: str = Field(default="demo-v2", max_length=100)

    @field_validator("at")
    @classmethod
    def aware(cls, value):
        return Task.aware(value)


class EventBatch(StrictModel):
    events: list[BehaviorEvent] = Field(min_length=1, max_length=100)


class CheckIn(StrictModel):
    language: Language = "en"
    id: Identifier
    phase: Literal["baseline", "daily", "before", "during", "after"]
    condition: Condition | None = None
    at: datetime
    offsetMinutes: int = Field(ge=-840, le=840)
    taskId: Identifier | None = None
    instrumentVersion: Literal["demo-check-in-v1"] = "demo-check-in-v1"
    answers: dict[str, str] = Field(max_length=20)

    @field_validator("at")
    @classmethod
    def aware(cls, value):
        return Task.aware(value)

    @field_validator("answers")
    @classmethod
    def bounded_answers(cls, value):
        if any(len(k) > 100 or len(v) > 1000 for k, v in value.items()):
            raise ValueError("Check-in answer too long")
        return value
