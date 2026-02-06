"""User profile and preferences endpoints."""
from fastapi import APIRouter, Depends
from fastapi import UploadFile

from app.core.deps import get_current_user_id
from app.core.errors import NotFoundError
from app.db.supabase import get_supabase
from app.schemas.user import (
    UserProfileResponse,
    UserProfileUpdate,
    UserPreferencesResponse,
    UserPreferencesUpdate,
    UserStatsResponse,
)

router = APIRouter()


def _ensure_user_row(user_id: str) -> dict:
    """Return user row from public.users; if missing, create from auth and return."""
    supabase = get_supabase()
    r = supabase.table("users").select("*").eq("id", user_id).execute()
    if r.data and len(r.data) > 0:
        row = r.data[0]
        if row.get("preferred_journaling_time"):
            row["preferred_journaling_time"] = str(row["preferred_journaling_time"])[:5]
        return row
    # No row: fetch from Supabase Auth and create profile so login flow never 404s
    try:
        auth_user = supabase.auth.admin.get_user_by_id(user_id)
    except Exception:
        raise NotFoundError("User not found")
    if not auth_user or not getattr(auth_user, "user", None):
        raise NotFoundError("User not found")
    u = auth_user.user
    email = getattr(u, "email", None) or ""
    meta = getattr(u, "user_metadata", None) or {}
    full_name = meta.get("full_name") if isinstance(meta, dict) else None
    supabase.table("users").insert({
        "id": user_id,
        "email": email,
        "full_name": full_name,
    }).execute()
    r = supabase.table("users").select("*").eq("id", user_id).execute()
    if not r.data or len(r.data) == 0:
        raise NotFoundError("User not found")
    row = r.data[0]
    if row.get("preferred_journaling_time"):
        row["preferred_journaling_time"] = str(row["preferred_journaling_time"])[:5]
    return row


def _user_row(user_id: str) -> dict:
    supabase = get_supabase()
    r = supabase.table("users").select("*").eq("id", user_id).execute()
    if not r.data or len(r.data) == 0:
        raise NotFoundError("User not found")
    row = r.data[0]
    if row.get("preferred_journaling_time"):
        row["preferred_journaling_time"] = str(row["preferred_journaling_time"])[:5]
    return row


def _prefs_row(user_id: str) -> dict:
    supabase = get_supabase()
    r = supabase.table("user_preferences").select("*").eq("user_id", user_id).execute()
    if not r.data or len(r.data) == 0:
        return {}
    row = r.data[0]
    if row.get("reminder_time"):
        row["reminder_time"] = str(row["reminder_time"])[:5]
    return row


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(user_id: str = Depends(get_current_user_id)):
    row = _ensure_user_row(user_id)
    return UserProfileResponse(
        id=row["id"],
        email=row["email"],
        full_name=row.get("full_name"),
        avatar_url=row.get("avatar_url"),
        onboarding_completed=row.get("onboarding_completed", False),
        journaling_goal=row.get("journaling_goal"),
        preferred_journaling_time=row.get("preferred_journaling_time"),
        ai_personality=row.get("ai_personality", "supportive"),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


@router.put("/profile", response_model=UserProfileResponse)
async def update_profile(
    body: UserProfileUpdate,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    payload = body.model_dump(exclude_unset=True)
    if not payload:
        return UserProfileResponse(**_user_row(user_id))
    supabase.table("users").update(payload).eq("id", user_id).execute()
    return UserProfileResponse(**_user_row(user_id))


@router.patch("/avatar")
async def update_avatar(
    file: UploadFile | None = None,
    user_id: str = Depends(get_current_user_id),
):
    if not file or not file.filename:
        return {"message": "No file provided"}
    # Upload to Supabase Storage and set avatar_url on users
    supabase = get_supabase()
    content = await file.read()
    path = f"avatars/{user_id}/{file.filename}"
    supabase.storage.from_("avatars").upload(path, content, file_options={"content-type": file.content_type or "image/jpeg"})
    url = supabase.storage.from_("avatars").get_public_url(path)
    supabase.table("users").update({"avatar_url": url}).eq("id", user_id).execute()
    return {"avatar_url": url}


@router.get("/preferences", response_model=UserPreferencesResponse)
async def get_preferences(user_id: str = Depends(get_current_user_id)):
    row = _prefs_row(user_id)
    if not row:
        # Return defaults
        return UserPreferencesResponse(
            theme="auto",
            accent_color="#6366F1",
            font_family="system",
            font_size=16,
            reminder_enabled=True,
            reminder_time="21:00",
            reminder_days=["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
            auto_save_interval=30,
            show_word_count=True,
            ai_enabled=True,
            ai_response_style="balanced",
            sync_enabled=True,
        )
    return UserPreferencesResponse(
        theme=row.get("theme", "auto"),
        accent_color=row.get("accent_color", "#6366F1"),
        font_family=row.get("font_family", "system"),
        font_size=row.get("font_size", 16),
        reminder_enabled=row.get("reminder_enabled", True),
        reminder_time=row.get("reminder_time"),
        reminder_days=row.get("reminder_days"),
        auto_save_interval=row.get("auto_save_interval", 30),
        show_word_count=row.get("show_word_count", True),
        ai_enabled=row.get("ai_enabled", True),
        ai_response_style=row.get("ai_response_style", "balanced"),
        sync_enabled=row.get("sync_enabled", True),
    )


@router.put("/preferences", response_model=UserPreferencesResponse)
async def update_preferences(
    body: UserPreferencesUpdate,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    payload = body.model_dump(exclude_unset=True)
    if payload:
        supabase.table("user_preferences").upsert({
            "user_id": user_id,
            **payload,
        }, on_conflict="user_id").execute()
    return await get_preferences(user_id)


@router.get("/stats", response_model=UserStatsResponse)
async def get_stats(user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    # Entries count (non-draft, not deleted)
    r = supabase.table("journal_entries").select("id, word_count, entry_date", count="exact").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).execute()
    total_entries = r.count or 0
    total_words = sum(row.get("word_count", 0) for row in (r.data or []))
    # Streaks
    streak_r = supabase.table("streaks").select("*").eq("user_id", user_id).execute()
    current_streak = 0
    longest_streak = 0
    if streak_r.data and len(streak_r.data) > 0:
        current_streak = streak_r.data[0].get("current_streak", 0)
        longest_streak = streak_r.data[0].get("longest_streak", 0)
    # This week / month - would need date filters; simplified
    return UserStatsResponse(
        total_entries=total_entries,
        total_words=total_words,
        current_streak=current_streak,
        longest_streak=longest_streak,
        entries_this_week=0,
        entries_this_month=0,
    )
