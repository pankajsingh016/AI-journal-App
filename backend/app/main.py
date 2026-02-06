"""AI Journal API - FastAPI application."""
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.core.errors import (
    APIErrorResponse,
    ErrorBody,
    ErrorCode,
    AppException,
)
from app.api.v1 import router as api_v1_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    if get_settings().sentry_dsn:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        sentry_sdk.init(dsn=get_settings().sentry_dsn, integrations=[FastApiIntegration()])
    yield


app = FastAPI(
    title="AI Journal API",
    description="Backend for AI-powered journaling app",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code={
            ErrorCode.VALIDATION_ERROR: 400,
            ErrorCode.UNAUTHORIZED: 401,
            ErrorCode.FORBIDDEN: 403,
            ErrorCode.NOT_FOUND: 404,
            ErrorCode.CONFLICT: 409,
            ErrorCode.RATE_LIMIT_EXCEEDED: 429,
            ErrorCode.AI_SERVICE_ERROR: 503,
            ErrorCode.SERVICE_UNAVAILABLE: 503,
            ErrorCode.DATABASE_ERROR: 500,
        }.get(exc.code, 500),
        content=APIErrorResponse(error=ErrorBody(
            code=exc.code,
            message=exc.message,
            details=exc.details,
        )).model_dump(),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Pydantic validation errors -> VALIDATION_ERROR."""
    errors = exc.errors()
    first = errors[0] if errors else {}
    loc = first.get("loc", [])
    field = loc[-1] if len(loc) > 1 else None
    msg = first.get("msg", "Validation error")
    return JSONResponse(
        status_code=400,
        content=APIErrorResponse(error=ErrorBody(
            code=ErrorCode.VALIDATION_ERROR,
            message=str(msg),
            details={"field": field, "constraint": first.get("type")},
        )).model_dump(),
    )


@app.get("/health")
async def health():
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


app.include_router(api_v1_router, prefix=get_settings().api_v1_prefix)
