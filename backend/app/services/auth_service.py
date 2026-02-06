"""Auth: Supabase auth + our JWT and users table."""
from app.config import get_settings
from app.core.errors import UnauthorizedError, ValidationError, ConflictError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.db.supabase import get_supabase


def _supabase():
    return get_supabase()


def register(email: str, password: str, full_name: str | None = None) -> dict:
    """Sign up via Supabase Auth and ensure user row in public.users."""
    supabase = _supabase()
    settings = get_settings()
    # Supabase auth sign_up (creates auth.users row)
    resp = supabase.auth.sign_up({"email": email, "password": password, "options": {"data": {"full_name": full_name or ""}}})
    if resp.user is None:
        msg = resp.model_dump() if hasattr(resp, "model_dump") else str(resp)
        if "already registered" in str(msg).lower() or "already exists" in str(msg).lower():
            raise ConflictError("Email already registered")
        raise ValidationError("Registration failed", constraint="email")
    user_id = str(resp.user.id)
    # Upsert public.users so we have profile
    supabase.table("users").upsert({
        "id": user_id,
        "email": email,
        "full_name": full_name,
        "onboarding_completed": False,
    }, on_conflict="id").execute()
    # Prefer returning our JWT so client uses same token format everywhere
    access = create_access_token(user_id)
    refresh = create_refresh_token(user_id)
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in": settings.access_token_expire_minutes * 60,
    }


def login(email: str, password: str) -> dict:
    """Sign in via Supabase Auth; return our JWT."""
    supabase = _supabase()
    settings = get_settings()
    try:
        resp = supabase.auth.sign_in_with_password({"email": email, "password": password})
    except Exception as e:
        err_msg = str(e).lower()
        if "email not confirmed" in err_msg or "confirm your email" in err_msg:
            raise UnauthorizedError("Please confirm your email first. Check your inbox for the verification link.")
        if "invalid login" in err_msg or "invalid credentials" in err_msg or "invalid" in err_msg:
            raise UnauthorizedError("Invalid email or password")
        raise UnauthorizedError("Login failed. Please check your email and password, and confirm your email if required.")
    if not resp.user:
        raise UnauthorizedError("Invalid email or password")
    user_id = str(resp.user.id)
    # Ensure public.users row exists (e.g. if user was created before we added upsert on register).
    # Do not fail login if upsert fails; GET /user/profile will create the row on first access.
    meta = getattr(resp.user, "user_metadata", None) or {}
    full_name = meta.get("full_name") if isinstance(meta, dict) else None
    try:
        supabase.table("users").upsert({
            "id": user_id,
            "email": email,
            "full_name": full_name,
        }, on_conflict="id").execute()
    except Exception:
        pass  # Profile will be created when client calls GET /user/profile
    access = create_access_token(user_id)
    refresh = create_refresh_token(user_id)
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in": settings.access_token_expire_minutes * 60,
    }


def refresh_tokens(refresh_token: str) -> dict:
    """Issue new access (and optionally refresh) from refresh token."""
    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedError("Invalid or expired refresh token")
    sub = payload.get("sub")
    if not sub:
        raise UnauthorizedError("Invalid refresh token")
    settings = get_settings()
    access = create_access_token(sub)
    new_refresh = create_refresh_token(sub)
    return {
        "access_token": access,
        "refresh_token": new_refresh,
        "token_type": "bearer",
        "expires_in": settings.access_token_expire_minutes * 60,
    }


def logout(user_id: str) -> None:
    """Server-side: optionally invalidate refresh tokens (e.g. store blacklist). No-op for now."""
    pass


def forgot_password(email: str) -> None:
    """Send reset email via Supabase."""
    supabase = _supabase()
    supabase.auth.reset_password_email(email)


def reset_password(token: str, new_password: str) -> None:
    """Supabase uses the token from email; we need to use auth.update_user or similar."""
    supabase = _supabase()
    supabase.auth.update_user({"password": new_password})
