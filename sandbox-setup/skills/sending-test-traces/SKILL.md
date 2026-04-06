---
name: sending-test-traces
description: >-
  Use this skill whenever the user needs to send test trace data to Datadog or Grafana.
  Triggers on mentions of test traces, trace testing, sending sample traces, or validating
  trace ingestion. Also applies when the user wants to verify trace pipeline connectivity.
version: 0.1.0
---

# Sending Test Traces

Send test trace data to validate trace ingestion pipelines.

## Prerequisites

- Datadog or Grafana endpoint accessible
- curl or bash installed

## Instructions

Use the bundled shell script to send test traces:

```bash
bash scripts/send-test-trace-grafana-live.sh
```

See `references/README.md` for configuration details and expected output.

## Validation

Verify traces appear in the target platform's trace explorer within 60 seconds.

## Troubleshooting

### Traces not appearing
**Cause:** Endpoint URL or API key incorrect.
**Fix:** Verify the endpoint and authentication in the script configuration.
