# AI-Powered Journaling App

Production-ready AI journaling application (Reflection-style). **Python FastAPI** backend, **Flutter** frontend, **Supabase** database and auth.

## Repo structure

- **`backend/`** – FastAPI app (auth, entries, AI, search, analytics)
- **`supabase/schema.sql`** – PostgreSQL schema and RLS (run in Supabase SQL Editor)
- **`flutter_app/`** – Flutter app (scaffold and core features)

## Backend (FastAPI)

### Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env        # edit with your Supabase and API keys
```

### Run

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: http://localhost:8000  
- Docs: http://localhost:8000/docs  

### Environment

- `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_ANON_KEY` – from Supabase project settings
- `JWT_SECRET` – secret for issuing access/refresh tokens
- `GROQ_API_KEY` – for AI (free at [console.groq.com](https://console.groq.com)); optional `GROQ_MODEL` (default: `llama-3.1-8b-instant`)

### API overview

| Area        | Endpoints |
|------------|-----------|
| Auth        | `POST /api/v1/auth/register`, `login`, `refresh`, `logout`, `forgot-password`, `reset-password`, `DELETE account` |
| User        | `GET/PUT /api/v1/user/profile`, `GET/PUT preferences`, `GET stats`, `PATCH avatar` |
| Entries     | `GET/POST /api/v1/entries`, `GET/PUT/PATCH/DELETE /entries/{id}`, drafts, favorites, calendar, on-this-day |
| Search      | `GET /api/v1/search?q=`, `GET /api/v1/search/suggestions` |
| AI          | `POST /api/v1/ai/generate-prompt`, `POST /api/v1/ai/improve-text`, `POST /api/v1/ai/chat` (SSE), conversation history |
| Analytics   | `GET /api/v1/analytics/mood-trends`, `writing-stats`, `streaks`, `dashboard`, `word-cloud` |

Errors follow the spec format: `{"error": {"code": "...", "message": "...", "details": {...}, "timestamp": "..."}}`.

## Database (Supabase)

1. Create a Supabase project.
2. In SQL Editor, run `supabase/schema.sql` (creates tables, RLS, triggers, full-text search).
3. Create Storage bucket `avatars` (and optionally `journal-media`) if using avatar upload and media.

## Flutter app

**Connecting to the backend:** The app reads the API URL from **`flutter_app/assets/.env`**. Edit `API_BASE_URL` there:

- **Backend and app on the same machine:** `API_BASE_URL=http://localhost:8000`
- **Backend on your laptop, app on phone or another PC:** use your laptop’s LAN IP, e.g. `API_BASE_URL=http://192.168.1.100:8000` (and ensure the backend is run with `--host 0.0.0.0`)

```bash
cd flutter_app
flutter pub get
flutter run
```

See `flutter_app/README.md` for structure and feature checklist.

## Feature checklist (spec)

- [x] Backend: Auth (register, login, refresh, forgot/reset), user profile & preferences, journal entries CRUD, search, AI (prompt, chat SSE, improve-text), analytics
- [x] Supabase schema and RLS
- [ ] Flutter: Auth screens, onboarding, home dashboard, entry editor, AI chat, calendar, insights, search, templates, settings
- [ ] E2E tests, rate limiting, push notifications, export/backup endpoints

## License

Proprietary / your choice.
# AI-journal-App
