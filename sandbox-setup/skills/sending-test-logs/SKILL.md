---
name: sending-test-logs
description: >-
  Use this skill whenever the user needs to send test logs to Datadog. Triggers on
  mentions of test logs, log submission, log API testing, log pipeline validation,
  or verifying log ingestion.
version: 0.1.0
---

# Sending Test Logs

Send test log data to Datadog to validate log ingestion pipelines.

## Prerequisites

- Datadog API key
- curl installed

## Instructions

```bash
bash scripts/send-logs.sh
```

See `references/README.md` for configuration and expected log format.

## Validation

Check **Logs > Search** in the Datadog UI for the test logs.

## Troubleshooting

### Logs not appearing
**Cause:** API key invalid, site mismatch, or log pipeline misconfigured.
**Fix:** Verify `DD_API_KEY` and `DD_SITE`. Check Logs > Configuration > Pipelines for processing rules.
