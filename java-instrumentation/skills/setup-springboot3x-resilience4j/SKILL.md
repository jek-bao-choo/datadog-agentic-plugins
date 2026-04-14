---
name: setup-springboot3x-resilience4j
description: >-
  Build and run a Spring Boot 3.4 middleware (Component B) with Resilience4j retry + circuit
  breaker. Receives JSON, generates airway_bill_id, forwards enriched JSON to Component C
  with fault tolerance. 20% fault injection. Fallback when C is unavailable.
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.4.5]
  resilience4j_version: [2.2.0]
---

# Spring Boot 3.4 + Resilience4j — Middleware (Component B)

Build and run the middleware that enriches payloads with `airway_bill_id` and forwards to Component C with retry + circuit breaker protection.

## Prerequisites

- EC2 with Java 17 and Maven (from `setup-ec2-centos9`)
- Component C running on port 8083 (from `setup-springboot3x-apachecamel`)
- Component D running on port 8084 (from `setup-springboot3x`)

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Resilience4j | 2.2.0 |
| Java | OpenJDK 17 |
| Port | 8082 |
| Service name | jek-otel-java-springboot3x-r4j |

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/jek-forward` | Receives JSON, adds airway_bill_id, forwards to Component C |
| GET | `/health` | Health check |

## Resilience4j config

- **Retry**: 3 attempts, 500ms wait, exponential backoff (x2)
- **Circuit breaker**: sliding window 10, failure threshold 50%, 10s open wait

## Build

```bash
cd references/
mvn clean package -DskipTests
```

## OTel instrumentation

Reuse `springboot3x-otel-java-tool-opt` — JAVA_TOOL_OPTIONS already set system-wide. Just start the app and the agent loads automatically.

## Next Step

Build Component A with `setup-springboot3x` (ingress).
