# Codebase Verification Summary

## Backend

### Auth flow
- **Login**: Supabase `sign_in_with_password` → on success, upsert `public.users` (so profile exists) → return our JWT. Exceptions (e.g. email not confirmed) are caught and re-raised as `UnauthorizedError` with clear messages.
- **Register**: Supabase `sign_up` → upsert `public.users` → return our JWT.
- **Protected routes**: `get_current_user_id` uses Bearer token, decodes JWT with `JWT_SECRET`, returns `sub` (user id). 401 responses use `detail={"error": ErrorBody(...)}`.

### Error responses
- `AppException` (e.g. `UnauthorizedError`) → handler returns `{"error": {"code", "message", "details", "timestamp"}}` with correct status.
- `RequestValidationError` → 400 with same error shape.
- Auth route login: wrapped in try/except so any failure becomes `UnauthorizedError` with a safe message.

### Config / DB
- Settings from env (`.env`); Supabase and JWT have placeholder defaults so app starts without env.
- Supabase client uses **service key** for auth and table access.

---

## Flutter

### API client
- **Base URL**: From `AppConfig.apiBaseUrl` (dotenv `API_BASE_URL`), default `http://localhost:8000`. Prefix `/api/v1`.
- **Auth**: `onRequest` reads token from secure storage and sets `Authorization: Bearer <token>`.
- **Errors**: `onError` maps response to `AppException` (e.g. `UnauthorizedException`) with message from body, then rejects with `DioException(error: appError)`.
- **Message extraction**: Supports `{ "error": { "message": "..." } }`, `{ "detail": "..." }`, `{ "detail": [ { "msg": "..." } ] }`, and **`{ "detail": { "error": { "message": "..." } } }`** (FastAPI HTTPException from deps).

### Error display
- **ErrorHandler.getMessage()**: If `error is DioException` and `error.error is AppException`, returns `(error.error as AppException).message` so the backend message is shown. Otherwise falls back to known exception types or generic message.

### Auth
- **AuthRepository**: login → post `/auth/login` → _storeTokens → fetchProfile. Same for register.
- **AuthProvider**: login() catches exception and sets _error = ErrorHandler.getMessage(e). UI shows _error.
- **dotenv**: Loaded in `main()` before runApp so `AppConfig.apiBaseUrl` is available when ApiClient is built.

### Entry editor
- **Route**: `/entry/new` → EntryEditorScreen.
- **EntryRepository**: createEntry (POST /entries), getInspirationPrompt (POST /ai/generate-prompt). Uses same ApiClient pattern; token read from secure storage on each request.
- **EntryProvider** init() called in app.dart; repo.init() runs so interceptors are attached.

### Routes
- `/login`, `/signup`, `/`, `/entry/new` defined. Redirect: not auth → /login; auth and on auth route → /.
- Home FAB and “Today’s prompt” card push `/entry/new`.

---

## Fixes applied in this pass

1. **Flutter ApiClient**: `_extractErrorMessage` now handles `detail` as a **Map** (e.g. `{"detail": {"error": {"message": "..."}}}` from FastAPI HTTPException), so 401 from `get_current_user_id` shows the real message.
2. **Flutter ApiClient**: Removed unused `import 'dart:convert'`.
3. **ErrorHandler** (already fixed earlier): Uses `DioException.error` when it’s an `AppException` so backend message is shown after login/API failures.

---

## Quick checklist

- [x] Backend login returns `access_token`, `refresh_token`; profile exists after login (upsert on login).
- [x] Backend auth errors return `{"error": {"message": "..."}}`; 401 from deps uses `detail` that client can parse.
- [x] Flutter parses all known error shapes and shows backend message.
- [x] Flutter unwraps `DioException.error` (AppException) in ErrorHandler.
- [x] Env: backend `.env` (Supabase, JWT, Groq); Flutter `assets/.env` (API_BASE_URL).
- [x] New entry flow: FAB → editor; Ask inspiration → POST /ai/generate-prompt; Save draft/Publish → POST /entries.
