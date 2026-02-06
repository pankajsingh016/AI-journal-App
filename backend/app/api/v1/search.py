"""Search and filters."""
from fastapi import APIRouter, Depends, Query

from app.core.deps import get_current_user_id
from app.db.supabase import get_supabase
from app.schemas.entry import EntryResponse

router = APIRouter()


def _entry_response(row: dict, tags: list[str]) -> dict:
    return {
        "id": row["id"],
        "user_id": row["user_id"],
        "title": row.get("title"),
        "content": row.get("content", "")[:200],
        "mood": row.get("mood"),
        "entry_date": str(row.get("entry_date", "")),
        "entry_time": str(row.get("entry_time", ""))[:8],
        "word_count": row.get("word_count", 0),
        "is_draft": row.get("is_draft", False),
        "is_favorite": row.get("is_favorite", False),
        "tags": tags,
        "created_at": row.get("created_at"),
        "updated_at": row.get("updated_at"),
    }


@router.get("")
async def search(
    q: str = Query("", min_length=1),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    mood: str | None = None,
    tags: str | None = None,  # comma-separated
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    # Use Supabase full-text search if search_vector column exists
    query = supabase.table("journal_entries").select("*, entry_tags(tag)").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False)
    if q:
        query = query.ilike("content", f"%{q}%")
    if mood:
        query = query.eq("mood", mood)
    query = query.order("entry_date", desc=True).order("entry_time", desc=True).range((page - 1) * limit, page * limit - 1)
    r = query.execute()
    results = []
    for row in (r.data or []):
        tag_list = [t["tag"] for t in row.get("entry_tags", [])] if isinstance(row.get("entry_tags"), list) else []
        if tags:
            wanted = [t.strip() for t in tags.split(",") if t.strip()]
            if wanted and not any(t in tag_list for t in wanted):
                continue
        results.append(_entry_response(row, tag_list))
    return {"results": results, "query": q, "page": page, "limit": limit}


@router.get("/suggestions")
async def suggestions(
    q: str = Query("", min_length=0),
    user_id: str = Depends(get_current_user_id),
):
    if not q or len(q) < 2:
        return {"suggestions": []}
    supabase = get_supabase()
    # Suggest tags or recent queries
    r = supabase.table("tags").select("tag").eq("user_id", user_id).ilike("tag", f"%{q}%").limit(10).execute()
    tags = [row["tag"] for row in (r.data or [])]
    return {"suggestions": tags}
