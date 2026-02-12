# Flutter App Architecture

This document explains how the Flutter app is structured so you can understand it in one go.

---

## Entry Point and App Bootstrap

| File | Purpose |
|------|--------|
| **`main.dart`** | `WidgetsFlutterBinding.ensureInitialized()`, loads `assets/.env` via `flutter_dotenv`, then `runApp(const App())`. |
| **`app.dart`** | Builds **`MultiProvider`** with three `ChangeNotifierProvider`s: **`AuthProvider`**, **`EntryProvider`**, **`PreferencesProvider`**. Child is **`_AppRouterScope`**, which creates **`GoRouter`** once (in `didChangeDependencies`) and builds **`MaterialApp.router`** with theme from `PreferencesProvider` (theme mode + color theme id) and `AppTheme.light/dark`. |

So: one place for global state (providers), one router, theme driven by preferences.

---

## Directory Layout (`lib/`)

```
lib/
├── main.dart
├── app.dart
├── core/                      # Shared config, routing, theme, errors, utils
│   ├── config/
│   │   ├── app_config.dart    # API_BASE_URL, apiV1Prefix from .env
│   │   ├── routes/
│   │   │   └── app_router.dart  # GoRouter, redirect, all routes
│   │   └── theme/             # app_theme, theme_palette, theme_extension, app_colors
│   ├── constants/             # api_constants, storage_constants
│   ├── errors/                # error_handler, exceptions (e.g. ServerException)
│   └── utils/                 # validators
├── data/                      # Data layer
│   ├── data_sources/remote/
│   │   └── api_client.dart    # Dio client, auth header, error mapping, get/post/put/multipart
│   ├── models/                # entry_model, user_model
│   └── repositories/          # auth_repository, entry_repository, preferences_repository
└── presentation/
    ├── providers/             # auth_provider, entry_provider, preferences_provider
    ├── screens/               # auth, home, entries, entry editor, profile, settings, main_shell
    └── widgets/               # common (buttons, text fields), entry_card_actions
```

---

## Routing (`core/config/routes/app_router.dart`)

- **GoRouter** with `initialLocation: '/login'`, **`refreshListenable: authProvider`**, and a **redirect**:
  - Not logged in and not on `/login` or `/signup` → `/login`.
  - Logged in and on login/signup → `/`.
- **Routes**:
  - **`/login`**, **`/signup`** → `LoginScreen`, `SignupScreen`.
  - **`StatefulShellRoute.indexedStack`** with **`MainShell`** and three branches:
    - **`/`** → `HomeScreen`
    - **`/history`** → `EntriesListScreen`
    - **`/profile`** → `ProfileScreen`
  - **`/entry/new`** → `EntryEditorScreen()` (new entry).
  - **`/settings`** → `SettingsScreen` (pushed on top via `rootNavigatorKey`).

Entry editor for **editing** or **with initial prompt** is opened via **`Navigator.push`** with a custom `builder` that passes `EntryEditorScreen(entry: entry)` or `EntryEditorScreen(initialPrompt: prompt)` — not via a GoRouter path with params.

---

## State: The Three Providers

| Provider | Role |
|----------|------|
| **AuthProvider** | Holds `UserModel?`, `isLoading`, `error`. `init()` restores session (tokens in secure storage), fetches profile if logged in. `login`, `register`, `logout`. Exposes `isLoggedIn`; used by router redirect and screens. |
| **EntryProvider** | Holds drafts, recent entries, all entries, streak counts, `datesWithEntries`. Calls **EntryRepository** for create/update, list, get one, upload media, get dates, get inspiration prompt. Exposes `error` for snackbars. |
| **PreferencesProvider** | Theme mode (light/dark), color theme id, and any other prefs. Persisted (e.g. shared_preferences). Read in `app.dart` for theme and in Profile/Settings. |

All three are **ChangeNotifier**; UI uses `context.watch<>` / `context.read<>` / `Provider.of<>`.

---

## Data Layer

| Component | Responsibility |
|-----------|----------------|
| **ApiClient** | Dio instance with base URL from `AppConfig`, interceptors: attach Bearer token, on 401 try refresh then retry, map errors to app exceptions. Methods: `get`, `getList`, `post`, `put`, `delete`, `postMultipartXFile`, `patchMultipart`, etc. Parses API error body (our format + FastAPI detail). |
| **api_constants.dart** | Path strings: `/auth/login`, `/entries`, `/entries/:id`, `/entries/:id/media`, `/ai/generate-prompt`, etc. |
| **Models** | **EntryModel**, **EntryMediaItem**, **UserModel** with `fromJson` / `toJson`. |
| **Repositories** | **AuthRepository**: login, register, logout, refresh, fetchProfile; uses ApiClient + secure storage for tokens. **EntryRepository**: createEntry, updateEntry, listEntries, getEntry, uploadEntryMedia, getEntryDates, getInspirationPrompt (calls `/ai/generate-prompt`). **PreferencesRepository**: load/save theme and prefs. |

No direct API calls from UI; screens call providers, providers call repositories, repositories use ApiClient.

---

## Screens (Where What Lives)

| Screen | Path / How opened | Main role |
|--------|--------------------|-----------|
| **LoginScreen** | `/login` | Email/password form, calls `AuthProvider.login`, navigates on success. |
| **SignupScreen** | `/signup` | Register form, `AuthProvider.register`. |
| **HomeScreen** | `/` | Greeting, calendar strip, streak widget, “Today’s prompt” card (tap → new entry with prompt), FAB “New entry” → `/entry/new` or push editor. |
| **EntriesListScreen** | `/history` | List of published entries; tap entry → push `EntryEditorScreen(entry: entry)`. |
| **ProfileScreen** | `/profile` | User info, theme selector, dark mode; Settings icon → push `/settings`. |
| **SettingsScreen** | `/settings` | App settings; can open drafts list and tap draft → push `EntryEditorScreen(entry: entry)`. |
| **MainShell** | Wraps shell routes | Bottom nav: Home, History, Profile. |
| **EntryEditorScreen** | `/entry/new` or pushed | Title + content; bottom bar: Voice, Ask inspiration, Add photos, Use templates; Save draft / Publish. Loads entry if `entry != null`; uses `initialPrompt` to prefill. Voice uses `speech_to_text`; photos use `image_picker`, then upload on save via **EntryProvider**. |

---

## Theme

- **AppTheme** (`core/config/theme/app_theme.dart`): Builds `ThemeData` for light/dark from a **color theme id** (e.g. warm, soft_blue, sage).
- **ThemePalette** (`theme_palette.dart`): Defines palette per theme (primary, surface, etc.).
- **ThemeExtension** (`theme_extension.dart`): Extra colors (e.g. success, inspiration) for the app.
- **PreferencesProvider** stores `themeMode` and `colorTheme`; **app.dart** passes them into `MaterialApp.router`.

---

## Error Handling

- **core/errors/exceptions.dart**: App-specific exceptions (e.g. `ServerException`, `ValidationException`, `UnauthorizedException`).
- **core/errors/error_handler.dart**: **ErrorHandler.getMessage(e)** turns any exception into a user-facing string (from API body or generic message).
- Providers catch in try/catch, set `_error`, `notifyListeners()`; screens show SnackBar with `provider.error`.

---

## Entry Editor in Short

- **State**: `TextEditingController`s for title/content, `_pendingImages` (XFile), `_entryWithMedia`, speech state (`_speech`, `_isListening`, `_voiceTranscript`), upload loading.
- **Voice**: Permission via **permission_handler**; **speech_to_text** to listen; on stop, sanitized transcript is appended to content.
- **Photos**: **image_picker** multi-pick → add to `_pendingImages`; on Save/Publish, **EntryProvider.uploadEntryMedia** for each, then **getEntry** to refresh `_entryWithMedia` so thumbnails show.
- **Ask inspiration**: **EntryProvider.getInspirationPrompt()** → append to content.
- **Save/Publish**: Content is sanitized (`_sanitizeContent`), then **EntryProvider.saveEntry** with `isDraft: true/false`; then upload pending media; then pop or refresh as needed.

With this map you can jump to any layer (router, provider, repository, API client, screen) and know how it fits the whole app.
