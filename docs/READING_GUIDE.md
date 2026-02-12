# How to Read This Codebase in One Go

This is the **index and reading order** for the documentation set. Follow it to understand the whole project quickly.

---

## Step 1: Read the Overview (5 min)

**File:** [CODEBASE_OVERVIEW.md](CODEBASE_OVERVIEW.md)

- What the project is (Flutter + FastAPI + Supabase).
- Repo layout (backend vs flutter_app vs docs vs supabase).
- Tech stack in one line per layer.
- How backend and app communicate (auth, REST).
- Table: main user flows and where they live in code.
- Pointers to the other docs.

**Outcome:** You have a mental map of the repo and where to dig next.

---

## Step 2: Choose Your Depth

### Option A – “I want the full picture”

Read in this order:

1. **[CODEBASE_OVERVIEW.md](CODEBASE_OVERVIEW.md)** (you already did).
2. **[BACKEND_ARCHITECTURE.md](BACKEND_ARCHITECTURE.md)** – entry point, API structure, core (deps, errors, DB), main modules, media upload, env.
3. **[FLUTTER_ARCHITECTURE.md](FLUTTER_ARCHITECTURE.md)** – bootstrap, directory layout, routing, the three providers, data layer, screens, theme, errors, entry editor summary.
4. **[KEY_FLOWS.md](KEY_FLOWS.md)** – login, create/publish entry with photo, voice note, Ask inspiration, history, theme.

**Outcome:** You can explain the system to someone and jump to the right file for any feature.

### Option B – “I only care about backend”

1. [CODEBASE_OVERVIEW.md](CODEBASE_OVERVIEW.md) – first two sections and “How Backend and App Talk”.
2. [BACKEND_ARCHITECTURE.md](BACKEND_ARCHITECTURE.md) – full read.
3. [KEY_FLOWS.md](KEY_FLOWS.md) – only the backend parts of flows 1, 2, 4, 5.

Plus **`backend/API.md`** for the endpoint list.

### Option C – “I only care about Flutter”

1. [CODEBASE_OVERVIEW.md](CODEBASE_OVERVIEW.md) – same as above.
2. [FLUTTER_ARCHITECTURE.md](FLUTTER_ARCHITECTURE.md) – full read.
3. [KEY_FLOWS.md](KEY_FLOWS.md) – only the Flutter parts of each flow.

---

## Step 3: Follow Code Along One Flow (optional)

Pick one flow (e.g. “Create and publish an entry with a photo”) and open the files mentioned in **KEY_FLOWS.md** in this order:

**Flutter**

1. `flutter_app/lib/presentation/screens/entry/entry_editor_screen.dart` – where Publish and upload are triggered.
2. `flutter_app/lib/presentation/providers/entry_provider.dart` – saveEntry, uploadEntryMedia.
3. `flutter_app/lib/data/repositories/entry_repository.dart` – createEntry, uploadEntryMedia, API paths.
4. `flutter_app/lib/data/data_sources/remote/api_client.dart` – post, postMultipartXFile, error handling.

**Backend**

1. `backend/app/api/v1/entries.py` – create_entry, upload_entry_media.
2. `backend/app/core/deps.py` – get_current_user_id.
3. `backend/app/schemas/entry.py` – EntryCreate, EntryResponse, EntryMediaItem.

That one path gives you the full request/response cycle.

---

## Document Index

| Document | Purpose |
|----------|--------|
| **READING_GUIDE.md** (this file) | Index and “how to read in one go”. |
| **CODEBASE_OVERVIEW.md** | High-level map: what the project is, layout, stack, backend↔app, flow table. |
| **BACKEND_ARCHITECTURE.md** | FastAPI app, config, API routes, core (deps, errors, DB), modules, media upload, env. |
| **FLUTTER_ARCHITECTURE.md** | App bootstrap, lib layout, routing, providers, data layer, screens, theme, entry editor. |
| **KEY_FLOWS.md** | End-to-end: login, create/publish entry + photo, voice, Ask inspiration, history, theme. |
| **SUPABASE_SETUP.md** | Supabase project and schema setup. |
| **SUPABASE_STORAGE_AVATARS.md** | Storage bucket for avatars (and similar for journal-media if referenced). |
| **backend/API.md** | Full API reference (paths, methods, auth). |

---

## File Checklist (minimal set to “get it”)

If you want the smallest set of files to open and skim:

**Backend**

- `backend/app/main.py` – app, errors, router mount.
- `backend/app/api/v1/__init__.py` – route aggregation.
- `backend/app/core/deps.py` – auth dependency.
- `backend/app/api/v1/entries.py` – create + media upload (first ~100 and upload_entry_media).
- `backend/app/config.py` – settings.

**Flutter**

- `flutter_app/lib/main.dart` – entry.
- `flutter_app/lib/app.dart` – providers, router, theme.
- `flutter_app/lib/core/config/routes/app_router.dart` – routes and redirect.
- `flutter_app/lib/presentation/providers/entry_provider.dart` – entry + media + inspiration.
- `flutter_app/lib/presentation/screens/entry/entry_editor_screen.dart` – editor, voice, photos, save/publish.
- `flutter_app/lib/data/repositories/entry_repository.dart` – API calls for entries.
- `flutter_app/lib/data/data_sources/remote/api_client.dart` – HTTP + auth + errors.

**Docs**

- **CODEBASE_OVERVIEW.md** → **BACKEND_ARCHITECTURE.md** → **FLUTTER_ARCHITECTURE.md** → **KEY_FLOWS.md**.

With the four main MD files plus this reading guide, you can understand the whole codebase in one go and then drill into any area as needed.
