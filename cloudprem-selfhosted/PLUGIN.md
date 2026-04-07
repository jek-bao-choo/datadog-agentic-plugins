---
name: cloudprem-selfhosted
description: >
  Set up Datadog Cloud-Prem (Observability Pipelines) and
  S3-compatible storage locally using Docker Compose for log
  routing and pipeline testing.
category: infrastructure
requires: []
supported_versions: {}
---

## Overview

The cloudprem-selfhosted plugin provides skills for running Datadog Cloud-Prem (Observability Pipelines) locally for log routing and pipeline testing. Also includes Scality ZenkoCloudServer for S3-compatible object storage — useful as a pipeline destination or source.

## Prerequisites

- Docker and Docker Compose installed
- Datadog API key

## Skills

### running-cloudprem
Run Datadog Cloud-Prem (Observability Pipelines) locally with Docker Compose. Two renditions with different pipeline configurations for log routing.

### running-scality-docker
Run Scality ZenkoCloudServer for S3-compatible object storage testing. Available as Docker container or Kubernetes deployment.

## Recommended Skill Order

1. running-scality-docker (if S3-compatible storage is needed as a pipeline target)
2. running-cloudprem

## Compatibility Notes

Both skills run locally via Docker. No cloud infrastructure required.
