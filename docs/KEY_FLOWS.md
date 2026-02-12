# Key Flows – End to End

This document walks through the main user flows so you can see how backend and Flutter work together in one read.

---

## 1. Login

**User** → enters email/password on LoginScreen → taps Login.

**Flutter**

1. **LoginScreen** calls `AuthProvider.login(email, password)`.
2. **AuthProvider** sets loading, clears error, calls **AuthRepository.login(email, password)**.
3. **AuthRepository** POSTs to **`/api/v1/auth/login`** with `{ email, password }` via **ApiClient**.
4. ApiClient interceptor adds no auth header (login is public); on success it gets `access_token`, `refresh_token` (and optionally user). Repository stores tokens in **flutter_secure_storage**, then fetches profile via **GET /api/v1/user/profile** (with Bearer) and returns **UserModel**.
5. AuthProvider sets `_user`, `notifyListeners()`. GoRouter’s **refreshListenable** is AuthProvider, so **redirect** runs: user is logged in and on `/login` → redirect to **`/`** (Home).

**Backend**

1. **POST /auth/login** (auth.py): Receives email/password, uses **Supabase Auth** to sign in, gets Supabase user.
2. **AuthService** (or auth module) creates our **JWT** access + refresh tokens (payload includes `sub` = user id, `type` = "access" / "refresh"), returns them in response.
3. **GET /user/profile** is protected: **get_current_user_id** decodes Bearer token, returns `sub`; route loads user from `users` table (or creates row via `_ensure_user_row`) and returns profile.

**Files to trace**: `flutter_app/.../login_screen.dart` → `auth_provider.dart` → `auth_repository.dart` → `api_client.dart`; `backend/app/api/v1/auth.py`, `backend/app/core/deps.py`, `backend/app/services/auth_service.py`.

---

## 2. Create and Publish an Entry (with optional photo)

**User** → Home → FAB “New entry” → writes (or uses voice / Ask inspiration) → maybe adds photos → Publish.

**Flutter**

1. **HomeScreen** FAB or “Today’s prompt” → **Navigator.push** or **context.go('/entry/new')** with **EntryEditorScreen(initialPrompt: prompt)** or **EntryEditorScreen()**.
2. **EntryEditorScreen**: User edits title/content; can tap **Voice** (speech_to_text → append transcript), **Ask inspiration** (EntryProvider.getInspirationPrompt → append), **Add photos** (image_picker → add to `_pendingImages`).
3. On **Publish**, editor calls `_sanitizeContent(_contentController.text)`, then **EntryProvider.saveEntry(entryId: null, content: ..., isDraft: false, title: ...)**.
4. **EntryProvider** calls **EntryRepository.createEntry(...)** (POST **/api/v1/entries** with body: content, title, is_draft, entry_date, entry_time).
5. Backend returns created entry; provider returns **EntryModel** to editor.
6. Editor calls ** _uploadPendingMedia(saved.id)** → for each `_pendingImages`, **EntryProvider.uploadEntryMedia(entryId, xFile)** → **EntryRepository.uploadEntryMedia** → **POST /api/v1/entries/{id}/media** (multipart). After each success, provider clears error; after all, editor calls **entryProvider.getEntry(entryId)** and sets ** _entryWithMedia** so thumbnails update.
7. Editor then **entryProvider.loadRecentEntries()**, **loadUserStats()**, **loadCalendarDates()**, **Navigator.pop()**.

**Backend**

1. **POST /entries** (entries.py): **create_entry** with **EntryCreate** body. **get_current_user_id** → user_id. Optionally ** _ensure_user_row(user_id)**. Insert into **journal_entries** (user_id, content, entry_date, entry_time, is_draft=false, word_count, character_count, etc.). Return **EntryResponse** (201).
2. **POST /entries/{id}/media**: **upload_entry_media** receives multipart file; checks entry exists and belongs to user; uploads file to Supabase storage bucket **journal-media** at `{entry_id}/{uuid}.{ext}`; inserts one row into **entry_media**; returns **EntryMediaItem** (id, url, file_name, mime_type).

**Files to trace**: `entry_editor_screen.dart` (_publish, _uploadPendingMedia, _addPhotos) → `entry_provider.dart` → `entry_repository.dart` → `api_client.dart`; `backend/app/api/v1/entries.py` (create_entry, upload_entry_media).

---

## 3. Voice Note (on-device only)

**User** → In entry editor → taps **Voice** → speaks → taps **Stop & insert**.

**Flutter only** (no backend for transcription).

1. **EntryEditorScreen**: Tap Voice → **permission_handler** for microphone; **speech_to_text** initialize and **listen(onResult: ...)**. Partial and final results update ** _voiceTranscript** / ** _voicePartial** (and “Listening…” strip).
2. Tap Stop → **speech.stop()**; build final text from ** _voiceTranscript** + ** _voicePartial**; ** _sanitizeContent**; append to ** _contentController** (with `\n\n` if content not empty). SnackBar “Voice note added”.
3. That text is part of the same content; when user taps Save/Publish, it goes in **saveEntry** as usual.

**Files**: `entry_editor_screen.dart` (_toggleVoiceNote, _stopVoiceNote, _ensureSpeechReady, _sanitizeContent).

---

## 4. Ask Inspiration (AI prompt)

**User** → In entry editor → taps **Ask inspiration**.

**Flutter**

1. **EntryEditorScreen** calls **EntryProvider.getInspirationPrompt()**.
2. **EntryProvider** calls **EntryRepository** method that POSTs to **/api/v1/ai/generate-prompt** (body optional).
3. Response `{ "prompt": "..." }`; provider returns string; editor appends to ** _contentController** (prepend `\n\n` if content not empty).

**Backend**

1. **POST /ai/generate-prompt** (ai_routes.py): **get_current_user_id**; calls **AI service** (e.g. Groq) to generate a short journaling prompt; returns **{ "prompt": "..." }**.

**Files**: `entry_editor_screen.dart` (_askInspiration) → `entry_provider.dart` → `entry_repository.dart` (getInspirationPrompt / ApiConstants.aiGeneratePrompt); `backend/app/api/v1/ai_routes.py`, `backend/app/services/ai_service.py`.

---

## 5. View History and Open an Entry

**User** → Bottom nav **History** → sees list → taps an entry.

**Flutter**

1. **EntriesListScreen** (path **/history**) uses **EntryProvider.allEntries** (or list from provider). Provider loaded list via **EntryRepository.listEntries** (GET **/api/v1/entries** with query params).
2. List shows **EntryModel** cards. On tap, **Navigator.push** with **EntryEditorScreen(entry: entry)** (entry is the **EntryModel**).
3. **EntryEditorScreen** with `entry != null`: in initState, **EntryProvider.getEntry(entry.id)** to load full entry (with media); sets ** _entryWithMedia**. UI shows title, content, and media thumbnails (from ** _entryWithMedia?.media** or **widget.entry?.media**).

**Backend**

1. **GET /entries**: List with filters (is_draft, pagination, sort); for each entry, optionally load **entry_media** and attach to response.
2. **GET /entries/{id}**: Single entry + tags + media ( ** _get_entry_media**).

**Files**: `entries_list_screen.dart`, `entry_editor_screen.dart` initState; `entry_provider.dart`; `backend/app/api/v1/entries.py` (list_entries, get_entry).

---

## 6. Theme / Preferences

**User** → Profile → Theme row or Dark mode switch; or opens Settings.

**Flutter**

1. **PreferencesProvider** holds **themeMode** (ThemeMode) and **colorTheme** (string id). Loaded from **PreferencesRepository** (e.g. shared_preferences) on init.
2. **ProfileScreen** or **SettingsScreen**: user picks theme or toggles dark mode; calls **PreferencesProvider** setters; repository persists.
3. **app.dart** does **context.watch<PreferencesProvider>()** and passes **themeMode** and **colorThemeId** into **MaterialApp.router** (theme / darkTheme from **AppTheme.light/dark(colorThemeId)**).

**Backend**: User preferences can be synced via **GET/PUT /user/preferences**; theme is also stored locally so it works offline.

**Files**: `app.dart`, `preferences_provider.dart`, `profile_screen.dart`, `settings_screen.dart`, `core/config/theme/`.

---

## Quick Reference: “Where is X?”

| What | Backend | Flutter |
|------|--------|--------|
| JWT validation | `core/deps.py` get_current_user_id | ApiClient interceptor (add Bearer), 401 → refresh |
| Entry create | `entries.py` create_entry | EntryRepository.createEntry → EntryProvider.saveEntry |
| Photo upload | `entries.py` upload_entry_media | EntryRepository.uploadEntryMedia, editor _uploadPendingMedia |
| Voice text | — | entry_editor_screen, speech_to_text |
| Inspiration prompt | ai_routes.py generate-prompt | EntryProvider.getInspirationPrompt |
| List entries | entries.py list_entries | EntryProvider + EntriesListScreen / HomeScreen |
| Theme | user prefs (optional) | PreferencesProvider, app.dart, theme/* |

Use this with **CODEBASE_OVERVIEW**, **BACKEND_ARCHITECTURE**, and **FLUTTER_ARCHITECTURE** to follow any flow from UI to API and back.
