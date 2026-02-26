# Producer image: run with env from GitHub Secrets or .env
# Build from repo root: docker build -f producer/Dockerfile producer/
# Or from producer/: docker build .
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY producer.py .

# BOOTSTRAP_SERVERS, SCHEMA_REGISTRY_URL, KAFKA_API_KEY, KAFKA_API_SECRET, TOPIC
ENTRYPOINT ["python", "producer.py"]
