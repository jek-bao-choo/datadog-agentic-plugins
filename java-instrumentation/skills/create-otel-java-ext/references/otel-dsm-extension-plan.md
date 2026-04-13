# Implementation Plan: Datadog DSM & Business Transaction Tracking via OTel Java Agent Extension

## Background & Motivation
The objective is to implement Datadog's Data Streams Monitoring (DSM) and Business Transaction Tracking natively within a pure OpenTelemetry (OTel) Java environment. The customer wishes to use `opentelemetry-java-instrumentation` as their primary agent and bypass `dd-trace-java` entirely, while still leveraging the Datadog Agent's ability to forward DSM metrics to the Datadog backend.

Since pure OTel does not understand Datadog's proprietary pathway hashing, binary transaction packing, or the `/v0.1/pipeline_stats` payload, we must bridge this gap by reverse-engineering Datadog's DSM logic into an OpenTelemetry Agent Extension.

## Scope & Impact
We will create a standalone OpenTelemetry Java Agent Extension (`.jar`). When plugged into the `opentelemetry-javaagent.jar` via the `otel.javaagent.extensions` property, it will:
1. Extract and inject Datadog's proprietary `dd-pathway-ctx-base64` headers across service boundaries.
2. Intercept OTel messaging spans to calculate FNV-1a pathway hashes.
3. Batch Data Streams metrics and `transaction.id` attributes into time-windowed buckets.
4. Serialize the buckets into Datadog's proprietary MessagePack format.
5. Export the payload to the local Datadog Agent (`http://localhost:8126/v0.1/pipeline_stats`).

This allows the application code to remain clean and vendor-neutral (using standard OTel APIs and Span Attributes) while fully supporting Datadog's advanced tracking capabilities.

## Proposed Solution

### 1. Extension Initialization & SPI Registration
Create a standard OpenTelemetry Agent Extension project. Register the following SPIs (Service Provider Interfaces):
*   `ConfigurablePropagatorProvider`: To inject our custom Datadog Pathway Propagator.
*   `SpanProcessor`: To intercept spans and perform hashing and batching logic.

### 2. Context Propagation (`TextMapPropagator`)
Implement a custom `TextMapPropagator` that specifically handles the `dd-pathway-ctx-base64` header.
*   **Extract:** Decode the base64 string to extract the `parentHash`, `pathwayStartMillis`, and `edgeStartMillis` using VarInt / ZigZag decoding. Store this context in the OTel `Context`.
*   **Inject:** Encode the current pathway state into a base64 string and inject it into outgoing carrier headers (e.g., Kafka record headers or HTTP headers).

### 3. Span Interception & Hashing (`SpanProcessor`)
Implement a custom `SpanProcessor` that hooks into the `onStart` and `onEnd` methods.
*   When a span ends, check if it's a messaging span (e.g., has `messaging.destination.name`) or if it contains a `transaction.id` attribute.
*   If so, extract the `parentHash` from the current OTel Context.
*   Compute the `nodeHash` based on the checkpoint string (e.g., `type:kafka,direction:out,topic:orders`).
*   Compute the 64-bit FNV-1a `newHash` by combining `nodeHash` and `parentHash`.
*   **CRITICAL FOR CORRELATION:** You must attach the resulting `newHash` to the OTel span as the `pathway.hash` attribute. If a transaction ID is present, you must also attach the `dsm.transaction.id` and `dsm.transaction.checkpoint` attributes. Without these tags, the Datadog backend cannot link the APM trace to the Business Transaction.

### 4. Data Aggregation & Binary Packing
Implement an aggregator that mirrors Datadog's `DefaultDataStreamsMonitoring` and `StatsBucket`.
*   Create a background worker thread (`InboxProcessor`) with a non-blocking queue (e.g., JCTools MPSC queue) to receive stats asynchronously without blocking the application's transaction threads.
*   Aggregate incoming stats into 10-second buckets.
*   If a `transaction.id` is present, pack it into a `TransactionContainer` byte array: `[checkpointId (1 byte)] [timestamp (8 bytes)] [idLength (1 byte)] [transactionId bytes]`.

### 5. MessagePack Exporter
Implement an HTTP exporter that runs when a 10-second bucket closes.
*   Serialize the bucket data into Datadog's expected MessagePack schema using a library like `msgpack-core`.
*   Include the required metadata (`Env`, `Service`, `TracerVersion`).
*   POST the payload to the Datadog Agent at `http://localhost:8126/v0.1/pipeline_stats`.

## Alternatives Considered
*   **Hybrid Instrumentation (`dd-trace-java` as OTel Bridge):** Running the Datadog agent and configuring it to ingest OTel APIs is the vendor-recommended path. This was discarded to meet the strict requirement of using only `opentelemetry-java-instrumentation`.
*   **Custom OTel Collector Exporter:** Shifting this logic to the OTel Collector was investigated but rejected because the Collector does not receive the proprietary `dd-pathway-ctx-base64` context across boundaries without a custom propagator in the application anyway.

## Verification
1.  **Unit Tests:** Write tests for the `TextMapPropagator` to ensure base64 decoding/encoding matches the byte layout of `dd-trace-java`.
2.  **Mock Agent:** Stand up a local HTTP server mirroring the Datadog Agent's `/v0.1/pipeline_stats` endpoint to verify the generated MessagePack payload structure.
3.  **Integration Test:** Run a sample application with `opentelemetry-javaagent.jar` and our custom extension JAR, process a transaction with a `transaction.id` span attribute, and verify it appears correctly in the Datadog Data Streams UI.