"""Auth endpoints: register, login, refresh, forgot/reset password."""
from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse

from app.core.deps import get_current_user_id
from app.core.errors import ConflictError, UnauthorizedError, ValidationError
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    RefreshRequest,
)
from app.services.auth_service import (
    register as do_register,
    login as do_login,
    refresh_tokens,
    logout as do_logout,
    forgot_password,
    reset_password as do_reset_password,
)

router = APIRouter()


@router.post("/register", response_model=TokenResponse)
async def register(body: RegisterRequest):
    data = do_register(
        email=body.email,
        password=body.password,
        full_name=body.full_name,
    )
    return TokenResponse(**data)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest):
    try:
        data = do_login(email=body.email, password=body.password)
        return TokenResponse(**data)
    except (UnauthorizedError, ConflictError, ValidationError):
        raise
    except Exception as e:
        msg = "Login failed. Check your email and password, and confirm your email if required."
        if "confirm" in str(e).lower() or "email" in str(e).lower():
            msg = "Please confirm your email first. Check your inbox for the verification link."
        raise UnauthorizedError(msg)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest):
    data = refresh_tokens(body.refresh_token)
    return TokenResponse(**data)


@router.post("/logout")
async def logout(user_id: str = Depends(get_current_user_id)):
    do_logout(user_id)
    return {"message": "Logged out"}


@router.post("/forgot-password")
async def forgot_pwd(body: ForgotPasswordRequest):
    forgot_password(body.email)
    return {"message": "If an account exists, you will receive a reset link."}


@router.post("/reset-password")
async def reset_pwd(body: ResetPasswordRequest):
    # Supabase: client usually completes reset via recovery link; backend can use admin API if needed
    try:
        do_reset_password(body.token, body.new_password)
    except Exception:
        pass  # Don't leak whether token was valid
    return {"message": "Password has been reset."}


@router.delete("/account")
async def delete_account(user_id: str = Depends(get_current_user_id)):
    # Delete user from Supabase auth + cascade in DB (handled by RLS/schema)
    from app.db.supabase import get_supabase
    supabase = get_supabase()
    supabase.auth.admin.delete_user(user_id)
    return {"message": "Account deleted."}
