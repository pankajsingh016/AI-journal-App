"""Journal entries CRUD and list."""
import logging
import uuid
from datetime import date, datetime, time
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, status

logger = logging.getLogger(__name__)

from app.core.deps import get_current_user_id
from app.core.errors import AppException, ErrorCode, NotFoundError, ValidationError
from app.db.supabase import get_supabase
from app.schemas.entry import (
    EntryCreate,
    EntryUpdate,
    EntryResponse,
    EntryMediaItem,
    MOOD_VALUES,
)

from app.api.v1.user import _ensure_user_row
from app.config import get_settings

router = APIRouter()


def _storage_public_url(supabase, bucket_name: str, path: str) -> str:
    """Use Supabase client's get_public_url so format matches exactly (same as avatar)."""
    raw = (path or "").strip().lstrip("/")
    if not raw:
        base = (get_settings().supabase_url or "").strip().rstrip("/")
        if not base or "placeholder" in base.lower():
            raise AppException(
                ErrorCode.SERVICE_UNAVAILABLE,
                "SUPABASE_URL is not set. Set it in backend .env so journal images work.",
            )
        return f"{base}/storage/v1/object/public/{bucket_name}/"
    return supabase.storage.from_(bucket_name).get_public_url(raw)


def _storage_upload_supabase(supabase, bucket_name: str, path: str, content: bytes, content_type: str = "image/jpeg") -> None:
    """Upload bytes using Supabase storage client (same pattern as avatar upload). All file_options values are strings."""
    file_options = {
        "content-type": content_type,
        "contentType": content_type,
        "upsert": "true",
    }
    bucket = supabase.storage.from_(bucket_name)
    bucket.upload(path, content, file_options=file_options)


def _ensure_mood(mood: str | None) -> None:
    if mood is not None and mood not in MOOD_VALUES:
        raise ValidationError("Invalid mood", field="mood", constraint="enum")


@router.get("", response_model=list[EntryResponse])
async def list_entries(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    sort: str = Query("desc"),  # desc | asc
    is_draft: bool | None = None,
    is_favorite: bool | None = None,
    entry_date: str | None = Query(None, description="Filter by date YYYY-MM-DD; returns all entries written on that day"),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    q = supabase.table("journal_entries").select("*").eq("user_id", user_id).is_("deleted_at", "null")
    if is_draft is not None:
        q = q.eq("is_draft", is_draft)
    if is_favorite is not None:
        q = q.eq("is_favorite", is_favorite)
    if entry_date is not None and entry_date.strip():
        q = q.eq("entry_date", entry_date.strip())
    q = q.order("entry_date", desc=(sort == "desc")).order("entry_time", desc=(sort == "desc"))
    q = q.range((page - 1) * limit, page * limit - 1)
    r = q.execute()
    rows = r.data or []
    entry_ids = [str(row.get("id")) for row in rows if row.get("id")]
    media_by_entry: dict[str, list[EntryMediaItem]] = {}
    if entry_ids:
        media_r = supabase.table("entry_media").select("entry_id, id, storage_path, storage_bucket, file_name, mime_type").in_("entry_id", entry_ids).order("created_at").execute()
        for m in (media_r.data or []):
            eid = str(m.get("entry_id", ""))
            if eid not in media_by_entry:
                media_by_entry[eid] = []
            path = m.get("storage_path")
            bucket = m.get("storage_bucket") or "journal-media"
            if path:
                url = _storage_public_url(supabase, bucket, path)
                media_by_entry[eid].append(EntryMediaItem(
                    id=str(m.get("id", "")),
                    url=url,
                    file_name=m.get("file_name"),
                    mime_type=m.get("mime_type"),
                ))
    out = []
    for row in rows:
        eid = str(row.get("id", ""))
        media = media_by_entry.get(eid) or None
        out.append(_row_to_response(row, tags=None, media=media))
    return out


def _parse_datetime(v) -> datetime:
    """Normalize DB value (string or datetime) to datetime for EntryResponse."""
    if v is None:
        return datetime.now()
    if isinstance(v, datetime):
        return v
    s = str(v).strip()
    if not s:
        return datetime.now()
    # Supabase/PostgREST returns ISO strings e.g. 2025-02-12T10:30:00.123456+00:00
    for fmt, size in (("%Y-%m-%dT%H:%M:%S", 19), ("%Y-%m-%d %H:%M:%S", 19), ("%Y-%m-%d", 10)):
        try:
            return datetime.strptime(s[:size], fmt)
        except ValueError:
            continue
    return datetime.now()


def _safe_int(v, default: int = 0) -> int:
    if v is None:
        return default
    if isinstance(v, int):
        return v
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return default


def _safe_int_optional(v) -> int | None:
    """For mood_intensity: int | None."""
    if v is None:
        return None
    if isinstance(v, int):
        return v
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


def _safe_weather(v):
    """Return dict or None for EntryResponse.weather."""
    if v is None:
        return None
    if isinstance(v, dict):
        return v
    if isinstance(v, str) and v.strip():
        try:
            import json
            return json.loads(v)
        except Exception:
            return None
    return None


def _row_to_response(row: dict, tags: list[str] | None = None, media: list[EntryMediaItem] | None = None) -> EntryResponse:
    row = dict(row)
    def _str(v):
        return str(v) if v is not None else None
    if row.get("entry_time") is not None:
        row["entry_time"] = _str(row["entry_time"])[:8] if len(_str(row["entry_time"])) > 8 else _str(row["entry_time"])
    if row.get("entry_date") is not None:
        row["entry_date"] = _str(row["entry_date"])
    return EntryResponse(
        id=_str(row.get("id")),
        user_id=_str(row.get("user_id")),
        title=row.get("title") if isinstance(row.get("title"), (str, type(None))) else _str(row.get("title")),
        content=row.get("content") or "",
        mood=row.get("mood"),
        mood_intensity=_safe_int_optional(row.get("mood_intensity")),
        entry_date=row.get("entry_date") or "",
        entry_time=row.get("entry_time") or "00:00:00",
        word_count=_safe_int(row.get("word_count")),
        character_count=_safe_int(row.get("character_count")),
        is_draft=bool(row.get("is_draft", False)),
        is_favorite=bool(row.get("is_favorite", False)),
        weather=_safe_weather(row.get("weather")),
        location=row.get("location") if isinstance(row.get("location"), (str, type(None))) else _str(row.get("location")),
        template_id=_str(row.get("template_id")) if row.get("template_id") is not None else None,
        created_at=_parse_datetime(row.get("created_at")),
        updated_at=_parse_datetime(row.get("updated_at")),
        tags=tags if tags is not None else [],
        media=media,
    )


@router.get("/drafts", response_model=list[EntryResponse])
async def list_drafts(user_id: str = Depends(get_current_user_id)):
    try:
        return await list_entries(page=1, limit=50, is_draft=True, user_id=user_id)
    except (NotFoundError, ValidationError, AppException):
        raise
    except Exception as e:
        raise AppException(
            ErrorCode.DATABASE_ERROR,
            "Failed to load drafts. Please try again.",
            details={"hint": str(e)},
        ) from e


@router.get("/favorites", response_model=list[EntryResponse])
async def list_favorites(user_id: str = Depends(get_current_user_id)):
    return await list_entries(page=1, limit=50, is_favorite=True, user_id=user_id)


@router.get("/calendar")
async def calendar_entries(
    year: int = Query(...),
    month: int = Query(..., ge=1, le=12),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    from datetime import date
    start = date(year, month, 1)
    if month == 12:
        end = date(year, 12, 31)
    else:
        end = date(year, month + 1, 1)
    r = supabase.table("journal_entries").select("id, entry_date, mood, is_draft").eq("user_id", user_id).gte("entry_date", str(start)).lt("entry_date", str(end)).is_("deleted_at", "null").eq("is_draft", False).execute()
    return {"entries": r.data or []}


@router.get("/on-this-day")
async def on_this_day(
    month: int = Query(..., ge=1, le=12),
    day: int = Query(..., ge=1, le=31),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("id, entry_date, title, content").eq("user_id", user_id).is_("deleted_at", "null").execute()
    data = []
    for e in (r.data or []):
        d = e.get("entry_date")
        if d:
            parts = str(d).split("-")
            if len(parts) >= 3 and int(parts[1]) == month and int(parts[2]) == day:
                data.append(e)
    return {"entries": data}


@router.get("/dates")
async def entry_dates(user_id: str = Depends(get_current_user_id)):
    """Return distinct dates (YYYY-MM-DD) when the user has at least one published entry."""
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("entry_date").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).execute()
    dates = set()
    for row in (r.data or []):
        d = row.get("entry_date")
        if d is None:
            continue
        s = str(d).strip()[:10]
        if len(s) == 10 and s[4] == "-" and s[7] == "-":
            dates.add(s)
    return {"dates": sorted(dates)}


def _get_entry_media(supabase, entry_id: str) -> list[EntryMediaItem]:
    r = supabase.table("entry_media").select("id, storage_path, storage_bucket, file_name, mime_type").eq("entry_id", entry_id).order("created_at").execute()
    out = []
    bucket_name = "journal-media"
    for m in (r.data or []):
        path = m.get("storage_path")
        bucket = m.get("storage_bucket") or bucket_name
        if path:
            url = _storage_public_url(supabase, bucket, path)
            out.append(EntryMediaItem(
                id=str(m.get("id", "")),
                url=url,
                file_name=m.get("file_name"),
                mime_type=m.get("mime_type"),
            ))
    return out


@router.get("/{entry_id}", response_model=EntryResponse)
async def get_entry(entry_id: UUID, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("*, entry_tags(tag)").eq("id", str(entry_id)).eq("user_id", user_id).is_("deleted_at", "null").execute()
    if not r.data or len(r.data) == 0:
        raise NotFoundError("Entry not found")
    row = r.data[0]
    tags = [t["tag"] for t in row.get("entry_tags", [])] if isinstance(row.get("entry_tags"), list) else []
    media = _get_entry_media(supabase, str(entry_id))
    return _row_to_response(row, tags, media)


@router.post("", response_model=EntryResponse, status_code=status.HTTP_201_CREATED)
async def create_entry(body: EntryCreate, user_id: str = Depends(get_current_user_id)):
    try:
        _ensure_mood(body.mood)
        _ensure_user_row(user_id)
        supabase = get_supabase()
        entry_date = body.entry_date or date.today()
        entry_time = body.entry_time or time(0, 0, 0)
        time_str = str(entry_time)
        if len(time_str) > 8:
            time_str = time_str[:8]
        word_count = len(body.content.split())
        payload = {
            "user_id": user_id,
            "content": body.content,
            "entry_date": str(entry_date),
            "entry_time": time_str,
            "word_count": word_count,
            "character_count": len(body.content),
            "is_draft": body.is_draft,
            "is_favorite": body.is_favorite,
        }
        if body.title is not None:
            payload["title"] = body.title
        if body.mood is not None:
            payload["mood"] = body.mood
        if body.mood_intensity is not None:
            payload["mood_intensity"] = body.mood_intensity
        if body.weather is not None:
            payload["weather"] = body.weather
        if body.location is not None:
            payload["location"] = body.location
        if body.location_lat is not None:
            payload["location_lat"] = body.location_lat
        if body.location_lng is not None:
            payload["location_lng"] = body.location_lng
        if body.template_id is not None:
            payload["template_id"] = str(body.template_id)
        r = supabase.table("journal_entries").insert(payload).execute()
        if not r.data or len(r.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Entry was created but server could not return it. Please refresh your entries.",
            )
        row = r.data[0]
        if body.tags:
            for tag in body.tags:
                try:
                    supabase.table("entry_tags").insert({"entry_id": row["id"], "tag": tag}).execute()
                except Exception:
                    pass
        return _row_to_response(row, body.tags or [])
    except (NotFoundError, ValidationError, AppException, HTTPException):
        raise
    except Exception as e:
        err_str = str(e).lower()
        # PostgreSQL 42501 = insufficient_privilege — usually backend using anon key instead of service_role
        if "42501" in str(e) or "permission denied" in err_str or "insufficient_privilege" in err_str:
            logger.warning("Create entry 42501/permission denied: %s", e)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "Database permission denied (42501). The backend must use the Supabase service_role key, not the anon key. "
                    "Set SUPABASE_SERVICE_KEY in your backend .env to the service_role secret from Supabase Dashboard → Project Settings → API. "
                    "See docs/SUPABASE_SETUP.md."
                ),
            ) from e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create entry: {e!s}",
        ) from e


@router.put("/{entry_id}", response_model=EntryResponse)
async def update_entry(entry_id: UUID, body: EntryUpdate, user_id: str = Depends(get_current_user_id)):
    _ensure_mood(body.mood)
    supabase = get_supabase()
    payload = body.model_dump(exclude_unset=True)
    if "tags" in payload:
        tags = payload.pop("tags")
    else:
        tags = None
    if "content" in payload and payload["content"] is not None:
        payload["word_count"] = len(payload["content"].split())
        payload["character_count"] = len(payload["content"])
    if payload:
        for k in ("entry_date", "entry_time"):
            if k in payload and payload[k] is not None:
                payload[k] = str(payload[k])
        supabase.table("journal_entries").update(payload).eq("id", str(entry_id)).eq("user_id", user_id).execute()
    if tags is not None:
        supabase.table("entry_tags").delete().eq("entry_id", str(entry_id)).execute()
        for tag in tags:
            supabase.table("entry_tags").insert({"entry_id": str(entry_id), "tag": tag}).execute()
    return await get_entry(entry_id, user_id)


@router.patch("/{entry_id}", response_model=EntryResponse)
async def patch_entry(entry_id: UUID, body: EntryUpdate, user_id: str = Depends(get_current_user_id)):
    return await update_entry(entry_id, body, user_id)


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_entry(entry_id: UUID, user_id: str = Depends(get_current_user_id)):
    from datetime import datetime, timezone
    supabase = get_supabase()
    supabase.table("journal_entries").update({
        "deleted_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", str(entry_id)).eq("user_id", user_id).execute()
    return None


@router.post("/{entry_id}/favorite", response_model=EntryResponse)
async def add_favorite(entry_id: UUID, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    supabase.table("journal_entries").update({"is_favorite": True}).eq("id", str(entry_id)).eq("user_id", user_id).execute()
    return await get_entry(entry_id, user_id)


@router.delete("/{entry_id}/favorite", response_model=EntryResponse)
async def remove_favorite(entry_id: UUID, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    supabase.table("journal_entries").update({"is_favorite": False}).eq("id", str(entry_id)).eq("user_id", user_id).execute()
    return await get_entry(entry_id, user_id)


def _entry_media_error(e: Exception) -> AppException:
    """Turn storage/DB errors into a clear message for the client."""
    err_msg = str(e).lower()
    if "bucket" in err_msg and ("not found" in err_msg or "does not exist" in err_msg):
        return AppException(
            ErrorCode.SERVICE_UNAVAILABLE,
            "Journal media storage is not set up. Create a storage bucket named 'journal-media' in Supabase (Storage → New bucket, set to public).",
        )
    if "entry_media" in err_msg or "relation" in err_msg or "does not exist" in err_msg:
        return AppException(
            ErrorCode.DATABASE_ERROR,
            "Database table entry_media is missing. Run the full supabase/schema.sql in Supabase SQL Editor. See docs/SUPABASE_SETUP.md.",
        )
    if "encode" in err_msg:
        return AppException(
            ErrorCode.SERVICE_UNAVAILABLE,
            "Photo upload failed due to a server configuration error. Please try again or use a different image.",
        )
    if "row-level security" in err_msg or "policy" in err_msg or "permission" in err_msg or "forbidden" in err_msg:
        return AppException(
            ErrorCode.SERVICE_UNAVAILABLE,
            "Storage permission denied. In Supabase: create bucket 'journal-media' (Storage → New bucket, Public ON) and run the policy SQL in docs/SUPABASE_STORAGE_JOURNAL_MEDIA.md.",
            details={"hint": str(e)},
        )
    # Surface the real error so we can fix bucket/RLS/config issues
    return AppException(
        ErrorCode.SERVICE_UNAVAILABLE,
        f"Photo upload failed. {e!s}",
        details={"hint": str(e)},
    )


@router.post("/{entry_id}/media", response_model=EntryMediaItem, status_code=status.HTTP_201_CREATED)
async def upload_entry_media(
    entry_id: UUID,
    file: UploadFile | None = None,
    user_id: str = Depends(get_current_user_id),
):
    """Upload an image (or other media) for a journal entry. Entry must exist and belong to the user."""
    if not file or not file.filename:
        raise ValidationError("No file provided", field="file")
    settings = get_settings()
    if not settings.supabase_service_key or "placeholder" in (settings.supabase_service_key or "").lower():
        raise AppException(
            ErrorCode.SERVICE_UNAVAILABLE,
            "Storage is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_KEY in backend .env (use the service_role key from Supabase Dashboard → Project Settings → API).",
        )
    try:
        supabase = get_supabase()
        r = supabase.table("journal_entries").select("id").eq("id", str(entry_id)).eq("user_id", user_id).is_("deleted_at", "null").execute()
        if not r.data or len(r.data) == 0:
            raise NotFoundError("Entry not found")
        content = await file.read()
        ext = "jpg"
        if file.filename and "." in file.filename:
            ext = file.filename.rsplit(".", 1)[-1].lower() or "jpg"
        if ext not in ("jpg", "jpeg", "png", "gif", "webp"):
            ext = "jpg"
        path = f"{entry_id}/{uuid.uuid4()}.{ext}"
        bucket_name = "journal-media"
        content_type = file.content_type or "image/jpeg"
        _storage_upload_supabase(supabase, bucket_name, path, content, content_type)
        url = _storage_public_url(supabase, bucket_name, path)
        media_type = file.content_type or "image/jpeg"
        # Use .execute() only; insert() returns inserted row by default (representation). Chaining .select() can return a builder and cause "SyncQueryRequest Builder Object" errors.
        ins = supabase.table("entry_media").insert({
            "entry_id": str(entry_id),
            "media_type": media_type,
            "storage_path": path,
            "storage_bucket": bucket_name,
            "file_name": file.filename,
            "mime_type": media_type,
        }).execute()
        if not ins.data or len(ins.data) == 0:
            raise AppException(
                ErrorCode.DATABASE_ERROR,
                "Media record could not be created. Ensure the entry_media table exists. Run supabase/schema.sql. See docs/SUPABASE_SETUP.md.",
            )
        row = ins.data[0]
        return EntryMediaItem(
            id=str(row.get("id", "")),
            url=url,
            file_name=file.filename,
            mime_type=media_type,
        )
    except (NotFoundError, ValidationError, AppException):
        raise
    except Exception as e:
        logger.warning("Journal media upload failed: %s", e, exc_info=True)
        raise _entry_media_error(e)
