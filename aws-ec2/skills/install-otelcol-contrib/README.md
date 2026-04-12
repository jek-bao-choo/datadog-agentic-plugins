# install-otelcol-contrib

Step-by-step guide to install the OpenTelemetry Collector Contrib on CentOS Stream 9 as a systemd service. This replaces the Datadog Agent entirely — all telemetry (traces, metrics, logs, host metrics) flows through the OTel Collector to Datadog.

Two exporter options are available. Choose one in Step 3.

## Architecture

### Option B: Datadog Exporter — Comprehensive

The [Datadog Connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/datadogconnector) computes APM stats (latency distributions, error rates, requests/s) from traces *before* export. These stats power the APM service page, service map edge metrics, and latency histograms. The `datadog/exporter` handles all 3 signals through a single exporter, manages metrics temporality automatically, and provides built-in `sending_queue` for durable batching.

```
┌───────────────────────── OTel Collector Contrib ─────────────────────────────┐
│                                                                              │
│  Extensions: health_check (:13133) | file_storage | datadog (Fleet Mgmt)    │
│                                                                              │
│  TRACES ─────────────────────────────────────────────────────────────────    │
│  otlp (:4317/4318) ──→ resourcedetection ──→ datadog/connector ─┐           │
│                                                                   │ traces   │
│                                              ┌────────────────────┘           │
│                                              ↓                               │
│                                  datadog/exporter ──────→ Datadog APM        │
│                                  debug                                       │
│                                              │ APM stats (metrics)           │
│  METRICS ────────────────────────────────────┼───────────────────────────    │
│  otlp (:4317/4318) ──┐                      ↓                               │
│  hostmetrics ─────────┼→ resourcedetection ──→ datadog/exporter ──→ Datadog  │
│  datadog/connector ───┘                                            Metrics   │
│                                                                              │
│  LOGS ───────────────────────────────────────────────────────────────────    │
│  otlp (:4317/4318) ──┐                                                      │
│  filelog/system ──────┼→ resourcedetection ──→ datadog/exporter ──→ Datadog  │
│                       ┘                                            Logs      │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Option A: OTLP HTTP Exporter — Comprehensive

Sends standard OTLP to Datadog's ingest endpoints (`otlp.datadoghq.com`) — vendor-neutral with no Datadog-specific components in the export path. Uses 3 separate named exporters (one per signal) with signal-specific headers. Requires `cumulativetodelta` processor because Datadog OTLP ingest only accepts delta metrics. No connector needed — Datadog's OTLP ingest computes APM stats server-side.

```
┌───────────────────────── OTel Collector Contrib ─────────────────────────────┐
│                                                                              │
│  Extensions: health_check (:13133) | file_storage | datadog (Fleet Mgmt)    │
│                                                                              │
│  TRACES ─────────────────────────────────────────────────────────────────    │
│  otlp (:4317/4318) ──→ resourcedetection ──→ otlphttp/dd_traces ──→ Datadog │
│                                              debug                   APM     │
│                                                                              │
│  METRICS ────────────────────────────────────────────────────────────────    │
│  otlp (:4317/4318) ──┐                                                      │
│  hostmetrics ─────────┼→ resourcedetection ──→ cumulativetodelta             │
│                       ┘          ──→ otlphttp/dd_metrics ──→ Datadog Metrics │
│                                                                              │
│  LOGS ───────────────────────────────────────────────────────────────────    │
│  otlp (:4317/4318) ──┐                                                      │
│  filelog/system ──────┼→ resourcedetection ──→ otlphttp/dd_logs ──→ Datadog  │
│                       ┘                                            Logs      │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Key differences

| Aspect | Datadog Exporter (Option B) | OTLP HTTP Exporter (Option A) |
|---|---|---|
| APM stats | Computed locally by `datadog/connector` before export | Computed server-side by Datadog OTLP ingest |
| Metrics temporality | Handled automatically by exporter | Requires `cumulativetodelta` processor |
| Exporters | 1 exporter for all signals | 3 separate exporters (traces, metrics, logs) |
| Batching | Built-in `sending_queue` | Standard OTLP HTTP batching |
| Vendor neutrality | Datadog-specific components | Standard OTLP protocol only |
| Hostname/tags | Set in exporter + extension | Set in extension only |

Both options share the same receivers (`otlp`, `hostmetrics`, `filelog/system`), the `resourcedetection` processor, and the `datadog` extension for Fleet Automation.

### Simplified view — Datadog Exporter (Option B)

```
TRACES:   otlp ──→ resourcedetection ──→ datadog/connector ──→ datadog/exporter ──→ Datadog
METRICS:  otlp + hostmetrics + connector stats ──→ resourcedetection ──→ datadog/exporter ──→ Datadog
LOGS:     otlp + filelog ──→ resourcedetection ──→ datadog/exporter ──→ Datadog
```

### Simplified view — OTLP HTTP Exporter (Option A)

```
TRACES:   otlp ──→ resourcedetection ──→ otlphttp/dd_traces ──→ Datadog
METRICS:  otlp + hostmetrics ──→ resourcedetection ──→ cumulativetodelta ──→ otlphttp/dd_metrics ──→ Datadog
LOGS:     otlp + filelog ──→ resourcedetection ──→ otlphttp/dd_logs ──→ Datadog
```

## Prerequisites

Before starting, make sure you have:

- An EC2 instance running CentOS Stream 9 (from `setup-ec2-centos9` skill)
- SSH access to the instance: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`
- Your Datadog API key (DD_API_KEY) for datadoghq.com (US1)

## Step 1: SSH into the EC2 instance

```bash
ssh-add ~/.ssh/jek_rsa_pem
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
```

All commands from Step 2 onwards are run **on the EC2 instance** unless stated otherwise.

## Step 2: Download and install otelcol-contrib

```bash
# Download the RPM package (v0.149.0)
curl -L -o /tmp/otelcol-contrib.rpm \
  https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.149.0/otelcol-contrib_0.149.0_linux_amd64.rpm

# Install it
sudo rpm -Uvh /tmp/otelcol-contrib.rpm

# Clean up the downloaded file
rm -f /tmp/otelcol-contrib.rpm
```

This installs:
- Binary at `/usr/bin/otelcol-contrib`
- Systemd service `otelcol-contrib.service`
- Config directory at `/etc/otelcol-contrib/`
- Runs as user `otelcol-contrib`

## Step 3: Choose your exporter and deploy the config

There are two ways to export telemetry to Datadog. Pick **one**.

### Which option should I choose?

| Feature | Option A: OTLP HTTP Exporter | Option B: Datadog Exporter |
|---|---|---|
| Protocol | Standard OTLP — vendor-neutral | Datadog-native |
| Vendor lock-in | None | Datadog-specific component |
| Service map | Yes (via OTLP ingest) | Yes (full-fidelity) |
| Host metadata/tags | Via Datadog extension | Built-in `host_metadata` + extension |
| Metrics temporality | Needs `cumulativetodelta` processor | Handled automatically |
| Batching | Standard OTLP HTTP batching | Built-in `sending_queue` ([why no batch processor?](https://github.com/open-telemetry/opentelemetry.io/pull/9088)) |
| Config complexity | 3 named exporters (one per signal) | 1 exporter |
| Docs | [OTLP Ingest](https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/) | [Datadog Exporter](https://docs.datadoghq.com/opentelemetry/setup/collector/) |

---

### Option A: OTLP HTTP Exporter (vendor-neutral)

Sends traces, metrics, and logs to Datadog's OTLP ingest endpoints using the standard `otlphttp` exporter. No Datadog-specific exporter component needed.

References:
- Traces: `https://otlp.datadoghq.com/v1/traces` ([source](https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/))
- Metrics: `https://otlp.datadoghq.com/v1/metrics` ([source](https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/metrics.md))
- Logs: `https://otlp.datadoghq.com/v1/logs` ([source](https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/logs.md))

```bash
sudo tee /etc/otelcol-contrib/config.yaml > /dev/null <<'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  hostmetrics:
    collection_interval: 30s
    scrapers:
      cpu:
      disk:
      filesystem:
      load:
      memory:
      network:
      paging:
      processes:

  filelog/system:
    include:
      - /var/log/messages
      - /var/log/secure
    include_file_name: true
    include_file_path: true
    storage: file_storage
    operators:
      - type: regex_parser
        regex: '^(?P<time>\w+ +\d+ \d+:\d+:\d+) (?P<host>\S+) (?P<ident>\S+?)(?:\[(?P<pid>\d+)\])?: (?P<message>.*)$'
        severity:
          parse_from: attributes.ident
        timestamp:
          parse_from: attributes.time
          layout: '%b %d %H:%M:%S'

processors:
  resourcedetection:
    detectors: [system, env]
    system:
      hostname_sources: ["os"]
      resource_attributes:
        host.name:
          enabled: true
        os.type:
          enabled: true

  # Datadog OTLP ingest requires delta temporality for metrics.
  # hostmetrics emits cumulative by default — this processor converts them.
  cumulativetodelta:

exporters:
  # Traces — https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/
  otlphttp/dd_traces:
    traces_endpoint: "https://otlp.datadoghq.com/v1/traces"
    headers:
      dd-api-key: ${env:DD_API_KEY}
      dd-otlp-source: "datadog"

  # Metrics — https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/metrics.md
  otlphttp/dd_metrics:
    metrics_endpoint: "https://otlp.datadoghq.com/v1/metrics"
    headers:
      dd-api-key: ${env:DD_API_KEY}
      dd-otel-metric-config: '{"resource_attributes_as_tags": true}'

  # Logs — https://docs.datadoghq.com/opentelemetry/setup/otlp_ingest/logs.md
  otlphttp/dd_logs:
    logs_endpoint: "https://otlp.datadoghq.com/v1/logs"
    headers:
      dd-api-key: ${env:DD_API_KEY}

  debug:
    verbosity: basic

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  file_storage:
    directory: /var/lib/otelcol-contrib/storage
  datadog:
    api:
      key: ${env:DD_API_KEY}
      site: datadoghq.com
    hostname: "jek-ec2-centos9"

service:
  extensions: [health_check, file_storage, datadog]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resourcedetection]
      exporters: [otlphttp/dd_traces, debug]
    metrics:
      receivers: [otlp, hostmetrics]
      processors: [resourcedetection, cumulativetodelta]
      exporters: [otlphttp/dd_metrics]
    logs:
      receivers: [otlp, filelog/system]
      processors: [resourcedetection]
      exporters: [otlphttp/dd_logs]
EOF
```

**Key points for Option A:**
- The `cumulativetodelta` processor is required because Datadog OTLP ingest only accepts delta metrics, but `hostmetrics` emits cumulative.
- Hostname and tags are set via the `datadog` extension (not the exporter).
- Each signal (traces, metrics, logs) has its own named exporter with signal-specific headers.

---

### Option B: Datadog Exporter (native, full-fidelity)

Uses the native `datadog/exporter` from otelcol-contrib. Provides full-fidelity service map, trace metrics, and built-in host metadata. Named `datadog/exporter` to disambiguate from the `datadog` extension ([per Datadog docs](https://docs.datadoghq.com/opentelemetry/integrations/datadog_extension.md)).

```bash
sudo tee /etc/otelcol-contrib/config.yaml > /dev/null <<'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  hostmetrics:
    collection_interval: 30s
    scrapers:
      cpu:
      disk:
      filesystem:
      load:
      memory:
      network:
      paging:
      processes:

  filelog/system:
    include:
      - /var/log/messages
      - /var/log/secure
    include_file_name: true
    include_file_path: true
    storage: file_storage
    operators:
      - type: regex_parser
        regex: '^(?P<time>\w+ +\d+ \d+:\d+:\d+) (?P<host>\S+) (?P<ident>\S+?)(?:\[(?P<pid>\d+)\])?: (?P<message>.*)$'
        severity:
          parse_from: attributes.ident
        timestamp:
          parse_from: attributes.time
          layout: '%b %d %H:%M:%S'

processors:
  resourcedetection:
    detectors: [system, env]
    system:
      hostname_sources: ["os"]
      resource_attributes:
        host.name:
          enabled: true
        os.type:
          enabled: true

connectors:
  # Datadog Connector — computes APM stats (latency, error rates, request counts) from traces
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/datadogconnector
  datadog/connector:
    traces:
      span_name_as_resource_name: true
      compute_stats_by_span_kind: true
      peer_tags_aggregation: true

exporters:
  # Named datadog/exporter to disambiguate from the datadog extension
  datadog/exporter:
    hostname: "jek-ec2-centos9"
    sending_queue:
      enabled: true
      num_consumers: 10
      queue_size: 1000
    api:
      key: ${env:DD_API_KEY}
      site: datadoghq.com
    traces:
      span_name_as_resource_name: true
    host_metadata:
      enabled: true
      hostname_source: config_or_system
      tags:
        - env:sandbox
        - owner:jek

  debug:
    verbosity: basic

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  file_storage:
    directory: /var/lib/otelcol-contrib/storage
  datadog:
    api:
      key: ${env:DD_API_KEY}
      site: datadoghq.com
    hostname: "jek-ec2-centos9"

service:
  extensions: [health_check, file_storage, datadog]
  pipelines:
    # Traces flow through the connector first for APM stats computation,
    # then continue to the exporter via a second traces pipeline.
    traces:
      receivers: [otlp]
      processors: [resourcedetection]
      exporters: [datadog/connector]
    traces/2:
      receivers: [datadog/connector]
      exporters: [datadog/exporter, debug]
    metrics:
      receivers: [otlp, hostmetrics, datadog/connector]
      processors: [resourcedetection]
      exporters: [datadog/exporter]
    logs:
      receivers: [otlp, filelog/system]
      processors: [resourcedetection]
      exporters: [datadog/exporter]
EOF
```

**Key points for Option B:**
- The [Datadog Connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/datadogconnector) computes APM stats (latency, error rates, request counts) from traces before they are exported. These stats power the APM service page, service map, and latency histograms.
- Traces flow: `otlp → resourcedetection → datadog/connector → datadog/exporter`. The connector also feeds computed metrics into the metrics pipeline.
- No `cumulativetodelta` processor needed — the Datadog exporter handles temporality automatically.
- Hostname and tags are set in both `datadog/exporter` and the `datadog` extension. They **must match**.
- Uses `sending_queue` for exporter-level batching — no batch processor needed ([why?](https://github.com/open-telemetry/opentelemetry.io/pull/9088)).

---

## Step 4: Configure the environment file

The systemd service reads environment variables from `/etc/otelcol-contrib/otelcol-contrib.conf`. Two variables are required:

- `DD_API_KEY` — your Datadog API key
- `OTELCOL_OPTIONS` — tells the binary where to find the config file (without this, the collector fails with "at least one config flag must be provided")

```bash
sudo tee /etc/otelcol-contrib/otelcol-contrib.conf > /dev/null <<EOF
DD_API_KEY=<YOUR_DD_API_KEY>
OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"
EOF

# Restrict permissions (file contains your API key)
sudo chmod 600 /etc/otelcol-contrib/otelcol-contrib.conf
```

Replace `<YOUR_DD_API_KEY>` with your actual Datadog API key.

## Step 5: Enable system log collection

The collector runs as user `otelcol-contrib`, which doesn't have permission to read system log files by default. Grant read access:

```bash
# Grant read access to system logs
sudo setfacl -m u:otelcol-contrib:r /var/log/messages /var/log/secure

# Create storage directory for filelog checkpoint (tracks where the reader left off)
sudo mkdir -p /var/lib/otelcol-contrib/storage
sudo chown otelcol-contrib:otelcol-contrib /var/lib/otelcol-contrib/storage
```

If `setfacl` is not available, use: `sudo chmod o+r /var/log/messages /var/log/secure`

## Step 6: Start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable otelcol-contrib
sudo systemctl restart otelcol-contrib
```

Wait 3 seconds, then check it's running:

```bash
sudo systemctl status otelcol-contrib
```

You should see `Active: active (running)`. The logs should show:
- `Starting GRPC server` on port 4317
- `Starting HTTP server` on port 4318
- `Started watching file` for `/var/log/messages` and `/var/log/secure`
- `Everything is ready. Begin running and processing data.`

If it fails, check the logs:

```bash
sudo journalctl -u otelcol-contrib -n 50 --no-pager
```

## Step 7: Verify everything works

### 7a. Health check

```bash
curl -s http://localhost:13133/
```

Expected: `{"status":"Server available","upSince":"...","uptime":"..."}`

### 7b. Send a test trace

```bash
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "jek-otel-test"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5B8EFFF798038103D269B633813FC60C",
          "spanId": "EEE19B7EC3C1B174",
          "name": "test-span-verify",
          "kind": 1,
          "startTimeUnixNano": "1000000000",
          "endTimeUnixNano": "2000000000",
          "status": {}
        }]
      }]
    }]
  }'
```

Expected: `{"partialSuccess":{}}`

### 7c. Send a test log

```bash
curl -X POST http://localhost:4318/v1/logs \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "jek-otel-test"}
        }]
      },
      "scopeLogs": [{
        "logRecords": [{
          "timeUnixNano": "1000000000",
          "severityNumber": 9,
          "severityText": "INFO",
          "body": {"stringValue": "Test log from OTel Collector verify"},
          "attributes": [{
            "key": "log.source",
            "value": {"stringValue": "manual-test"}
          }]
        }]
      }]
    }]
  }'
```

Expected: `{"partialSuccess":{}}`

### 7d. Verify in Datadog (wait 1-2 minutes after sending)

1. **Traces**: Go to APM > Traces. Search for `service:jek-otel-test`. You should see the `test-span-verify` span with host `jek-ec2-centos9`.

2. **Logs**: Go to Logs. Search for `service:jek-otel-test`. You should see the test log message. Also search `host:jek-ec2-centos9` for system logs from `/var/log/messages` and `/var/log/secure`.

3. **Host metrics**: Go to Infrastructure > Host Map. Find `jek-ec2-centos9`. The Host Info tab should show CPU, memory, filesystem metrics. Tags should show `env:sandbox` and `owner:jek`.

## Customization

### Changing hostname and tags

**If using Option A (OTLP HTTP):** Edit the `datadog` extension section:

```yaml
extensions:
  datadog:
    hostname: "your-custom-hostname"
```

**If using Option B (Datadog Exporter):** Edit **both** the exporter and extension (they must match):

```yaml
exporters:
  datadog/exporter:
    hostname: "your-custom-hostname"
    host_metadata:
      tags:
        - env:your-environment
        - owner:your-name

extensions:
  datadog:
    hostname: "your-custom-hostname"
```

After changing, restart: `sudo systemctl restart otelcol-contrib`

### Switching between exporters

To switch from Option A to Option B (or vice versa), replace the config file in Step 3 with the other option's config block and restart the service. No reinstallation needed.

## Troubleshooting

### Collector won't start

```bash
sudo journalctl -u otelcol-contrib -n 50 --no-pager
```

| Error | Cause | Fix |
|---|---|---|
| `at least one config flag must be provided` | Missing `OTELCOL_OPTIONS` in env file | Add `OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"` to `/etc/otelcol-contrib/otelcol-contrib.conf` |
| `error decoding config` | Invalid YAML in config.yaml | Check YAML syntax — indentation matters |
| `API key validation failed` | Wrong DD_API_KEY | Verify key in `/etc/otelcol-contrib/otelcol-contrib.conf` |

### No traces in Datadog

- Check collector is running: `sudo systemctl status otelcol-contrib`
- Check for export errors: `sudo journalctl -u otelcol-contrib -f`
- Verify outbound HTTPS connectivity: `curl -s https://api.datadoghq.com`

### No logs in Datadog

- Check the collector can read log files: `sudo -u otelcol-contrib cat /var/log/messages | head -1`
- If "Permission denied": re-run `sudo setfacl -m u:otelcol-contrib:r /var/log/messages /var/log/secure`
- Check collector logs for filelog errors: `sudo journalctl -u otelcol-contrib | grep filelog`

### Hostname shows as EC2 instance ID instead of custom name

- If Option A: check `hostname` in the `datadog` extension config
- If Option B: check `hostname` in both `datadog/exporter` and the `datadog` extension — they must match
- Restart: `sudo systemctl restart otelcol-contrib`
- Wait 5-10 minutes for host metadata to update in Datadog

## Teardown

```bash
sudo systemctl stop otelcol-contrib
sudo systemctl disable otelcol-contrib
sudo rpm -e otelcol-contrib
sudo rm -rf /etc/otelcol-contrib /var/lib/otelcol-contrib
```
