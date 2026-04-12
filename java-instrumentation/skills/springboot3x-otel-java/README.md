# springboot3x-otel-java

Step-by-step guide to instrument a Spring Boot 3.x application with the [OpenTelemetry Java agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation) for zero-code auto-instrumentation. No application code changes needed — the agent is attached at JVM startup via `-javaagent`.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| OTel Java agent | v2.26.1 |
| Download URL | [opentelemetry-javaagent.jar](https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar) |
| Protocol | OTLP HTTP (http/protobuf) |
| Collector endpoint | http://localhost:4318 |
| Service name | jek-otel-java-springboot3x |
| Environment | sandbox |

## What gets auto-instrumented

| Library | What it captures |
|---|---|
| Spring MVC | Incoming HTTP request spans (method, path, status code) |
| RestTemplate / WebClient | Outgoing HTTP call spans (downstream service calls) |
| Logback | Log records exported via OTLP with automatic trace_id/span_id injection |
| JVM | Runtime metrics — heap usage, GC counts, thread counts |

## Prerequisites

- Spring Boot 3.x application built (from `setup-springboot3x` skill) — JAR at `/opt/cargostream/component-d/target/springboot3x-0.0.1-SNAPSHOT.jar`
- OTel Collector running on `localhost:4318` (from `install-otelcol-contrib` skill)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`

All commands below are run **on the EC2 instance** unless stated otherwise.

## Step 1: Pre-flight checks

Before starting, verify the two prerequisites are in place.

### 1a. Verify the Spring Boot app JAR exists

```bash
ls -lh /opt/cargostream/component-d/target/springboot3x-0.0.1-SNAPSHOT.jar
```

If the file doesn't exist, go back to the `setup-springboot3x` skill and complete Steps 1-2 (copy source, build with Maven).

### 1b. Verify the OTel Collector is running

```bash
curl -s http://localhost:13133/
```

Expected: `{"status":"Server available","upSince":"...","uptime":"..."}`

If the collector is not running, go back to the `install-otelcol-contrib` skill and start it.

## Step 2: Download the OTel Java agent

```bash
# Create directory if it doesn't exist
sudo mkdir -p /opt/otel
sudo chown ec2-user:ec2-user /opt/otel

# Download v2.26.1
curl -L -o /opt/otel/opentelemetry-javaagent.jar \
  https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar

# Verify download (should be ~24MB)
ls -lh /opt/otel/opentelemetry-javaagent.jar
```

## Step 3: Stop the application (if running without the agent)

If the app is currently running without the OTel agent, stop it first:

```bash
pkill -f springboot3x 2>/dev/null
echo "Stopped"
```

Wait 2 seconds for the process to terminate.

## Step 4: Run the application with the OTel Java agent

```bash
cd /opt/cargostream/component-d

java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://localhost:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar target/springboot3x-0.0.1-SNAPSHOT.jar --server.port=8084
```

### What each flag does

| Flag | Purpose |
|---|---|
| `-javaagent:/opt/otel/opentelemetry-javaagent.jar` | Attaches the OTel agent to the JVM — enables auto-instrumentation |
| `-Dotel.service.name=jek-otel-java-springboot3x` | Sets the service name shown in Datadog APM |
| `-Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0` | Adds environment and version tags |
| `-Dotel.exporter.otlp.endpoint=http://localhost:4318` | Sends telemetry to the local OTel Collector |
| `-Dotel.exporter.otlp.protocol=http/protobuf` | Uses HTTP protobuf (not gRPC) |
| `-Dotel.logs.exporter=otlp` | Exports Logback log records via OTLP |
| `-Dotel.metrics.exporter=otlp` | Exports JVM runtime metrics via OTLP |

### What to expect on startup

You should see two key lines in the output:

```
[otel.javaagent] opentelemetry-javaagent - version: 2.26.1
Started Springboot3xApplication in X.XX seconds
```

The first line confirms the agent loaded. The second confirms the app started. Wait for both before proceeding.

To run in the background (so you can continue in the same terminal):

```bash
nohup java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://localhost:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar target/springboot3x-0.0.1-SNAPSHOT.jar --server.port=8084 \
  > /tmp/component-d.log 2>&1 &

# Wait for startup (takes ~10-12 seconds)
sleep 12

# Verify it started
curl -s http://localhost:8084/health
```

## Step 5: Send test requests

### 5a. Health check

```bash
curl -s http://localhost:8084/health
```

Expected:
```json
{"status":"healthy","port":8084,"service":"jek-otel-java-springboot3x"}
```

### 5b. Send a single XML payload

```bash
curl -X POST http://localhost:8084/jek-receive-xml \
  -H "Content-Type: application/xml" \
  -d '<shipment>
    <transaction_id>test-tx-otel</transaction_id>
    <airway_bill_id>test-awb-otel</airway_bill_id>
    <houseway_bill_id>test-hwb-otel</houseway_bill_id>
    <timestamp>2026-04-12T10:00:00Z</timestamp>
    <source>otel-test</source>
  </shipment>'
```

Expected: XML response with `<status>received</status>`.

## Step 6: Generate traffic (10 requests over 90 seconds)

To ensure traces are visible in Datadog even with sampling enabled, send 10 requests with 10-second intervals. This spreads traces over ~90 seconds for a clear distribution.

### Option A: Using the bundled script

From your local machine:

```bash
scp -i ~/.ssh/jek_rsa_pem scripts/send-traffic.sh ec2-user@<EC2_PUBLIC_IP>:/tmp/send-traffic.sh
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> 'chmod +x /tmp/send-traffic.sh && /tmp/send-traffic.sh'
```

### Option B: Manual loop on the EC2 instance

```bash
for i in $(seq 1 10); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8084/jek-receive-xml \
    -H "Content-Type: application/xml" \
    -d "<shipment><transaction_id>tx-traffic-${i}</transaction_id><airway_bill_id>awb-traffic-${i}</airway_bill_id><houseway_bill_id>hwb-traffic-${i}</houseway_bill_id><timestamp>$(date -u +%Y-%m-%dT%H:%M:%SZ)</timestamp><source>traffic-gen</source></shipment>")
  echo "[$(date -u +%H:%M:%S)] Request ${i}/10: HTTP ${CODE}"
  [ "${i}" -lt 10 ] && sleep 10
done
```

You should see ~1 out of 10 return HTTP 500 (10% fault injection).

## Step 7: Verify in Datadog (wait 1-2 minutes after traffic)

### 7a. Traces

Go to **APM > Traces**. Search for `service:jek-otel-java-springboot3x`.

You should see:
- Spans for `POST /jek-receive-xml` and `GET /health`
- Host: `jek-ec2-centos9`
- Environment: `sandbox`
- Error spans (red) from the 10% fault injection
- Traces distributed over ~90 seconds

### 7b. Logs with trace correlation

Go to **Logs**. Search for `service:jek-otel-java-springboot3x`.

You should see:
- Application log entries (`Received shipment`, `FAULT INJECTION`)
- Each log has `trace_id` and `span_id` fields — click to jump to the correlated trace

### 7c. JVM runtime metrics

Go to **Infrastructure > Host Map**. Click on `jek-ec2-centos9`.

Under the **Metrics** tab, you should see JVM metrics:
- `jvm.memory.used`, `jvm.memory.committed`
- `jvm.gc.duration`
- `jvm.thread.count`

## How trace-to-log correlation works

Trace-to-log correlation allows you to click from a trace in Datadog APM directly to its correlated logs, and vice versa. Here's how it's achieved in this setup:

### The three pieces that make it work

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────┐
│ OTel Java Agent  │ ──→ │  OTel Collector   │ ──→ │   Datadog    │
│ (auto-injects    │     │  (forwards logs   │     │  (correlates │
│  trace_id into   │     │   with trace_id   │     │   trace_id   │
│  Logback MDC)    │     │   to Datadog)     │     │   across UI) │
└──────────────────┘     └──────────────────┘     └──────────────┘
```

**1. OTel Java agent injects trace context into Logback MDC (automatic)**

When the OTel Java agent (`-javaagent`) is attached, it automatically instruments Logback. For every log statement emitted during an active trace, the agent injects `trace_id` and `span_id` into the Logback MDC (Mapped Diagnostic Context). No code changes or Logback configuration changes needed — this happens transparently.

**2. OTel Java agent exports logs via OTLP (requires `-Dotel.logs.exporter=otlp`)**

The flag `-Dotel.logs.exporter=otlp` enables the agent's log bridge. This bridges Logback log records into the OTel SDK and exports them via OTLP to the collector. Each exported log record carries:
- `trace_id` — the trace this log belongs to
- `span_id` — the specific span within the trace
- `severity` — mapped from Logback level (INFO, WARN, ERROR)
- `body` — the log message
- `resource.service.name` — set by `-Dotel.service.name`

Without this flag, logs are only written to console/file and NOT exported via OTLP.

**3. Datadog receives both traces and logs with matching trace_id**

When Datadog receives a trace and a log with the same `trace_id`, it links them. In the UI:
- From **APM > Traces**: click the **Logs** tab on any trace to see correlated logs
- From **Logs**: click the `trace_id` field to jump to the correlated trace

### Configuration summary

| What | Where | Required? |
|---|---|---|
| `-javaagent:/opt/otel/opentelemetry-javaagent.jar` | JVM startup flag | Yes — enables auto-instrumentation including Logback MDC injection |
| `-Dotel.logs.exporter=otlp` | JVM startup flag | Yes — enables OTLP log export (disabled by default) |
| `-Dotel.service.name=jek-otel-java-springboot3x` | JVM startup flag | Yes — ensures logs and traces share the same service name |
| OTel Collector logs pipeline | `config.yaml` service.pipelines.logs | Yes — must have a logs pipeline that receives OTLP and exports to Datadog |
| Logback configuration changes | `logback-spring.xml` | **No** — the agent handles MDC injection automatically |
| Application code changes | Java source | **No** — zero code changes needed |

### What if logs appear but have no trace_id?

This means the log was emitted outside of an active trace context (e.g., during application startup, or from a background thread not associated with an HTTP request). Only logs emitted during an active span will have `trace_id` and `span_id` injected.

## Troubleshooting

| Issue | Fix |
|---|---|
| No `[otel.javaagent]` line on startup | Check the agent JAR path: `ls /opt/otel/opentelemetry-javaagent.jar` |
| No traces in Datadog | Check OTel Collector is running: `curl localhost:13133` |
| No logs in Datadog | Ensure `-Dotel.logs.exporter=otlp` is set |
| Traces show but no log correlation | Logback auto-instrumentation requires the OTel agent — ensure `-javaagent` flag is present |
| Port 8084 already in use | Kill the existing process: `pkill -f springboot3x` |

## Teardown

```bash
# Stop the application
pkill -f springboot3x 2>/dev/null
```

To remove the agent: `rm /opt/otel/opentelemetry-javaagent.jar`
