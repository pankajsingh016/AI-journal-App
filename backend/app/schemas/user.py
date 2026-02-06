"""User and profile schemas."""
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class UserProfileResponse(BaseModel):
    id: str
    email: str
    full_name: str | None
    avatar_url: str | None
    onboarding_completed: bool
    journaling_goal: str | None
    preferred_journaling_time: str | None  # "HH:MM"
    ai_personality: str
    created_at: datetime
    updated_at: datetime


class UserProfileUpdate(BaseModel):
    full_name: str | None = None
    journaling_goal: str | None = None
    preferred_journaling_time: str | None = None
    ai_personality: str | None = None
    onboarding_completed: bool | None = None


class UserPreferencesResponse(BaseModel):
    theme: str
    accent_color: str
    font_family: str
    font_size: int
    reminder_enabled: bool
    reminder_time: str | None
    reminder_days: list[str] | None
    auto_save_interval: int
    show_word_count: bool
    ai_enabled: bool
    ai_response_style: str
    sync_enabled: bool


class UserPreferencesUpdate(BaseModel):
    theme: str | None = None
    accent_color: str | None = None
    font_family: str | None = None
    font_size: int | None = None
    reminder_enabled: bool | None = None
    reminder_time: str | None = None
    reminder_days: list[str] | None = None
    auto_save_interval: int | None = None
    show_word_count: bool | None = None
    ai_enabled: bool | None = None
    ai_response_style: str | None = None
    sync_enabled: bool | None = None


class UserStatsResponse(BaseModel):
    total_entries: int
    total_words: int
    current_streak: int
    longest_streak: int
    entries_this_week: int
    entries_this_month: int
