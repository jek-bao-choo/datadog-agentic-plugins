---
name: fastapi-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a FastAPI application with Datadog
  APM. Triggers on mentions of Python APM, ddtrace FastAPI, FastAPI tracing, or Datadog
  Python tracer. Also applies for Python web API monitoring with Datadog.
version: 0.1.0
version_matrix:
  python_version: [3.9]
  fastapi_version: [0.116]
---

# FastAPI — Datadog APM Instrumentation

Instrument a deployed FastAPI application with Datadog APM using `ddtrace`.

## Prerequisites

- Skill `setup-fastapi` has been completed successfully
- Datadog Agent running on the host or cluster
- Datadog API key configured

## Instructions

### 1. Install ddtrace

```bash
pip install ddtrace
```

### 2. Run with ddtrace-run

```bash
DD_SERVICE=fastapi-gateway DD_ENV=sandbox DD_AGENT_HOST=localhost \
  ddtrace-run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Or for Gunicorn:

```bash
DD_SERVICE=fastapi-gateway DD_ENV=sandbox DD_AGENT_HOST=localhost \
  ddtrace-run gunicorn -c gunicorn.conf.py app.main:app
```

### 3. Generate traffic

```bash
for i in $(seq 1 20); do curl -s http://localhost:8000/health > /dev/null; done
```

## Validation

```bash
# Check agent is receiving traces
sudo datadog-agent status | grep -A 10 "Receiver"
```

In the Datadog UI: **APM > Services** — look for `fastapi-gateway` with `env:sandbox`.

## Troubleshooting

### No traces appearing
**Cause:** `DD_AGENT_HOST` incorrect or agent not running.
**Fix:** Verify agent is reachable: `curl http://localhost:8126/info`
