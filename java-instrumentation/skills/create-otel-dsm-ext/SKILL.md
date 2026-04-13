---
name: create-otel-dsm-ext
description: >-
  Create an OTel Java Agent Extension that implements Datadog Data Streams Monitoring (DSM).
  Computes FNV-1a pathway hashes, propagates dd-pathway-ctx-base64 headers across service
  boundaries, aggregates stats in 10-second buckets, and exports MessagePack payloads to
  the Datadog Agent /v0.1/pipeline_stats. Enables DSM in a pure OTel environment without
  dd-trace-java. Requires Datadog Agent on localhost:8126.
version: 0.1.0
---

# Create OTel DSM Extension — Datadog Data Streams Monitoring

Build an OTel Java Agent Extension that enables Datadog DSM in a pure OTel environment. Tracks end-to-end latency across async messaging services (Kafka, SQS, RabbitMQ) without using dd-trace-java.

## Architecture

```
App JVM (OTel Agent + DSM Extension)
  ├── PathwayPropagator (inject/extract dd-pathway-ctx-base64)
  ├── DsmSpanProcessor (FNV-1a hashing on messaging spans)
  ├── StatsAggregator (10-sec buckets, background thread)
  └── PipelineStatsExporter (MessagePack → DD Agent :8126/v0.1/pipeline_stats)
```

## Prerequisites

- Java 17, Maven 3.6.3+
- Datadog Agent running on localhost:8126

## Build

```bash
cd references/
mvn clean package
# Produces target/otel-dsm-extension-1.0.jar
```

## Load

```bash
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar \
  -Ddsm.agent.url=http://localhost:8126 \
  -Dotel.service.name=my-service \
  -jar my-app.jar
```

## Components (10 Java classes)

| Class | Purpose |
|---|---|
| `DsmExtensionProvider` | SPI entry point — registers SpanProcessor + StatsAggregator |
| `DatadogPathwayPropagator` | TextMapPropagator for dd-pathway-ctx-base64 |
| `PathwayContext` | Stores hash, pathwayStartMillis, edgeStartMillis |
| `FnvHash` | FNV-1a 64-bit hash (nodeHash + parentHash → pathwayHash) |
| `VarIntCodec` | VarInt/ZigZag encode/decode for binary header |
| `DsmSpanProcessor` | Intercepts messaging spans, computes hashes, emits stats |
| `StatsAggregator` | Background thread, 10-sec time-windowed buckets |
| `StatsBucket` | Container for a single time window |
| `StatsGroup` | Per-pathway aggregate (latency stats) |
| `MsgPackSerializer` | Serializes buckets into DD's MessagePack format |
| `PipelineStatsExporter` | HTTP POST to DD Agent /v0.1/pipeline_stats |

## Status

**Scaffolding / Alpha** — core components implemented with simplified latency histograms (counters instead of DDSketch). Production use requires:
- DDSketch histogram implementation for PathwayLatency/EdgeLatency
- Full PathwayContext propagation through OTel Context across threads
- Loop detection (closestOppositeDirectionHash)
- Schema registry support
