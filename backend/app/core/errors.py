"""Standard API error response and exception types."""
from datetime import datetime, timezone
from typing import Any

from pydantic import BaseModel, Field


class ErrorCode:
    VALIDATION_ERROR = "VALIDATION_ERROR"
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR"
    SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
    AI_SERVICE_ERROR = "AI_SERVICE_ERROR"
    DATABASE_ERROR = "DATABASE_ERROR"


class ErrorDetail(BaseModel):
    field: str | None = None
    constraint: str | None = None
    extra: dict[str, Any] | None = None


class ErrorBody(BaseModel):
    code: str
    message: str
    details: ErrorDetail | dict[str, Any] | None = None
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class APIErrorResponse(BaseModel):
    """Response body for all API errors (spec format)."""
    error: ErrorBody


class AppException(Exception):
    """Base exception for API errors."""
    def __init__(self, code: str, message: str, details: ErrorDetail | dict[str, Any] | None = None):
        self.code = code
        self.message = message
        self.details = details
        super().__init__(message)


class ValidationError(AppException):
    def __init__(self, message: str, field: str | None = None, constraint: str | None = None):
        super().__init__(
            ErrorCode.VALIDATION_ERROR,
            message,
            ErrorDetail(field=field, constraint=constraint),
        )


class UnauthorizedError(AppException):
    def __init__(self, message: str = "Authentication required"):
        super().__init__(ErrorCode.UNAUTHORIZED, message)


class ForbiddenError(AppException):
    def __init__(self, message: str = "Access denied"):
        super().__init__(ErrorCode.FORBIDDEN, message)


class NotFoundError(AppException):
    def __init__(self, message: str = "Resource not found"):
        super().__init__(ErrorCode.NOT_FOUND, message)


class ConflictError(AppException):
    def __init__(self, message: str, details: dict | None = None):
        super().__init__(ErrorCode.CONFLICT, message, details)


class RateLimitError(AppException):
    def __init__(self, message: str = "Rate limit exceeded", retry_after: int | None = None):
        super().__init__(
            ErrorCode.RATE_LIMIT_EXCEEDED,
            message,
            {"retry_after": retry_after} if retry_after else None,
        )


class AIServiceError(AppException):
    def __init__(self, message: str = "AI service temporarily unavailable"):
        super().__init__(ErrorCode.AI_SERVICE_ERROR, message)
