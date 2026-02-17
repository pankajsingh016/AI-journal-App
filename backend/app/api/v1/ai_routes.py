"""AI endpoints: prompt, chat (SSE), improve-text."""
import json
import random
from typing import Any

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from app.core.deps import get_current_user_id
from app.core.errors import AIServiceError
from app.db.supabase import get_supabase
from app.services.ai_service import generate_prompt, improve_text, chat_stream, inspiration_action

router = APIRouter()

INSPIRATION_ACTIONS = {"improve", "grammar", "expand", "soften", "title", "questions"}


class ImproveTextRequest(BaseModel):
    text: str
    instruction: str = "improve clarity and grammar"


class ChatRequest(BaseModel):
    message: str
    entry_id: str | None = None


# Fallback when Groq is unavailable so "Get a writing prompt" always gives the user something.
FALLBACK_PROMPTS = [
    "What is one thing you're grateful for today?",
    "What was a small win or good moment today?",
    "How are you feeling right now, in one sentence?",
    "What would make tomorrow a little better?",
    "Who or what made you smile recently?",
]


@router.post("/generate-prompt")
async def get_daily_prompt(
    context: str | None = None,
    user_id: str = Depends(get_current_user_id),
):
    try:
        prompt_text = generate_prompt(context)
        return {"prompt": prompt_text or FALLBACK_PROMPTS[0]}
    except AIServiceError:
        return {"prompt": random.choice(FALLBACK_PROMPTS)}


@router.post("/improve-text")
async def improve_writing(
    body: ImproveTextRequest,
    user_id: str = Depends(get_current_user_id),
):
    try:
        result = improve_text(body.text, body.instruction)
        return {"original": body.text, "improved": result}
    except AIServiceError as e:
        raise AIServiceError(e.message)


class InspirationRequest(BaseModel):
    text: str = ""
    action: str  # improve | grammar | expand | soften | title | questions


@router.post("/inspiration")
async def run_inspiration(
    body: InspirationRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Run an AI inspiration action on the given text. Returns { result: str }."""
    if body.action not in INSPIRATION_ACTIONS:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=f"action must be one of: {sorted(INSPIRATION_ACTIONS)}")
    try:
        result = inspiration_action(body.text, body.action)
        return {"result": result}
    except AIServiceError as e:
        raise AIServiceError(e.message)


@router.post("/chat")
async def ai_chat_stream(
    body: ChatRequest,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    # Load recent conversation or create new
    conv_r = supabase.table("ai_conversations").select("id, messages").eq("user_id", user_id).order("updated_at", desc=True).limit(1).execute()
    history = []
    conv_id = None
    if conv_r.data and len(conv_r.data) > 0:
        conv_id = conv_r.data[0]["id"]
        history = conv_r.data[0].get("messages") or []
    history.append({"role": "user", "content": body.message})

    async def event_stream():
        full = []
        try:
            for chunk in chat_stream(user_id, body.message, history[:-1]):
                full.append(chunk)
                yield f"data: {json.dumps({'content': chunk})}\n\n"
            # Append assistant message and persist
            assistant_content = "".join(full)
            history.append({"role": "assistant", "content": assistant_content})
            if conv_id:
                supabase.table("ai_conversations").update({"messages": history, "entry_id": body.entry_id}).eq("id", conv_id).eq("user_id", user_id).execute()
            else:
                supabase.table("ai_conversations").insert({"user_id": user_id, "entry_id": body.entry_id, "messages": history}).execute()
        except AIServiceError:
            yield f"data: {json.dumps({'error': 'AI temporarily unavailable'})}\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@router.get("/conversation-history")
async def get_conversation_history(
    limit: int = 5,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    r = supabase.table("ai_conversations").select("id, messages, created_at, updated_at").eq("user_id", user_id).order("updated_at", desc=True).limit(limit).execute()
    return {"conversations": r.data or []}


@router.delete("/conversation-history")
async def clear_conversation_history(user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    supabase.table("ai_conversations").delete().eq("user_id", user_id).execute()
    return {"message": "Conversation history cleared"}
