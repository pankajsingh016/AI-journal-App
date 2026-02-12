# AI Journal – Codebase Overview

This document gives you a single high-level picture of the whole project so you can understand the codebase in one go.

---

## What This Project Is

**AI Journal** is a journaling app with:

- **Flutter** mobile/app client (iOS, Android, web).
- **Python/FastAPI** backend (REST API).
- **Supabase** for auth, Postgres database, and storage (avatars, journal media).

Users can write entries, add photos, record voice notes (transcribed to text), get AI-inspired prompts, save drafts, publish entries, and view history. The app has a theme system, streaks, and a calendar of writing days.

---

## Repository Layout

```
AI Journal Node Backend Vibe-code/
├── backend/                 # Python FastAPI API
│   ├── app/
│   │   ├── api/v1/          # Route modules (auth, user, entries, search, ai, analytics)
│   │   ├── core/            # Deps (auth), errors, security (JWT)
│   │   ├── db/              # Supabase client
│   │   ├── schemas/         # Pydantic request/response models
│   │   ├── services/        # Auth service, AI service
│   │   ├── config.py        # Settings from .env
│   │   └── main.py          # FastAPI app, CORS, exception handlers
│   ├── requirements.txt
│   └── .env.example
├── flutter_app/             # Flutter application
│   ├── lib/
│   │   ├── main.dart        # Entry point, loads .env, runs App
│   │   ├── app.dart         # MultiProvider, theme, GoRouter
│   │   ├── core/            # Config, routes, theme, constants, errors, utils
│   │   ├── data/            # API client, models, repositories
│   │   └── presentation/    # Providers, screens, widgets
│   ├── assets/.env          # API_BASE_URL etc.
│   └── pubspec.yaml
├── docs/                    # Documentation (this set of MD files)
├── supabase/
│   └── schema.sql           # Tables (users, journal_entries, entry_media, etc.)
└── README.md
```

---

## Tech Stack (One Line Each)

| Layer        | Tech |
|-------------|------|
| **Backend** | FastAPI, Pydantic, Supabase (Postgres + Auth + Storage), JWT, optional Groq for AI |
| **Flutter** | Dart 3, Provider (state), GoRouter (routes), Dio (HTTP), speech_to_text, image_picker, permission_handler |
| **Data**    | Supabase: `users`, `user_preferences`, `journal_entries`, `entry_media`, `entry_tags`, `ai_conversations` |

---

## How Backend and App Talk

1. **Auth**: App sends email/password to `/api/v1/auth/login` (or register). Backend uses Supabase Auth and returns **JWT access + refresh** tokens. App stores them (e.g. secure storage) and sends `Authorization: Bearer <access_token>` on every API call.
2. **Protected routes**: Backend dependency `get_current_user_id` validates the Bearer token and extracts `user_id` (Supabase user UUID). All entry/user/ai routes use this.
3. **REST**: Entries CRUD, user profile, preferences, search, AI prompts, analytics, media upload – all under `/api/v1/*`. See `backend/API.md` for the full list.

---

## Main User Flows (Where to Look in Code)

| Flow            | Backend entry point        | Flutter entry point                    |
|-----------------|----------------------------|----------------------------------------|
| Login / signup  | `app/api/v1/auth.py`       | `AuthProvider`, `LoginScreen`, `SignupScreen` |
| Create entry    | `app/api/v1/entries.py` POST /entries | `EntryProvider.saveEntry`, `EntryEditorScreen` |
| Upload photo    | `app/api/v1/entries.py` POST /entries/:id/media | `EntryRepository.uploadEntryMedia`, editor `_uploadPendingMedia` |
| Voice note      | (no backend; on-device)    | `EntryEditorScreen` + `speech_to_text` |
| Ask inspiration | `app/api/v1/ai_routes.py` POST /ai/generate-prompt | `EntryProvider.getInspirationPrompt`, editor “Ask inspiration” |
| List / history  | GET /entries, /entries/drafts | `EntryProvider`, `EntriesListScreen`, `HomeScreen` |
| Profile / theme | `app/api/v1/user.py`, prefs | `PreferencesProvider`, `ProfileScreen`, `SettingsScreen` |

---

## Where to Start Reading

- **“I want the full map”** → [READING_GUIDE.md](READING_GUIDE.md) (order to read files).
- **Backend only** → [BACKEND_ARCHITECTURE.md](BACKEND_ARCHITECTURE.md).
- **Flutter only** → [FLUTTER_ARCHITECTURE.md](FLUTTER_ARCHITECTURE.md).
- **How a feature works end-to-end** → [KEY_FLOWS.md](KEY_FLOWS.md).

---

## Configuration Quick Reference

- **Backend**: `backend/.env` – `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `JWT_SECRET`, `GROQ_API_KEY` (for AI). See `backend/.env.example`.
- **Flutter**: `flutter_app/assets/.env` – `API_BASE_URL` (e.g. `http://localhost:8000` or your server). See `assets/.env.example`.
- **Supabase**: Run `supabase/schema.sql` in the SQL Editor; create storage bucket `journal-media` (and optional avatars bucket). See `docs/SUPABASE_SETUP.md` and `docs/SUPABASE_STORAGE_AVATARS.md`.

Once you have this overview, use the other MD files to go deep on backend, Flutter, and flows.
