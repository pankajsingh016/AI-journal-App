# AI Journal – Backend API Reference

Base URL: `http://localhost:8000` (or your server)  
API prefix: **`/api/v1`**

All protected routes require: **`Authorization: Bearer <access_token>`**

---

## Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Health check |

---

## Authentication (`/api/v1/auth`)

| Method | Path | Auth | Description | Status | 
|--------|------|------|-------------|---------|
| POST | `/auth/register` | No | Register with email, password, optional full_name. Returns access_token, refresh_token. |Done|
| POST | `/auth/login` | No | Login with email, password. Returns access_token, refresh_token. |Done|
| POST | `/auth/refresh` | No | Body: `{ "refresh_token": "..." }`. Returns new access_token, refresh_token. | Not Check |
| POST | `/auth/logout` | Yes | Invalidate session (client should discard tokens). | Done |
| POST | `/auth/forgot-password` | No | Body: `{ "email": "..." }`. Sends reset email via Supabase. | Not Done|
| POST | `/auth/reset-password` | No | Body: `{ "token": "...", "new_password": "..." }`. | Not-Done|
| DELETE | `/auth/account` | Yes | Delete current user account. | Not-Done|

---

## User (`/api/v1/user`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/user/profile` | Yes | Get current user profile. |
| PUT | `/user/profile` | Yes | Update profile (full_name, journaling_goal, preferred_journaling_time, ai_personality, onboarding_completed). |
| PATCH | `/user/avatar` | Yes | Upload avatar (multipart file). |
| GET | `/user/preferences` | Yes | Get user preferences (theme, reminders, AI, sync, etc.). |
| PUT | `/user/preferences` | Yes | Update preferences. |
| GET | `/user/stats` | Yes | Get user stats (total_entries, total_words, streaks, etc.). |

---

## Journal entries (`/api/v1/entries`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/entries` | Yes | List entries. Query: `page`, `limit`, `sort` (desc/asc), `is_draft`, `is_favorite`. |
| GET | `/entries/drafts` | Yes | List draft entries. |
| GET | `/entries/favorites` | Yes | List favorite entries. |
| GET | `/entries/calendar` | Yes | Query: `year`, `month`. Entries for calendar view. |
| GET | `/entries/on-this-day` | Yes | Query: `month`, `day`. Entries on same month/day in any year. |
| GET | `/entries/{entry_id}` | Yes | Get single entry by ID. |
| POST | `/entries` | Yes | Create entry. Body: content, title, mood, entry_date, entry_time, tags, is_draft, etc. |
| PUT | `/entries/{entry_id}` | Yes | Full update of entry. |
| PATCH | `/entries/{entry_id}` | Yes | Partial update of entry. |
| DELETE | `/entries/{entry_id}` | Yes | Soft-delete entry. |
| POST | `/entries/{entry_id}/favorite` | Yes | Mark entry as favorite. |
| DELETE | `/entries/{entry_id}/favorite` | Yes | Remove favorite. |

---

## Search (`/api/v1/search`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/search` | Yes | Query: `q`, `page`, `limit`, `mood`, `tags` (comma-separated). Full-text/search. |
| GET | `/search/suggestions` | Yes | Query: `q`. Tag suggestions for autocomplete. |

---

## AI (`/api/v1/ai`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/ai/generate-prompt` | Yes | Generate a journaling prompt (optional context in body). Returns `{ "prompt": "..." }`. |
| POST | `/ai/improve-text` | Yes | Body: `{ "text": "...", "instruction": "..." }`. Returns improved text. |
| POST | `/ai/chat` | Yes | Body: `{ "message": "...", "entry_id": null }`. **SSE stream** (text/event-stream). |
| GET | `/ai/conversation-history` | Yes | Query: `limit`. List recent AI conversations. |
| DELETE | `/ai/conversation-history` | Yes | Clear all AI conversation history. |

---

## Analytics (`/api/v1/analytics`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/analytics/mood-trends` | Yes | Query: `period` (e.g. 30d). Mood by date. |
| GET | `/analytics/writing-stats` | Yes | Total entries, words, average length, longest/shortest. |
| GET | `/analytics/streaks` | Yes | Current and longest streak. |
| GET | `/analytics/dashboard` | Yes | Summary: totals, streak, recent entries. |
| GET | `/analytics/word-cloud` | Yes | Query: `limit`. Most used words. |

---

## Error response format

All errors return:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": { "field": "...", "constraint": "..." },
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

Common codes: `VALIDATION_ERROR` (400), `UNAUTHORIZED` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `CONFLICT` (409), `RATE_LIMIT_EXCEEDED` (429), `AI_SERVICE_ERROR` (503).

---

## Interactive docs

- **Swagger UI:** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`
