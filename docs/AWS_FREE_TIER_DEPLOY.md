# Deploying the backend on AWS free tier

**Yes — the backend is deployable on AWS free tier.** It’s a standard FastAPI app with no special hosting requirements.

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
