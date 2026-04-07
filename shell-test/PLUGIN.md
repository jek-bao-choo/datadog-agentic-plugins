---
name: shell-test
description: >
  Send test traces, logs, and events to Datadog via bash/curl scripts.
  Used to validate telemetry ingestion pipelines during PoC setup.
category: infrastructure
requires: []
supported_versions: {}
---

## Overview

The shell-test plugin provides lightweight bash scripts for sending test telemetry (traces, logs, events) to Datadog. Use these to quickly validate that the Datadog intake endpoints are reachable and data flows through correctly — no application or agent required, just curl.

## Prerequisites

- bash and curl installed
- Datadog API key (read from `.env` file)

## Skills

### sending-test-traces
Send test trace data to validate trace ingestion pipelines.

### sending-test-events
Send test events to Datadog via the Events API.

### sending-test-logs
Send test logs to Datadog via the Logs HTTP API.

## Recommended Skill Order

Skills are independent — use whichever matches the telemetry type you need to validate.

## Compatibility Notes

Pure bash/curl — works on any system with a shell. No Docker, no agents, no SDKs required.
