---
name: create-otel-dsm-ext
description: >-
  Create an OTel Java Agent Extension that implements Datadog Data Streams Monitoring (DSM).
  Two modes: (1) OTel Collector only (default) — sets dsm.transaction.id span attributes for
  DSM Traces, no DD Agent needed. (2) Full export (dsm.export.enabled=true) — also computes
  FNV-1a pathway hashes, aggregates stats in 10-second buckets, exports MessagePack+gzip to
  DD Agent /v0.1/pipeline_stats. Enables DSM in a pure OTel environment without dd-trace-java.
version: 0.1.0
---

# Create OTel DSM Extension — Datadog Data Streams Monitoring

Build an OTel Java Agent Extension that enables Datadog DSM in a pure OTel environment. Tracks business transactions and pathway hashes across async messaging services (Kafka, SQS, RabbitMQ) without using dd-trace-java.

## Architecture

```
App JVM (OTel Agent + DSM Extension)
  ├── DsmSpanProcessor (FNV-1a hashing, sets pathway.hash + dsm.transaction.id on spans)
  ├── PathwayPropagator (inject/extract dd-pathway-ctx-base64)
  ├── StatsAggregator (10-sec buckets — only when dsm.export.enabled=true)
  └── PipelineStatsExporter (MessagePack+gzip → DD Agent — only when enabled)
```

## Prerequisites

- Java 17, Maven 3.6.3+
- OTel Collector on 127.0.0.1:4318 (from `install-otelcol-contrib`)
- Datadog Agent on localhost:8126 — **optional** (only if `dsm.export.enabled=true`)

## Build

```bash
cd references/
mvn clean package
# Produces target/otel-dsm-extension-1.0.jar (~149KB)
```

## Load

### Mode 1: OTel Collector only (default — no DD Agent needed)

```bash
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar \
  -Dotel.service.name=my-service \
  -jar my-app.jar
```

Sets `pathway.hash`, `dsm.transaction.id`, `dsm.transaction.checkpoint` on spans. DSM Traces work via OTel Collector → Datadog.

### Mode 2: Full DSM export (requires DD Agent)

```bash
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar \
  -Ddsm.export.enabled=true \
  -Ddsm.agent.url=http://localhost:8126 \
  -Dotel.service.name=my-service \
  -jar my-app.jar
```

## Components (11 Java classes)

| Class | Purpose |
|---|---|
| `DsmExtensionProvider` | SPI entry point — registers SpanProcessor, configures mode |
| `DatadogPathwayPropagator` | TextMapPropagator for dd-pathway-ctx-base64 |
| `PathwayContext` | Stores hash, pathwayStartMillis, edgeStartMillis |
| `PathwayContextKey` | OTel Context key for PathwayContext |
| `FnvHash` | FNV-1a 64-bit hash (nodeHash + parentHash → pathwayHash) |
| `VarIntCodec` | VarInt/ZigZag encode/decode for binary header |
| `DsmSpanProcessor` | Intercepts spans, computes hashes, sets dsm.transaction.id |
| `StatsAggregator` | Background thread (when enabled), 10-sec buckets |
| `StatsBucket` | Container for a single time window |
| `StatsGroup` | Per-pathway aggregate (latency stats) |
| `StatsPoint` | Single data point from SpanProcessor |
| `MsgPackSerializer` | Serializes buckets into DD's MessagePack format |
| `PipelineStatsExporter` | HTTP POST + gzip to DD Agent /v0.1/pipeline_stats |

## Battle-tested results

| What | Status |
|---|---|
| DSM Traces in Datadog (`dsm.transaction.id`) | **Working** — visible in DSM Transactions > Traces |
| `pathway.hash` span attribute | **Working** |
| MessagePack+gzip export to DD Agent | **Working** (202 Accepted) |
| DSM Summary metrics (Transactions By Status, Latency) | **Not working** — requires DDSketch histograms + multi-service pipeline |

## Status

**Alpha** — DSM Traces work end-to-end with OTel Collector only. Simplified latency histograms (counters instead of DDSketch). Production use requires:
- DDSketch histogram implementation (`com.datadoghq:sketches-java:0.8.3`)
- Full PathwayContext propagation through OTel Context across threads
- Loop detection (closestOppositeDirectionHash)
- Real multi-service messaging pipeline (Kafka/SQS)
