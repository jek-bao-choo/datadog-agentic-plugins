---
name: setup-springboot3x-apachecamel
description: >-
  Build and run a Spring Boot 3.4 + Apache Camel ESB mock (Component C). Receives JSON,
  transforms to XML (simulating IBM webMethods), generates houseway_bill_id, executes
  80/20 probabilistic branching, and forwards XML to Component D. 20% fault injection.
  Battle-tested: requires bridgeEndpoint=true on Camel HTTP producer.
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.4.5]
  camel_version: [4.10.3]
---

# Spring Boot 3.4 + Apache Camel — ESB Mock (Component C)

Build and run the ESB integration hub that mocks IBM webMethods. Transforms JSON→XML, generates logistics IDs, applies probabilistic branching, and forwards to downstream services.

## Prerequisites

- EC2 with Java 17 and Maven (from `setup-ec2-centos9`)
- Component D running on port 8084 (from `setup-springboot3x`)

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache Camel | 4.10.3 |
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3 |
| Port | 8083 |
| Service name | jek-otel-java-springboot3x-camel |
| Fault injection | 20% on all endpoints except /health |
| 80/20 branching | 80% pristine, 20% mutates IDs with MUTATED- prefix |

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/jek-process` | Receives JSON, transforms to XML, forwards to Component D |
| GET | `/health` | Health check |

## Key battle-tested lesson

The Camel HTTP producer requires `bridgeEndpoint=true` when forwarding to another HTTP endpoint:

```java
.to("http://localhost:8084/jek-receive-xml?bridgeEndpoint=true");
```

Without this, Camel throws `IllegalArgumentException: Invalid url` because it tries to use the incoming request URI as the outgoing URL.

## Build

```bash
cd references/
mvn clean package -DskipTests
```

## Validation

```bash
curl http://localhost:8083/health
curl -X POST http://localhost:8083/jek-process \
  -H "Content-Type: application/json" \
  -d '{"transaction_id": "test-tx-001", "airway_bill_id": "test-awb-001"}'
```

## OTel instrumentation

Reuse `springboot3x-otel-java-tool-opt` — JAVA_TOOL_OPTIONS (with extensions + header capture) set system-wide. `transaction_id` captured via HTTP header. See that skill for full configuration.

## Next Step

Set up `springboot3x-otel-java-tool-opt` for zero-touch OTel agent injection, then build Component B with `setup-springboot3x-resilience4j`.
