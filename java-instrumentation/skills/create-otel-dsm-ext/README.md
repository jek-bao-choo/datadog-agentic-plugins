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

## Architecture — Detailed Diagrams

### 1. Big Picture: Where DSM fits in the observability stack

```
┌─────────────────────────────── Application JVM ──────────────────────────────┐
│                                                                               │
│  ┌─ OTel Java Agent (javaagent) ───────────────────────────────────────────┐ │
│  │                                                                          │ │
│  │  ┌─ DSM Extension (otel.javaagent.extensions) ───────────────────────┐  │ │
│  │  │  PathwayPropagator  ←→  DsmSpanProcessor  →  StatsAggregator     │  │ │
│  │  │                                                    ↓              │  │ │
│  │  │                                          PipelineStatsExporter    │  │ │
│  │  └──────────────────────────────────────────────────┬────────────────┘  │ │
│  │                                                      │                  │ │
│  │  ┌─ XML Attribute Extension (loader.path) ────────┐  │                  │ │
│  │  │  XmlAttributeExtractorFilter                    │  │                  │ │
│  │  │    → span attributes + dsm.transaction.id       │  │                  │ │
│  │  │    → HTTP response headers                      │  │                  │ │
│  │  └─────────────────────────────────────────────────┘  │                  │ │
│  │                                                       │                  │ │
│  │  Auto-instrumentation: Spring MVC, HTTP client,       │                  │ │
│  │  Logback, JVM metrics, Kafka, etc.                    │                  │ │
│  └───────────────────────────────────┬───────────────────┘                  │ │
│                                       │ OTLP (traces, metrics, logs)         │
│  Spring Boot Application (no changes) │                                      │
└───────────────────────────────────────┼──────────────────────────────────────┘
                                        │                           │
                            ┌───────────┘                           │ MessagePack+gzip
                            ↓                                       ↓
               ┌────────────────────────┐              ┌────────────────────────┐
               │   OTel Collector       │              │   Datadog Agent        │
               │   :4317/4318           │              │   :8126                │
               │                        │              │                        │
               │ datadog/connector      │              │ /v0.1/pipeline_stats   │
               │ datadog/exporter       │              │ (DSM stats endpoint)   │
               └────────┬───────────────┘              └────────┬───────────────┘
                        │                                       │
                        ↓                                       ↓
               ┌─────────────────────────────────────────────────────────────┐
               │                    Datadog Backend                          │
               │                                                             │
               │  APM > Traces     (spans with dsm.transaction.id)          │
               │  APM > Service Map (pathway.hash correlation)              │
               │  DSM > Transactions (dsm.transaction.id traces)            │
               │  DSM > Explore     (pathway latency — requires DDSketch)   │
               │  Infrastructure    (host metrics, JVM metrics)             │
               │  Logs              (correlated via trace_id)               │
               └─────────────────────────────────────────────────────────────┘
```

### 2. Extension Internals: Component interaction

```
┌─────────────── DSM Extension (loaded via -Dotel.javaagent.extensions) ──────────────┐
│                                                                                      │
│  ┌─────────────────────┐     ┌─────────────────────────────────────────────────┐    │
│  │ DsmExtensionProvider │────→│ Registers SpanProcessor + StatsAggregator       │    │
│  │ (SPI entry point)    │     │ via AutoConfigurationCustomizerProvider          │    │
│  └─────────────────────┘     └─────────────────────────────────────────────────┘    │
│                                                                                      │
│  ┌─── propagator/ ──────────────────────────────────────────────────────────────┐   │
│  │                                                                               │   │
│  │  DatadogPathwayPropagator (TextMapPropagator)                                │   │
│  │    extract(): dd-pathway-ctx-base64 header → PathwayContext in OTel Context  │   │
│  │    inject():  PathwayContext → dd-pathway-ctx-base64 header                  │   │
│  │                                                                               │   │
│  │  PathwayContext (immutable value object)                                      │   │
│  │    fields: hash, pathwayStartMillis, edgeStartMillis                         │   │
│  │                                                                               │   │
│  │  PathwayContextKey (OTel ContextKey)                                         │   │
│  └───────────────────────────────────────────────────────────────────────────────┘   │
│           ↑ extract                    ↓ inject                                      │
│           │                            │                                             │
│  ┌─── processor/ ────────────────────────────────────────────────────────────────┐  │
│  │                                                                                │  │
│  │  DsmSpanProcessor (SpanProcessor)                                             │  │
│  │    onStart(context, span):                                                     │  │
│  │      1. Check if PRODUCER/CONSUMER/SERVER span                                │  │
│  │      2. Get parentPathway from OTel Context (via PathwayContextKey)           │  │
│  │      3. Build checkpoint: "type:kafka,direction:out,topic:orders"             │  │
│  │      4. nodeHash = FnvHash.nodeHash(checkpoint)                               │  │
│  │      5. pathwayHash = FnvHash.pathwayHash(nodeHash, parentHash)              │  │
│  │      6. span.setAttribute("pathway.hash", pathwayHash)  ← CRITICAL          │  │
│  │      7. span.setAttribute("dsm.transaction.id", ...)                          │  │
│  │                                                                                │  │
│  │    onEnd(span):                                                                │  │
│  │      1. Read pathway.hash from span                                           │  │
│  │      2. Build StatsPoint (hash, parentHash, edgeTags, latencies)             │  │
│  │      3. aggregator.submit(statsPoint)  ← non-blocking                        │  │
│  └──────────────────────────────────┬─────────────────────────────────────────────┘  │
│                                      │ StatsPoint                                    │
│  ┌─── hash/ ───────────────────┐    │                                               │
│  │ FnvHash                      │    │                                               │
│  │   nodeHash(checkpoint)       │    ↓                                               │
│  │   pathwayHash(node, parent)  │  ┌─── stats/ ─────────────────────────────────┐   │
│  │                              │  │                                              │   │
│  │ VarIntCodec                  │  │  StatsAggregator (background daemon thread) │   │
│  │   encodeSignedVarLong()      │  │    inbox: ConcurrentLinkedQueue<StatsPoint> │   │
│  │   decodeSignedVarLong()      │  │    currentBucket: StatsBucket               │   │
│  └──────────────────────────────┘  │    flush() every 10 seconds:               │   │
│                                     │      drain inbox → bucket.add(point)       │   │
│                                     │      if bucket full → export + new bucket  │   │
│                                     │                                             │   │
│                                     │  StatsBucket (10-sec time window)           │   │
│                                     │    groups: Map<hash, StatsGroup>            │   │
│                                     │    transactionData: byte[] (packed)         │   │
│                                     │                                             │   │
│                                     │  StatsGroup (per-pathway aggregate)         │   │
│                                     │    hash, parentHash, edgeTags              │   │
│                                     │    pathwayLatency (count/sum/min/max)       │   │
│                                     │    edgeLatency (count/sum/min/max)          │   │
│                                     └──────────────────┬──────────────────────────┘   │
│                                                         │ List<StatsBucket>           │
│                                     ┌─── exporter/ ─────┼──────────────────────────┐  │
│                                     │                    ↓                          │  │
│                                     │  MsgPackSerializer                           │  │
│                                     │    serialize(buckets, env, service)           │  │
│                                     │    → MessagePack byte[]                      │  │
│                                     │                    ↓                          │  │
│                                     │  PipelineStatsExporter                       │  │
│                                     │    gzip(payload)                              │  │
│                                     │    HTTP POST → DD Agent :8126                │  │
│                                     │    /v0.1/pipeline_stats                      │  │
│                                     │    Content-Type: application/msgpack         │  │
│                                     │    Content-Encoding: gzip                    │  │
│                                     └──────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 3. Sequence Diagram: Single request lifecycle

```
Time ──→

 Client              OTel Agent           DSM Extension              Spring Boot App
   │                     │                      │                          │
   │── HTTP POST ───────→│                      │                          │
   │  (with header:      │                      │                          │
   │   transaction_id)   │                      │                          │
   │                     │                      │                          │
   │                     │── Create SERVER span │                          │
   │                     │   (span.start)       │                          │
   │                     │─────────────────────→│                          │
   │                     │                      │                          │
   │                     │                      │── onStart(context, span) │
   │                     │                      │   1. Check isMessagingSpan
   │                     │                      │   2. Get parentPathway    │
   │                     │                      │      from Context         │
   │                     │                      │   3. Build checkpoint:    │
   │                     │                      │      "type:http,          │
   │                     │                      │       direction:in,       │
   │                     │                      │       topic:/jek-receive-xml"
   │                     │                      │   4. nodeHash = FNV-1a(   │
   │                     │                      │        checkpoint)        │
   │                     │                      │   5. pathwayHash = FNV-1a(│
   │                     │                      │        nodeHash,parentHash)
   │                     │                      │   6. span.setAttribute(   │
   │                     │                      │        "pathway.hash",    │
   │                     │                      │        pathwayHash)       │
   │                     │                      │                          │
   │                     │────────── HTTP request to controller ──────────→│
   │                     │                      │                          │
   │                     │                      │  XmlAttributeExtractorFilter:
   │                     │                      │  ├─ Cache XML body        │
   │                     │                      │  ├─ chain.doFilter() ────→│
   │                     │                      │  │                        │── Process XML
   │                     │                      │  │                        │   Log IDs
   │                     │                      │  │                        │── Return XML
   │                     │                      │  │                    ←───│   response
   │                     │                      │  ├─ Parse cached body     │
   │                     │                      │  ├─ Span.current()        │
   │                     │                      │  │  .setAttribute(        │
   │                     │                      │  │   "transaction_id",    │
   │                     │                      │  │   "dsm.transaction.id",│
   │                     │                      │  │   "dsm.transaction.    │
   │                     │                      │  │    checkpoint")        │
   │                     │                      │  └─ Set response headers  │
   │                     │                      │     transaction_id: ...   │
   │                     │                      │                          │
   │←── HTTP Response ───│                      │                          │
   │  (with header:      │                      │                          │
   │   transaction_id)   │── span.end() ───────→│                          │
   │                     │                      │── onEnd(span)            │
   │                     │                      │   1. Read pathway.hash   │
   │                     │                      │   2. Build edgeTags      │
   │                     │                      │   3. Create StatsPoint   │
   │                     │                      │   4. aggregator.submit() │
   │                     │                      │      (non-blocking)      │
   │                     │                      │                          │
   │                     │                      │                          │
   │                     │           ┌──────────┼── [Background: every 10s]│
   │                     │           │          │   StatsAggregator.flush()│
   │                     │           │          │   1. Drain inbox         │
   │                     │           │          │   2. Aggregate into      │
   │                     │           │          │      StatsBucket         │
   │                     │           │          │   3. MsgPackSerializer   │
   │                     │           │          │      .serialize()        │
   │                     │           │          │   4. gzip(payload)       │
   │                     │           │          │   5. HTTP POST →         │
   │                     │           ↓          │      DD Agent :8126      │
   │                  DD Agent ←────────────────│      /v0.1/pipeline_stats│
   │                  (202 OK)                  │                          │
```

### 4. Cross-Service Pathway: Producer → Queue → Consumer

```
Service A (Producer)                Kafka                  Service B (Consumer)
┌─────────────────┐           ┌──────────┐           ┌─────────────────┐
│                 │           │          │           │                 │
│ OTel Agent      │           │  Topic:  │           │ OTel Agent      │
│ + DSM Extension │           │  orders  │           │ + DSM Extension │
│                 │           │          │           │                 │
│ 1. PRODUCER span│           │          │           │ 5. CONSUMER span│
│    created      │           │          │           │    created      │
│                 │           │          │           │                 │
│ 2. DsmSpanProc: │           │          │           │ 6. Propagator   │
│    checkpoint=  │           │          │           │    EXTRACTS     │
│    "type:kafka, │           │          │           │    dd-pathway-  │
│     direction:  │           │          │           │    ctx-base64   │
│     out,        │           │          │           │    from Kafka   │
│     topic:      │           │          │           │    record header│
│     orders"     │           │          │           │    → parentHash │
│    nodeHash=    │           │          │           │      =AABB...   │
│     FNV("type:  │           │          │           │                 │
│     kafka,...")  │           │          │           │ 7. DsmSpanProc: │
│    pathwayHash= │           │          │           │    checkpoint=  │
│     FNV(node,0) │           │          │           │    "type:kafka, │
│     =AABB...    │           │          │           │     direction:  │
│                 │           │          │           │     in,         │
│ 3. Propagator   │           │          │           │     topic:      │
│    INJECTS      │──────────→│ Record   │──────────→│     orders"    │
│    dd-pathway-  │  header:  │ headers: │  header:  │    nodeHash=   │
│    ctx-base64   │  AABB...  │ dd-path- │  AABB...  │     FNV("type: │
│    into Kafka   │  +VarInt  │ way-ctx- │  +VarInt  │     kafka,...") │
│    record header│  times    │ base64   │  times    │    pathwayHash=│
│                 │           │          │           │     FNV(node,  │
│ 4. StatsPoint   │           │          │           │     AABB...)   │
│    → aggregator │           │          │           │     =CCDD...   │
│                 │           │          │           │                 │
│                 │           │          │           │ 8. StatsPoint   │
│                 │           │          │           │    → aggregator │
└────────┬────────┘           └──────────┘           └────────┬────────┘
         │                                                     │
         ↓ every 10s                                          ↓ every 10s
┌─────────────────┐                                  ┌─────────────────┐
│ POST /v0.1/     │                                  │ POST /v0.1/     │
│ pipeline_stats  │                                  │ pipeline_stats  │
│ Hash: AABB...   │                                  │ Hash: CCDD...   │
│ ParentHash: 0   │                                  │ ParentHash:     │
│ EdgeTags:       │                                  │   AABB...       │
│  type:kafka     │                                  │ EdgeTags:       │
│  direction:out  │                                  │  type:kafka     │
│  topic:orders   │                                  │  direction:in   │
└────────┬────────┘                                  │  topic:orders   │
         │                                           └────────┬────────┘
         │                                                     │
         └──────────────────→ DD Agent ←───────────────────────┘
                                 │
                                 ↓
                          Datadog Backend
                          builds pathway:
                          Service A → orders → Service B
                          with latency at each edge
```

### 5. Data Formats

#### dd-pathway-ctx-base64 header

```
Raw bytes (before Base64):
┌──────────────────────┬─────────────────────────────┬──────────────────────────────┐
│ hash (8 bytes LE)    │ pathwayStartMillis (VarInt) │ edgeStartMillis (VarInt)     │
│ little-endian long   │ ZigZag + variable length    │ ZigZag + variable length     │
├──────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ BB AA 00 00 00 00    │ F4 E3 D2 C1 (example)      │ A8 B7 C6 (example)           │
│ 00 00                │                             │                              │
└──────────────────────┴─────────────────────────────┴──────────────────────────────┘
                                    │
                                    ↓ Base64 encode
                        "u6oAAAAAAATj0sHotwY=" (example)
                                    │
                                    ↓ Set as header
                        dd-pathway-ctx-base64: u6oAAAAAAATj0sHotwY=
```

#### FNV-1a pathway hash computation

```
Step 1: Build checkpoint string
  "type:kafka,direction:out,topic:orders"

Step 2: Compute nodeHash
  nodeHash = FNV-1a-64(bytes of checkpoint string)
           = 0x7A8B3C4D5E6F7081  (example)

Step 3: Combine with parentHash (16 bytes input)
  ┌─────────────────────────┬─────────────────────────┐
  │ nodeHash (8 bytes LE)   │ parentHash (8 bytes LE)  │
  │ 81 70 6F 5E 4D 3C 8B 7A│ 00 00 00 00 00 00 00 00 │ (root: parent=0)
  └─────────────────────────┴─────────────────────────┘

Step 4: pathwayHash = FNV-1a-64(16 bytes) = 0xAABBCCDDEEFF0011
```

#### MessagePack payload to /v0.1/pipeline_stats

```
{                                              ← gzip compressed
  "Env": "sandbox",                            ← from -Dotel.resource.attributes
  "Service": "jek-otel-java-springboot3x",     ← from -Dotel.service.name
  "Lang": "java",
  "TracerVersion": "otel-dsm-ext-1.0",
  "Version": "",
  "ProductMask": 2,                            ← 2 = DSM
  "Stats": [                                   ← array of 10-sec buckets
    {
      "Start": 1744516800000000000,            ← bucket start (nanos)
      "Duration": 10000000000,                 ← 10 seconds (nanos)
      "Stats": [                               ← array of StatsGroups
        {
          "Hash": 12345678901234567,           ← unsigned 64-bit (MsgPack uint64)
          "ParentHash": 0,                     ← unsigned 64-bit
          "EdgeTags": [                        ← checkpoint identifiers
            "type:kafka",
            "direction:out",
            "topic:orders"
          ],
          "PathwayLatency": <binary>,          ← DDSketch histogram (simplified)
          "EdgeLatency": <binary>              ← DDSketch histogram (simplified)
        }
      ],
      "Transactions": <binary>                 ← optional TransactionContainer
    }
  ]
}

TransactionContainer binary format (packed per transaction):
┌──────────────┬──────────────────┬──────────────┬──────────────────────────┐
│ checkpointId │ timestamp        │ idLength     │ transactionId            │
│ (1 byte)     │ (8 bytes)        │ (1 byte)     │ (N bytes UTF-8)          │
├──────────────┼──────────────────┼──────────────┼──────────────────────────┤
│ 0x00         │ 00 18 4A 3B ...  │ 0x0E         │ "TX-FIXED-001"           │
└──────────────┴──────────────────┴──────────────┴──────────────────────────┘
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
