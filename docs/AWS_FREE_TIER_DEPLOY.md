# Deploying the backend on AWS free tier

**Yes — the backend is deployable on AWS free tier.** It’s a standard FastAPI app with no special hosting requirements.

---

## Exact commands to deploy on AWS (after pushing to GitHub)

Use these steps **on your EC2 instance** once the code is on GitHub. Replace `YOUR_GITHUB_REPO_URL` with your repo (e.g. `https://github.com/username/AI-journal-App.git` or `git@github.com:username/AI-journal-App.git`).

### One-time setup on EC2

1. **Launch EC2:** Amazon Linux 2, t2.micro. Security group: allow **inbound 22** (SSH) and **8000** (API).

2. **SSH in and install Docker:**
   ```bash
   ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>
   ```
   ```bash
   sudo yum update -y && sudo yum install -y docker git
   sudo systemctl start docker && sudo systemctl enable docker
   sudo usermod -aG docker ec2-user
   ```
   Log out and SSH in again so `docker` works without `sudo`.

3. **Create `.env` on the server** (use your real values; never commit this file):
   ```bash
   nano ~/.env
   ```
   Paste (then replace placeholders):
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_KEY=your-service-role-key
   SUPABASE_ANON_KEY=your-anon-key
   JWT_SECRET=your-256-bit-jwt-secret
   GROQ_API_KEY=your-groq-key-if-using-ai
   ```
   Save (Ctrl+O, Enter, Ctrl+X). Then:
   ```bash
   chmod 600 ~/.env
   ```

### Deploy / update from GitHub

Run these every time you want to deploy or after you push new code:

```bash
# Clone or pull the repo (use your actual GitHub repo URL)
cd ~
git clone YOUR_GITHUB_REPO_URL app-repo || (cd app-repo && git pull)

# Build the Docker image from the backend folder
cd app-repo
docker build -t ai-journal-api -f backend/Dockerfile backend/

# Stop and remove the old container if it exists
docker stop api 2>/dev/null; docker rm api 2>/dev/null

# Run the new container (loads env from ~/.env)
docker run -d -p 8000:8000 --restart unless-stopped \
  --env-file ~/.env \
  --name api ai-journal-api
```

**Check it’s running:**
```bash
curl http://localhost:8000/health
```

Your API is at **`http://<EC2-PUBLIC-IP>:8000`**. In the Flutter app set `API_BASE_URL` to that URL (no trailing slash).

**To update after a new push:** run the “Deploy / update from GitHub” block again (clone/pull, build, stop/rm container, run).

---

## Docker (recommended for EC2 / App Runner / ECS)

The backend has a **Dockerfile** in `backend/`. Use it to build and run the API in any container-friendly AWS service.

### Build and run locally

From the **repo root**:

```bash
docker build -t ai-journal-api -f backend/Dockerfile backend/
docker run -p 8000:8000 --env-file backend/.env ai-journal-api
```

Or from **backend/**:

```bash
cd backend
docker build -t ai-journal-api .
docker run -p 8000:8000 --env-file .env ai-journal-api
```

**Note:** Pass env vars via `--env-file` or `-e KEY=value`. Do not bake secrets into the image.

### Deploy with Docker on AWS free tier

| Option | Steps |
|--------|--------|
| **EC2 + Docker** | Launch t2.micro (Amazon Linux 2), install Docker, pull/run your image or build from repo. Expose port 8000 in security group. |
| **ECR + EC2** | Push image to Amazon ECR (free tier: 500 MB/month), pull on EC2 and run. |
| **App Runner** | Create ECR repo, push image, create App Runner service from that image. Free tier for 12 months. |

**1. EC2 with Docker (simplest free tier)**

1. Launch **Amazon Linux 2** (t2.micro, 750 hrs/month free for 12 months).
2. Security group: allow **inbound 22** (SSH) and **8000** (API).
3. SSH in and install Docker:  
   `sudo yum update -y && sudo yum install -y docker && sudo systemctl start docker && sudo usermod -aG docker ec2-user`  
   Log out and back in so `docker` works without `sudo`.
4. **Create a `.env` file on the server** (e.g. in your home dir). The container will load all variables from this file — do not commit it.
   ```bash
   # On the EC2 instance, create the file (e.g. in home directory)
   nano ~/.env
   ```
   Add the same variables as in `backend/.env.example` (see repo). Minimum:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_KEY=your-service-role-key
   SUPABASE_ANON_KEY=your-anon-key
   JWT_SECRET=your-256-bit-secret
   GROQ_API_KEY=optional-for-ai
   ```
   Save and restrict: `chmod 600 ~/.env`.
5. Get the image on the server:
   - **Option A:** On your machine: `docker save ai-journal-api | gzip > api.tar.gz`, scp to EC2, then on EC2: `docker load < api.tar.gz`
   - **Option B:** On EC2, clone repo and run:  
     `docker build -t ai-journal-api -f backend/Dockerfile backend/`
6. **Run the container using the server’s `.env` file** (Docker loads all env vars from it):
   ```bash
   docker run -d -p 8000:8000 --restart unless-stopped \
     --env-file ~/.env \
     --name api ai-journal-api
   ```
7. API: `http://<EC2-public-IP>:8000` (use in Flutter `API_BASE_URL`).

**2. Push to ECR and run on EC2 or App Runner**

```bash
# One-time: create ECR repo (AWS Console or CLI)
aws ecr create-repository --repository-name ai-journal-api

# Login and push (replace REGION and ACCOUNT)
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com
docker tag ai-journal-api:latest ACCOUNT.dkr.ecr.REGION.amazonaws.com/ai-journal-api:latest
docker push ACCOUNT.dkr.ecr.REGION.amazonaws.com/ai-journal-api:latest
```

Then on EC2: `docker pull ...` and run with your server `.env` file:  
`docker run -d -p 8000:8000 --restart unless-stopped --env-file ~/.env --name api <ECR_IMAGE_URI>`  

For **App Runner**: create a service from the ECR image and set env vars in the App Runner console (it does not use a file; add each variable in the UI).

---

## What the backend needs

| Requirement | How it’s met |
|-------------|----------------|
| **Runtime** | Python 3.x + uvicorn (or any ASGI server) |
| **Database** | Supabase (external) — no RDS needed |
| **Storage** | Supabase Storage — no S3 needed |
| **Config** | Environment variables only |
| **State** | Stateless; no local DB or file storage |
| **Long-lived connections** | None (no WebSockets) |

So you only need **compute** on AWS; DB and file storage stay on Supabase.

---

## Free-tier–friendly options

### 1. **EC2 (e.g. t2.micro)** — simplest

- **Free:** 750 hours/month of t2.micro for 12 months (enough for one instance 24/7).
- **How:** Launch Amazon Linux 2, install Python 3, clone the repo, install deps, set env vars, run `uvicorn app.main:app --host 0.0.0.0 --port 8000`.
- **Pros:** Always on, easy to debug, behaves like your laptop.
- **Cons:** You manage OS and updates; free tier only for first 12 months.

### 2. **Lambda + API Gateway (HTTP API)**

- **Free:** 1M requests/month and 400,000 GB‑seconds of compute per month (stays free after 12 months).
- **How:** Use an adapter like [Mangum](https://mangum.io/) so FastAPI runs as a Lambda handler; expose it via API Gateway HTTP API.
- **Pros:** No servers, pay-per-use, free tier is ongoing.
- **Cons:** Cold starts; need to wire env vars (e.g. from Lambda config or Parameter Store); streaming (e.g. `/api/v1/ai/chat` SSE) may have timeout/behavior limits to test.

### 3. **Elastic Beanstalk**

- **Free:** Uses EC2 under the hood — same 750 hrs/month t2.micro for 12 months.
- **How:** Deploy as a Python platform; EB runs your app (e.g. with gunicorn + uvicorn worker).
- **Pros:** Handles load balancer, platform updates, and scaling config.
- **Cons:** Slightly more setup than raw EC2; same 12‑month free tier as EC2.

### 4. **App Runner**

- **Free:** Free tier for new accounts (e.g. first 12 months).
- **How:** Deploy from a container image or source; App Runner runs the service.
- **Pros:** Fully managed, auto-scaling.
- **Cons:** Free tier is time-limited; you need a Dockerfile or connected repo.

---

## Config on AWS

- **EC2 / EB / App Runner:** Set env vars in the environment or in the platform’s config (e.g. EB “Environment properties”). Never commit `.env`; use placeholders or AWS Systems Manager Parameter Store / Secrets Manager for secrets.
- **Lambda:** Set variables in the Lambda function configuration, or use Parameter Store / Secrets Manager and resolve them in code (or at deploy time).

Required (or recommended) variables:

- `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_ANON_KEY`
- `JWT_SECRET`
- Optional: `GROQ_API_KEY`, `OPENWEATHER_API_KEY`, `SENTRY_DSN`, `DEBUG`

---

## Summary

- The backend is **deployable on AWS free tier** with no code changes.
- **Easiest:** EC2 t2.micro (or Elastic Beanstalk) for a long-running process.
- **Ongoing free tier:** Lambda + API Gateway if you’re okay with cold starts and adapting deployment (e.g. Mangum + API Gateway).
- All external services (Supabase, Groq, etc.) are unchanged; only the host running the FastAPI app moves to AWS.
