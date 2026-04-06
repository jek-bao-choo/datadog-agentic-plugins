---
name: setup-springboot
description: >-
  Use this skill whenever the user needs to build, run, or deploy a Spring Boot application
  before instrumenting it with Datadog APM. Triggers on mentions of Spring Boot setup,
  Java application deployment, building a Spring Boot JAR, deploying Spring Boot to
  Kubernetes, or running a Spring Boot app in Docker. Also applies when the user needs to
  prepare a Java application for Datadog APM instrumentation.
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.5.9]
---

# Spring Boot 3.5.9 — Build and Deploy

Build and deploy a Spring Boot 3.5.9 REST API application. Provides the foundation for Datadog APM instrumentation (see `springboot-dd-tracer` skill).

The sample application provides three REST API endpoints with different logging destinations and random HTTP status codes (30% 2XX, 40% 4XX, 30% 5XX). See `../springboot-dd-tracer/references/README.md` for the full application documentation.

## Prerequisites

- Java 17 or Docker
- `kubectl` (for Kubernetes deployment)
- A Kubernetes cluster (see aws-ec2 or gcp-gke plugins)

## Instructions

The full application source and documentation is in `../springboot-dd-tracer/references/`. Key steps:

### Option A: Maven (local development)

```bash
cd ../springboot-dd-tracer/references/
./mvnw clean package
./mvnw spring-boot:run
```

The application starts on `http://localhost:8080`.

### Option B: Docker

```bash
cd ../springboot-dd-tracer/references/
docker build -t springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT .
docker run -p 8080:8080 springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT
```

### Option C: Kubernetes (production)

```bash
cd ../springboot-dd-tracer/references/

# Build for linux/amd64 and push to registry
docker buildx build --platform linux/amd64 \
  -t <REGISTRY>/springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT --push .

# Deploy
kubectl apply -f k8s/
kubectl rollout status deployment/springboot3dot5dot9-sandbox
```

### Test the endpoints

```bash
# GET endpoint
curl http://localhost:8080/api/data

# POST endpoint
curl -X POST http://localhost:8080/api/submit \
  -H "Content-Type: application/json" \
  -d '{"key": "test"}'

# PUT endpoint
curl -X PUT http://localhost:8080/api/update -v
```

## Validation

```bash
# Verify app is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health
# Expected: 200

# Verify all three endpoints respond
curl -s http://localhost:8080/api/data | head -1
# Expected: JSON response with randomNumber, loremIpsum, statusCode

# For Kubernetes: verify pods are ready
kubectl get pods -l app=springboot3dot5dot9-sandbox
kubectl rollout status deployment/springboot3dot5dot9-sandbox
```

## Troubleshooting

### Port 8080 already in use
**Cause:** Another process is using port 8080.
**Fix:** `lsof -i :8080` to find it, then kill or change port in `application.properties`.

### Maven build fails
**Cause:** Wrong Java version or corrupted cache.
**Fix:** Verify `java -version` shows 17.x, then `./mvnw clean` and retry.

### Kubernetes pods stuck in CrashLoopBackOff
**Cause:** JVM startup exceeds probe timeout, or image pull failure.
**Fix:** Check logs: `kubectl logs -l app=springboot3dot5dot9-sandbox`. The startup probe allows up to 70s for JVM boot.
