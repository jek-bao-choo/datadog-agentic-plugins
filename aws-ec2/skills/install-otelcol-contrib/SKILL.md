---
name: install-otelcol-contrib
description: >-
  Install the OpenTelemetry Collector Contrib on an EC2 instance as a systemd service.
  Configures OTLP receivers (gRPC 4317, HTTP 4318), hostmetrics receiver, journald
  receiver for non-root system logs (Tier 2 via the systemd-journal group, with
  optional filelog for world-readable app logs — Tier 1), and the Datadog extension
  for Fleet Automation visibility. Offers two exporter options: (A) OTLP HTTP Exporter
  (vendor-neutral, sends to Datadog OTLP ingest endpoints) or (B) native Datadog
  Exporter (full-fidelity service map, trace metrics, host metadata). Replaces the
  Datadog Agent entirely.
version: 0.1.0
version_matrix:
  otelcol-contrib: ["0.150.1"]
  os: [centos-stream-9]
---

# Install OTel Collector Contrib

Install and configure the OpenTelemetry Collector Contrib as a systemd service on EC2. This is the sole telemetry pipeline — no Datadog Agent needed. Two exporter options are available.

## Prerequisites

- EC2 instance running CentOS Stream 9 (from `setup-ec2-centos9` skill)
- SSH access to the instance
- Datadog API key (`DD_API_KEY`) for `datadoghq.com` (US1) or your site's endpoint (e.g. `datadoghq.eu`)

## Exporter Options

### Option A: OTLP HTTP Exporter (vendor-neutral)

| Pipeline | Receivers | Processors | Exporters |
|---|---|---|---|
| Traces | OTLP (gRPC 4317, HTTP 4318) | resourcedetection | otlphttp/dd_traces, debug |
| Metrics | OTLP + hostmetrics | resourcedetection, cumulativetodelta | otlphttp/dd_metrics |
| Logs | OTLP + journald (+ optional filelog/apps) | resourcedetection | otlphttp/dd_logs |

Uses standard OTLP protocol to send to Datadog's OTLP ingest endpoints (`otlp.datadoghq.com`). No Datadog-specific exporter component. Requires `cumulativetodelta` processor for metrics.

### Option B: Datadog Exporter + Connector (native, full-fidelity)

| Pipeline | Receivers | Processors | Exporters |
|---|---|---|---|
| Traces | OTLP (gRPC 4317, HTTP 4318) | resourcedetection | datadog/connector |
| Traces/2 | datadog/connector | — | datadog/exporter, debug |
| Metrics | OTLP + hostmetrics + datadog/connector | resourcedetection | datadog/exporter |
| Logs | OTLP + journald (+ optional filelog/apps) | resourcedetection | datadog/exporter |

Native Datadog exporter with built-in `sending_queue` for batching ([no batch processor needed](https://github.com/open-telemetry/opentelemetry.io/pull/9088)). The [Datadog Connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/datadogconnector) computes APM stats (latency, error rates, request counts) from traces before export. Handles metrics temporality automatically.

Both options include the [Datadog extension](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/extension/datadogextension/README.md) for Fleet Automation visibility.

**Log collection runs as non-root.** System logs come from the `journald` receiver (Tier 2, requires the collector user to be in the `systemd-journal` group — Step 5 in README). Application logs that are already world-readable (mode 644+) can be tailed via an optional `filelog/apps` receiver (Tier 1 — no special permissions needed). This avoids the `setfacl` workaround on `/var/log/messages` that would break on every `logrotate` run.

## Instructions

See **README.md** for the full step-by-step guide. Quick summary:

### Automated install via script

```bash
scp -i ~/.ssh/jek_rsa_pem references/custom-config.yaml ec2-user@<IP>:/tmp/otelcol-contrib-config.yaml
scp -i ~/.ssh/jek_rsa_pem scripts/install.sh ec2-user@<IP>:/tmp/install-otelcol.sh
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP> 'chmod +x /tmp/install-otelcol.sh && /tmp/install-otelcol.sh <DD_API_KEY>'
```

`references/custom-config.yaml` is the canonical config — it uses the native `datadog/exporter` path (Option B) by default; the `otlp_http/dd_*` exporters (Option A) are present as commented-out alternatives.

## Validation

```bash
sudo systemctl status otelcol-contrib
curl -s http://localhost:13133/

# Send a test trace (unique IDs + current timestamps — see the "Manual Send Test Trace" section below for the full block)
TID=$(openssl rand -hex 16); SID=$(openssl rand -hex 8); NOW=$(date +%s%N); END=$(( NOW + 50000000 ))
curl -sS -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"jek-trace-test"}},{"key":"service.version","value":{"stringValue":"1.2.3"}},{"key":"deployment.environment","value":{"stringValue":"sandbox"}},{"key":"datadog.host.name","value":{"stringValue":"jek-centos9-v3"}}]},"scopeSpans":[{"spans":[{"traceId":"'$TID'","spanId":"'$SID'","name":"GET /hello","kind":2,"startTimeUnixNano":"'$NOW'","endTimeUnixNano":"'$END'","attributes":[{"key":"http.method","value":{"stringValue":"GET"}},{"key":"http.route","value":{"stringValue":"/hello"}},{"key":"http.status_code","value":{"intValue":200}}],"status":{"code":1}}]}]}]}'
echo

# Datadog checks:
# APM > Services:      service:jek-trace-test (env:sandbox, version:1.2.3)
# Logs:                host:jek-centos9-v3 (substitute your datadog.host.name)
# Infrastructure Host: jek-centos9-v3
```

## Customization

**Recommended — drive host / env / version from the systemd env file** (no YAML edit needed):

```
# /etc/otelcol-contrib/otelcol-contrib.conf
OTEL_RESOURCE_ATTRIBUTES="datadog.host.name=your-host,deployment.environment=your-env,service.version=your-version"
```

The `env` resource detector picks these up. `datadog.host.name` is Datadog's purpose-built override attribute — it beats `host.name` (which the `system` detector sets to the OS hostname) for host association, so it works without fighting detector ordering.

**Alternative — hardcode in YAML:**

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
| `at least one config flag must be provided` | Add `OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/custom-config.yaml"` to env file |
| `API key validation failed` | Check `DD_API_KEY` in `/etc/otelcol-contrib/otelcol-contrib.conf` |
| No logs in Datadog | Add the collector user to the `systemd-journal` group: `sudo usermod -a -G systemd-journal otelcol-contrib && sudo systemctl restart otelcol-contrib` |
| Hostname shows instance ID | Set `OTEL_RESOURCE_ATTRIBUTES="datadog.host.name=..."` in the env file (or hardcode `hostname:` per Customization) |

## Teardown

```bash
sudo systemctl stop otelcol-contrib
sudo systemctl disable otelcol-contrib
sudo rpm -e otelcol-contrib
sudo rm -rf /etc/otelcol-contrib /var/lib/otelcol-contrib
```

---

## Manual install

```bash
sudo yum update

sudo yum -y install wget

wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.150.1/otelcol-contrib_0.150.1_linux_amd64.rpm

sudo rpm -ivh otelcol-contrib_0.150.1_linux_amd64.rpm

sudo journalctl -u otelcol-contrib

sudo journalctl -u otelcol-contrib -f

/usr/bin/otelcol-contrib --help

sudo systemctl status otelcol-contrib

cat /etc/otelcol-contrib/otelcol-contrib.conf

sudo vi /etc/otelcol-contrib/otelcol-contrib.conf

# add DD_SITE and DD_API_KEY and modify it to use /etc/otelcol-contrib/custom-config.yaml

cat /etc/otelcol-contrib/config.yaml

sudo cp /etc/otelcol-contrib/config.yaml /etc/otelcol-contrib/custom-config.yaml

sudo vi /etc/otelcol-contrib/custom-config.yaml

# Modify from original-config.yaml to custom-config.yaml 

# Enable Tier 2 log collection: add otelcol-contrib to the systemd-journal group
sudo usermod -a -G systemd-journal otelcol-contrib

otelcol-contrib validate --config=/etc/otelcol-contrib/custom-config.yaml

sudo systemctl restart otelcol-contrib

sudo systemctl status otelcol-contrib
```

## Manual Send Test Trace

```bash
TID=$(openssl rand -hex 16)
SID=$(openssl rand -hex 8)
NOW=$(date +%s%N)
END=$(( NOW + 50000000 ))
curl -sS -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans":[{
      "resource":{"attributes":[
          {"key":"service.name","value":{"stringValue":"jek-trace-test"}},
          {"key":"service.version","value":{"stringValue":"1.2.3"}},
          {"key":"deployment.environment","value":{"stringValue":"sandbox"}},
          {"key":"datadog.host.name","value":{"stringValue":"jek-centos9-v3"}}
        ]},
        "scopeSpans":[{
          "scope":{"name":"manual-curl-test"},
          "spans":[{
            "traceId":"'$TID'",
            "spanId":"'$SID'",
            "name":"GET /hello",
            "kind":2,
            "startTimeUnixNano":"'$NOW'",
            "endTimeUnixNano":"'$END'",
            "attributes":[
              {"key":"http.method","value":{"stringValue":"GET"}},
              {"key":"http.route","value":{"stringValue":"/hello"}},
              {"key":"http.status_code","value":{"intValue":200}}
            ],
            "status":{"code":1}
          }]
        }]
      }]
    }'
echo
```
