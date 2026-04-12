# install-otelcol-contrib

Step-by-step guide to install the OpenTelemetry Collector Contrib on CentOS Stream 9 as a systemd service. This replaces the Datadog Agent entirely — all telemetry (traces, metrics, logs, host metrics) flows through the OTel Collector to Datadog.

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

## Step 3: Deploy the config file

Create the config file at `/etc/otelcol-contrib/config.yaml`. This file controls what the collector receives, how it processes data, and where it exports to.

```bash
sudo tee /etc/otelcol-contrib/config.yaml > /dev/null <<'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  # Host metrics — replaces Datadog Agent for infrastructure monitoring
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

  # System logs — collect syslog and auth logs from the host
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

exporters:
  # Native Datadog exporter — full-fidelity (service map, trace metrics, host metadata)
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

  # Debug exporter — for troubleshooting during setup
  debug:
    verbosity: basic

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  file_storage:
    directory: /var/lib/otelcol-contrib/storage
  # Datadog extension — makes collector visible in Datadog Infrastructure and Fleet Automation
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/extension/datadogextension/README.md
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
      exporters: [datadog/exporter, debug]
    metrics:
      receivers: [otlp, hostmetrics]
      processors: [resourcedetection]
      exporters: [datadog/exporter]
    logs:
      receivers: [otlp, filelog/system]
      processors: [resourcedetection]
      exporters: [datadog/exporter]
EOF
```

### What each section does

| Section | Purpose |
|---|---|
| `datadog/exporter.hostname` | Sets the hostname shown in Datadog (default is EC2 instance ID which is not human-readable) |
| `datadog/exporter.host_metadata.tags` | Adds tags like `env:sandbox` and `owner:jek` to the host in Datadog |
| `otlp` receiver | Receives traces, metrics, logs from Java apps via OTel Java agent (ports 4317/4318) |
| `hostmetrics` receiver | Collects CPU, memory, disk, network metrics from the host (replaces Datadog Agent) |
| `filelog/system` receiver | Reads system logs from `/var/log/messages` and `/var/log/secure` |
| `datadog/exporter` exporter | Sends all telemetry to Datadog US1 using your API key. Named `datadog/exporter` to disambiguate from the `datadog` extension. Has built-in batching via `sending_queue` — no separate batch processor needed. See: [Sunset of the OTel Batch Processor](https://github.com/open-telemetry/opentelemetry.io/pull/9088), [Move batching to exporters](https://github.com/open-telemetry/opentelemetry-collector/issues/8122) |
| `datadog/exporter.sending_queue` | Exporter-level batching and queuing. Replaces the deprecated batch processor with better durability during collector restarts |
| `debug` exporter | Prints trace info to collector logs for troubleshooting |
| `datadog` extension | Makes collector config and build info visible in Datadog Infrastructure and [Fleet Automation](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/extension/datadogextension/README.md). Hostname must match the exporter's hostname |

### To customize hostname and tags

Edit the `datadog/exporter` section in the config:

```yaml
exporters:
  datadog/exporter:
    hostname: "your-custom-hostname"    # Change this
    host_metadata:
      tags:
        - env:your-environment           # Change this
        - owner:your-name                # Change this
        - team:your-team                 # Add more tags
```

After changing, restart the service: `sudo systemctl restart otelcol-contrib`

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
- `API key validation successful`
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

### 7c. Verify in Datadog (wait 1-2 minutes after sending)

1. **Traces**: Go to APM > Traces. Search for `service:jek-otel-test`. You should see the `test-span-verify` span with host `jek-ec2-centos9`.

2. **Logs**: Go to Logs. Search for `host:jek-ec2-centos9`. You should see system log entries from `/var/log/messages` and `/var/log/secure` with source `otelcol-contrib`.

3. **Host metrics**: Go to Infrastructure > Host Map. Find `jek-ec2-centos9`. The Host Info tab should show CPU, memory, filesystem metrics. Tags should show `env:sandbox` and `owner:jek`.

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

- Check `hostname` is set in the `datadog/exporter` section of config.yaml
- Restart: `sudo systemctl restart otelcol-contrib`
- Wait 5-10 minutes for host metadata to update in Datadog

## Teardown

```bash
sudo systemctl stop otelcol-contrib
sudo systemctl disable otelcol-contrib
sudo rpm -e otelcol-contrib
sudo rm -rf /etc/otelcol-contrib /var/lib/otelcol-contrib
```
