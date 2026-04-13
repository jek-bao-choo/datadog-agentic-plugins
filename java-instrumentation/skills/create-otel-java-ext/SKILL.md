---
name: create-otel-java-ext
description: >-
  Create an OTel Java extension JAR that extracts custom business IDs from HTTP request
  bodies and adds them as span attributes + HTTP response headers. Also sets dsm.transaction.id
  and dsm.transaction.checkpoint for Datadog DSM Transaction Tracking. No application code
  changes — uses Spring Boot auto-configuration loaded via -Dloader.path. OTel API is shaded
  into the JAR (required because PropertiesLauncher classloader can't see bootstrap classes).
version: 0.1.0
---

# Create OTel Java Extension — XML Attribute Extractor

Build a JAR that automatically extracts business IDs from HTTP request bodies and adds them as OTel span attributes + HTTP response headers. Zero application code changes.

## How it works

1. A `jakarta.servlet.Filter` wraps the HTTP request to cache the body
2. After Spring MVC processes the request, the filter parses the cached body with regex
3. Extracts `transaction_id`, `airway_bill_id`, `houseway_bill_id` (configurable)
4. Calls `Span.current().setAttribute()` to add them to the active OTel span
5. Also sets `dsm.transaction.id` and `dsm.transaction.checkpoint` for DSM Transaction Tracking
6. Also sets extracted IDs as HTTP response headers (for DSM extractor: HTTP Response Header Outgoing)
7. Registered via Spring Boot `@AutoConfiguration`

## Prerequisites

- Java 17, Maven 3.6.3+ (from `setup-ec2-centos9`)
- Spring Boot app must use `<layout>ZIP</layout>` in pom.xml (enables PropertiesLauncher for `-Dloader.path`)

## Key lessons from battle-testing

- OTel API must be **compile scope + shaded** (not provided) — `PropertiesLauncher` classloader can't see bootstrap classes
- Extension JAR is ~214KB (includes shaded OTel API classes)
- Without `<layout>ZIP</layout>` in the app's pom.xml, `-Dloader.path` has no effect
- `dsm.transaction.id` must be set in the filter (not in the DSM SpanProcessor) due to timing — the SpanProcessor's `onStart` fires before the filter runs, and `onEnd` has a read-only span

## Build

```bash
cd references/
mvn clean package
# Produces target/otel-extension-xml-attributes-1.0.jar (~214KB)
```

## What's in the JAR

- `XmlAttributeExtractorFilter.java` — Servlet Filter: body caching + XML parsing + span attributes + DSM attributes + response headers
- `XmlAttributeAutoConfiguration.java` — Spring Boot auto-config that registers the filter
- `io/opentelemetry/api/**` — Shaded OTel API classes
- `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`

## Span attributes set by this extension

| Attribute | Purpose |
|---|---|
| `transaction_id` | Business ID from XML body → visible in APM traces |
| `airway_bill_id` | Business ID from XML body → visible in APM traces |
| `houseway_bill_id` | Business ID from XML body → visible in APM traces |
| `dsm.transaction.id` | Same as transaction_id → enables DSM Transaction Tracking Traces |
| `dsm.transaction.checkpoint` | Checkpoint name (e.g., `receive-xml`) → DSM Transaction Tracking |

## Adapting for prospect code

See README.md "Adapting for Your Prospect's Code" section for how to change:
- Endpoint paths, field names, payload format (XML/JSON), ID location (body/headers/params)

## Beyond span attributes: Data Streams Monitoring

For full DSM pathway tracking across async messaging (Kafka, SQS, RabbitMQ), see the `create-otel-dsm-ext` skill — a separate, more advanced extension that implements FNV-1a pathway hashing, dd-pathway-ctx-base64 propagation, and MessagePack export to the DD Agent. Full design in `references/otel-dsm-extension-plan.md`.
