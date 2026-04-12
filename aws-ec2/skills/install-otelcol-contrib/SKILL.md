---
name: install-otelcol-contrib
description: >-
  Install the OpenTelemetry Collector Contrib on an EC2 instance as a systemd service.
  Configures OTLP receivers (gRPC 4317, HTTP 4318), hostmetrics receiver, filelog receiver
  for system logs, and the Datadog extension for Fleet Automation visibility. Offers two
  exporter options: (A) OTLP HTTP Exporter (vendor-neutral, sends to Datadog OTLP ingest
  endpoints) or (B) native Datadog Exporter (full-fidelity service map, trace metrics,
  host metadata). Replaces the Datadog Agent entirely.
version: 0.1.0
version_matrix:
  otelcol-contrib: ["0.149.0"]
  os: [centos-stream-9]
---

# Install OTel Collector Contrib

Install and configure the OpenTelemetry Collector Contrib as a systemd service on EC2. This is the sole telemetry pipeline — no Datadog Agent needed. Two exporter options are available.

## Prerequisites

- EC2 instance running CentOS Stream 9 (from `setup-ec2-centos9` skill)
- SSH access to the instance
- Datadog API key (DD_API_KEY) for datadoghq.com (US1)

## Exporter Options

### Option A: OTLP HTTP Exporter (vendor-neutral)

| Pipeline | Receivers | Processors | Exporters |
|---|---|---|---|
| Traces | OTLP (gRPC 4317, HTTP 4318) | resourcedetection | otlphttp/dd_traces, debug |
| Metrics | OTLP + hostmetrics | resourcedetection, cumulativetodelta | otlphttp/dd_metrics |
| Logs | OTLP + filelog/system | resourcedetection | otlphttp/dd_logs |

Uses standard OTLP protocol to send to Datadog's OTLP ingest endpoints (`otlp.datadoghq.com`). No Datadog-specific exporter component. Requires `cumulativetodelta` processor for metrics.

### Option B: Datadog Exporter + Connector (native, full-fidelity)

| Pipeline | Receivers | Processors | Exporters |
|---|---|---|---|
| Traces | OTLP (gRPC 4317, HTTP 4318) | resourcedetection | datadog/connector |
| Traces/2 | datadog/connector | — | datadog/exporter, debug |
| Metrics | OTLP + hostmetrics + datadog/connector | resourcedetection | datadog/exporter |
| Logs | OTLP + filelog/system | resourcedetection | datadog/exporter |

Native Datadog exporter with built-in `sending_queue` for batching ([no batch processor needed](https://github.com/open-telemetry/opentelemetry.io/pull/9088)). The [Datadog Connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/datadogconnector) computes APM stats (latency, error rates, request counts) from traces before export. Handles metrics temporality automatically.

Both options include the [Datadog extension](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/extension/datadogextension/README.md) for Fleet Automation visibility.

## Instructions

See **README.md** for the full step-by-step guide. Quick summary:

### Automated install via script

```bash
scp -i ~/.ssh/jek_rsa_pem references/config.yaml ec2-user@<IP>:/tmp/otelcol-contrib-config.yaml
scp -i ~/.ssh/jek_rsa_pem scripts/install.sh ec2-user@<IP>:/tmp/install-otelcol.sh
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP> 'chmod +x /tmp/install-otelcol.sh && /tmp/install-otelcol.sh <DD_API_KEY>'
```

The `references/config.yaml` contains both options. Edit it to uncomment your preferred exporter before deploying.

## Validation

```bash
sudo systemctl status otelcol-contrib
curl -s http://localhost:13133/

# Send test trace
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"jek-otel-test"}}]},"scopeSpans":[{"spans":[{"traceId":"5B8EFFF798038103D269B633813FC60C","spanId":"EEE19B7EC3C1B174","name":"test-span","kind":1,"startTimeUnixNano":"1000000000","endTimeUnixNano":"2000000000","status":{}}]}]}]}'

# Datadog: APM > Traces: service:jek-otel-test
# Datadog: Logs: host:jek-ec2-centos9
# Datadog: Infrastructure > Host Map: jek-ec2-centos9
```

## Customization

**Option A** — hostname/tags via extension only:
```yaml
extensions:
  datadog:
    hostname: "your-hostname"
```

**Option B** — hostname/tags in both exporter and extension (must match):
```yaml
exporters:
  datadog/exporter:
    hostname: "your-hostname"
    host_metadata:
      tags:
        - env:your-env
        - owner:your-name
extensions:
  datadog:
    hostname: "your-hostname"
```

Then restart: `sudo systemctl restart otelcol-contrib`

## Troubleshooting

| Error | Fix |
|---|---|
| `at least one config flag must be provided` | Add `OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"` to env file |
| `API key validation failed` | Check DD_API_KEY in `/etc/otelcol-contrib/otelcol-contrib.conf` |
| No logs in Datadog | Run `sudo setfacl -m u:otelcol-contrib:r /var/log/messages /var/log/secure` |
| Hostname shows instance ID | Set `hostname` in extension (Option A) or both exporter + extension (Option B) |

## Teardown

```bash
sudo systemctl stop otelcol-contrib
sudo systemctl disable otelcol-contrib
sudo rpm -e otelcol-contrib
sudo rm -rf /etc/otelcol-contrib /var/lib/otelcol-contrib
```
