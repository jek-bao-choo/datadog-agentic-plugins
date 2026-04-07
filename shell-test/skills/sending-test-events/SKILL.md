---
name: sending-test-events
description: >-
  Use this skill whenever the user needs to send test events to Datadog. Triggers on
  mentions of test events, Datadog event submission, event API testing, or validating
  event ingestion.
version: 0.1.0
---

# Sending Test Events

Send test events to Datadog to validate event ingestion.

## Prerequisites

- Datadog API key
- curl installed

## Instructions

```bash
bash scripts/send-event.sh
```

The script sends a test event to the Datadog Events API. Configure `DD_API_KEY` and `DD_SITE` environment variables before running.

## Validation

Check **Events > Explorer** in the Datadog UI for the test event.

## Troubleshooting

### Event not appearing
**Cause:** API key invalid or site mismatch.
**Fix:** Verify `DD_API_KEY` and `DD_SITE` environment variables.
