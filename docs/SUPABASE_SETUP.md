# Supabase setup for AI Journal

Follow these steps so the app can use Supabase for auth, database, and storage (avatars + entry photos).

---

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in.
2. Click **New project**, pick organization, name, database password, and region.
3. Wait for the project to be ready.

---

## 2. Get project settings

In the project:

- **Settings** → **API**: copy **Project URL**, **anon (public) key**, and **service_role key**.
- **Settings** → **Database**: if you need the DB connection string (optional).

Put these in your backend **`.env`**:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJ...   # service_role key (backend only, keep secret)
SUPABASE_ANON_KEY=eyJ...     # anon key (for auth flows if needed)
```

---

## 3. Run the database schema

1. In Supabase, open **SQL Editor**.
2. Create a new query and paste the **entire** contents of **`supabase/schema.sql`** from this repo.
3. Run the query (Run button).

This creates:

- **Tables**: `users`, `user_preferences`, `journal_entries`, **`entry_media`**, `entry_tags`, etc.
- **RLS** (Row Level Security) on those tables.
- **Policies** for `users`, `journal_entries`, `entry_tags` (and enables RLS on `entry_media`).

Important: the backend uses the **service_role** key, which **bypasses RLS**. So the backend can insert into `entry_media` even if no RLS policies are defined for it. If you ever use the anon key for DB access, you would need policies on `entry_media` too.

---

## 4. Add RLS policies for `entry_media` (if needed)

The schema enables RLS on `entry_media` but does **not** create policies. With **service_role**, the backend can still read/write. If you see “Media record could not be created” or permission errors:

1. **Confirm the table exists**  
   In **Table Editor**, check that **`entry_media`** exists and has columns: `id`, `entry_id`, `media_type`, `storage_path`, `storage_bucket`, `file_name`, `mime_type`, etc.

2. **Allow the backend to insert/select**  
   If your backend ever used a key that does **not** bypass RLS, add policies. In **SQL Editor** run:

```sql
-- Allow insert when the entry belongs to the current user (for anon/authenticated).
-- Backend using service_role bypasses RLS and does not need these.
CREATE POLICY "Users can insert media for own entries"
ON entry_media FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM journal_entries j
    WHERE j.id = entry_media.entry_id AND j.user_id = auth.uid()
  )
);

CREATE POLICY "Users can view media for own entries"
ON entry_media FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM journal_entries j
    WHERE j.id = entry_media.entry_id AND j.user_id = auth.uid()
  )
);

CREATE POLICY "Users can delete media for own entries"
ON entry_media FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM journal_entries j
    WHERE j.id = entry_media.entry_id AND j.user_id = auth.uid()
  )
);
```

3. **Ensure the table was created correctly**  
   If `entry_media` was never created, run only the table part of the schema:

```sql
CREATE TABLE IF NOT EXISTS entry_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  storage_bucket TEXT DEFAULT 'journal-media',
  file_name TEXT,
  file_size INTEGER,
  mime_type TEXT,
  duration INTEGER,
  transcription TEXT,
  thumbnail_path TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_entry_media_entry_id ON entry_media(entry_id);
```

---

## 5. Create Storage buckets

### 5.1 Avatars (profile photos)

1. Go to **Storage** in the sidebar.
2. **New bucket** → Name: **`avatars`**, **Public bucket**: ON → Create.

See **[SUPABASE_STORAGE_AVATARS.md](SUPABASE_STORAGE_AVATARS.md)** for more detail.

### 5.2 Journal media (entry photos)

1. In **Storage**, click **New bucket** again.
2. Name: **`journal-media`**
3. **Public bucket**: ON (so entry images load in the app).
4. Create.

If this bucket is missing, the app will show an error when uploading entry photos.  
If you see **"Storage permission denied"**, follow **[SUPABASE_STORAGE_JOURNAL_MEDIA.md](SUPABASE_STORAGE_JOURNAL_MEDIA.md)** to create the bucket and add the Storage policy.

---

## 6. Checklist

- [ ] Supabase project created; **Project URL** and **service_role** key in backend `.env`.
- [ ] **SQL Editor**: full **`supabase/schema.sql`** run (so `journal_entries`, **`entry_media`**, etc. exist).
- [ ] **Table Editor**: table **`entry_media`** exists and has the columns above.
- [ ] (Optional) RLS policies on **`entry_media`** added if you use a key that respects RLS.
- [ ] **Storage** bucket **`avatars`** created and public.
- [ ] **Storage** bucket **`journal-media`** created and public.
- [ ] Backend restarted after any `.env` or schema change.

---

## 7. If “Media record could not be created” still appears

1. **Backend**: The code now uses `.select("*")` on insert so the created row is returned. Restart the backend after pulling the fix.
2. **Table**: In **Table Editor** → **entry_media**, try inserting one row by hand (entry_id = an existing journal entry id). If that fails, the table or RLS is the issue.
3. **Logs**: Check backend logs for the exact Supabase/Postgres error (e.g. constraint violation, missing column).
4. **Keys**: Confirm the backend uses **SUPABASE_SERVICE_KEY** (service_role), not the anon key, so RLS is bypassed for backend requests.
