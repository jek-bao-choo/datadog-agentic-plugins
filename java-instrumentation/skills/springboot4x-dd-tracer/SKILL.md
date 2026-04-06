---
name: springboot4x-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a Spring Boot 4.x application with
  Datadog APM. Triggers on mentions of Java 21 APM, Spring Boot 4 tracing, dd-java-agent
  with Java 21, or latest Spring Boot Datadog instrumentation with custom tags.
version: 0.1.0
version_matrix:
  java_version: [21]
  springboot_version: [4.0.2]
---

# Spring Boot 4.0.2 + Java 21 — Datadog APM Instrumentation

Instrument a deployed Spring Boot 4.0.2 application with Datadog APM using the Java tracer, including payload-to-custom-tags mapping.

## Prerequisites

- Skill `setup-springboot4x` has been completed successfully
- Datadog Agent running
- Datadog API key configured

## Instructions

### 1. Download the Datadog Java tracer

```bash
wget -O dd-java-agent.jar https://dtdg.co/latest-java-tracer
```

### 2. Run with the tracer attached

```bash
java -javaagent:dd-java-agent.jar \
  -Ddd.service=springboot4x-app \
  -Ddd.env=sandbox \
  -Ddd.agent.host=localhost \
  -Ddd.trace.sample.rate=1 \
  -jar target/*.jar
```

### 3. Generate traffic

```bash
for i in $(seq 1 20); do
  curl -s http://localhost:8080/api/data > /dev/null
  curl -s -X POST http://localhost:8080/api/submit -H "Content-Type: application/json" -d '{"key":"test"}' > /dev/null
done
```

## Validation

In the Datadog UI:
- **APM > Services** — look for `springboot4x-app` with `env:sandbox`
- **APM > Traces** — verify custom tags from payload appear on spans

## Troubleshooting

### Custom tags not appearing on traces
**Cause:** Payload-to-custom-tag mapping not configured.
**Fix:** Verify the application's tag extraction logic is working and the Datadog tracer is intercepting the spans.
