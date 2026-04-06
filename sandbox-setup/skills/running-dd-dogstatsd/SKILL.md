---
name: running-dd-dogstatsd
description: >-
  Use this skill whenever the user needs to test DogStatsD custom metrics and events.
  Triggers on mentions of DogStatsD, custom metrics testing, StatsD Datadog, custom
  events, or metric submission testing via Docker.
version: 0.1.0
---

# DogStatsD Custom Metrics Testing

Run the Datadog Agent (v7.68.3) with DogStatsD enabled and test custom metrics/events submission using Python scripts.

## Prerequisites

- Docker and Docker Compose installed
- Python 3 installed
- Datadog API key

## Instructions

### 1. Start the agent

```bash
echo "DD_API_KEY=<YOUR_API_KEY>" > .env
docker compose -f references/docker-compose.yml up -d
```

### 2. Send test metrics

```bash
# With datadog dependency
python scripts/test-metrics.py

# Without datadog dependency (raw UDP)
python scripts/test-metrics-no-datadog-dep.py
```

See `references/README.md` for detailed metric types and expected output.

## Validation

Check **Metrics > Explorer** in the Datadog UI for custom metrics. See `assets/` for proof screenshots of expected results.

## Troubleshooting

### Metrics not appearing
**Cause:** DogStatsD port 8125 not exposed or agent not running.
**Fix:** Verify the agent container is running and port 8125/UDP is mapped.
