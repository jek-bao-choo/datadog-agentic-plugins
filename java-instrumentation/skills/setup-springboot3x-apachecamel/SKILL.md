---
name: setup-springboot3x-apachecamel
description: >-
  Build and run a Spring Boot 3.4 + Apache Camel ESB mock (Component C). Receives JSON,
  transforms to XML (simulating IBM webMethods), generates houseway_bill_id, executes
  80/20 probabilistic branching, and forwards XML to Component D. 20% fault injection.
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

| Component | Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache Camel | 4.10.3 |
| Java | OpenJDK 17 |
| Port | 8083 |
| Service name | jek-otel-java-springboot3x-camel |

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/jek-process` | Receives JSON, transforms to XML, forwards to Component D |
| GET | `/health` | Health check |

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
