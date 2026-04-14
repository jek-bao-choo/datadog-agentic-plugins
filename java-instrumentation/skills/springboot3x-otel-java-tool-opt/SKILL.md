---
name: springboot3x-otel-java-tool-opt
description: >-
  Auto-inject the OTel Java agent into any Java process via JAVA_TOOL_OPTIONS — the OTel
  equivalent of Dynatrace's LD_PRELOAD. No startup script changes needed. Downloads the
  agent JAR, sets system-wide env, and any JVM on the host picks it up automatically.
  Generic skill — works for any Java application (Spring Boot, Camel, webMethods, etc.).
  Battle-tested: "Picked up JAVA_TOOL_OPTIONS" confirmed on startup.
version: 0.1.0
version_matrix:
  otel_java_agent: ["2.26.1"]
---

# OTel Java Auto-Injection via JAVA_TOOL_OPTIONS

Inject the OTel Java agent into **any Java process** without modifying startup scripts or application code. This is the OTel equivalent of Dynatrace's LD_PRELOAD injection.

## How it works

```
JAVA_TOOL_OPTIONS env var (system-wide)
  → JVM reads on startup (built-in feature)
  → Prepends -javaagent:/opt/otel/opentelemetry-javaagent.jar
  → OTel agent loads, auto-instruments the app
  → Sends OTLP to local collector on 127.0.0.1:4318
```

No startup script changes. No `-javaagent` flag to add manually. No application code changes.

## Prerequisites

- OTel Collector running on 127.0.0.1:4318 (from `install-otelcol-contrib`)

## Quick Start

```bash
sudo ./scripts/setup-java-tool-options.sh
# Restart your Java app — it's now instrumented
```

## Full JAVA_TOOL_OPTIONS (battle-tested)

```
-javaagent:/opt/otel/opentelemetry-javaagent.jar
-Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar
-Dloader.path=/opt/otel/extensions/
-Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318
-Dotel.exporter.otlp.protocol=http/protobuf
-Dotel.logs.exporter=otlp
-Dotel.metrics.exporter=otlp
-Dotel.instrumentation.http.server.capture-request-headers=transaction_id
-Dotel.instrumentation.http.server.capture-response-headers=transaction_id
```

Extensions are optional — basic instrumentation works without them. Add when you need custom span attributes or DSM.

## Comparison: Dynatrace vs OTel vs Datadog

| Aspect | Dynatrace LD_PRELOAD | OTel JAVA_TOOL_OPTIONS | Datadog SSI |
|---|---|---|---|
| Mechanism | OS dynamic linker | JVM built-in env var | OS dynamic linker |
| Affects | ALL processes | Java only | ALL processes |
| Config file | `/etc/ld.so.preload` | `/etc/profile.d/` + `/etc/environment` | `/etc/ld.so.preload` |
| Startup changes | None | None | None |
| App code changes | None | None | None |
| Multi-language | Yes | No (Java only) | Yes |

## Battle-tested results

- `Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/...` confirmed on JVM startup
- `[otel.javaagent] opentelemetry-javaagent - version: 2.26.1` confirmed
- Distributed traces (C → D) visible in Datadog APM
- Use `127.0.0.1` not `localhost` in endpoint (IPv6 resolution issue)

## Key notes

- `otel.service.name` is NOT in JAVA_TOOL_OPTIONS — each app sets its own via `OTEL_SERVICE_NAME` env var or `spring.application.name`
- Works for any Java app: Spring Boot, Apache Camel, webMethods, Tomcat, etc.
- README.md covers: systemd overrides for service name (no app code access), adding/modifying properties, enterprise alternatives (Ansible, systemd drop-in, Docker)

## Teardown

```bash
sudo ./scripts/remove-java-tool-options.sh
# Restart apps to stop the agent
```
