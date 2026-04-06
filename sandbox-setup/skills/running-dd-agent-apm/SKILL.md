---
name: running-dd-agent-apm
description: >-
  Use this skill whenever the user needs to run the Datadog Agent with APM enabled via
  Docker Compose. Triggers on mentions of Datadog Agent Docker, APM agent container,
  docker-compose Datadog, or local Datadog Agent for trace collection.
version: 0.1.0
---

# Datadog Agent APM via Docker Compose

Run the Datadog Agent (v7.69.3) with APM enabled using Docker Compose for local trace collection.

## Prerequisites

- Docker and Docker Compose installed
- Datadog API key

## Instructions

```bash
# Create .env file with your API key
echo "DD_API_KEY=<YOUR_API_KEY>" > .env

# Start the agent
docker compose -f references/docker-compose.yml up -d
```

See `README.md` for full configuration and port mappings.

## Validation

```bash
docker compose -f references/docker-compose.yml ps
# Expected: agent container running

curl http://localhost:8126/info
# Expected: JSON response from trace agent
```

## Troubleshooting

### Agent exits immediately
**Cause:** Missing or invalid `DD_API_KEY`.
**Fix:** Verify `.env` file contains a valid API key.
