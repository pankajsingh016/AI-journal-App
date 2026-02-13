# Journal Media Storage (entry photos)

If you see **"Storage permission denied"** when adding photos to a journal entry, do the following in Supabase.

---

## 1. Create the bucket

1. In the Supabase dashboard, go to **Storage** (left sidebar).
2. Click **New bucket**.
3. **Name:** `journal-media` (exactly).
4. **Public bucket:** turn **ON** (so images load in the app).
5. Click **Create bucket**.

---

## 2. Allow uploads (Storage policy)

The backend uploads with the **service role** key, which usually bypasses Storage RLS. If you still get permission errors, add a policy that allows uploads to this bucket.

In **SQL Editor**, run:

```sql
-- Allow uploads to journal-media bucket (for backend service role / any authenticated user)
CREATE POLICY "Allow uploads to journal-media"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'journal-media');

-- Allow public read (so image URLs work in the app)
CREATE POLICY "Allow public read journal-media"
ON storage.objects
FOR SELECT
USING (bucket_id = 'journal-media');
```

If you get "policy already exists", the policies are already there; skip or drop the existing one first.

---

## 3. Check backend .env

Ensure your **backend** `.env` has:

- `SUPABASE_URL` = your project URL (e.g. `https://xxxxx.supabase.co`)
- `SUPABASE_SERVICE_KEY` = your **service_role** key (not the anon key)

Restart the backend after any change.

---

## 4. Test

In the app, create or edit an entry, tap **Add photos**, pick an image, then Save or Publish. The photo should upload and appear in the entry.
