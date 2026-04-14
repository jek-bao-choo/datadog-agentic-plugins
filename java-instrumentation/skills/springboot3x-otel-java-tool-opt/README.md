# springboot3x-otel-java-tool-opt

Step-by-step guide to auto-inject the OTel Java agent into **any Java process** using `JAVA_TOOL_OPTIONS`. This is the OTel equivalent of Dynatrace's LD_PRELOAD injection — no startup script changes needed, no application code changes needed.

## How it works

`JAVA_TOOL_OPTIONS` is a JVM-recognized environment variable. When set, **every JVM on the host** automatically prepends its value to the startup flags. The JVM prints `Picked up JAVA_TOOL_OPTIONS: ...` on startup to confirm.

```
Without JAVA_TOOL_OPTIONS:
  java -jar my-app.jar
  → App starts without agent

With JAVA_TOOL_OPTIONS set:
  java -jar my-app.jar
  → JVM prints: Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/...
  → OTel agent loads automatically
  → App is instrumented — traces, metrics, logs flow to OTel Collector
```

Nobody needs to edit the application's startup script, Dockerfile, or systemd unit. The infrastructure team sets `JAVA_TOOL_OPTIONS` once on the host, and every Java process picks it up on next restart.

## Comparison: injection methods

| Aspect | Dynatrace LD_PRELOAD | OTel JAVA_TOOL_OPTIONS | Datadog SSI |
|---|---|---|---|
| Mechanism | OS dynamic linker (`/etc/ld.so.preload`) | JVM built-in env var | OS dynamic linker (`/etc/ld.so.preload`) |
| Affects | ALL processes (any language) | Java processes only | ALL processes (any language) |
| Config | `/etc/ld.so.preload` | `/etc/profile.d/` + `/etc/environment` | `/etc/ld.so.preload` |
| Startup changes | None | None | None |
| App code changes | None | None | None |
| Restart needed | Yes | Yes | Yes |

For Java-only environments (like IBM webMethods ESB), `JAVA_TOOL_OPTIONS` achieves the **exact same outcome** as Dynatrace's LD_PRELOAD.

## Tech Stack

| Component | Version |
|---|---|
| OTel Java agent | v2.26.1 |
| Download | [opentelemetry-javaagent.jar](https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar) |
| Protocol | OTLP HTTP (http/protobuf) |
| Collector endpoint | http://127.0.0.1:4318 |

## Prerequisites

- OTel Collector running on `127.0.0.1:4318` (from `install-otelcol-contrib`)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`

All commands below are run **on the EC2 instance**.

---

## Step 1: Download the OTel Java agent

```bash
sudo mkdir -p /opt/otel
sudo chown ec2-user:ec2-user /opt/otel

curl -L -o /opt/otel/opentelemetry-javaagent.jar \
  https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar

ls -lh /opt/otel/opentelemetry-javaagent.jar
# Should be ~24MB
```

---

## Step 2: Set JAVA_TOOL_OPTIONS system-wide

### 2a. For login shells (SSH sessions, terminals)

```bash
sudo tee /etc/profile.d/otel-java.sh > /dev/null <<'EOF'
# OTel Java agent auto-injection — equivalent to Dynatrace LD_PRELOAD
# Includes: agent, DSM extension, XML attribute extractor, header capture
export JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar -Dloader.path=/opt/otel/extensions/ -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp -Dotel.instrumentation.http.server.capture-request-headers=transaction_id -Dotel.instrumentation.http.server.capture-response-headers=transaction_id"
EOF
```

#### What does this command do?

- `sudo tee /etc/profile.d/otel-java.sh` **creates a new file** at `/etc/profile.d/otel-java.sh`
- `/etc/profile.d/` is a directory where Linux stores shell scripts that run **automatically when any user logs in** (SSH, terminal, etc.)
- The file is created **immediately** when you run this command — it doesn't exist before this step
- After creation, any new login session will execute this script and set `JAVA_TOOL_OPTIONS`
- Existing sessions are NOT affected until you run `source /etc/profile.d/otel-java.sh` or re-login

### 2b. For non-login shells (systemd services, cron jobs)

```bash
echo 'JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar -Dloader.path=/opt/otel/extensions/ -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp -Dotel.instrumentation.http.server.capture-request-headers=transaction_id -Dotel.instrumentation.http.server.capture-response-headers=transaction_id"' | sudo tee -a /etc/environment
```

#### What does `| sudo tee -a /etc/environment` do?

- `tee -a` **appends** the text to a file (the `-a` means append; without it, `tee` overwrites the file)
- `/etc/environment` is a system-wide file that sets environment variables for **all processes**, including systemd services, cron jobs, and non-login shells
- Unlike `/etc/profile.d/` (which only runs for login shells like SSH), `/etc/environment` is read by PAM (Pluggable Authentication Modules) and affects every session
- This is important because if the Java application runs as a **systemd service** (like webMethods IS), it won't read `/etc/profile.d/` — only `/etc/environment`
- **Why both?** Step 2a covers SSH sessions (for testing). Step 2b covers systemd services (for production apps).

### 2c. Load in current session

```bash
source /etc/profile.d/otel-java.sh
echo $JAVA_TOOL_OPTIONS
# Should show: -javaagent:/opt/otel/opentelemetry-javaagent.jar ...
```

### What each flag does

| Flag | Purpose |
|---|---|
| `-javaagent:/opt/otel/opentelemetry-javaagent.jar` | Attaches OTel agent — auto-instruments Spring MVC, HTTP clients, Logback, JVM |
| `-Dotel.javaagent.extensions=.../otel-dsm-extension-1.0.jar` | Loads DSM extension — computes pathway hashes, sets `dsm.transaction.id` on spans |
| `-Dloader.path=/opt/otel/extensions/` | Adds XML attribute extractor to Spring Boot classpath — extracts `transaction_id`, `airway_bill_id`, `houseway_bill_id` from XML bodies as span attributes |
| `-Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318` | Sends telemetry to local OTel Collector (use `127.0.0.1` not `localhost` — IPv6 issue) |
| `-Dotel.exporter.otlp.protocol=http/protobuf` | OTLP HTTP protocol |
| `-Dotel.logs.exporter=otlp` | Exports Logback logs via OTLP for trace-log correlation |
| `-Dotel.metrics.exporter=otlp` | Exports JVM runtime metrics via OTLP |
| `-Dotel.instrumentation.http.server.capture-request-headers=transaction_id` | Captures `transaction_id` from incoming HTTP request headers as span attributes |
| `-Dotel.instrumentation.http.server.capture-response-headers=transaction_id` | Captures `transaction_id` from outgoing HTTP response headers as span attributes |

**Note**: The extensions are optional. Basic instrumentation (traces, metrics, logs) works with just the agent + OTLP flags. Add the extensions when you need custom span attributes or DSM.

---

## How to add more properties to JAVA_TOOL_OPTIONS

After the initial setup, you may need to add more `-D` properties (e.g., sampling rate, additional resource attributes, debug flags).

### Step-by-step: Adding a new property

**Example**: Add `-Dotel.traces.sampler=parentbased_traceidratio` and `-Dotel.traces.sampler.arg=0.5` (50% sampling)

#### 1. Edit the profile script

```bash
sudo vi /etc/profile.d/otel-java.sh
```

Change the `JAVA_TOOL_OPTIONS` line — add new `-D` flags separated by spaces:

```bash
# Before:
export JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp"

# After (added sampling flags):
export JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp -Dotel.traces.sampler=parentbased_traceidratio -Dotel.traces.sampler.arg=0.5"
```

#### 2. Also update /etc/environment (if you set it in Step 2b)

```bash
sudo vi /etc/environment
```

Update the same `JAVA_TOOL_OPTIONS` line with the new flags.

#### 3. Is a restart required?

**Yes — you must restart the Java application.** `JAVA_TOOL_OPTIONS` is read by the JVM **only at startup**. Changing the environment variable while the app is running has no effect. The app must be restarted for the new properties to take effect.

#### 4. Is a status check required?

**Yes — verify the new flags were picked up.** After restart, check the application's stdout/log for:

```
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/... -Dotel.traces.sampler=parentbased_traceidratio -Dotel.traces.sampler.arg=0.5
```

If the new flags don't appear, the environment variable wasn't loaded. Re-source the profile or re-login.

#### 5. What is the next step after adding?

After verifying the flags are picked up:
1. Send test traffic to the application
2. Check Datadog APM to verify the new behavior (e.g., reduced trace volume if sampling was enabled)
3. Check application logs for any OTel agent warnings

### Summary: after-change checklist

| Step | Action | Why |
|---|---|---|
| Edit `/etc/profile.d/otel-java.sh` | Add new `-D` flags | Profile script for login shells |
| Edit `/etc/environment` | Add same flags | For systemd services |
| Source profile or re-login | `source /etc/profile.d/otel-java.sh` | Apply to current session |
| Restart the Java application | See Step 4 below | JVM reads env var only at startup |
| Check startup log | Look for `Picked up JAVA_TOOL_OPTIONS` | Verify flags were picked up |
| Send test traffic | curl or traffic generator | Verify instrumentation works |
| Check Datadog APM | Search for service traces | Verify end-to-end |

---

## Step 3: Set per-application service name

`JAVA_TOOL_OPTIONS` applies to ALL Java processes on the host. Each application needs its own service name so they appear as separate services in Datadog APM.

**Important: `otel.service.name` is intentionally NOT in JAVA_TOOL_OPTIONS** — if it were, every Java process would have the same service name, making them indistinguishable in Datadog.

### If you have access to the application code or config

**Option A: spring.application.name** (in the app's `application.properties`)
```properties
spring.application.name=jek-otel-java-springboot3x-camel
```
The OTel agent reads this automatically as the service name.

### If you do NOT have access to the application code

This is the common case for infrastructure teams managing webMethods or other vendor software. Use one of these approaches:

**Option B: OTEL_SERVICE_NAME environment variable**

Set it in the app's systemd unit file (no code changes):

```bash
# Find the systemd unit for the application
sudo systemctl cat webmethods-is   # or whatever the service name is

# Create an override that adds the env var
sudo systemctl edit webmethods-is
```

In the override editor, add:

```ini
[Service]
Environment="OTEL_SERVICE_NAME=webmethods-esb"
```

Save and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart webmethods-is
```

This sets the service name **without touching the application code, startup script, or JAR**.

**Option C: System-wide OTEL_SERVICE_NAME** (if only one Java app on the host)

```bash
echo 'OTEL_SERVICE_NAME="webmethods-esb"' | sudo tee -a /etc/environment
```

Only use this if there's a single Java application on the host. If multiple apps run on the same host, use Option B (per-service override).

**Option D: otel.resource.attributes in JAVA_TOOL_OPTIONS**

Add `-Dotel.resource.attributes=service.name=webmethods-esb` to JAVA_TOOL_OPTIONS. But note: this applies to ALL Java processes on the host.

### Which option for webMethods ESB?

For prospects running IBM webMethods where the infrastructure team manages the host but doesn't own the application code:

1. Use **Option B** (systemd override) — adds `OTEL_SERVICE_NAME` to the webMethods systemd unit
2. No application code changes
3. No startup script changes
4. The infrastructure team can do this independently

---

## Step 4: Restart your Java application

### If you manage the application directly

```bash
# Stop current instance
pkill -f springboot3x-camel 2>/dev/null
sleep 2

# Start — no -javaagent needed, JAVA_TOOL_OPTIONS handles it
cd /opt/cargostream/component-c
java -jar target/springboot3x-camel-0.0.1-SNAPSHOT.jar
```

### If the application runs as a systemd service (common for webMethods, Tomcat, etc.)

**You don't need access to the application code to restart a systemd service.** The infrastructure team uses standard Linux service management:

```bash
# Check the service name
sudo systemctl list-units | grep -i webmethods

# Restart the service (this triggers JAVA_TOOL_OPTIONS pickup)
sudo systemctl restart webmethods-is

# Check it started successfully
sudo systemctl status webmethods-is
```

After restart, verify the OTel agent loaded by checking the application's log file:

```bash
# Find the log file (varies by application)
sudo journalctl -u webmethods-is --no-pager -n 20 | grep "Picked up JAVA_TOOL_OPTIONS"

# Or check the application's own log directory
grep "Picked up JAVA_TOOL_OPTIONS" /opt/webmethods/IntegrationServer/logs/server.log
```

You should see:

```
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/opentelemetry-javaagent.jar ...
[otel.javaagent] opentelemetry-javaagent - version: 2.26.1
```

### If the application is managed by a process manager (like webMethods IS)

Some applications have their own restart mechanism:

```bash
# webMethods Integration Server example
cd /opt/webmethods/IntegrationServer/bin
./shutdown.sh
sleep 10
./startup.sh
```

The key point: **you don't need to change the startup script**. The JVM will pick up `JAVA_TOOL_OPTIONS` from the environment regardless of how it's started.

### What if the application team needs to do the restart?

Provide them with these instructions:

1. "We've set up `JAVA_TOOL_OPTIONS` on the host. No code changes needed."
2. "Please restart the webMethods Integration Server at your convenience."
3. "After restart, look for `Picked up JAVA_TOOL_OPTIONS` in the startup log."
4. "The OTel agent will load automatically — you should see `[otel.javaagent] opentelemetry-javaagent - version: 2.26.1` in the log."

On startup you should see:

```
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/opentelemetry-javaagent.jar ...
[otel.javaagent] opentelemetry-javaagent - version: 2.26.1
Started Springboot3xCamelApplication in X.XX seconds
```

---

## Step 5: Verify in Datadog

### 5a. Health check

```bash
curl -s http://localhost:8083/health
```

### 5b. Send test JSON (Component C → Component D chain)

```bash
curl -X POST http://localhost:8083/jek-process \
  -H "Content-Type: application/json" \
  -H "transaction_id: TX-TOOL-OPT-001" \
  -d '{"transaction_id": "TX-TOOL-OPT-001", "airway_bill_id": "AWB-TOOL-OPT-001"}'
```

### 5c. Check Datadog APM (wait 1-2 minutes)

Go to **APM > Traces**. Search for `service:jek-otel-java-springboot3x-camel`.

You should see:
- Incoming span for POST `/jek-process`
- Apache Camel route spans (JSON→XML transformation)
- Outgoing HTTP span to Component D at `localhost:8084/jek-receive-xml`
- **Distributed trace linking C → D** via W3C traceparent propagation

### 5d. Generate traffic (10 requests, 10s intervals)

```bash
./scripts/send-traffic.sh
```

Or manually:

```bash
for i in $(seq 1 10); do
  curl -sf -o /dev/null -w "HTTP %{http_code}\n" -X POST http://localhost:8083/jek-process \
    -H "Content-Type: application/json" \
    -H "transaction_id: TX-CAMEL-${i}" \
    -d "{\"transaction_id\": \"TX-CAMEL-${i}\", \"airway_bill_id\": \"AWB-CAMEL-${i}\"}"
  sleep 10
done
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| No `Picked up JAVA_TOOL_OPTIONS` on startup | Source the profile: `source /etc/profile.d/otel-java.sh` or re-login |
| `JAVA_TOOL_OPTIONS` not picked up by systemd service | Add to `/etc/environment` (Step 2b) and run `sudo systemctl daemon-reload` then restart the service |
| Agent JAR not found | Check `ls /opt/otel/opentelemetry-javaagent.jar` — re-download if missing (Step 1) |
| Metrics export fails (IPv6) | Ensure endpoint uses `127.0.0.1` not `localhost` |
| Multiple Java apps with same service name | Set `OTEL_SERVICE_NAME` per service via systemd override (Step 3 Option B) |
| Don't know which Java processes are running | `ps aux \| grep java` shows all Java processes on the host |

---

## About the bundled scripts

### What is `setup-java-tool-options.sh`?

This script **automates Steps 1 and 2** in a single command. It:

1. Downloads the OTel Java agent JAR to `/opt/otel/` (if not already there)
2. Creates `/etc/profile.d/otel-java.sh` (for login shells)
3. Adds `JAVA_TOOL_OPTIONS` to `/etc/environment` (for systemd services)

```bash
sudo ./scripts/setup-java-tool-options.sh
# Optional: custom collector endpoint
sudo ./scripts/setup-java-tool-options.sh http://otel-collector.internal:4318
```

**When to use it**: Quick setup for PoC or development. Run once, restart apps, done.

### What is `remove-java-tool-options.sh`?

This script **reverses everything** that `setup-java-tool-options.sh` did:

1. Deletes `/etc/profile.d/otel-java.sh`
2. Removes the `JAVA_TOOL_OPTIONS` line from `/etc/environment`
3. Unsets `JAVA_TOOL_OPTIONS` in the current session

```bash
sudo ./scripts/remove-java-tool-options.sh
# Then restart apps to stop the agent from loading
```

**When to use it**: When the PoC is over, when switching to a different agent (Datadog SSI), or when troubleshooting conflicts.

**Note**: Neither script touches the agent JAR at `/opt/otel/opentelemetry-javaagent.jar` — it's left in place. Delete it manually if needed: `rm /opt/otel/opentelemetry-javaagent.jar`

### Alternatives if the prospect doesn't want to use these scripts

The scripts are convenience wrappers. If the prospect prefers not to run third-party scripts on their servers (common in enterprise environments), they can do everything manually:

**Alternative 1: Manual setup (same steps, no script)**

Follow Steps 1 and 2 in this README manually. The commands are the same ones the script runs — copy-paste from the README.

**Alternative 2: Configuration management (Ansible, Puppet, Chef)**

Add the environment variable through the prospect's existing configuration management:

```yaml
# Ansible example
- name: Download OTel Java agent
  get_url:
    url: https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.26.1/opentelemetry-javaagent.jar
    dest: /opt/otel/opentelemetry-javaagent.jar

- name: Set JAVA_TOOL_OPTIONS system-wide
  lineinfile:
    path: /etc/environment
    line: 'JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp"'
    create: yes
```

**Alternative 3: Systemd drop-in (per-service, most controlled)**

Instead of setting `JAVA_TOOL_OPTIONS` host-wide, set it only for the specific service:

```bash
sudo systemctl edit webmethods-is
```

Add:

```ini
[Service]
Environment="JAVA_TOOL_OPTIONS=-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp"
Environment="OTEL_SERVICE_NAME=webmethods-esb"
```

This approach:
- Only affects that one service (not all Java processes)
- Uses the standard systemd override mechanism
- Survives service restarts and package updates
- Is reversible: `sudo systemctl revert webmethods-is`

**Alternative 4: Docker / container environment variable**

If the app runs in Docker:

```bash
docker run -e JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar ..." \
  -v /opt/otel:/opt/otel:ro \
  my-java-app
```

Or in `docker-compose.yml`:

```yaml
services:
  webmethods:
    environment:
      - JAVA_TOOL_OPTIONS=-javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.exporter.otlp.endpoint=http://otel-collector:4318 -Dotel.exporter.otlp.protocol=http/protobuf
      - OTEL_SERVICE_NAME=webmethods-esb
    volumes:
      - /opt/otel:/opt/otel:ro
```

### Which alternative should the prospect use?

| Prospect's environment | Recommended approach |
|---|---|
| PoC / dev / testing | Scripts (`setup-java-tool-options.sh`) or manual Steps 1-2 |
| Enterprise with config management | Alternative 2 (Ansible/Puppet/Chef) |
| Single app on the host | Alternative 3 (systemd drop-in) |
| Multiple apps, different configs | Alternative 3 (one systemd drop-in per service) |
| Containerized / Docker / K8s | Alternative 4 (container env var) |
| Prospect won't run any scripts | Manual Steps 1-2 (copy-paste commands from README) |

---

## Teardown

```bash
# Remove system-wide JAVA_TOOL_OPTIONS
sudo rm -f /etc/profile.d/otel-java.sh
sudo sed -i '/JAVA_TOOL_OPTIONS/d' /etc/environment
unset JAVA_TOOL_OPTIONS

# Restart apps to stop the agent
pkill -f springboot3x 2>/dev/null
```

Or use the cleanup script:

```bash
sudo ./scripts/remove-java-tool-options.sh
```
