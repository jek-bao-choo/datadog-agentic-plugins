---
name: create-otel-java-ext
description: >-
  Create an OTel Java extension JAR that extracts custom business IDs from HTTP request
  bodies and adds them as span attributes. No application code changes — uses Spring Boot
  auto-configuration loaded via -Dloader.path. OTel API is shaded into the JAR (required
  because PropertiesLauncher classloader can't see bootstrap classes). Includes guidance
  for adapting to different payload formats, field names, and endpoints.
version: 0.1.0
---

# Create OTel Java Extension — XML Attribute Extractor

Build a JAR that automatically extracts business IDs from HTTP request bodies and adds them as OTel span attributes. Zero application code changes.

## How it works

1. A `jakarta.servlet.Filter` wraps the HTTP request to cache the body
2. After Spring MVC processes the request, the filter parses the cached body with regex
3. Extracts `transaction_id`, `airway_bill_id`, `houseway_bill_id` (configurable)
4. Calls `Span.current().setAttribute()` to add them to the active OTel span
5. Registered via Spring Boot `@AutoConfiguration`

## Prerequisites

- Java 17, Maven 3.6.3+ (from `setup-ec2-centos9`)
- Spring Boot app must use `<layout>ZIP</layout>` in pom.xml (enables PropertiesLauncher for `-Dloader.path`)

## Key lessons from battle-testing

- OTel API must be **compile scope + shaded** (not provided) — `PropertiesLauncher` classloader can't see bootstrap classes
- Extension JAR is ~214KB (includes shaded OTel API classes)
- Without `<layout>ZIP</layout>` in the app's pom.xml, `-Dloader.path` has no effect

## Build

```bash
cd references/
mvn clean package
# Produces target/otel-extension-xml-attributes-1.0.jar (~214KB)
```

## What's in the JAR

- `XmlAttributeExtractorFilter.java` — Servlet Filter with body caching + XML parsing + `Span.current().setAttribute()`
- `XmlAttributeAutoConfiguration.java` — Spring Boot auto-config that registers the filter
- `io/opentelemetry/api/**` — Shaded OTel API classes
- `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`

## Adapting for prospect code

See README.md "Adapting for Your Prospect's Code" section for how to change:
- Endpoint paths, field names, payload format (XML/JSON), ID location (body/headers/params)

## Beyond span attributes: Data Streams Monitoring

If the prospect uses async messaging (Kafka, SQS, RabbitMQ), see README.md "Beyond Span Attributes: Data Streams Monitoring Extension" for the architecture of a more advanced extension that implements Datadog DSM pathway tracking. This is a separate, significantly more complex extension (~1000+ lines, 5 components, requires DD Agent on localhost:8126). Full plan in `references/otel-dsm-extension-plan.md`.
