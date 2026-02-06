"""API v1 router - aggregates all v1 route modules."""
from fastapi import APIRouter

from app.api.v1 import auth, user, entries, search, ai_routes, analytics

router = APIRouter()
router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(user.router, prefix="/user", tags=["user"])
router.include_router(entries.router, prefix="/entries", tags=["entries"])
router.include_router(search.router, prefix="/search", tags=["search"])
router.include_router(ai_routes.router, prefix="/ai", tags=["ai"])
router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
