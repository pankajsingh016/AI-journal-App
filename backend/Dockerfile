# AI Journal Backend - production image for AWS (EC2, ECR, App Runner, ECS)
# Env vars are NOT baked in. Run with: docker run -p 8000:8000 --env-file /path/to/.env ai-journal-api
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/app

WORKDIR /app

# Install system deps needed for cryptography/bcrypt wheels on slim (then remove to keep image small)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Remove build deps so image stays small (optional; uncomment if you want minimal size)
# RUN apt-get purge -y gcc libffi-dev && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Application code
COPY app/ ./app/

# Non-root user (home dir is default; we set HOME=/app at runtime so libs find /app)
RUN adduser --disabled-password --gecos "" appuser \
    && chown -R appuser:appuser /app

USER appuser

ENV HOME=/app

EXPOSE 8000

# Bind to 0.0.0.0 so the API is reachable from host and network
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Optional: health check so Docker/ECS can see if the app is up
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=2 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1
