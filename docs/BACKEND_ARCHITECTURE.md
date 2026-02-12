# Backend Architecture (Python / FastAPI)

This document explains how the backend is structured so you can understand it in one go.

---

## Entry Point and Configuration

| File | Purpose |
|------|--------|
| **`main.py`** | Creates the FastAPI app, mounts CORS, registers global exception handlers (`AppException`, `RequestValidationError`, `HTTPException`, bare `Exception`), and includes the v1 API router at `prefix=get_settings().api_v1_prefix` (default `/api/v1`). Also `/health` and optional Sentry in lifespan. |
| **`config.py`** | Pydantic `Settings` from env: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `JWT_SECRET`, `GROQ_API_KEY`, `api_v1_prefix`, JWT expiry, rate limits, etc. `get_settings()` is cached. |

---

## API Structure

All v1 routes live under **`/api/v1`**. The router is built in **`app/api/v1/__init__.py`**:

| Prefix | Module | Role |
|--------|--------|------|
| `/auth` | `auth.py` | Register, login, refresh, logout, forgot-password, reset-password. Uses Supabase Auth; issues our own JWT (access + refresh). |
| `/user` | `user.py` | Profile (get/update), avatar upload (PATCH multipart → Supabase storage), preferences (get/update), stats (streaks, totals). Ensures a `users` row exists via `_ensure_user_row`. |
| `/entries` | `entries.py` | Full CRUD for journal entries: list (with filters), get one, create, update, patch, soft-delete; drafts, favorites, calendar, on-this-day, dates; **POST `/entries/{id}/media`** for image upload (storage + `entry_media` row). |
| `/search` | `search.py` | Full-text search over entries; tag suggestions. |
| `/ai` | `ai_routes.py` | Generate journaling prompt (Groq), improve text, chat (SSE), conversation history. |
| `/analytics` | `analytics.py` | Dashboard, streaks, mood trends, writing stats. |

Detailed endpoint list: **`backend/API.md`**.

---

## Core Pieces

### Auth and Dependencies (`app/core/deps.py`)

- **`get_current_user_id`**: Depends on `HTTPBearer`. Decodes JWT, checks `type == "access"`, returns `sub` (user UUID). Used by all protected routes. Raises 401 if missing/invalid.
- **`get_optional_user_id`**: Same decode but returns `None` if no/invalid token (for optional-auth routes if any).

JWT encoding/decoding is in **`app/core/security.py`** (secret from config, HS256).

### Errors (`app/core/errors.py`)

- **`ErrorCode`**: String constants (e.g. `VALIDATION_ERROR`, `UNAUTHORIZED`, `NOT_FOUND`).
- **`APIErrorResponse`** / **`ErrorBody`**: Standard JSON shape `{ "error": { "code", "message", "details", "timestamp" } }`.
- **`AppException`** and subclasses (`ValidationError`, `NotFoundError`, etc.): Raised in routes; `main.py`’s `app_exception_handler` maps them to status codes and the above JSON.

So every API error the client sees has the same structure.

### Database (`app/db/supabase.py`)

- **`get_supabase()`**: Cached Supabase client using **service key** (full access). Used for all table access and storage.
- **`get_supabase_anon()`**: Anon key client (e.g. for auth flows that need it).

Tables (from `supabase/schema.sql`): `users`, `user_preferences`, `journal_entries`, `entry_media`, `entry_tags`, `ai_conversations`, etc.

---

## Request Flow (Typical Protected Route)

1. Request hits FastAPI with `Authorization: Bearer <token>`.
2. Route declares `user_id: str = Depends(get_current_user_id)` → dependency runs, validates JWT, returns `user_id`.
3. Route uses `get_supabase()` to query/insert/update (e.g. `journal_entries`, `entry_media`).
4. Response is built from Pydantic schemas (`app/schemas/`): e.g. `EntryResponse`, `EntryCreate`, `EntryUpdate`, `EntryMediaItem`, user and auth schemas.

---

## Key Modules in Short

| Module | Responsibility |
|--------|----------------|
| **`auth.py`** | Register/login via Supabase Auth; create our JWT; refresh; logout. |
| **`user.py`** | CRUD for `users` and `user_preferences`; avatar upload to storage; stats (streaks computed from `journal_entries`). |
| **`entries.py`** | All entry CRUD; media upload (file → Supabase storage bucket `journal-media` + row in `entry_media`); helpers like `_row_to_response`, `_get_entry_media`, `_storage_public_url`, `_entry_media_error`. |
| **`ai_routes.py`** | Calls AI service (e.g. Groq) for prompt generation; improve text; chat with history stored in `ai_conversations`. |
| **`schemas/entry.py`** | `EntryBase`, `EntryCreate`, `EntryUpdate`, `EntryResponse`, `EntryMediaItem`, `MOOD_VALUES`. |
| **`services/auth_service.py`** | Supabase auth calls and JWT creation. |
| **`services/ai_service.py`** | Groq (or other) API for prompts/chat. |

---

## Media Upload Flow (Picture in Editor)

1. Client: **POST** `/api/v1/entries/{entry_id}/media` with multipart file.
2. **`upload_entry_media`** in `entries.py`: Verifies entry exists and belongs to user; reads file; uploads to Supabase storage `journal-media` at `{entry_id}/{uuid}.{ext}`; inserts one row into **`entry_media`** (no `.select()` chained on insert to avoid builder issues); returns **`EntryMediaItem`** (id, url, file_name, mime_type).

Storage public URL is built from `supabase_url` + `/storage/v1/object/public/{bucket}/{path}`.

---

## Environment and Running

- Copy **`backend/.env.example`** to **`.env`** and set at least: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `JWT_SECRET`. Optional: `GROQ_API_KEY`, `DEBUG`, `SENTRY_DSN`.
- Install: `pip install -r requirements.txt`.
- Run: `uvicorn app.main:app --reload` (or your preferred host/port).

With this, you can trace any API from `main.py` → router → specific route → deps → Supabase/schemas and errors.
