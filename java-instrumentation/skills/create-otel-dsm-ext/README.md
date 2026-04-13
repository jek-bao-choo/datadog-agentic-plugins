# create-otel-dsm-ext

OTel Java Agent Extension that implements Datadog Data Streams Monitoring (DSM) in a pure OpenTelemetry environment. Enables pathway tracking and business transaction correlation across async messaging services without using `dd-trace-java`.

## How it works

```
Service A (Producer)                        Service B (Consumer)
  ├── OTel Agent creates PRODUCER span       ├── OTel Agent creates CONSUMER span
  ├── DsmSpanProcessor:                      ├── PathwayPropagator:
  │   ├── Builds checkpoint string           │   └── Extracts dd-pathway-ctx-base64
  │   │   "type:kafka,direction:out,         │       from Kafka record header
  │   │    topic:orders"                     │       → parentHash, pathwayStart, edgeStart
  │   ├── Computes nodeHash (FNV-1a)         │
  │   ├── Computes pathwayHash               ├── DsmSpanProcessor:
  │   │   = FNV-1a(nodeHash + parentHash)    │   ├── Computes new pathwayHash
  │   ├── Sets span: pathway.hash            │   ├── Sets span: pathway.hash
  │   └── Emits StatsPoint to aggregator     │   └── Emits StatsPoint to aggregator
  │                                          │
  ├── PathwayPropagator:                     └── StatsAggregator → PipelineStatsExporter
  │   └── Injects dd-pathway-ctx-base64           → DD Agent :8126/v0.1/pipeline_stats
  │       into Kafka record header                → Datadog DSM UI
  │
  └── StatsAggregator → PipelineStatsExporter
        → DD Agent :8126/v0.1/pipeline_stats
        → Datadog DSM UI
```

## Tech Stack

| Component | Version |
|---|---|
| Java | 17 |
| OTel SDK | 1.48.0 (provided by agent) |
| msgpack-core | 0.9.8 (shaded into JAR) |
| Target | Datadog Agent :8126 |

## Prerequisites

- Java 17 and Maven on the build machine
- Datadog Agent running on `localhost:8126` (or configured via `-Ddsm.agent.url`)

## Step 1: Copy source to build machine

```bash
scp -i ~/.ssh/jek_rsa_pem -r references/* ec2-user@<EC2_PUBLIC_IP>:/opt/otel/dsm-ext-src/
```

## Step 2: Build

```bash
cd /opt/otel/dsm-ext-src
mvn clean package
```

Produces `target/otel-dsm-extension-1.0.jar`.

## Step 3: Deploy

```bash
cp target/otel-dsm-extension-1.0.jar /opt/otel/extensions/
```

## Step 4: Load with the OTel Java agent

```bash
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar \
  -Ddsm.agent.url=http://localhost:8126 \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -jar my-app.jar
```

On startup you should see:
```
[otel-dsm] Initializing Datadog DSM extension
[otel-dsm]   Agent URL: http://localhost:8126
[otel-dsm]   Service: jek-otel-java-springboot3x
[otel-dsm]   Env: sandbox
```

## Components

| Package | Class | OTel Interface | Responsibility |
|---|---|---|---|
| root | `DsmExtensionProvider` | `AutoConfigurationCustomizerProvider` | SPI entry — wires everything together |
| propagator | `DatadogPathwayPropagator` | `TextMapPropagator` | Encode/decode `dd-pathway-ctx-base64` header (8-byte LE hash + VarInt timestamps) |
| propagator | `PathwayContext` | — | Immutable container: hash, pathwayStartMillis, edgeStartMillis |
| propagator | `PathwayContextKey` | `ContextKey` | OTel Context key for storing PathwayContext |
| hash | `FnvHash` | — | FNV-1a 64-bit: nodeHash from checkpoint string, pathwayHash from node+parent |
| hash | `VarIntCodec` | — | ZigZag + VarInt encode/decode for binary header timestamps |
| processor | `DsmSpanProcessor` | `SpanProcessor` | Intercepts PRODUCER/CONSUMER spans, computes hashes, sets `pathway.hash` attribute, emits StatsPoint |
| stats | `StatsAggregator` | — | Background thread, 10-sec buckets, ConcurrentLinkedQueue inbox |
| stats | `StatsBucket` | — | Time-windowed container with StatsGroups + TransactionContainer |
| stats | `StatsGroup` | — | Per-pathway latency aggregation (simplified counters) |
| stats | `StatsPoint` | — | Single checkpoint data point from SpanProcessor |
| exporter | `MsgPackSerializer` | — | Serializes stats into Datadog's MessagePack schema |
| exporter | `PipelineStatsExporter` | — | HTTP POST to DD Agent /v0.1/pipeline_stats |

## dd-pathway-ctx-base64 binary format

```
Byte layout: [hash: 8 bytes LE] [pathwayStartMillis: signed VarInt] [edgeStartMillis: signed VarInt]
             └── Base64 encoded ──────────────────────────────────────────────────────────────────────┘
```

## FNV-1a pathway hash computation

```
1. Build checkpoint string: "type:kafka,direction:out,topic:orders"
2. nodeHash = FNV-1a(checkpoint bytes)
3. pathwayHash = FNV-1a( writeLongLE(nodeHash) + writeLongLE(parentHash) )  // 16 bytes input
```

## MessagePack payload schema

```
{
  "Env": "sandbox",
  "Service": "jek-otel-java-springboot3x",
  "Lang": "java",
  "TracerVersion": "otel-dsm-ext-1.0",
  "ProductMask": 2,
  "Stats": [{
    "Start": 1234567890000000000,
    "Duration": 10000000000,
    "Stats": [{
      "Hash": 12345678901234,
      "ParentHash": 0,
      "EdgeTags": ["type:kafka", "direction:out", "topic:orders"],
      "PathwayLatency": <binary histogram>,
      "EdgeLatency": <binary histogram>
    }],
    "Transactions": <binary> (optional)
  }]
}
```

## Battle-tested results

| What | Status |
|---|---|
| Extension loads via `-Dotel.javaagent.extensions` | Working |
| FNV-1a pathway hashing | Working |
| StatsAggregator (10-sec buckets) | Working |
| MessagePack + gzip export to DD Agent :8126 | Working (202 Accepted) |
| DSM Transaction Tracking traces (`dsm.transaction.id`) | **Working** — visible in Datadog DSM Traces section |
| DSM Summary metrics (Transactions By Status, Success Rate, Latency) | **Not working** — see below |
| DSM Breached Transactions | **Not working** — see below |

### Why Summary metrics and Breached Transactions don't populate

The traces section works because `dsm.transaction.id` and `dsm.transaction.checkpoint` are standard span attributes that Datadog APM indexes. However, the DSM Summary metrics (Transactions By Status, Success Rate, Latency) and Breached Transactions require the Datadog backend to correlate pipeline_stats pathway data with the Transaction Tracking pipeline definition. This correlation fails because:

1. **Simplified histograms**: Our PathwayLatency and EdgeLatency fields use placeholder byte arrays (4 longs: count/sum/min/max) instead of Datadog's proprietary DDSketch format. The backend expects DDSketch-serialized histograms to compute percentile distributions.

2. **Single-service testing**: The DSM pipeline was tested with both Start and End steps on the same service (HTTP request/response on `jek-otel-java-springboot3x`). DSM is designed for multi-service async pathways (Service A → Kafka → Service B), where each checkpoint has a distinct hash that the backend links into a pathway graph.

3. **Testing mode (SERVER spans)**: The SpanProcessor was modified to accept SERVER spans for testing. In production, it should only process PRODUCER/CONSUMER spans from messaging libraries (Kafka, SQS, RabbitMQ), which the OTel agent instruments with `messaging.destination.name` attributes.

4. **Split telemetry path**: APM traces flow through OTel Collector → Datadog exporter, but DSM pipeline_stats go directly to the DD Agent trace-agent on :8126. The DD Agent trace-agent logs "No data received" because it never sees the APM traces (they bypass it). For full DSM correlation, the trace-agent needs to see both the DSM stats AND the APM traces. This would require either: (a) sending traces to the DD Agent as well (dual export), or (b) sending DSM stats through the OTel Collector instead of the DD Agent.

### What would make Summary metrics work

- **Unify telemetry path** — Either: (a) also send APM traces to the DD Agent via `/v0.4/traces` so the trace-agent can correlate DSM stats with traces, or (b) find a way to send DSM stats through the OTel Collector (not currently supported)
- **Implement DDSketch histograms** — Replace the simplified counter format with `com.datadoghq:sketches-java:0.8.3` DDSketch serialization matching `dd-trace-java`'s histogram format
- **Multi-service pipeline** — Deploy Components A→B→C→D, each with the DSM extension, where messages flow through an actual Kafka/SQS queue
- **Real PRODUCER/CONSUMER spans** — Disable TESTING_MODE in DsmSpanProcessor so it only processes messaging spans with proper checkpoint strings
- **Proper dd-pathway-ctx-base64 propagation** — The propagator must inject/extract the pathway context via Kafka record headers across service boundaries

## Known limitations (Alpha)

| Limitation | Impact | Fix |
|---|---|---|
| Simplified latency histograms | DD backend can't compute latency distributions → Summary metrics empty | Implement DDSketch serialization |
| TESTING_MODE processes SERVER spans | Not realistic for messaging-based DSM | Set `TESTING_MODE = false` for production |
| PathwayContext not propagated through async threads | Missing pathway continuity in async frameworks | Add Context propagation via OTel Context.current() |
| No loop detection | Cardinality explosion on bidirectional messaging | Implement closestOppositeDirectionHash |
| No schema registry support | Missing schema tracking | Add SchemaBuilder integration |
| Single-service pipeline | No multi-hop pathway graph | Deploy full A→B→C→D chain with messaging |

## Reference implementation

- [dd-trace-java datastreams/](https://github.com/DataDog/dd-trace-java/tree/master/dd-trace-core/src/main/java/datadog/trace/core/datastreams) — 13 Java classes
- [otel-dsm-extension-plan.md](references/otel-dsm-extension-plan.md) — full design document
