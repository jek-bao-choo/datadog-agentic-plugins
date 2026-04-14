---
name: springboot3x-otel-java-tool-opt
description: >-
  Auto-inject the OTel Java agent into any Java process via JAVA_TOOL_OPTIONS — the OTel
  equivalent of Dynatrace's LD_PRELOAD. No startup script changes needed. Downloads the
  agent JAR, sets system-wide env, and any JVM on the host picks it up automatically.
  Generic skill — works for any Java application (Spring Boot, Camel, webMethods, etc.).
version: 0.1.0
version_matrix:
  otel_java_agent: ["2.26.1"]
---

# OTel Java Auto-Injection via JAVA_TOOL_OPTIONS

Inject the OTel Java agent into **any Java process** without modifying startup scripts. This is the OTel equivalent of Dynatrace's LD_PRELOAD injection.

## How it works

```
JAVA_TOOL_OPTIONS env var (system-wide)
  → JVM reads on startup (built-in feature)
  → Prepends -javaagent:/opt/otel/opentelemetry-javaagent.jar
  → OTel agent loads, auto-instruments the app
  → Sends OTLP to local collector on 127.0.0.1:4318
```

No startup script changes. No `-javaagent` flag to add manually.

## Prerequisites

- OTel Collector running on 127.0.0.1:4318 (from `install-otelcol-contrib`)

## Quick Start

```bash
sudo ./scripts/setup-java-tool-options.sh
# Restart your Java app — it's now instrumented
```

## Comparison: Dynatrace vs OTel vs Datadog

| Aspect | Dynatrace LD_PRELOAD | OTel JAVA_TOOL_OPTIONS | Datadog SSI |
|---|---|---|---|
| Mechanism | OS dynamic linker | JVM built-in env var | OS dynamic linker |
| Affects | ALL processes | Java only | ALL processes |
| Config file | `/etc/ld.so.preload` | `/etc/profile.d/` | `/etc/ld.so.preload` |
| Startup changes | None | None | None |
| Multi-language | Yes | No (Java only) | Yes |

## Teardown

```bash
sudo ./scripts/remove-java-tool-options.sh
# Restart apps to stop the agent
```
