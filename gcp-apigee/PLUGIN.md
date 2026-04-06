---
name: gcp-apigee
description: >
  Set up Apigee X as an API gateway on GCP with OpenTelemetry
  observability. Covers end-to-end provisioning including VPC, PSC,
  load balancers, API proxies, and Datadog integration.
category: infrastructure
requires: [gcp-gke]
supported_versions:
  apigee: [X]
---

## Overview

The gcp-apigee plugin provides skills for setting up Apigee X as a middleware layer between clients and GKE-hosted backends. Includes full end-to-end provisioning with OpenTelemetry observability for tracing requests through the API gateway.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- A running GKE cluster with a backend service (see gcp-gke plugin)

## Skills

### setup-apigee-x
Set up Apigee X as an API gateway with end-to-end provisioning: organization, instance, environments, API proxies, PSC, and load balancers. Includes an Apigee Emulator option for local development.

## Recommended Skill Order

1. setup-apigee-x

## Compatibility Notes

Apigee X instance provisioning takes 45-90 minutes. For rapid local development, use the Apigee Emulator (Docker).
