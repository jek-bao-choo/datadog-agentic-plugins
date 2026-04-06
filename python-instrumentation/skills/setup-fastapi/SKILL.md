---
name: setup-fastapi
description: >-
  Use this skill whenever the user needs to build and deploy a FastAPI application.
  Triggers on mentions of FastAPI setup, Python API gateway, Gunicorn FastAPI,
  or deploying a FastAPI app with Docker. Also applies when the user wants to prepare
  a Python API for Datadog APM instrumentation.
version: 0.1.0
version_matrix:
  python_version: [3.9]
  fastapi_version: [0.116]
---

# FastAPI Application Setup

Build and deploy a FastAPI application with OpenAI API gateway functionality, Gunicorn/Uvicorn production setup, and Docker deployment.

## Prerequisites

- Python 3.9+
- Docker (optional, for containerized deployment)

## Instructions

The complete application source is in `references/`. Key files:

- `references/README.md` — Full setup documentation
- `references/app/` — FastAPI application source (main.py, config, models, services)
- `references/pyproject.toml` — Dependencies with pinned versions
- `references/Dockerfile` — Container image definition
- `references/docker-compose.yml` — Single-command launch
- `references/gunicorn.conf.py` — Production server configuration

### Local Development

```bash
cd references/
pip install -e .
uvicorn app.main:app --reload --port 8000
```

### Docker Deployment

```bash
cd references/
docker compose up -d
```

## Validation

```bash
curl http://localhost:8000/docs  # FastAPI auto-generated docs
curl http://localhost:8000/health  # Health check
```

## Troubleshooting

### Import errors on startup
**Cause:** Missing dependencies.
**Fix:** `pip install -e .` or rebuild the Docker image.
