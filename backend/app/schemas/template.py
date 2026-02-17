"""Templates schema for journal entry templates."""
from pydantic import BaseModel, Field


class TemplateStructure(BaseModel):
    """Expected shape of template.structure: title and content for the entry."""

    title: str | None = None
    content: str = ""


class TemplateResponse(BaseModel):
    """Single template as returned by the API."""

    id: str
    name: str
    description: str | None
    category: str
    structure: dict  # {"title": "...", "content": "..."}
    is_system: bool
    created_by: str | None
    usage_count: int = 0


class TemplateCreate(BaseModel):
    """Body to create a user-owned template."""

    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    category: str = Field(default="custom", min_length=1, max_length=100)
    structure: dict = Field(default_factory=lambda: {"title": "", "content": ""})
