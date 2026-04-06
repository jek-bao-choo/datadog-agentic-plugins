---
name: running-cloudprem
description: >-
  Use this skill whenever the user needs to set up a Datadog Cloud-Prem (observability
  pipelines) environment. Triggers on mentions of Cloud-Prem, observability pipelines,
  log forwarding pipeline, Datadog log routing, or local pipeline testing with Docker.
version: 0.1.0
---

# Datadog Cloud-Prem Observability Pipelines

Run Datadog Cloud-Prem (observability pipelines) locally using Docker Compose. Two renditions are available with different pipeline configurations.

## Prerequisites

- Docker and Docker Compose installed
- Datadog API key

## Instructions

Two renditions are available in `references/`:

### Rendition 1 — Basic log pipeline

```bash
echo "DD_API_KEY=<YOUR_API_KEY>" > .env
docker compose -f references/docker-compose-rendition1.yml up -d
```

Generate test logs:
```bash
bash scripts/generate-logs.sh
```

Clear logs:
```bash
bash scripts/clear-cloudprem-logs.sh
```

### Rendition 2 — Advanced pipeline

```bash
echo "DD_API_KEY=<YOUR_API_KEY>" > .env
docker compose -f references/docker-compose-rendition2.yml up -d
```

See `README-rendition1.md` and `README-rendition2.md` for detailed configuration and architecture.

## Validation

Check **Logs > Search** in the Datadog UI for logs flowing through the pipeline. See `assets/` for proof screenshots and architecture diagrams.

## Troubleshooting

### Pipeline not forwarding logs
**Cause:** Pipeline configuration incorrect or agent not connected.
**Fix:** Check docker logs for the pipeline container and verify the pipeline config.
