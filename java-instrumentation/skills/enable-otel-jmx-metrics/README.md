# enable-otel-jmx-metrics

Step-by-step guide to enable **generic JMX metrics** collection via the OTel Java agent. This goes beyond the standard JVM runtime metrics (`jvm.memory.used`, `jvm.gc.duration`, etc.) that are already collected — it scrapes framework-specific MBean attributes like Tomcat thread pool sizes, Apache Camel route stats, and Jetty connections.

Battle-tested on CentOS Stream 9 EC2 with OTel Java agent v2.26.1, Spring Boot 3.4.5, and Apache Camel 4.10.3. **9 Tomcat JMX metrics confirmed in Datadog Metrics Summary.**

---

## Background: What are generic JMX metrics?

Java applications and frameworks register **MBeans** (Managed Beans) with the JVM's MBeanServer. These MBeans expose operational data:

- **Tomcat**: thread pool size (busy/max), request count, error count, session count, network I/O
- **Apache Camel**: exchanges completed/failed per route, processing time, in-flight count
- **Jetty**: thread pool, idle threads, queue size, select calls
- **Kafka clients**: consumer lag, producer throughput, partition assignment
- **webMethods IS**: flow service invocation count, errors, average execution time

The OTel Java agent can scrape these MBeans and export them as metrics via OTLP — **no application code changes needed**.

### Runtime metrics vs generic JMX metrics

| Aspect | Runtime Metrics (jvm.*) | Generic JMX Metrics |
|---|---|---|
| What they are | Standardized JVM metrics: memory, GC, threads, CPU | Any MBean attribute from application frameworks |
| Enabled by | `-Dotel.metrics.exporter=otlp` (already on) | `-Dotel.jmx.target.system=...` (this skill) |
| Already collected? | **Yes** — flowing to Datadog now | **No** — must be explicitly enabled |

### Available predefined targets

The OTel Java agent has built-in scrapers for these frameworks:

| Target | What it scrapes |
|---|---|
| `tomcat` | Thread pool (busy/max), request count, error count, sessions, network I/O |
| `camel` | Route exchanges completed/failed, context uptime |
| `jetty` | Thread pool, idle threads, queue size, select calls |
| `kafka-broker` | Partition count, under-replicated, ISR shrinks |
| `kafka-consumer` | Records consumed, lag, fetch rate |
| `kafka-producer` | Records sent, byte rate, request latency |
| `activemq` | Queue size, enqueue/dequeue count, consumer count |
| `wildfly` | Data source pool, transactions, undertow requests |

### Tech Stack

| Component | Version |
|---|---|
| OTel Java agent | v2.26.1 |
| Spring Boot | 3.4.5 |
| Apache Camel | 4.10.3 (Component C) |
| JMX scrape interval | 10 seconds |
| Metric export interval | 60 seconds (batched with all other metrics) |

---

## How it works: two things are required

Getting JMX metrics into Datadog requires **two things**, both configured via `JAVA_TOOL_OPTIONS` flags:

```
┌─────────────────────────────────────────────────────────────────┐
│  Step A: EXPOSE the MBeans (make them visible in the JVM)       │
│                                                                 │
│  Spring Boot 3.x disables MBean registration by default.       │
│  You must re-enable it:                                         │
│    -Dspring.jmx.enabled=true                                    │
│    -Dserver.tomcat.mbeanregistry.enabled=true                   │
│                                                                 │
│  Without this → MBeanServer is empty → nothing to scrape        │
├─────────────────────────────────────────────────────────────────┤
│  Step B: ENABLE the OTel agent to scrape them                   │
│                                                                 │
│  Tell the agent which frameworks to collect metrics from:       │
│    -Dotel.jmx.target.system=tomcat,camel,jetty                  │
│                                                                 │
│  Without this → agent ignores MBeans → no JMX metrics exported  │
└─────────────────────────────────────────────────────────────────┘
```

Both are added to `JAVA_TOOL_OPTIONS` in a single command (Step 1 below).

---

## Prerequisites

- OTel Java agent already injected via `JAVA_TOOL_OPTIONS` (from `springboot3x-otel-java-tool-opt` skill)
- OTel Collector running on `127.0.0.1:4318` (from `install-otelcol-contrib` skill)
- SSH access to the EC2 instance

**All commands below are run on the EC2 instance:**

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
```

---

## Step 1: Add JMX flags to JAVA_TOOL_OPTIONS

This single command adds both the **MBean exposure flags** and the **JMX scraping flag** to `JAVA_TOOL_OPTIONS`.

Run this command to **replace** your existing `/etc/profile.d/otel-java.sh`:

```bash
sudo tee /etc/profile.d/otel-java.sh > /dev/null <<'EOF'
export JAVA_TOOL_OPTIONS="\
-javaagent:/opt/otel/opentelemetry-javaagent.jar \
-Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar \
-Dloader.path=/opt/otel/extensions/ \
-Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 \
-Dotel.exporter.otlp.protocol=http/protobuf \
-Dotel.logs.exporter=otlp \
-Dotel.metrics.exporter=otlp \
-Dotel.instrumentation.http.server.capture-request-headers=transaction_id \
-Dotel.instrumentation.http.server.capture-response-headers=transaction_id \
-Dotel.jmx.target.system=tomcat,camel,jetty \
-Dspring.jmx.enabled=true \
-Dserver.tomcat.mbeanregistry.enabled=true"
EOF
```

Then load it in the current session:

```bash
source /etc/profile.d/otel-java.sh
```

Verify it was set correctly:

```bash
echo $JAVA_TOOL_OPTIONS | tr ' ' '\n'
```

You should see each flag on its own line, including these three new ones:

```
-Dotel.jmx.target.system=tomcat,camel,jetty
-Dspring.jmx.enabled=true
-Dserver.tomcat.mbeanregistry.enabled=true
```

### What each new flag does

| Flag | Phase | Purpose |
|---|---|---|
| `-Dspring.jmx.enabled=true` | **Expose MBeans** | Re-enables Spring's JMX MBean exporter. Spring Boot 3.x disables this by default. Without it, no Spring or Camel MBeans are registered in the JVM |
| `-Dserver.tomcat.mbeanregistry.enabled=true` | **Expose MBeans** | Re-enables Tomcat's Catalina MBean registration (`ThreadPool`, `GlobalRequestProcessor`, etc.). Without it, no Tomcat MBeans are registered |
| `-Dotel.jmx.target.system=tomcat,camel,jetty` | **Enable scraping** | Tells the OTel Java agent to scrape MBeans for Tomcat, Camel, and Jetty using built-in predefined YAML configs |

> **Why do you need BOTH expose AND enable?** The OTel JMX scraper queries the JVM's MBeanServer. If the MBeans are not registered (expose step missing), the scraper has nothing to scrape. If the scraper is not told to look (enable step missing), it ignores the MBeans. **Both must be present.** Missing the expose step was the #1 issue we hit during battle-testing — zero metrics appeared in Datadog until we added `-Dspring.jmx.enabled=true`.

---

## Step 2 (optional): Deploy custom YAML for deeper Camel metrics

The predefined `camel` target covers basic metrics. For deeper visibility — per-route processing times, in-flight exchanges, min/max latencies — deploy a custom YAML config.

**Skip this step if you only need Tomcat metrics.**

### 2a. Create the YAML file

```bash
sudo tee /opt/otel/camel-jmx-metrics.yaml > /dev/null <<'EOF'
rules:
  - beans:
      - org.apache.camel:context=*,type=routes,name=*
    metricAttribute:
      camel.context: param(context)
      camel.route: param(name)
    mapping:
      ExchangesCompleted:
        metric: camel.route.exchanges.completed
        type: counter
        unit: "{exchange}"
        desc: Total completed exchanges on this route
      ExchangesFailed:
        metric: camel.route.exchanges.failed
        type: counter
        unit: "{exchange}"
        desc: Total failed exchanges on this route
      ExchangesInflight:
        metric: camel.route.exchanges.inflight
        type: gauge
        unit: "{exchange}"
        desc: Currently in-flight exchanges on this route
      MeanProcessingTime:
        metric: camel.route.processing_time.mean
        type: gauge
        unit: ms
        desc: Mean processing time per exchange
      MaxProcessingTime:
        metric: camel.route.processing_time.max
        type: gauge
        unit: ms
        desc: Maximum processing time observed
      MinProcessingTime:
        metric: camel.route.processing_time.min
        type: gauge
        unit: ms
        desc: Minimum processing time observed

  - beans:
      - org.apache.camel:context=*,type=context,name=*
    metricAttribute:
      camel.context: param(name)
    mapping:
      ExchangesTotal:
        metric: camel.context.exchanges.total
        type: counter
        unit: "{exchange}"
        desc: Total exchanges across all routes
      ExchangesFailed:
        metric: camel.context.exchanges.failed
        type: counter
        unit: "{exchange}"
        desc: Total failed exchanges across all routes
      UptimeMillis:
        metric: camel.context.uptime
        type: gauge
        unit: ms
        desc: Camel context uptime in milliseconds
EOF
```

### 2b. Add the custom YAML flag to JAVA_TOOL_OPTIONS

Re-run the Step 1 command but add this line before the closing quote:

```
-Dotel.jmx.config=/opt/otel/camel-jmx-metrics.yaml \
```

Then re-source:

```bash
source /etc/profile.d/otel-java.sh
```

### Custom YAML format rules (battle-tested)

| Rule | Wrong | Correct |
|---|---|---|
| Key name | `bean:` (singular) | `beans:` (plural, as YAML list) |
| Unit field | omitted | `unit: ms` or `unit: "{exchange}"` — **mandatory** |
| Bean syntax | `bean: org.apache...` | `beans:` then `- org.apache...` on next line |

---

## Step 3: Restart the Java application

`JAVA_TOOL_OPTIONS` is read by the JVM **only at startup**. You must restart.

```bash
# Stop Component C
pkill -f springboot3x-camel 2>/dev/null
sleep 3

# Re-source to ensure JAVA_TOOL_OPTIONS is set in this shell
source /etc/profile.d/otel-java.sh

# Start Component C
cd /opt/cargostream/component-c
nohup java -jar target/springboot3x-camel-0.0.1-SNAPSHOT.jar > /tmp/component-c.log 2>&1 &
```

Wait 30 seconds for the app to start, then verify:

```bash
sleep 30
curl -sf http://localhost:8083/actuator/health
```

Expected output:

```json
{"status":"UP"}
```

---

## Step 4: Verify JMX metrics are being scraped

### 4a. Check that JAVA_TOOL_OPTIONS was picked up

```bash
head -1 /tmp/component-c.log
```

You should see:

```
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/... -Dotel.jmx.target.system=tomcat,camel,jetty -Dspring.jmx.enabled=true -Dserver.tomcat.mbeanregistry.enabled=true
```

### 4b. Check that JMX metrics were registered

```bash
grep 'MetricRegistrar.*Created' /tmp/component-c.log
```

You should see lines like:

```
[jmx_bean_finder] INFO ... - Created Counter for tomcat.error.count
[jmx_bean_finder] INFO ... - Created Counter for tomcat.request.count
[jmx_bean_finder] INFO ... - Created Gauge for tomcat.request.duration.max
[jmx_bean_finder] INFO ... - Created Counter for tomcat.request.duration.sum
[jmx_bean_finder] INFO ... - Created Counter for tomcat.network.io
[jmx_bean_finder] INFO ... - Created UpDownCounter for tomcat.session.active.count
[jmx_bean_finder] INFO ... - Created UpDownCounter for tomcat.thread.busy.count
[jmx_bean_finder] INFO ... - Created UpDownCounter for tomcat.thread.count
[jmx_bean_finder] INFO ... - Created UpDownCounter for tomcat.thread.limit
```

**If you see these lines, JMX metrics are being scraped.** Proceed to Step 5.

**If you don't see any `MetricRegistrar` lines**, the MBeans are not registered. Double-check that `-Dspring.jmx.enabled=true` and `-Dserver.tomcat.mbeanregistry.enabled=true` appear in the `Picked up JAVA_TOOL_OPTIONS` line from Step 4a.

---

## Step 5: Send test traffic

```bash
for i in $(seq 1 5); do
  curl -sf -o /dev/null -w "Request $i: HTTP %{http_code}\n" \
    -X POST http://localhost:8083/jek-process \
    -H "Content-Type: application/json" \
    -H "transaction_id: TX-JMX-${i}" \
    -d "{\"transaction_id\": \"TX-JMX-${i}\", \"airway_bill_id\": \"AWB-JMX-${i}\"}"
  sleep 3
done
```

Expected output (some may return 500 due to fault injection):

```
Request 1: HTTP 200
Request 2: HTTP 200
Request 3: HTTP 200
Request 4: HTTP 200
Request 5: HTTP 200
```

---

## Step 6: Verify in Datadog

**Wait 2 minutes** after restart before checking. The OTel agent exports metrics every 60 seconds.

### 6a. Open Datadog Metrics Summary

Go to **Metrics > Summary** in Datadog.

### 6b. Search for `tomcat`

Type `tomcat` in the search box. You should see **9 metrics**:

| Metric Name | Type | What it measures |
|---|---|---|
| `tomcat.thread.busy.count` | UpDownCounter | Busy threads in the Tomcat thread pool |
| `tomcat.thread.count` | UpDownCounter | Total threads in the Tomcat thread pool |
| `tomcat.thread.limit` | UpDownCounter | Max threads in the Tomcat thread pool |
| `tomcat.request.count` | Counter | Total HTTP requests processed |
| `tomcat.error.count` | Counter | Total HTTP errors |
| `tomcat.request.duration.max` | Gauge | Longest request processing time (seconds) |
| `tomcat.request.duration.sum` | Counter | Total request processing time (seconds) |
| `tomcat.network.io` | Counter | Bytes transmitted |
| `tomcat.session.active.count` | UpDownCounter | Currently active HTTP sessions |

All 9 metrics confirmed in Datadog Metrics Summary on 2026-04-14.

### 6c. Important: metric naming in Datadog

- Metric names are preserved **as-is** — there is no `jmx.` or `otel.` prefix
- Search `tomcat` directly — not `jmx.tomcat`
- Dots are preserved (not converted to underscores)

### 6d. Jetty and Camel metrics

- **Jetty metrics** (`jetty.thread.count`, etc.) only appear if the application uses Jetty as its embedded server. Spring Boot defaults to Tomcat, so Jetty metrics won't appear unless you switch.
- **Camel metrics** (`camel.context.exchange.completed`, etc.) require Camel MBeans to be registered. If they don't appear after enabling `spring.jmx.enabled=true`, try adding `-Dcamel.springboot.jmx-enabled=true` to `JAVA_TOOL_OPTIONS`.

---

## Writing custom YAML for other frameworks

### webMethods Integration Server example

IBM webMethods IS exposes JMX MBeans for flow service execution. A custom YAML would look like:

```yaml
# webmethods-jmx-metrics.yaml (example — MBean names vary by version)
rules:
  - beans:
      - com.softwareag.is:type=FlowService,name=*
    metricAttribute:
      webmethods.flow_service: param(name)
    mapping:
      InvocationCount:
        metric: webmethods.flow_service.invocations
        type: counter
        unit: "{invocation}"
        desc: Total flow service invocations
      ErrorCount:
        metric: webmethods.flow_service.errors
        type: counter
        unit: "{error}"
        desc: Total flow service errors
      AverageResponseTime:
        metric: webmethods.flow_service.response_time.avg
        type: gauge
        unit: ms
        desc: Average response time

  - beans:
      - com.softwareag.is:type=ThreadPool,name=*
    metricAttribute:
      webmethods.thread_pool: param(name)
    mapping:
      ActiveThreads:
        metric: webmethods.thread_pool.active
        type: gauge
        unit: "{thread}"
        desc: Active threads in the pool
      MaxThreads:
        metric: webmethods.thread_pool.max
        type: gauge
        unit: "{thread}"
        desc: Maximum threads in the pool
```

To find the actual MBean names for your application, use JConsole:

```bash
jcmd <PID> ManagementAgent.start
jconsole <PID>
```

---

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Zero JMX metrics in Datadog | Spring Boot 3.x disables MBean registration by default | Add `-Dspring.jmx.enabled=true -Dserver.tomcat.mbeanregistry.enabled=true` to JAVA_TOOL_OPTIONS |
| No `Created Counter for tomcat.*` in startup log | MBeans not registered or flags not in JAVA_TOOL_OPTIONS | Run `head -1 /tmp/component-c.log` and verify all flags are present |
| Custom YAML: `Error while loading JMX configuration` | Used `bean` (singular) instead of `beans` (plural) | Change to `beans:` with list syntax (`- org.apache...`) |
| Custom YAML: `Metric unit is required` | Missing `unit` field in metric definition | Add `unit:` to every metric (e.g., `ms`, `"{exchange}"`, `"{thread}"`) |
| Metrics not in Datadog after 1 minute | OTel agent exports metrics every 60 seconds | Wait 2 minutes after restart, then check Metrics Summary |
| Searching `jmx.tomcat` returns nothing | No `jmx.` prefix — metric names are preserved as-is | Search `tomcat` directly |
| Camel metrics not appearing | Camel JMX may be disabled | Add `-Dcamel.springboot.jmx-enabled=true` to JAVA_TOOL_OPTIONS |
| Jetty metrics not appearing | App uses embedded Tomcat, not Jetty | Jetty metrics only appear for Jetty-based apps |

---

## About the bundled scripts

### What is `enable-jmx-metrics.sh`?

This script automates Steps 1 and 2:

1. Copies `camel-jmx-metrics.yaml` to `/opt/otel/`
2. Adds JMX flags + MBean registration flags to existing `JAVA_TOOL_OPTIONS` in both `/etc/profile.d/otel-java.sh` and `/etc/environment`
3. Sources the updated profile in the current session

```bash
sudo ./scripts/enable-jmx-metrics.sh
# Then restart your Java app (Step 3)
```

### What is `disable-jmx-metrics.sh`?

This script reverses everything:

1. Removes the JMX and MBean registration flags from `JAVA_TOOL_OPTIONS` in both files
2. Deletes `/opt/otel/camel-jmx-metrics.yaml`

```bash
sudo ./scripts/disable-jmx-metrics.sh
# Then restart your Java app to stop JMX metric collection
```

---

## Teardown

### Option A: Use the script

```bash
sudo ./scripts/disable-jmx-metrics.sh

# Restart the app
pkill -f springboot3x-camel 2>/dev/null
sleep 3
source /etc/profile.d/otel-java.sh
cd /opt/cargostream/component-c
nohup java -jar target/springboot3x-camel-0.0.1-SNAPSHOT.jar > /tmp/component-c.log 2>&1 &
```

### Option B: Manual removal

```bash
# 1. Edit /etc/profile.d/otel-java.sh — remove the JMX and MBean flags
sudo vi /etc/profile.d/otel-java.sh

# 2. Edit /etc/environment — remove the same flags
sudo vi /etc/environment

# 3. Delete the custom YAML (if deployed)
sudo rm -f /opt/otel/camel-jmx-metrics.yaml

# 4. Reload and restart
source /etc/profile.d/otel-java.sh
pkill -f springboot3x-camel 2>/dev/null
sleep 3
cd /opt/cargostream/component-c
nohup java -jar target/springboot3x-camel-0.0.1-SNAPSHOT.jar > /tmp/component-c.log 2>&1 &
```
