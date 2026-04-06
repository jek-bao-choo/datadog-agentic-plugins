---
name: setup-apigee-x
description: >-
  Use this skill whenever the user wants to set up Apigee X as an API gateway on GCP
  with Datadog or OpenTelemetry observability. Triggers on mentions of Apigee X, GCP API
  gateway, API proxy setup, Apigee with Datadog, or API management on Google Cloud.
  Also applies when the user needs to route traffic through Apigee X to a GKE backend.
version: 0.1.0
---

# GCP Apigee X — API Gateway with Observability

Set up Apigee X as a middleware layer between clients and a GKE-hosted Spring Boot backend, with OpenTelemetry observability.

**Architecture:** Android App / Client -> External HTTPS LB -> Apigee X -> PSC -> GKE ILB -> Spring Boot

**Estimated provisioning time:** 45-90 minutes end-to-end (Apigee instance creation is the bottleneck at 30-60 min).

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- A running GKE cluster with a backend service (see gcp-gke plugin)
- Familiarity with Apigee concepts (API proxies, environments, deployments)

## Instructions

Follow the comprehensive step-by-step guide in `references/GUIDE.md`. The guide covers:

1. **Phase 0** — Authentication, API enablement, IAM setup
2. **Phase 1** — Apigee organization provisioning (eval or paid)
3. **Phase 2** — Apigee instance creation (30-60 min)
4. **Phase 3** — Environment and environment group setup
5. **Phase 4** — API proxy bundle creation and deployment (see `references/apiproxy/`)
6. **Phase 5** — PSC and load balancer configuration
7. **Phase 6** — Testing and traffic generation
8. **Phase 7** — Cloud Trace and observability verification

### Quick alternative: Apigee Emulator

For rapid proxy development without cloud provisioning:

```bash
docker run -p 8998:8998 google/apigee-emulator
```

The emulator starts instantly (vs 45+ min for cloud) and is free. Use it for iterating on proxy policies, then deploy to cloud for end-to-end testing.

## Reference Files

- `references/GUIDE.md` — Complete end-to-end implementation guide
- `references/apiproxy/` — API proxy bundle (proxy definition, endpoints, targets)
- `references/springboot-deployment.yaml` — Backend Kubernetes deployment
- `references/springboot-ilb-service.yaml` — Internal load balancer service

## Validation

```bash
# Test the Apigee endpoint (replace with your actual hostname)
curl -v https://<APIGEE_HOSTNAME>/v1/<PROXY_BASEPATH>

# Verify API proxy is deployed
gcloud apigee apis list --organization=$PROJECT

# Check Cloud Trace for request traces
# Navigate to Trace > Trace list in the GCP Console
```

In the Datadog UI, verify traces appear under **APM > Traces** if the backend is instrumented with Datadog APM.

## Troubleshooting

### Apigee instance creation takes longer than expected
**Cause:** Apigee X instance provisioning is inherently slow (30-60 min). This is normal.
**Fix:** Monitor progress with `gcloud apigee instances list --organization=$PROJECT`. Wait for status to become `ACTIVE`.

### PSC connection fails
**Cause:** Private Service Connect endpoint not properly linked to the Apigee instance.
**Fix:** Verify the service attachment and NEG configuration as described in Phase 5 of the GUIDE.md.

### No traces appearing in Datadog
**Cause:** The backend application is not instrumented with Datadog APM, or the Datadog Agent is not deployed in the GKE cluster.
**Fix:** Ensure the Datadog Agent is running (see gcp-gke plugin's install-dd-operator skill) and the backend app has the Datadog tracer configured.
