# Journal entry images – why they might not show

Images in journal entries (History, entry editor, calendar-by-date) are loaded from **Supabase Storage**. If they don’t show, check the following.

---

## 1. Backend: set `SUPABASE_URL`

In the **backend** `.env` (same folder as the FastAPI app), set:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
```

- Get the value from **Supabase dashboard** → **Settings** → **API** → **Project URL**.
- If this is missing or still the default placeholder, every image URL will be wrong and images won’t load.
- Restart the backend after changing `.env`.

---

## 2. Flutter app (optional override): set `SUPABASE_URL`

In **flutter_app/assets/.env**, you can set the same URL so the app rewrites image URLs even if the backend sent a wrong host:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
```

- Use the **same** value as in the backend.
- If the backend already has the correct `SUPABASE_URL`, you can leave this unset.

---

## 3. Supabase: bucket exists and is public

1. In Supabase, go to **Storage**.
2. Ensure there is a bucket named **`journal-media`**.
3. Open the bucket → **Settings** → set it as a **Public bucket** so the app can load images without signed URLs.

If the bucket is missing or private, create/set it and add the policies from **docs/SUPABASE_STORAGE_JOURNAL_MEDIA.md**.

---

## 4. Quick checklist

| Check | Where |
|-------|--------|
| `SUPABASE_URL` set to real project URL (no “placeholder”) | Backend `.env` |
| Backend restarted after editing `.env` | Terminal |
| Optional: same `SUPABASE_URL` in app | `flutter_app/assets/.env` |
| Bucket **journal-media** exists and is **Public** | Supabase → Storage |
| Storage policies applied (see SUPABASE_STORAGE_JOURNAL_MEDIA.md) | Supabase → SQL Editor |

After fixing the above, journal images should load in the app.
