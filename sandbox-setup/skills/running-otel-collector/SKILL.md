---
name: running-otel-collector
description: >-
  Use this skill whenever the user needs to run an OpenTelemetry Collector with Datadog
  export. Triggers on mentions of OTel Collector, OpenTelemetry setup, OTLP export to
  Datadog, OTel Collector Docker, or OpenTelemetry trace collection.
version: 0.1.0
---

# OpenTelemetry Collector with Datadog Export

Run an OpenTelemetry Collector via Docker Compose that receives OTLP traces and exports to Datadog.

## Prerequisites

- Docker and Docker Compose installed
- Datadog API key
- Python 3 with `opentelemetry-sdk` and `opentelemetry-exporter-otlp-proto-http`

## Instructions

### 1. Start the OTel Collector

```bash
echo "DD_API_KEY=<YOUR_API_KEY>" > .env
docker compose -f references/docker-compose.yml up -d
```

See `references/otel-collector-config.yaml` for the collector pipeline configuration.

### 2. Send test traces

```bash
source .env && export DD_API_KEY
python scripts/send_trace.py
```

See `references/README.md` for full setup and configuration.

## Validation

Check **APM > Traces** in the Datadog UI for traces from the OTel Collector. See `assets/proof-traces.png` for expected output.

## Troubleshooting

### Collector fails to start
**Cause:** Invalid collector config or missing environment variables.
**Fix:** Verify `references/otel-collector-config.yaml` syntax and `DD_API_KEY` is set.
