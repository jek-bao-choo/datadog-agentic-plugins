---
name: load-otel-java-ext
description: >-
  Load the OTel Java extension JAR into a running Spring Boot application and verify
  that custom business IDs appear as span attributes in Datadog traces. Uses -Dloader.path
  to add the extension to Spring Boot's classpath. Requires the app to use PropertiesLauncher
  (layout=ZIP in pom.xml).
version: 0.1.0
---

# Load OTel Java Extension

Load the XML attribute extractor extension into the Spring Boot app and verify custom span attributes appear in Datadog.

## Prerequisites

- Extension JAR built (from `create-otel-java-ext`) at `/opt/otel/extensions/otel-extension-xml-attributes-1.0.jar`
- Spring Boot app built with `<layout>ZIP</layout>` (from `setup-springboot3x`) — this enables `PropertiesLauncher` required for `-Dloader.path`
- OTel Java agent at `/opt/otel/opentelemetry-javaagent.jar` (from `springboot3x-otel-java`)
- OTel Collector running on `127.0.0.1:4318` (from `install-otelcol-contrib`)

## How to load

Add `-Dloader.path=/opt/otel/extensions/` to the startup command:

```bash
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dloader.path=/opt/otel/extensions/ \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 \
  ... (other flags)
  -jar target/springboot3x-0.0.1-SNAPSHOT.jar --server.port=8084
```

## Validation

In Datadog APM > Traces > click a `POST /jek-receive-xml` span:
- Span attributes should include `transaction_id`, `airway_bill_id`, `houseway_bill_id`

## Key lessons from battle-testing

- App JAR must use `PropertiesLauncher` (set `<layout>ZIP</layout>` in pom.xml) — otherwise `-Dloader.path` is silently ignored
- `NoClassDefFoundError: io/opentelemetry/api/trace/Span` → the extension JAR must shade the OTel API (see `create-otel-java-ext`)
