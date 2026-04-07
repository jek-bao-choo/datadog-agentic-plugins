---
name: sandbox-setup
description: >
  Initialise sandbox environments for Datadog testing and telemetry
  validation. Covers LiteLLM Gateway, Datadog Agent (APM/DogStatsD),
  OTel Collector, and test telemetry scripts.
category: infrastructure
requires: []
supported_versions: {}
---

## Overview

The sandbox-setup plugin provides skills for setting up auxiliary sandbox environments used during Datadog PoC engagements. Covers LiteLLM Gateway, Datadog Agent configurations (APM, DogStatsD), OpenTelemetry Collector, and test telemetry scripts for traces, events, and logs. (Splunk Enterprise moved to `splunk-selfhosted`. Cloud-Prem and Scality moved to `cloudprem-selfhosted`.)

## Prerequisites

- Docker and Docker Compose (for most skills)
- Datadog API key
- Python 3 (for metric/trace test scripts)
- GCP project (for LiteLLM Gateway only)

## Skills

### initialising-litellm-gateway
Deploy a LiteLLM Gateway on GCP Cloud Run for budget-controlled access to Anthropic Claude models.

### sending-test-traces
Send test trace data to validate trace ingestion pipelines.

### sending-test-events
Send test events to Datadog via the Events API.

### sending-test-logs
Send test log data to validate log ingestion pipelines.

### running-dd-agent-apm
Run the Datadog Agent (v7.69.3) with APM enabled via Docker Compose for local trace collection.

### running-dd-dogstatsd
Run the Datadog Agent with DogStatsD and test custom metrics/events submission with Python scripts.

### running-otel-collector
Run an OpenTelemetry Collector via Docker Compose that receives OTLP traces and exports to Datadog.

## Recommended Skill Order

Skills are independent — use whichever matches the testing need:
1. `running-dd-agent-apm` — if you need a local Datadog Agent for APM
2. `sending-test-*` — to validate telemetry ingestion
3. `running-otel-collector` — for OTel pipeline testing
4. `initialising-litellm-gateway` — for Claude API budget management

## Compatibility Notes

Most skills require only Docker. The LiteLLM Gateway skill requires a GCP project. Test telemetry scripts require curl and/or Python 3.
