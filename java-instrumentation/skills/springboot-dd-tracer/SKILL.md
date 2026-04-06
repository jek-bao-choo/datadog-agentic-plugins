---
name: springboot-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a Spring Boot application with Datadog
  APM on Kubernetes. Triggers on mentions of Java APM, Spring Boot tracing, dd-java-agent,
  Datadog Java tracer, JVM runtime metrics, or Java application monitoring. Also applies when
  the user asks about manual init container injection for the Datadog tracer, or wants to
  monitor a Spring Boot REST API with Datadog.
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.5.9]
---

# Spring Boot 3.5.9 — Datadog APM Instrumentation

Instrument a Spring Boot 3.5.9 REST API with Datadog APM on Kubernetes using manual init container injection for the Datadog Java tracer (`dd-java-agent.jar`).

## Prerequisites

- A Kubernetes cluster with the Datadog Agent deployed (see aws-integration or gcp-integration plugins)
- Java 17 or Docker for building the application
- `kubectl` configured to access the cluster
- Datadog API key configured in the cluster

## Instructions

The complete setup is documented in `references/README.md`. Key phases:

### 1. Build the application

```bash
# Option A: Maven
./mvnw clean package

# Option B: Docker (multi-stage build)
docker build -t springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT .
```

The application provides three REST API endpoints:
- **GET /api/data** — Returns JSON data (logs to console)
- **POST /api/submit** — Accepts JSON payload (logs to syslog)
- **PUT /api/update** — Returns status code only (logs to file)

### 2. Deploy to Kubernetes

```bash
# Build for linux/amd64 and push (if on Apple Silicon)
docker buildx build --platform linux/amd64 -t <REGISTRY>/springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT --push .

# Deploy
kubectl apply -f k8s/
kubectl rollout status deployment/springboot3dot5dot9-sandbox
```

### 3. Datadog APM via init container injection

The `k8s/deployment.yaml` already includes the Datadog tracer setup:

- **Init container** copies `dd-java-agent.jar` from `gcr.io/datadoghq/dd-lib-java-init:latest`
- **Environment variables** set `JAVA_TOOL_OPTIONS=-javaagent:/datadog-lib/dd-java-agent.jar` plus `DD_SERVICE`, `DD_ENV`, `DD_AGENT_HOST`, `DD_PROFILING_ENABLED`, `DD_LOGS_INJECTION`, `DD_TRACE_SAMPLE_RATE`, `DD_RUNTIME_METRICS_ENABLED`
- **Shared volume** (`emptyDir`) mounts in both init and app containers

This approach is preferred over the Datadog admission controller webhook, which excludes its own namespace from auto-injection.

### 4. Generate traffic

```bash
kubectl port-forward svc/springboot3dot5dot9-sandbox 8080:80 &
for i in $(seq 1 60); do
  curl -s http://localhost:8080/api/data > /dev/null
  curl -s -X POST http://localhost:8080/api/submit -H "Content-Type: application/json" -d "{\"key\":\"test\",\"iteration\":$i}" > /dev/null
  curl -s -X PUT http://localhost:8080/api/update > /dev/null
  sleep 2
done
```

## Validation

```bash
# Verify init container exists
kubectl get pods -l app=springboot3dot5dot9-sandbox \
  -o jsonpath='{.items[0].spec.initContainers[*].name}'
# Expected: datadog-lib-java-init

# Check tracer initialization
kubectl logs -l app=springboot3dot5dot9-sandbox --tail=30 | grep "DATADOG TRACER CONFIGURATION"

# Verify traces received by agent
kubectl exec $(kubectl get pods -l app.kubernetes.io/component=agent -o name | head -1) \
  -c agent -- agent status 2>/dev/null | grep -A 10 "Receiver (previous minute)"
```

In the Datadog UI:
- **APM > Services** — look for `springboot3dot5dot9-sandbox` with `env:sandbox`
- **APM > Traces** — filter by `service:springboot3dot5dot9-sandbox`
- **APM > Services > Runtime Metrics** — JVM heap, GC, threads

## Troubleshooting

### No traces appearing in Datadog
**Cause:** The `DD_AGENT_HOST` points to a service that doesn't exist, or the Datadog Agent DaemonSet is not running.
**Fix:** Verify the agent is running: `kubectl get pods -l app.kubernetes.io/component=agent`. Check `DD_AGENT_HOST` value matches the agent service FQDN.

### `DATADOG TRACER CONFIGURATION` not in logs
**Cause:** The init container failed to copy `dd-java-agent.jar`, or `JAVA_TOOL_OPTIONS` is not set.
**Fix:** Check init container logs: `kubectl logs <POD> -c datadog-lib-java-init`. Verify the shared volume is mounted correctly.

### Runtime metrics not appearing
**Cause:** DogStatsD port 8125 not exposed on the agent service.
**Fix:** Verify the `datadog-agent` service exposes port 8125/UDP. The agent DaemonSet should have `DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true`.

### Traces show `env:none` instead of `env:sandbox`
**Cause:** `DD_ENV` environment variable not set on the application pods.
**Fix:** Verify `DD_ENV=sandbox` is in the deployment manifest and reapply.
