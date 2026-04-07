---
name: splunk-selfhosted
description: >
  Set up a self-hosted Splunk Enterprise environment with Universal
  Forwarder using Docker Compose. Covers log ingestion, indexing
  verification, REST API export, and Datadog log migration.
category: infrastructure
requires: []
supported_versions:
  splunk_version: [latest]
---

## Overview

The splunk-selfhosted plugin provides skills for deploying a local Splunk Enterprise instance with a Universal Forwarder. Used during Datadog PoC engagements to demonstrate log migration from Splunk to Datadog — ingest logs into Splunk, export via REST API, and forward to Datadog.

## Prerequisites

- Docker and Docker Compose installed
- Datadog API key (for migration phase)

## Skills

### setup-splunk-enterprise
Stand up a local Splunk Enterprise instance with Universal Forwarder using Docker Compose. Send test data, verify indexing via `tstats` search, export data via the Splunk REST API (one-off curl and chunked script), and optionally upload to AWS S3.

## Recommended Skill Order

1. setup-splunk-enterprise

## Compatibility Notes

Runs locally via Docker. No cloud infrastructure required. The Splunk web UI is at http://localhost:8000 and the REST API at https://localhost:8089.
