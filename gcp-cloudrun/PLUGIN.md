---
name: gcp-cloudrun
description: >
  Deploy and monitor applications on Google Cloud Run with Datadog.
  Covers Terraform-based Cloud Run provisioning, Artifact Registry
  setup, and JVM metrics exposure via Spring Boot Actuator.
category: infrastructure
requires: []
supported_versions:
  runtime: [java17]
---

## Overview

The gcp-cloudrun plugin provides skills for deploying monitored applications to Google Cloud Run. Currently covers Java Spring Boot applications with JVM metrics exposed via Actuator endpoints, provisioned with Terraform.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI authenticated
- Terraform >= 1.0
- Docker and Maven for building the app

## Skills

### setup-cloudrun-java
Deploy a Java Spring Boot application to Cloud Run using Terraform. Includes Artifact Registry setup, service account configuration, and JVM metrics exposure.

## Recommended Skill Order

1. setup-cloudrun-java

## Compatibility Notes

Tested with Java 17 Spring Boot on Cloud Run in asia-southeast1.
