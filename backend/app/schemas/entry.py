"""Journal entry schemas."""
from datetime import date, datetime, time
from typing import Any

from pydantic import BaseModel, Field


MOOD_VALUES = ("very_sad", "sad", "neutral", "happy", "very_happy")


class EntryBase(BaseModel):
    title: str | None = None
    content: str
    mood: str | None = None  # one of MOOD_VALUES
    mood_intensity: int | None = Field(None, ge=1, le=10)
    entry_date: date | None = None
    entry_time: time | None = None
    is_draft: bool = False
    is_favorite: bool = False
    weather: dict[str, Any] | None = None
    location: str | None = None
    location_lat: float | None = None
    location_lng: float | None = None
    template_id: str | None = None
    tags: list[str] | None = None


class EntryCreate(EntryBase):
    content: str = Field(..., min_length=1)


class EntryUpdate(BaseModel):
    title: str | None = None
    content: str | None = None
    mood: str | None = None
    mood_intensity: int | None = Field(None, ge=1, le=10)
    entry_date: date | None = None
    entry_time: time | None = None
    is_draft: bool | None = None
    is_favorite: bool | None = None
    weather: dict[str, Any] | None = None
    location: str | None = None
    location_lat: float | None = None
    location_lng: float | None = None
    tags: list[str] | None = None


class EntryResponse(BaseModel):
    id: str
    user_id: str
    title: str | None
    content: str
    mood: str | None
    mood_intensity: int | None
    entry_date: str  # ISO date
    entry_time: str  # "HH:MM:SS"
    word_count: int
    character_count: int
    is_draft: bool
    is_favorite: bool
    weather: dict | None
    location: str | None
    template_id: str | None
    created_at: datetime
    updated_at: datetime
    tags: list[str] | None = None

    class Config:
        from_attributes = True
