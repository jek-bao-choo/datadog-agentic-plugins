---
name: springboot2x-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a Spring Boot 2.x application with
  Datadog APM. Triggers on mentions of Java 8 APM, Spring Boot 2 tracing, dd-java-agent
  with Java 8, or legacy Spring Boot Datadog instrumentation.
version: 0.1.0
version_matrix:
  java_version: [8]
  springboot_version: [2.7.5]
---

# Spring Boot 2.7.5 + Java 8 — Datadog APM Instrumentation

Instrument a deployed Spring Boot 2.7.5 application with Datadog APM using the Java tracer.

## Prerequisites

- Skill `setup-springboot2x` has been completed successfully
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
  -Ddd.service=springboot2x-app \
  -Ddd.env=sandbox \
  -Ddd.agent.host=localhost \
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

In the Datadog UI: **APM > Services** — look for `springboot2x-app` with `env:sandbox`.

## Troubleshooting

### Tracer not attaching (no DATADOG TRACER CONFIGURATION in logs)
**Cause:** `-javaagent` flag not before `-jar` in the command.
**Fix:** Ensure `-javaagent:dd-java-agent.jar` comes before `-jar`.

### Java 8 compatibility issues
**Cause:** Tracer version too new for Java 8.
**Fix:** The latest dd-java-agent.jar supports Java 8. Verify with `java -version`.
