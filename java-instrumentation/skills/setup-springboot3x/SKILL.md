---
name: setup-springboot3x
description: >-
  Build and run a Spring Boot 3.4 REST API on CentOS Stream 9. Component D (terminal node)
  for the distributed logistics PoC. Accepts XML payloads with transaction_id, airway_bill_id,
  houseway_bill_id. Includes 10% probabilistic fault injection and structured logging.
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.4.5]
---

# Spring Boot 3.4 — Build and Deploy (Component D)

Build and run Component D, the terminal node in the logistics chain. Receives XML payloads from Component C, logs the shipment IDs, and returns an XML response.

## Prerequisites

- EC2 instance with Java 17 and Maven (from `setup-ec2-centos9` skill)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP>`

## Tech Stack

| Component | Version |
|---|---|
| Spring Boot | 3.4.5 |
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3 |
| Port | 8084 |
| Service name | jek-otel-java-springboot3x |

## Instructions

See README.md for full step-by-step guide.

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/jek-receive-xml` | Accepts XML shipment payload, logs IDs, returns XML response |
| GET | `/health` | Health check — returns `{"status":"healthy","service":"jek-otel-java-springboot3x","port":8084}` |

## Fault injection

10% of requests (excluding `/health`) return HTTP 500 with a simulated fault error. This is controlled by `FaultInterceptor` with a configurable failure rate.

## Validation

```bash
curl http://localhost:8084/health
curl -X POST http://localhost:8084/jek-receive-xml \
  -H "Content-Type: application/xml" \
  -d '<shipment><transaction_id>test-tx-001</transaction_id><airway_bill_id>test-awb-001</airway_bill_id><houseway_bill_id>test-hwb-001</houseway_bill_id><timestamp>2026-04-12T10:00:00Z</timestamp><source>manual-test</source></shipment>'
```
