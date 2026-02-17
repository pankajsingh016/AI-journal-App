# AI Journal Backend - production image for AWS (EC2, ECR, App Runner, ECS)
# Env vars are NOT baked in. Create a .env on the server and run with:
#   docker run -p 8000:8000 --env-file /path/on/server/.env ai-journal-api
FROM python:3.12-slim

# Avoid pip cache and ensure non-root user
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install dependencies first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code
COPY app/ ./app/

# Run as non-root
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Production: bind to 0.0.0.0 so container accepts external traffic
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
