---
name: sandbox-setup
description: >
  Initialise sandbox environments for Datadog testing, migration,
  and telemetry validation. Covers Splunk Enterprise, LiteLLM Gateway,
  Datadog Agent (APM/DogStatsD), OTel Collector, Cloud-Prem pipelines,
  and test telemetry scripts.
category: infrastructure
requires: []
supported_versions: {}
---

## Overview

The sandbox-setup plugin provides skills for setting up auxiliary sandbox environments used during Datadog PoC engagements. Covers third-party tools (Splunk, LiteLLM), Datadog Agent configurations (APM, DogStatsD), OpenTelemetry Collector, Cloud-Prem observability pipelines, and test telemetry scripts for traces, events, and logs.

## Prerequisites

- Docker and Docker Compose (for most skills)
- Datadog API key
- Python 3 (for metric/trace test scripts)
- GCP project (for LiteLLM Gateway only)

## Skills

### initialising-splunk-enterprise
Stand up a local Splunk Enterprise with Universal Forwarder using Docker Compose. Send test data, verify indexing, export via REST API.

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

### running-cloudprem
Run Datadog Cloud-Prem (observability pipelines) locally with Docker Compose. Two renditions with different pipeline configurations.

## Recommended Skill Order

Skills are independent — use whichever matches the testing need:
1. `running-dd-agent-apm` — if you need a local Datadog Agent for APM
2. `sending-test-*` — to validate telemetry ingestion
3. `running-otel-collector` — for OTel pipeline testing
4. `running-cloudprem` — for observability pipeline testing
5. `initialising-splunk-enterprise` — for Splunk migration testing
6. `initialising-litellm-gateway` — for Claude API budget management

## Compatibility Notes

Most skills require only Docker. The LiteLLM Gateway skill requires a GCP project. Test telemetry scripts require curl and/or Python 3.
