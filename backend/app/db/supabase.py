"""Supabase client singleton."""
from functools import lru_cache

from supabase import create_client, Client

from app.config import get_settings


@lru_cache
def get_supabase() -> Client:
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_service_key)


def get_supabase_anon() -> Client:
    """Client with anon key for auth flows; use service key for backend ops."""
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_anon_key)
