---
name: initialising-splunk-enterprise
description: Set up and operate a Splunk Enterprise sandbox with a Universal Forwarder using Docker Compose. Use this skill whenever the user wants to spin up Splunk locally, ingest logs via a Universal Forwarder, query indexed data through the Splunk REST API, or export Splunk events to JSON files. Also use it when the user mentions Splunk docker setup, forwarding logs to Splunk, Splunk search export, the Splunk management API on port 8089, or chunked data export from Splunk — even if they don't explicitly say "sandbox" or "initialise".
---

# Initialising Splunk Enterprise

Stand up a local Splunk Enterprise instance with a Universal Forwarder, send test data, verify indexing, and export data via the REST API — all using Docker Compose.

## Architecture

```
┌─────────────────────┐         ┌──────────────────────────┐
│  Universal Forwarder │───9997──▶  Splunk Enterprise       │
│  (splunk-uf)         │         │  (splunk-enterprise)      │
│  Monitors /var/log   │         │                           │
└─────────────────────┘         │  :8000  Web UI            │
                                │  :8088  HEC               │
                                │  :8089  REST API / Mgmt   │
                                │  :9997  S2S Indexing       │
                                └──────────────────────────┘
```

Both containers run on a `splunk-net` bridge network. The UF forwards data to the indexer over port 9997.

## Quick Reference

| What              | Value                        |
|-------------------|------------------------------|
| Splunk Web UI     | http://localhost:8000        |
| REST API          | https://localhost:8089       |
| Username          | `admin`                      |
| Password          | `ChangedPassword123!`        |
| HEC Token         | `00000000-0000-0000-0000-000000000000` |

## Step-by-Step Workflow

### 1. Start the environment

Run from the `scripts/` directory within this skill:

```bash
docker-compose up -d
```

Wait for the health check to pass (Splunk Enterprise takes ~60-90 seconds to become healthy).

### 2. Send test data via the Universal Forwarder

First, register a monitor on the UF — this tells it which file to watch:

```bash
docker exec -u splunk splunk-uf /opt/splunkforwarder/bin/splunk add monitor /var/log/test.log \
  -index main \
  -sourcetype test_logs \
  -auth admin:ChangedPassword123!
```

Then write log entries (use `-u root` because `/var/log/` is owned by root):

```bash
docker exec -u root splunk-uf bash -c \
  'echo "$(date +"%Y-%m-%d %H:%M:%S") INFO  Test log entry from UF" >> /var/log/test.log'
```

The monitor must be added **before** writing entries — the UF only forwards data written after registration.

### 3. Verify data was indexed

From the CLI:

```bash
docker exec -u splunk splunk-enterprise /opt/splunk/bin/splunk search \
  "| tstats count where index=main sourcetype=test_logs by sourcetype" \
  -auth admin:ChangedPassword123!
```

Or open the Web UI at http://localhost:8000, set the time picker to **All time**, and run `index=main`.

### 4. Export data via the REST API

Port 8089 is exposed for direct REST API access from the host.

**One-off curl export:**

```bash
curl -k -u admin:ChangedPassword123! \
  -d 'search=search index=main sourcetype=test_logs' \
  -d 'earliest_time=-24h' \
  -d 'latest_time=now' \
  -d 'output_mode=json' \
  https://localhost:8089/services/search/v2/jobs/export
```

The `search` parameter value must begin with the `search` SPL command.

**Chunked export for large time ranges:**

Use `scripts/splunk-export.sh` which splits the time range into 1-hour windows to avoid timeouts:

```bash
./splunk-export.sh                                    # last 24h, index=main
./splunk-export.sh -s "search index=main sourcetype=test_logs" -o export.json
./splunk-export.sh -e $(date -v-7d +%s) -l $(date +%s)
```

Run `./splunk-export.sh -h` for all options. The script supports `SPLUNK_URL`, `SPLUNK_USER`, and `SPLUNK_PASS` environment variables.

### 5. Upload exported data to AWS S3

```bash
aws s3 cp splunk_export.json s3://your-bucket-name/splunk-exports/
```

Requires the AWS CLI installed and configured (`aws configure`).

## Bundled Resources

- **`scripts/docker-compose.yml`** — Docker Compose file defining the Splunk Enterprise and Universal Forwarder services
- **`scripts/splunk-export.sh`** — Bash script for hourly-chunked REST API data export
- **`README.md`** — Full step-by-step guide with troubleshooting. Read this for detailed instructions on verifying forwarding, checking input status, and diagnosing common issues.

## Troubleshooting

For troubleshooting forwarding connections, input status, receiving ports, and event counts, read `README.md` — it has specific commands for each diagnostic step.
