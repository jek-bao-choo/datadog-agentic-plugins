---
name: install-otelcol-contrib
description: >-
  Install the OpenTelemetry Collector Contrib on an EC2 instance as a systemd service.
  Configures OTLP receivers (gRPC 4317, HTTP 4318), hostmetrics receiver, filelog receiver
  for system logs, native Datadog exporter for traces/metrics/logs, and the Datadog extension
  for Fleet Automation visibility. Replaces the Datadog Agent entirely — all telemetry flows
  through OTel. Includes custom hostname and tags configuration.
version: 0.1.0
version_matrix:
  otelcol-contrib: ["0.149.0"]
  os: [centos-stream-9]
---

# Install OTel Collector Contrib

Install and configure the OpenTelemetry Collector Contrib as a systemd service on EC2. This is the sole telemetry pipeline — no Datadog Agent needed.

## Prerequisites

- EC2 instance running CentOS Stream 9 (from `setup-ec2-centos9` skill)
- SSH access to the instance
- Datadog API key (DD_API_KEY) for datadoghq.com (US1)

## Pipelines

| Pipeline | Receivers | Processors | Exporters |
|---|---|---|---|
| Traces | OTLP (gRPC 4317, HTTP 4318) | resourcedetection | datadog/exporter, debug |
| Metrics | OTLP + hostmetrics (CPU, disk, memory, network, load) | resourcedetection | datadog/exporter |
| Logs | OTLP + filelog/system (/var/log/messages, /var/log/secure) | resourcedetection | datadog/exporter |

No batch processor — the Datadog exporter's built-in `sending_queue` handles batching with better durability during collector restarts.

## Instructions

### Option A: Automated install via script

From your local machine:

```bash
# SCP config and install script to the instance
scp -i ~/.ssh/jek_rsa_pem references/config.yaml ec2-user@<IP>:/tmp/otelcol-contrib-config.yaml
scp -i ~/.ssh/jek_rsa_pem scripts/install.sh ec2-user@<IP>:/tmp/install-otelcol.sh

# Run the install script (pass your DD_API_KEY as the argument)
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP> 'chmod +x /tmp/install-otelcol.sh && /tmp/install-otelcol.sh <DD_API_KEY>'
```

### Option B: Manual install on the instance

SSH into the instance, then:

```bash
# 1. Download and install RPM
curl -L -o /tmp/otelcol-contrib.rpm \
  https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.149.0/otelcol-contrib_0.149.0_linux_amd64.rpm
sudo rpm -Uvh /tmp/otelcol-contrib.rpm
rm -f /tmp/otelcol-contrib.rpm

# 2. Deploy config (copy references/config.yaml to the instance first)
sudo cp /tmp/otelcol-contrib-config.yaml /etc/otelcol-contrib/config.yaml

# 3. Set environment variables (BOTH are required)
sudo tee /etc/otelcol-contrib/otelcol-contrib.conf > /dev/null <<EOF
DD_API_KEY=<your-api-key>
OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"
EOF
sudo chmod 600 /etc/otelcol-contrib/otelcol-contrib.conf

# 4. Grant log file access for the filelog receiver
sudo setfacl -m u:otelcol-contrib:r /var/log/messages /var/log/secure
sudo mkdir -p /var/lib/otelcol-contrib/storage
sudo chown otelcol-contrib:otelcol-contrib /var/lib/otelcol-contrib/storage

# 5. Start the service
sudo systemctl daemon-reload
sudo systemctl enable --now otelcol-contrib
```

## Validation

```bash
# Service running
sudo systemctl status otelcol-contrib

# Health check
curl -s http://localhost:13133/

# Send test trace
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"jek-otel-test"}}]},"scopeSpans":[{"spans":[{"traceId":"5B8EFFF798038103D269B633813FC60C","spanId":"EEE19B7EC3C1B174","name":"test-span","kind":1,"startTimeUnixNano":"1000000000","endTimeUnixNano":"2000000000","status":{}}]}]}]}'

# Check Datadog:
# - APM > Traces: service:jek-otel-test
# - Logs: host:jek-ec2-centos9
# - Infrastructure > Host Map: jek-ec2-centos9 with env:sandbox, owner:jek tags
```

## Customization

To change the hostname or tags, edit `/etc/otelcol-contrib/config.yaml`:

```yaml
exporters:
  datadog/exporter:
    hostname: "your-hostname"       # Shows in Datadog Infrastructure
    host_metadata:
      tags:
        - env:your-env              # Adds tags to the host
        - owner:your-name
```

Then restart: `sudo systemctl restart otelcol-contrib`

## Troubleshooting

| Error | Fix |
|---|---|
| `at least one config flag must be provided` | Add `OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"` to env file |
| `API key validation failed` | Check DD_API_KEY in `/etc/otelcol-contrib/otelcol-contrib.conf` |
| No logs in Datadog | Run `sudo setfacl -m u:otelcol-contrib:r /var/log/messages /var/log/secure` |
| Hostname shows instance ID | Set `hostname` in `datadog/exporter` config, restart, wait 5-10 min |

Full troubleshooting details in README.md.

## Teardown

```bash
sudo systemctl stop otelcol-contrib
sudo systemctl disable otelcol-contrib
sudo rpm -e otelcol-contrib
sudo rm -rf /etc/otelcol-contrib /var/lib/otelcol-contrib
```
