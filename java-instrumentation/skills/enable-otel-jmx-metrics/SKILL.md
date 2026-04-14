---
name: enable-otel-jmx-metrics
description: >-
  Enable generic JMX metrics collection via the OTel Java agent. Covers predefined
  target systems (tomcat, camel, jetty, kafka, etc.) and custom YAML configs for
  scraping any MBean. Requires -Dspring.jmx.enabled=true and
  -Dserver.tomcat.mbeanregistry.enabled=true for Spring Boot 3.x (MBean registration
  is disabled by default). Battle-tested: 9 Tomcat metrics confirmed in Datadog.
version: 0.1.0
version_matrix:
  otel_java_agent: ["2.26.1"]
  springboot_version: ["3.4.5"]
  camel_version: ["4.10.3"]
---

# Enable Generic JMX Metrics via OTel Java Agent

Collect framework-specific MBean metrics (Tomcat thread pools, Apache Camel routes, Jetty connections, Kafka consumer lag) beyond the standard JVM runtime metrics already collected by the OTel agent.

## How it works

```
JVM MBeanServer (framework registers MBeans at startup)
  → OTel Java agent's JMX metric insight module
  → Scrapes MBean attributes every 10 seconds
  → Batches with other metrics, exports via OTLP every 60 seconds
  → OTel Collector → Datadog Metrics Explorer
```

## Critical: Spring Boot 3.x MBean registration

Spring Boot 3.x disables JMX MBean registration by default. Without these flags, the OTel JMX scraper has nothing to scrape and **zero metrics appear**:

```
-Dspring.jmx.enabled=true
-Dserver.tomcat.mbeanregistry.enabled=true
```

## JAVA_TOOL_OPTIONS additions (battle-tested)

```
-Dotel.jmx.target.system=tomcat,camel,jetty
-Dotel.jmx.config=/opt/otel/camel-jmx-metrics.yaml
-Dspring.jmx.enabled=true
-Dserver.tomcat.mbeanregistry.enabled=true
```

## Option 1: Predefined target systems

```bash
-Dotel.jmx.target.system=tomcat,camel,jetty
```

Available targets: `activemq`, `camel`, `jetty`, `kafka-broker`, `kafka-consumer`, `kafka-producer`, `tomcat`, `wildfly`

## Option 2: Custom YAML config

```bash
-Dotel.jmx.config=/opt/otel/camel-jmx-metrics.yaml
```

See `references/camel-jmx-metrics.yaml` for a ready-to-deploy Camel example.

## Prerequisites

- OTel Java agent already injected via `JAVA_TOOL_OPTIONS` (from `springboot3x-otel-java-tool-opt`)
- OTel Collector running on 127.0.0.1:4318 (from `install-otelcol-contrib`)

## Quick start

```bash
sudo ./scripts/enable-jmx-metrics.sh
# Restart your Java app — JMX metrics now flow to Datadog
```

## Battle-tested results

| Metric Name | Type | Status |
|---|---|---|
| `tomcat.thread.busy.count` | UpDownCounter | Confirmed in Datadog |
| `tomcat.thread.count` | UpDownCounter | Confirmed in Datadog |
| `tomcat.thread.limit` | UpDownCounter | Confirmed in Datadog |
| `tomcat.request.count` | Counter | Confirmed in Datadog |
| `tomcat.error.count` | Counter | Confirmed in Datadog |
| `tomcat.request.duration.max` | Gauge | Confirmed in Datadog |
| `tomcat.request.duration.sum` | Counter | Confirmed in Datadog |
| `tomcat.network.io` | Counter | Confirmed in Datadog |
| `tomcat.session.active.count` | UpDownCounter | Confirmed in Datadog |

Metric names are preserved as-is in Datadog — no `jmx.` or `otel.` prefix. Search `tomcat` in Metrics Summary.

## Battle-tested pitfalls

| Pitfall | Error | Fix |
|---|---|---|
| Spring Boot 3.x MBeans disabled | Zero metrics in Datadog | Add `-Dspring.jmx.enabled=true -Dserver.tomcat.mbeanregistry.enabled=true` |
| Custom YAML uses `bean` (singular) | Silent parse failure, no metrics | Use `beans` (plural, as YAML list) |
| Custom YAML missing `unit` field | `IllegalArgumentException: Metric unit is required` | Add `unit` to every metric (`ms`, `{exchange}`, etc.) |
| Check Datadog too early | No metrics yet | OTel agent exports metrics every 60s, not 10s. Wait 2 minutes. |

## Teardown

```bash
sudo ./scripts/disable-jmx-metrics.sh
# Restart apps to stop JMX metric collection
```
