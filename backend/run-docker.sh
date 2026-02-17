#!/usr/bin/env bash
# Build and run the API in Docker. Use from backend/: ./run-docker.sh
set -e
cd "$(dirname "$0")"
docker build -t ai-journal-api -f Dockerfile .
docker run -p 8000:8000 --env-file .env ai-journal-api
