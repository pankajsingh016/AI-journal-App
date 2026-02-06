"""Analytics: mood trends, writing stats, streaks, dashboard."""
from fastapi import APIRouter, Depends, Query

from app.core.deps import get_current_user_id
from app.db.supabase import get_supabase

router = APIRouter()


@router.get("/mood-trends")
async def mood_trends(
    period: str = Query("30d"),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("entry_date, mood").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).not_.is_("mood", "null").order("entry_date").execute()
    # Group by date
    by_date = {}
    for row in (r.data or []):
        d = str(row.get("entry_date", ""))
        if d not in by_date:
            by_date[d] = []
        by_date[d].append(row.get("mood"))
    return {"period": period, "by_date": by_date}


@router.get("/writing-stats")
async def writing_stats(user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("word_count, character_count, entry_date, content").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).execute()
    data = r.data or []
    total_words = sum(x.get("word_count", 0) for x in data)
    total_entries = len(data)
    avg_words = total_words // total_entries if total_entries else 0
    longest = max(data, key=lambda x: x.get("word_count", 0)) if data else None
    shortest = min(data, key=lambda x: x.get("word_count", 0)) if data else None
    return {
        "total_entries": total_entries,
        "total_words": total_words,
        "average_entry_length": avg_words,
        "longest_entry": {"words": longest.get("word_count", 0), "date": str(longest.get("entry_date", ""))} if longest else None,
        "shortest_entry": {"words": shortest.get("word_count", 0), "date": str(shortest.get("entry_date", ""))} if shortest else None,
    }


@router.get("/streaks")
async def streaks(user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    r = supabase.table("streaks").select("*").eq("user_id", user_id).execute()
    if not r.data or len(r.data) == 0:
        return {"current_streak": 0, "longest_streak": 0}
    row = r.data[0]
    return {
        "current_streak": row.get("current_streak", 0),
        "longest_streak": row.get("longest_streak", 0),
        "last_entry_date": row.get("last_entry_date"),
        "streak_start_date": row.get("streak_start_date"),
    }


@router.get("/dashboard")
async def dashboard(user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    entries_r = supabase.table("journal_entries").select("id, word_count, entry_date, mood").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).execute()
    streak_r = supabase.table("streaks").select("current_streak, longest_streak").eq("user_id", user_id).execute()
    entries = entries_r.data or []
    total_entries = len(entries)
    total_words = sum(e.get("word_count", 0) for e in entries)
    current_streak = 0
    longest_streak = 0
    if streak_r.data and len(streak_r.data) > 0:
        current_streak = streak_r.data[0].get("current_streak", 0)
        longest_streak = streak_r.data[0].get("longest_streak", 0)
    recent = list(reversed(entries[-5:])) if entries else []
    return {
        "total_entries": total_entries,
        "total_words": total_words,
        "current_streak": current_streak,
        "longest_streak": longest_streak,
        "recent_entries": recent,
    }


@router.get("/word-cloud")
async def word_cloud(
    limit: int = Query(50, ge=1, le=200),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    r = supabase.table("journal_entries").select("content").eq("user_id", user_id).is_("deleted_at", "null").eq("is_draft", False).execute()
    from collections import Counter
    import re
    stop = {"the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "is", "it", "i", "my", "me", "we", "you", "they", "this", "that"}
    words = []
    for row in (r.data or []):
        words.extend(re.findall(r"\b[a-z]{3,}\b", (row.get("content") or "").lower()))
    counts = Counter(w for w in words if w not in stop).most_common(limit)
    return {"words": [{"word": w, "count": c} for w, c in counts]}
