# Create the Avatars Storage Bucket in Supabase

Profile picture upload needs a Storage bucket named **`avatars`**. Follow these steps in your Supabase project.

---

## 1. Open your Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in.
2. Open the project you use for this app (the one whose URL and keys are in your backend `.env`).

---

## 2. Go to Storage

1. In the left sidebar, click **Storage** (under “Build” or “Database”).
2. You’ll see the list of buckets (it may be empty).

---

## 3. Create a new bucket

1. Click **“New bucket”** (or **“Create a new bucket”**).
2. Fill in:
   - **Name:** `avatars`  
     (Must be exactly `avatars` – the backend uses this name.)
   - **Public bucket:** turn **ON**  
     So profile picture URLs work without signed URLs and the app can show avatars directly.
   - **Allowed MIME types (optional):**  
     You can leave default, or restrict to images only, e.g. `image/jpeg`, `image/png`, `image/gif`, `image/webp`.
3. Click **“Create bucket”** (or **“Save”**).

---

## 4. Set bucket to public (if you didn’t in step 3)

If the bucket was created as private:

1. Open the **avatars** bucket.
2. Use the bucket **settings** (gear or “…” menu).
3. Enable **“Public bucket”** so files are readable via the public URL.

---

## 5. (Optional) Storage policies

Supabase may prompt you to add policies. For this app, the **backend** uploads with the **service role key**, so uploads don’t rely on Storage RLS. If you want to lock down public read-only access:

- **Public read:**  
  Policy that allows `SELECT` for everyone (e.g. `true` on `SELECT`) so `get_public_url()` works.
- **Upload:**  
  Handled by the backend (service key), so you don’t need a policy for client uploads unless you add direct client uploads later.

You can leave policies as default for now and only refine them if you need stricter rules.

---

## 6. Test from the app

1. Restart your backend if it was already running.
2. In the app, open **Profile** and tap the **avatar** (or “Tap to change photo”).
3. Choose **Take photo** or **Choose from gallery** and pick an image.
4. The image should upload and the new profile picture should appear.

If you still see “Avatar storage is not set up”, double-check:

- Bucket name is exactly **`avatars`** (lowercase).
- The backend `.env` has the same Supabase project (`SUPABASE_URL`, `SUPABASE_SERVICE_KEY`).

---

## Summary

| Step | Action |
|------|--------|
| 1 | Open project at supabase.com |
| 2 | Go to **Storage** in the sidebar |
| 3 | Click **New bucket** → Name: `avatars`, **Public bucket: ON** → Create |
| 4 | If needed, set bucket to Public in bucket settings |
| 5 | (Optional) Adjust Storage policies later if needed |
| 6 | Test profile photo upload in the app |

Once the **avatars** bucket exists and is public, profile picture upload will work with your current backend and app.
