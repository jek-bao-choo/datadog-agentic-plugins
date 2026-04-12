---
name: springboot3x-otel-java
description: >-
  Instrument a running Spring Boot 3.x application with the OpenTelemetry Java agent for
  auto-instrumentation. No code changes needed — attach the javaagent at JVM startup.
  Auto-instruments Spring MVC, RestTemplate, Logback, and JVM runtime metrics. Exports
  traces, metrics, and logs via OTLP to a local OTel Collector.
version: 0.1.0
version_matrix:
  otel_java_agent: ["2.26.1"]
  java_version: [17]
  springboot_version: [3.4.5]
---

# OTel Java Auto-Instrumentation for Spring Boot 3.x

Instrument a Spring Boot 3.x application with the [OpenTelemetry Java agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation) for zero-code distributed tracing. The agent auto-instruments Spring MVC, HTTP clients, Logback, and JVM metrics.

## Prerequisites

- Spring Boot 3.x application running (from `setup-springboot3x` skill)
- OTel Collector running on `localhost:4318` (from `install-otelcol-contrib` skill)

## Tech Stack

| Component | Version |
|---|---|
| OTel Java agent | v2.26.1 |
| Download | [opentelemetry-javaagent.jar](https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar) |
| Protocol | OTLP HTTP (http/protobuf) to localhost:4318 |
| Service name | jek-otel-java-springboot3x |

## What gets auto-instrumented

- Spring MVC (incoming HTTP request spans)
- RestTemplate / WebClient (outgoing HTTP call spans)
- Logback (log records exported via OTLP with trace correlation)
- JVM runtime metrics (heap, GC, threads)

## Instructions

See README.md for full step-by-step guide.

## Quick Start

```bash
# Download the agent
curl -L -o /opt/otel/opentelemetry-javaagent.jar \
  https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar

# Run the app with the agent attached
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://localhost:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar target/springboot3x-0.0.1-SNAPSHOT.jar --server.port=8084
```

## Traffic Generation

Send 10 requests with 10-second intervals to ensure traces are visible even with sampling:

```bash
# Using the bundled script
./scripts/send-traffic.sh
```

Or SCP to EC2 and run remotely. See README.md Step 6 for details.

## Validation

After generating traffic, verify in Datadog (wait 1-2 minutes):

- Datadog APM > Traces: `service:jek-otel-java-springboot3x` — 10 traces over ~90s, ~10% error rate
- Datadog Logs: `service:jek-otel-java-springboot3x` — log entries with trace_id correlation
- Datadog Infrastructure > Host Map: `jek-ec2-centos9` — JVM runtime metrics (heap, GC, threads)
