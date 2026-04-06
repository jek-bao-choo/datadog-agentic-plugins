# Splunk Enterprise + Universal Forwarder

## Quick Start

```bash
# From the ../scripts/ directory
docker-compose up -d
```

Access the Splunk Web UI at http://localhost:8000 (User: `admin`, Password: `ChangedPassword123!`)

## Sending Test Dummy Logs via Universal Forwarder

### 1. Configure the Forwarder to Monitor a Log File

Add a monitor on the UF for a test log file. The UF runs its Splunk process as the `splunk` user:

```bash
docker exec -u splunk splunk-uf /opt/splunkforwarder/bin/splunk add monitor /var/log/test.log \
  -index main \
  -sourcetype test_logs \
  -auth admin:ChangedPassword123!
```

### 2. Write Dummy Log Entries

Write test log lines inside the UF container. Use `-u root` because `/var/log/` is owned by root and the default container user (`ansible`) does not have write access:

```bash
docker exec -u root splunk-uf bash -c 'echo "$(date +"%Y-%m-%d %H:%M:%S") INFO  Test log entry from Universal Forwarder to Splunk Enterprise v1" >> /var/log/test.log'
```

To generate multiple entries in a loop:

```bash
docker exec -u root splunk-uf bash -c '
for i in $(seq 1 10); do
  echo "$(date +"%Y-%m-%d %H:%M:%S") INFO  Test event #$i from UF" >> /var/log/test.log
  sleep 1
done
'
```

> **Note:** Make sure to run Step 1 (add monitor) **before** writing log entries. The UF only forwards data written after the monitor is registered.

### 3. Verify Logs in Splunk Enterprise

Open the Splunk Web UI and run a search. Set the time picker to **"All time"** (the Splunk server runs in UTC, so "Last 24 hours" may exclude recent events depending on your local timezone):

```
index=main sourcetype=test_logs

or 

index=main
```
![](../assets/proof-splunk-enterprise.png)

Or verify from the CLI using `tstats` (works regardless of time range):

```bash
docker exec -u splunk splunk-enterprise /opt/splunk/bin/splunk search \
  "| tstats count where index=main sourcetype=test_logs by sourcetype" \
  -auth admin:ChangedPassword123!
```
![](../assets/proof-tstats.png)

## Querying Data via REST API (Export Endpoint)

Port `8089` (Splunk management / REST API) is exposed in `docker-compose.yml`, so you can query indexed data directly from the host using `curl`.

### Standalone curl command

Quick one-off export — streams results as JSON to stdout:

```bash
curl -k -u admin:ChangedPassword123! \
  -d 'search=search index=main sourcetype=test_logs' \
  -d 'earliest_time=-24h' \
  -d 'latest_time=now' \
  -d 'output_mode=json' \
  https://localhost:8089/services/search/v2/jobs/export
```
![](proof-export-curl.png)

Save to a file:

```bash
curl -k -u admin:ChangedPassword123! \
  -d 'search=search index=main' \
  -d 'earliest_time=-7d' \
  -d 'latest_time=now' \
  -d 'output_mode=json' \
  https://localhost:8089/services/search/v2/jobs/export > export.json
```

> **Note:** The `search` field value must start with the `search` SPL command (e.g. `search=search index=main ...`).

### Hourly chunked export with `splunk-export.sh`

For large time ranges the standalone curl may time out. The `splunk-export.sh` script splits the range into 1-hour chunks and appends each chunk's results to an output file.

```bash
# Export the last 24 hours (defaults)
./splunk-export.sh

# Custom query and explicit epoch time range
./splunk-export.sh \
  -s "search index=main sourcetype=test_logs" \
  -e $(date -v-7d +%s) \
  -l $(date +%s)

# Write to a specific output file
./splunk-export.sh -o my_export.json
```
![](proof-export-script.png)

Run `./splunk-export.sh -h` for the full list of options and environment variables (`SPLUNK_URL`, `SPLUNK_USER`, `SPLUNK_PASS`).

### Next Step: Upload Exported Data to AWS S3 (automate with a script)

Once you have the exported JSON file, upload it to an S3 bucket using the AWS CLI:

```bash
# Upload a single export file
aws s3 cp splunk_export.json s3://your-bucket-name/splunk-exports/

# Upload with a date-stamped key
aws s3 cp splunk_export.json \
  "s3://your-bucket-name/splunk-exports/export-$(date +%Y-%m-%d).json"

# Upload all JSON exports in the current directory
aws s3 cp . s3://your-bucket-name/splunk-exports/ \
  --exclude "*" --include "*.json" --recursive
```

> **Prerequisites for Exprting Data to AWS S3:**
> - Install the AWS CLI: `brew install awscli` (macOS) or see [AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
> - Configure credentials: `aws configure` (requires Access Key ID, Secret Access Key, and region)
> - Ensure the target S3 bucket exists: `aws s3 mb s3://your-bucket-name`

### Troubleshooting When Initialising Splunk Enterprise

**Check the UF input status** to confirm the log file has been read:

```bash
docker exec -u splunk splunk-uf /opt/splunkforwarder/bin/splunk list inputstatus \
  -auth admin:ChangedPassword123! | grep -A5 test.log
```

You should see `file position` equal to `file size` and `type = finished reading`.

**Check the forwarding connection** from UF to the indexer:

```bash
docker exec -u splunk splunk-uf /opt/splunkforwarder/bin/splunk list forward-server \
  -auth admin:ChangedPassword123!
```

You should see `splunk:9997` under `Active forwards`.

**Check the receiving port** on Splunk Enterprise:

```bash
docker exec -u splunk splunk-enterprise /opt/splunk/bin/splunk display listen \
  -auth admin:ChangedPassword123!
```

Should output `Receiving is enabled on port 9997`.

**Check event count** on the indexer to confirm data was indexed:

```bash
docker exec -u splunk splunk-enterprise /opt/splunk/bin/splunk search \
  "| eventcount summarize=false index=main" \
  -auth admin:ChangedPassword123!
```

**Check UF container logs** for startup errors:

```bash
docker logs splunk-uf
```