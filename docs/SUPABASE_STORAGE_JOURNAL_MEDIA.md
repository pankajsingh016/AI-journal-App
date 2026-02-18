# Journal Media Storage (entry photos)

**To run the same app everywhere (local, server, Docker):** use the **same** `.env` on every machine: `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` (service_role key), **no quotes**. Create the **`journal-media`** bucket in Supabase (Storage → New bucket, **Public**), and add the three storage policies below. Then journal photos work locally and on the server.

If you see **"Storage permission denied"** or **"Photo upload failed"** when adding photos to a journal entry, follow these steps in order.

**If profile picture works but journal entry photos don’t load:**  
Profile uses the **avatars** bucket; journal photos use the **journal-media** bucket. Create a bucket named **journal-media**, set it to **Public**, and add the storage policies below. The app uses the same Supabase URL for both; only the bucket name differs.

---

## 1. Backend .env – use the **service_role** key

The backend **must** use the **service_role** key for storage uploads, not the anon key.

1. In Supabase: **Project Settings** (gear) → **API**.
2. Under **Project API keys**, copy the **`service_role`** key (secret). Do **not** use the `anon` public key.
3. In your **backend** `.env`:

   ```env
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...   # the service_role secret
   ```

4. Restart the backend after changing `.env`.

If `SUPABASE_SERVICE_KEY` is missing or still a placeholder, uploads will fail with a clear “Storage is not configured” message.

---

## 2. Create the bucket in Supabase

1. In the Supabase dashboard, go to **Storage** (left sidebar).
2. Click **New bucket**.
3. **Name:** `journal-media` (exactly; lowercase, hyphen).
4. **Public bucket:** turn **ON** (so image URLs load in the app).
5. Click **Create bucket**.

The bucket **id** in Storage will be `journal-media`. If you already have a bucket with a different name (e.g. `journal_media`), either create a new one named `journal-media` or the backend would need to be changed to use that name.

---

## 3. Storage policies (RLS on `storage.objects`)

Even when using the service role, some projects require policies. In **SQL Editor**, run:

```sql
-- Allow uploads to journal-media bucket (all roles including service_role)
CREATE POLICY "Allow uploads to journal-media"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'journal-media');

-- Allow overwrite (upsert) – needed for retries
CREATE POLICY "Allow update journal-media"
ON storage.objects
FOR UPDATE
USING (bucket_id = 'journal-media')
WITH CHECK (bucket_id = 'journal-media');

-- Allow public read (so image URLs work in the app)
CREATE POLICY "Allow public read journal-media"
ON storage.objects
FOR SELECT
USING (bucket_id = 'journal-media');
```

If you get **"policy already exists"**, the policies are already there; you can skip or drop the existing one first, e.g.:

```sql
DROP POLICY IF EXISTS "Allow uploads to journal-media" ON storage.objects;
-- then run the CREATE again
```

---

## 4. Verify

1. **Backend:** Restart the API. Check server logs; on upload failure you should see a line like:  
   `Journal media upload failed: <exact Supabase error>`.
2. **App:** Create or edit an entry → **Add photos** → pick an image → Save or Publish. The photo should upload and appear.

If it still fails, check:

- Backend logs for the exact error after **"Journal media upload failed:"**.
- API response body: the `details.hint` field often contains the raw Supabase error.
- Supabase **Storage** → **Policies** for the `storage.objects` table: ensure the three policies above exist and reference `bucket_id = 'journal-media'`.

---

## 5. Flutter image URLs (required for photos to show)

For journal photos to **load** in the app (history, list, entry editor):

1. In **backend** `.env`: set `SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co` with **no quotes** (Docker `--env-file` can break quoted values).
2. In **Flutter** `flutter_app/assets/.env`: set the **same** URL:
   ```env
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   ```
   Use the exact same value as in backend `.env`. No quotes.

If either is missing or wrong, you may see "can't save photos" or "old photos don't show". Backend needs the URL to build image URLs; Flutter uses it to display them.

---

## 6. Checklist if photos still don’t save or don’t show

- [ ] Backend `.env`: `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` set (service_role key), **no quotes**.
- [ ] Flutter `assets/.env`: `SUPABASE_URL` set to the **same** value as backend, **no quotes**.
- [ ] Supabase Storage: bucket **`journal-media`** exists and is **Public**.
- [ ] Supabase SQL: the three storage policies (upload, update, public read) exist for `journal-media`.
- [ ] After changing `.env`: restart backend and **restart the Flutter app** (full restart so dotenv reloads).

---

## 7. Works locally but image upload / access fails on the server

If the **same Docker image** works on your PC but you get image upload or journal image access errors on the server:

1. **Use the same .env on the server as locally**  
   Copy your local `backend/.env` to the server (e.g. `~/.env` or `backend/.env`) and run:
   ```bash
   docker run -d -p 8000:8000 --restart unless-stopped --env-file /path/to/.env --name api ai-journal-api
   ```
   The file must contain the **same** `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` (no quotes, no extra spaces).

2. **No quotes in .env on the server**  
   Use `SUPABASE_URL=https://xxx.supabase.co` not `SUPABASE_URL="https://..."`. Some environments break when values are quoted.

3. **Server must reach Supabase**  
   The server needs outbound HTTPS to `*.supabase.co`. If you use a firewall or security group (e.g. AWS), allow **egress** HTTPS (port 443) to the internet or to Supabase IPs.

4. **Check server logs**  
   On upload failure you’ll see: `Journal media upload failed: <error>`.  
   If URLs fail to build you’ll see: `Skipping journal media URL (entry ...): <error>`.  
   Use that message to fix config (wrong/missing SUPABASE_URL) or network (cannot reach Supabase).
