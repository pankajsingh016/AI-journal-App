"""AI: prompts, chat, improve text via Groq (free API)."""
from app.config import get_settings
from app.core.errors import AIServiceError

_groq_client = None

# Groq OpenAI-compatible API (free tier at console.groq.com)
GROQ_BASE_URL = "https://api.groq.com/openai/v1"


def _groq():
    global _groq_client
    if _groq_client is None:
        from openai import OpenAI
        key = get_settings().groq_api_key
        if not key:
            raise AIServiceError("Groq API key not configured. Set GROQ_API_KEY in .env (get free key at console.groq.com)")
        _groq_client = OpenAI(api_key=key, base_url=GROQ_BASE_URL)
    return _groq_client


def generate_prompt(context: str | None = None) -> str:
    client = _groq()
    model = get_settings().groq_model
    system = "You are a reflective journaling assistant. Generate one short, thoughtful journaling prompt (a question or reflection starter). Output only the prompt text, no quotes or preamble."
    user = context or "Suggest a journaling prompt for today."
    r = client.chat.completions.create(
        model=model,
        messages=[{"role": "system", "content": system}, {"role": "user", "content": user}],
        max_tokens=120,
    )
    if not r.choices:
        raise AIServiceError("No response from Groq")
    return (r.choices[0].message.content or "").strip()


def improve_text(text: str, instruction: str = "improve clarity and grammar") -> str:
    client = _groq()
    model = get_settings().groq_model
    r = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": f"You are an editor. {instruction}. Return only the revised text."},
            {"role": "user", "content": text},
        ],
        max_tokens=2000,
    )
    if not r.choices:
        raise AIServiceError("No response from Groq")
    return (r.choices[0].message.content or text).strip()


def chat_stream(user_id: str, message: str, history: list[dict]) -> "Iterator[str]":
    """Stream chat completion chunks from Groq."""
    client = _groq()
    model = get_settings().groq_model
    messages = [{"role": "system", "content": "You are a supportive, reflective journaling companion. Be warm and concise."}]
    for h in history[-10:]:
        messages.append({"role": h["role"], "content": h.get("content", "")})
    messages.append({"role": "user", "content": message})
    stream = client.chat.completions.create(model=model, messages=messages, stream=True)
    for chunk in stream:
        if chunk.choices and chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content
