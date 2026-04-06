---
name: setup-cloudrun-java
description: >-
  Use this skill whenever the user needs to deploy a Java application to Google Cloud Run
  with monitoring. Triggers on mentions of Cloud Run Java, Cloud Run Spring Boot, GCP
  serverless Java, or Terraform Cloud Run deployment. Also applies when the user needs
  JVM metrics from a Cloud Run service.
version: 0.1.0
---

# Cloud Run Java Spring Boot Setup

Deploy a Java Spring Boot application to Google Cloud Run using Terraform, with JVM metrics exposed via Actuator.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI authenticated
- Terraform >= 1.0
- Docker and Maven installed

## Instructions

The complete setup is documented in `README.md`. The Terraform scripts in `scripts/` provision:

- Artifact Registry repository
- Cloud Run service with Java Spring Boot image
- Service account with logging and monitoring permissions
- Health checks and autoscaling configuration

```bash
cd scripts/
terraform init
terraform plan
terraform apply
```

The Spring Boot app exposes:
- REST API: `/`, `/info`
- Health: `/actuator/health`
- Metrics: `/actuator/metrics/*` (JVM memory, GC, threads, classes)

## Validation

```bash
# Get the service URL
gcloud run services describe <SERVICE_NAME> --region <REGION> --format="value(status.url)"

# Test the endpoint
curl <SERVICE_URL>/actuator/health
# Expected: {"status":"UP"}

# Check JVM metrics
curl <SERVICE_URL>/actuator/metrics/jvm.memory.used
```

## Troubleshooting

### Cloud Run service fails to start
**Cause:** Container image not found or port mismatch.
**Fix:** Verify the image exists in Artifact Registry and the app listens on port 8080.

### Metrics endpoint returns 404
**Cause:** Actuator not configured or endpoints not exposed.
**Fix:** Ensure `management.endpoints.web.exposure.include=health,metrics` in application.properties.
