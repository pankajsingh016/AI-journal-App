"""Journal entries CRUD and list."""
from datetime import date, time
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi import HTTPException, status

from app.core.deps import get_current_user_id
from app.core.errors import NotFoundError, ValidationError
from app.db.supabase import get_supabase
from app.schemas.entry import EntryCreate, EntryUpdate, EntryResponse, MOOD_VALUES

router = APIRouter()


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
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    q = supabase.table("journal_entries").select("*, entry_tags(tag)").eq("user_id", user_id).is_("deleted_at", "null")
    if is_draft is not None:
        q = q.eq("is_draft", is_draft)
    if is_favorite is not None:
        q = q.eq("is_favorite", is_favorite)
    q = q.order("entry_date", desc=(sort == "desc")).order("entry_time", desc=(sort == "desc"))
    q = q.range((page - 1) * limit, page * limit - 1)
    r = q.execute()
    out = []
    for row in (r.data or []):
        tags = [t["tag"] for t in row.get("entry_tags", [])] if isinstance(row.get("entry_tags"), list) else []
        out.append(_row_to_response(row, tags))
    return out


def _row_to_response(row: dict, tags: list[str] | None = None) -> EntryResponse:
    row = dict(row)
    if row.get("entry_time"):
        row["entry_time"] = str(row["entry_time"])[:8] if len(str(row["entry_time"])) > 8 else str(row["entry_time"])
    if row.get("entry_date"):
        row["entry_date"] = str(row["entry_date"])
    return EntryResponse(
        id=row["id"],
        user_id=row["user_id"],
        title=row.get("title"),
        content=row["content"],
        mood=row.get("mood"),
        mood_intensity=row.get("mood_intensity"),
        entry_date=row["entry_date"],
        entry_time=row.get("entry_time") or "00:00:00",
        word_count=row.get("word_count", 0),
        character_count=row.get("character_count", 0),
        is_draft=row.get("is_draft", False),
        is_favorite=row.get("is_favorite", False),
        weather=row.get("weather"),
        location=row.get("location"),
        template_id=row.get("template_id"),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
        tags=tags or [],
    )


@router.get("/drafts", response_model=list[EntryResponse])
async def list_drafts(user_id: str = Depends(get_current_user_id)):
    return await list_entries(page=1, limit=50, is_draft=True, user_id=user_id)


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


@router.get("/{entry_id}", response_model=EntryResponse)
async def get_entry(entry_id: UUID, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("*, entry_tags(tag)").eq("id", str(entry_id)).eq("user_id", user_id).is_("deleted_at", "null").execute()
    if not r.data or len(r.data) == 0:
        raise NotFoundError("Entry not found")
    row = r.data[0]
    tags = [t["tag"] for t in row.get("entry_tags", [])] if isinstance(row.get("entry_tags"), list) else []
    return _row_to_response(row, tags)


@router.post("", response_model=EntryResponse, status_code=status.HTTP_201_CREATED)
async def create_entry(body: EntryCreate, user_id: str = Depends(get_current_user_id)):
    _ensure_mood(body.mood)
    supabase = get_supabase()
    entry_date = body.entry_date or date.today()
    entry_time = body.entry_time or time(0, 0, 0)
    word_count = len(body.content.split())
    payload = {
        "user_id": user_id,
        "title": body.title,
        "content": body.content,
        "mood": body.mood,
        "mood_intensity": body.mood_intensity,
        "entry_date": str(entry_date),
        "entry_time": str(entry_time),
        "word_count": word_count,
        "character_count": len(body.content),
        "is_draft": body.is_draft,
        "is_favorite": body.is_favorite,
        "weather": body.weather,
        "location": body.location,
        "location_lat": body.location_lat,
        "location_lng": body.location_lng,
        "template_id": body.template_id,
    }
    r = supabase.table("journal_entries").insert(payload).execute()
    if not r.data or len(r.data) == 0:
        raise HTTPException(status_code=500, detail="Failed to create entry")
    row = r.data[0]
    if body.tags:
        for tag in body.tags:
            supabase.table("entry_tags").insert({"entry_id": row["id"], "tag": tag}).execute()
    return _row_to_response(row, body.tags or [])


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
    supabase = get_supabase()
    from datetime import datetime, timezone
    supabase.table("journal_entries").update({"deleted_at": datetime.now(timezone.utc).isoformat()}).eq("id", str(entry_id)).eq("user_id", user_id).execute()
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
