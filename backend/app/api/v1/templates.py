"""Journal entry templates: list (system + user's own), get one, create user template."""
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.core.deps import get_current_user_id
from app.core.errors import AppException, ErrorCode, NotFoundError
from app.db.supabase import get_supabase
from app.schemas.template import TemplateCreate, TemplateResponse

router = APIRouter()


def _row_to_template(row: dict) -> TemplateResponse:
    structure = row.get("structure")
    if not isinstance(structure, dict):
        structure = {"title": "", "content": str(structure) if structure else ""}
    return TemplateResponse(
        id=str(row.get("id", "")),
        name=row.get("name", ""),
        description=row.get("description"),
        category=row.get("category", "general"),
        structure=structure,
        is_system=bool(row.get("is_system")),
        created_by=str(row["created_by"]) if row.get("created_by") is not None else None,
        usage_count=int(row.get("usage_count", 0)),
    )


@router.get("", response_model=list[TemplateResponse])
def list_templates(
    category: str | None = Query(None, description="Filter by category"),
    user_id: str = Depends(get_current_user_id),
):
    """List templates: system templates plus the current user's custom templates.
    Optionally filter by category. Ordered: system first, then by category, then user's."""
    supabase = get_supabase()
    # System templates
    q = supabase.table("templates").select("*").eq("is_system", True)
    if category:
        q = q.eq("category", category)
    r_system = q.order("category").order("name").execute()
    # User's own templates
    q_user = supabase.table("templates").select("*").eq("created_by", user_id)
    if category:
        q_user = q_user.eq("category", category)
    r_user = q_user.order("category").order("name").execute()
    out = []
    seen = set()
    for row in (r_system.data or []) + (r_user.data or []):
        tid = str(row.get("id", ""))
        if tid in seen:
            continue
        seen.add(tid)
        out.append(_row_to_template(row))
    return out


@router.get("/categories", response_model=list[str])
def list_template_categories(user_id: str = Depends(get_current_user_id)):
    """Return distinct template categories (system + user's) for filtering."""
    supabase = get_supabase()
    r = supabase.table("templates").select("category").eq("is_system", True).execute()
    categories = {row.get("category") for row in (r.data or []) if row.get("category")}
    r2 = supabase.table("templates").select("category").eq("created_by", user_id).execute()
    for row in (r2.data or []):
        if row.get("category"):
            categories.add(row.get("category"))
    return sorted(categories)


@router.get("/{template_id}", response_model=TemplateResponse)
def get_template(
    template_id: UUID,
    user_id: str = Depends(get_current_user_id),
):
    """Get a single template by id. Must be system or created by the current user."""
    supabase = get_supabase()
    r = supabase.table("templates").select("*").eq("id", str(template_id)).execute()
    if not r.data or len(r.data) == 0:
        raise NotFoundError("Template not found")
    row = r.data[0]
    if not row.get("is_system") and str(row.get("created_by")) != user_id:
        raise NotFoundError("Template not found")
    return _row_to_template(row)


@router.post("", response_model=TemplateResponse, status_code=201)
def create_template(
    body: TemplateCreate,
    user_id: str = Depends(get_current_user_id),
):
    """Create a user-owned template. It will appear in the template list for this user."""
    supabase = get_supabase()
    structure = body.structure if isinstance(body.structure, dict) else {"title": "", "content": ""}
    if "title" not in structure:
        structure = {**structure, "title": ""}
    if "content" not in structure:
        structure = {**structure, "content": ""}
    ins = supabase.table("templates").insert({
        "name": body.name,
        "description": body.description,
        "category": body.category,
        "structure": structure,
        "is_system": False,
        "created_by": user_id,
    }).execute()
    if not ins.data or len(ins.data) == 0:
        raise AppException(
            ErrorCode.DATABASE_ERROR,
            "Template could not be created. Ensure the templates table exists and RLS allows inserts. See docs/SUPABASE_SETUP.md.",
        )
    return _row_to_template(ins.data[0])
