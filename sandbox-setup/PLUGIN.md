---
name: sandbox-setup
description: >
  Initialise sandbox environments for Datadog testing and migration.
  Covers Splunk Enterprise for log export/migration and LiteLLM
  Gateway for budget-controlled access to Claude models on GCP.
category: infrastructure
requires: []
supported_versions: {}
---

## Overview

The sandbox-setup plugin provides skills for setting up auxiliary sandbox environments used during Datadog PoC engagements. Includes Splunk Enterprise for log migration testing and a LiteLLM Gateway for providing budget-controlled API access to Anthropic Claude models.

## Prerequisites

- Docker and Docker Compose for Splunk Enterprise
- GCP project with billing enabled for LiteLLM Gateway
- Anthropic API key for LiteLLM Gateway

## Skills

### initialising-splunk-enterprise
Stand up a local Splunk Enterprise environment with Universal Forwarder using Docker Compose. Send test data, verify indexing, export via REST API, and optionally upload to AWS S3. Useful for testing Datadog log migration from Splunk.

### initialising-litellm-gateway
Deploy a LiteLLM Gateway on GCP Cloud Run with PostgreSQL for budget-controlled access to Anthropic Claude models. Covers Cloud SQL provisioning, Cloud Run deployment, virtual key generation, and Claude Code integration.

## Recommended Skill Order

1. initialising-splunk-enterprise (if migrating from Splunk)
2. initialising-litellm-gateway (if providing Claude API access)

## Compatibility Notes

Skills are independent — install either or both based on the prospect's needs. Splunk Enterprise runs locally via Docker. LiteLLM Gateway requires a GCP project.
