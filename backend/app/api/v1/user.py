"""User profile and preferences endpoints."""
from datetime import date, datetime, timedelta

from fastapi import APIRouter, Depends
from fastapi import UploadFile

from app.core.deps import get_current_user_id
from app.core.errors import AppException, ErrorCode, NotFoundError
from app.db.supabase import get_supabase
from app.schemas.user import (
    UserProfileResponse,
    UserProfileUpdate,
    UserPreferencesResponse,
    UserPreferencesUpdate,
    UserStatsResponse,
)

router = APIRouter()


def _parse_entry_date(value) -> date | None:
    """Parse entry_date from Supabase (str, date, or datetime) to date."""
    if value is None:
        return None
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, datetime):
        return value.date()
    s = str(value).strip()
    if not s:
        return None
    # Handle "2025-02-06" or "2025-02-06T00:00:00" or "2025-02-06 00:00:00"
    s = s[:10]
    if len(s) != 10 or s[4] != "-" or s[7] != "-":
        return None
    try:
        return date(int(s[0:4]), int(s[5:7]), int(s[8:10]))
    except (ValueError, IndexError):
        return None


def _compute_streaks_from_entries(user_id: str) -> tuple[int, int]:
    """Compute current_streak and longest_streak from published journal entries.
    A day counts toward the streak if the user wrote (published) at least one entry that day.
    """
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("entry_date").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).execute()
    if not r.data:
        return 0, 0
    dates: set[date] = set()
    for row in r.data:
        parsed = _parse_entry_date(row.get("entry_date"))
        if parsed is not None:
            dates.add(parsed)
    if not dates:
        return 0, 0
    today = date.today()
    # Current streak: consecutive days including today, going backwards
    current = 0
    d = today
    while d in dates:
        current += 1
        d -= timedelta(days=1)
    # Longest streak: max run of consecutive days
    sorted_dates = sorted(dates)
    longest = 1
    run = 1
    for i in range(1, len(sorted_dates)):
        if (sorted_dates[i] - sorted_dates[i - 1]).days == 1:
            run += 1
            longest = max(longest, run)
        else:
            run = 1
    return current, longest


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


def _delete_old_avatars(supabase, user_id: str) -> None:
    """Remove any existing avatar files for this user from the avatars bucket to avoid buildup."""
    bucket = supabase.storage.from_("avatars")
    try:
        # List objects under this user's prefix (e.g. user_id/avatar.jpg, user_id/avatar.png)
        listed = bucket.list(user_id)
        to_remove = []
        for item in listed:
            name = item.get("name")
            if not name:
                continue
            # Path may be returned as "avatar.jpg" or "user_id/avatar.jpg"
            path = name if name.startswith(f"{user_id}/") else f"{user_id}/{name}"
            to_remove.append(path)
        if to_remove:
            bucket.remove(to_remove)
    except Exception:
        # Ignore: bucket might not exist, list might fail, or no files
        pass


@router.patch("/avatar")
async def update_avatar(
    file: UploadFile | None = None,
    user_id: str = Depends(get_current_user_id),
):
    if not file or not file.filename:
        return {"message": "No file provided"}
    supabase = get_supabase()
    content = await file.read()
    # Fixed path per user so we always overwrite; safe filename
    ext = "jpg"
    if file.filename and "." in file.filename:
        ext = file.filename.rsplit(".", 1)[-1].lower() or "jpg"
    if ext not in ("jpg", "jpeg", "png", "gif", "webp"):
        ext = "jpg"
    path = f"{user_id}/avatar.{ext}"
    # Delete old avatar file(s) for this user so we don't accumulate orphaned files
    _delete_old_avatars(supabase, user_id)
    # All file_options values must be strings (storage client may call .encode() on them)
    content_type = file.content_type or "image/jpeg"
    file_options = {
        "content-type": content_type,
        "contentType": content_type,
        "upsert": "true",
    }
    try:
        bucket = supabase.storage.from_("avatars")
        bucket.upload(path, content, file_options=file_options)
    except Exception as e:
        err_msg = str(e).lower()
        if "bucket" in err_msg and ("not found" in err_msg or "does not exist" in err_msg):
            raise AppException(
                ErrorCode.SERVICE_UNAVAILABLE,
                "Avatar storage is not set up. Create a storage bucket named 'avatars' in your "
                "Supabase project (Dashboard → Storage → New bucket), and set it to public if you want "
                "avatar URLs to be public.",
            ) from e
        if "duplicate" in err_msg or "already exists" in err_msg:
            try:
                bucket = supabase.storage.from_("avatars")
                bucket.upload(path, content, file_options=file_options)
            except Exception as e2:
                raise AppException(ErrorCode.SERVICE_UNAVAILABLE, f"Avatar upload failed. Please try again. ({e2})") from e2
        raise AppException(ErrorCode.SERVICE_UNAVAILABLE, f"Avatar upload failed. Please try again or use a different image. ({e})") from e
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
    # Streaks: computed from published entries (day counts if user wrote that day)
    current_streak, longest_streak = _compute_streaks_from_entries(user_id)
    return UserStatsResponse(
        total_entries=total_entries,
        total_words=total_words,
        current_streak=current_streak,
        longest_streak=longest_streak,
        entries_this_week=0,
        entries_this_month=0,
    )
