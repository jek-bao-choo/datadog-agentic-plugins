# Spring Boot 3.5.9 REST API

## Overview

This application provides three REST API endpoints, each configured with different logging destinations:
- **GET /api/data**: Returns JSON data with lorem ipsum text and random number, logs to **Console**
- **POST /api/submit**: Accepts JSON payload, logs to **Syslog**
- **PUT /api/update**: Returns status code only, logs to **File** (logs/app.log)

All endpoints randomly return HTTP status codes based on probability:
- **30% chance**: 2XX codes (200, 201, 204)
- **40% chance**: 4XX codes (400, 404, 409)
- **30% chance**: 5XX codes (500, 503)

## Tech Stack

- **Spring Boot**: 3.5.9
- **Java**: OpenJDK 17.0.17
- **Embedded Server**: Apache Tomcat 10.1.50 (included in Spring Boot)
- **Build Tool**: Maven (with wrapper)
- **Logging**: SLF4J + Logback with JSON formatting (logstash-logback-encoder)
- **Testing**: JUnit 5 + Playwright Java

## Prerequisites

- **Java 17** or higher (OpenJDK 17.0.17 recommended) — not needed if using Docker
- **Maven 3.6.3+** (Maven wrapper included, so local Maven installation optional) — not needed if using Docker
- **Docker** (optional) — for containerized builds and running
- **kubectl** (optional) — for Kubernetes deployment
- **Operating System**: macOS, Linux, or Windows

Verify Java installation:
```bash
java -version
```
Should show: openjdk version "17.0.17" or higher

## Project Structure

```
references/
├── src/
│   ├── main/
│   │   ├── java/com/jek/.../
│   │   │   ├── controller/
│   │   │   │   └── ApiController.java          # REST API endpoints
│   │   │   ├── service/
│   │   │   │   └── StatusCodeGenerator.java    # Random status code logic
│   │   │   └── ...Application.java              # Spring Boot main class
│   │   └── resources/
│   │       ├── application.properties           # App configuration
│   │       └── logback-spring.xml               # Logging configuration
│   └── test/
│       └── java/com/jek/.../
│           └── ApiEndpointTest.java             # Playwright integration tests
├── k8s/
│   ├── deployment.yaml                          # Deployment with health probes + Datadog APM tracer
│   └── service.yaml                             # ClusterIP Service (80 → 8080)
├── logs/
│   └── app.log                                  # PUT endpoint logs (JSON)
├── target/
│   └── *.jar                                    # Compiled JAR file
├── Dockerfile                                   # Multi-stage build (JDK → JRE)
├── .dockerignore                                # Excludes .git/, target/, logs/
├── pom.xml                                      # Maven dependencies
├── mvnw                                         # Maven wrapper (Unix)
├── mvnw.cmd                                     # Maven wrapper (Windows)
└── README.md                                    # This file
```

## Setup Instructions

### 1. Clone or Navigate to Project

```bash
cd /path/to/springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback
```

### 2. Verify Prerequisites

```bash
# Check Java version
java -version

# Check Maven wrapper
./mvnw -version
```

### 3. Build the Project

```bash
# Clean and build
./mvnw clean package

# Build output will be in target/ directory
ls -lh target/*.jar
```

## Running the Application

### Option 1: Using Maven Wrapper (Development)

```bash
./mvnw spring-boot:run
```

The application will start on **http://localhost:8080**

You should see output like:
```
Started Springboot3dot5dot9...Application in X.XXX seconds
```

### Option 2: Running the JAR File (Production)

```bash
# Build the JAR first
./mvnw clean package

# Run the JAR
java -jar target/springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar
```

### Option 3: Running with Docker

```bash
# Build the Docker image (multi-stage: JDK build + JRE runtime)
docker build -t asia-southeast1-docker.pkg.dev/datadog-ese-sandbox/jek-java-apps/springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT .

# Run the container
docker run -p 8080:8080 asia-southeast1-docker.pkg.dev/datadog-ese-sandbox/jek-java-apps/springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT
```

The Docker image:
- Uses **multi-stage build** (JDK 17 for build, JRE 17 for runtime — smaller image)
- Runs as **non-root user** (`appuser`) for security
- Uses `-XX:MaxRAMPercentage=75.0` so heap scales with container memory limits
- Caches Maven dependencies in a separate layer for faster rebuilds

The image is also available on **ghcr.io** as a public package:
- `ghcr.io/jek-bao-choo/springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT`
- When pushing a new image to ghcr.io, make it public after the first push: go to https://github.com/users/jek-bao-choo/packages/container/package/springboot3dot5dot9-sandbox → Package settings → Danger Zone → Change package visibility → Public. Subsequent pushes to the same package name remain public.

### Option 4: Running on Kubernetes

```bash
# Build for linux/amd64 (required when building on Apple Silicon for GKE)
docker buildx build --platform linux/amd64 \
  -t asia-southeast1-docker.pkg.dev/datadog-ese-sandbox/jek-java-apps/springboot3dot5dot9-sandbox:0.0.1-SNAPSHOT \
  --push .

# Deploy all K8s resources (deployment, service) to default namespace
kubectl apply -f k8s/

# Verify deployment
kubectl rollout status deployment/springboot3dot5dot9-sandbox
kubectl get pods

# Access via port-forward
kubectl port-forward svc/springboot3dot5dot9-sandbox 8080:80
curl http://localhost:8080/api/data
```

The Kubernetes deployment includes:
- **2 replicas** for availability
- **Startup probe** (up to 70s for JVM boot), **liveness probe**, and **readiness probe** on `/actuator/health`
- **Resource limits**: 256Mi–512Mi memory, 250m–1 CPU
- **emptyDir volumes** for `/app/logs` and `/datadog-lib`
- **Datadog APM tracer** via init container injection (see [Datadog APM Tracing](#datadog-apm-tracing-manual-init-container-injection) section)
- **ClusterIP Service** mapping port 80 → 8080
- **imagePullSecrets** referencing `ghcr-secret` (for clusters with restricted egress; not needed when using Artifact Registry on GKE)

**Note**: The POST endpoint's syslog appender targets `localhost:514`, which won't exist in a K8s pod — it will fail silently. This only affects the POST endpoint's syslog logging; the endpoint itself still works.

## Datadog APM Tracing (Manual Init Container Injection)

The deployment uses **manual init container patching** to inject the Datadog Java tracer (`dd-java-agent.jar`) into the Spring Boot pods. This approach is preferred over the Datadog admission controller webhook, which automatically excludes the namespace where the Datadog Operator/Agent is deployed (typically `default`). Manual patching gives you explicit control and works regardless of namespace.

### How It Works

Three pieces are added to the deployment spec:

**1. Init container** — copies `dd-java-agent.jar` from Datadog's official image into a shared volume:

```yaml
initContainers:
  - name: datadog-lib-java-init
    image: gcr.io/datadoghq/dd-lib-java-init:latest
    command:
      - sh
      - -c
      - cp /datadog-init/package/dd-java-agent.jar /datadog-lib/dd-java-agent.jar
    volumeMounts:
      - name: datadog-lib
        mountPath: /datadog-lib
```

**2. Environment variables** — on the app container, `JAVA_TOOL_OPTIONS` attaches the agent, and `DD_*` vars configure the tracer:

```yaml
env:
  - name: JAVA_TOOL_OPTIONS
    value: "-javaagent:/datadog-lib/dd-java-agent.jar"
  - name: DD_SERVICE
    value: "springboot3dot5dot9-sandbox"
  - name: DD_ENV
    value: "sandbox"
  - name: DD_AGENT_HOST
    value: "datadog-agent.default.svc.cluster.local"
  - name: DD_PROFILING_ENABLED
    value: "auto"
  - name: DD_LOGS_INJECTION
    value: "true"
  - name: DD_TRACE_SAMPLE_RATE
    value: "1"
  - name: DD_RUNTIME_METRICS_ENABLED
    value: "true"
```

**3. Shared volume** — an `emptyDir` volume mounted in both the init container and app container:

```yaml
# In the app container's volumeMounts:
- name: datadog-lib
  mountPath: /datadog-lib

# In the volumes section:
- name: datadog-lib
  emptyDir: {}
```

### Key Details

- **Init image**: `gcr.io/datadoghq/dd-lib-java-init:latest` — the jar is at `/datadog-init/package/dd-java-agent.jar` inside this image
- **DD_AGENT_HOST**: Points to the `datadog-agent` ClusterIP Service FQDN (`datadog-agent.default.svc.cluster.local`), which load-balances across all DaemonSet agent pods on port 8126. If the Datadog Agent DaemonSet exposes port 8126 via `hostPort`, you can use `status.hostIP` instead (via a `fieldRef`) to route traces directly to the node-local agent
- **DD_TRACE_SAMPLE_RATE**: Set to `1` (100%) for sandbox/testing. Lower this in production

### Why Manual Init Container Instead of the Admission Controller Webhook

The Datadog Operator manages a `MutatingWebhookConfiguration` called `datadog-webhook` that can auto-inject the Java tracer on pod creation. However, the operator **always excludes its own namespace** from the webhook's `namespaceSelector`. If the Datadog Agent is deployed in the `default` namespace, pods in `default` will never be intercepted by the webhook — even with `enabledNamespaces: ["default"]` in the `DatadogAgent` CR.

Manual init container patching avoids this limitation entirely and has the added benefit of making the instrumentation explicit and version-controlled in the deployment manifest.

### Applying and Verifying

```bash
# Apply the deployment (init container + env vars are already in k8s/deployment.yaml)
kubectl apply -f k8s/

# Wait for rollout
kubectl rollout status deployment/springboot3dot5dot9-sandbox

# Verify init container exists
kubectl get pods -l app=springboot3dot5dot9-sandbox \
  -o jsonpath='{.items[0].spec.initContainers[*].name}'
# Expected: datadog-lib-java-init

# Verify DD env vars
kubectl get pods -l app=springboot3dot5dot9-sandbox \
  -o jsonpath='{range .items[0].spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}' \
  | grep -E 'DD_|JAVA_TOOL'

# Check tracer initialization in pod logs (look for agent_error: false)
kubectl logs -l app=springboot3dot5dot9-sandbox --tail=30 \
  | grep "DATADOG TRACER CONFIGURATION"
```

### Generating Traffic and Viewing Traces

```bash
# Port-forward to the service
kubectl port-forward svc/springboot3dot5dot9-sandbox 8080:80 &
PF_PID=$!
sleep 2

# Hit all three endpoints for ~2 minutes (60 iterations × 3 endpoints = 180 requests)
# This sustained traffic ensures enough data for APM traces and runtime metrics to populate
for i in $(seq 1 60); do
  curl -s http://localhost:8080/api/data > /dev/null
  curl -s -X POST http://localhost:8080/api/submit \
    -H "Content-Type: application/json" \
    -d "{\"key\":\"test\",\"iteration\":$i}" > /dev/null
  curl -s -X PUT http://localhost:8080/api/update > /dev/null
  sleep 2
done

kill $PF_PID 2>/dev/null
```

After traffic generation, verify traces are being received by the agent and DogStatsD is processing runtime metrics:

```bash
# Verify traces are received by the agent
kubectl exec $(kubectl get pods -l app.kubernetes.io/component=agent -o name | head -1) \
  -c agent -- agent status 2>/dev/null | grep -A 10 "Receiver (previous minute)"

# Verify DogStatsD is receiving JVM runtime metrics (metric packet count should be growing)
kubectl exec $(kubectl get pods -l app.kubernetes.io/component=agent -o name | head -1) \
  -c agent -- agent status 2>/dev/null | grep -A 15 "DogStatsD"
```

Traces should appear in the Datadog UI under **APM > Traces**, filtered by `service:springboot3dot5dot9-sandbox` and `env:sandbox`.

### JVM Runtime Metrics

The Datadog Java tracer (`dd-java-agent.jar`) also collects **JVM runtime metrics** — heap memory, GC, threads, class loading — and sends them via **DogStatsD (UDP port 8125)** to the same `DD_AGENT_HOST`. The deployment sets `DD_RUNTIME_METRICS_ENABLED=true` explicitly for clarity (it defaults to `true` for Java).

**How it works:**
- The tracer sends metrics via UDP to `DD_AGENT_HOST:8125` (DogStatsD)
- The `datadog-agent` ClusterIP Service exposes port `8125/UDP`, routing to the agent DaemonSet
- No additional agent configuration is needed — DogStatsD is enabled by default

#### Detecting and Troubleshooting JVM Memory Leaks

Use these Datadog JVM metrics (emitted by `dd-java-agent` via DogStatsD) to detect and diagnose memory leaks:

| Metric | What to watch for |
|--------|-------------------|
| `jvm.heap_memory` / `jvm.heap_memory_max` | If heap usage trends upward over time and doesn't drop after GC, suspect a leak |
| `jvm.non_heap_memory` | Rising non-heap (Metaspace) can indicate classloader leaks |
| `jvm.gc.old_gen_size` | Old generation growing continuously means objects aren't being collected |
| `jvm.gc.major_collection_count` / `jvm.gc.major_collection_time` | Increasing frequency and duration of full GCs is a key leak symptom |
| `jvm.gc.minor_collection_count` / `jvm.gc.minor_collection_time` | Young generation GC stats — compare with major GC trends |
| `jvm.gc.eden_size` / `jvm.gc.survivor_size` | Memory pool sizes for young generation |
| `jvm.gc.metaspace_size` | Metaspace growth — watch for continuous increase |
| `jvm.buffer_pool.direct.used` / `jvm.buffer_pool.direct.capacity` | Direct buffer leaks (off-heap memory) |
| `jvm.buffer_pool.mapped.used` / `jvm.buffer_pool.mapped.capacity` | Mapped buffer leaks |

#### Monitoring JVM Thread Utilization

| Metric | What to watch for |
|--------|-------------------|
| `jvm.thread_count` | Total live threads — a steadily increasing count indicates a thread leak |
| `jvm.loaded_classes` | Class count growth can correlate with thread/classloader issues |
| `jvm.cpu_load.process` / `jvm.cpu_load.system` | High CPU with high thread count may indicate runaway threads |

#### Where to View in Datadog

- **APM > Services > `springboot3dot5dot9-sandbox`** → **Runtime Metrics** sidebar (set `env` to `sandbox`) — shows pre-built graphs for heap, non-heap, GC, and threads
- **Metrics > Explorer** → search any metric name above, filter by `service:springboot3dot5dot9-sandbox`, `env:sandbox`
- **Dashboards** → create custom dashboards with these metrics for ongoing monitoring
- **Monitors** → set alerts on `jvm.heap_memory` approaching `jvm.heap_memory_max`, or `jvm.thread_count` exceeding thresholds

**Important**: The deployment sets `DD_ENV=sandbox`, so ensure the `env` filter in the Datadog UI is set to **`sandbox`** (not `none`). Traces and metrics will not appear if filtered by the wrong environment.

### Stopping the Application

- **If running in foreground**: Press `Ctrl+C`
- **If running in background**: `pkill -f spring-boot` or `pkill -f springboot3dot5dot9`
- **If running in Docker**: `docker stop <container-id>`
- **If running on Kubernetes**: `kubectl delete -f k8s/`

## API Endpoints

### 1. GET /api/data

Returns JSON data with lorem ipsum text and a 5-digit random number.

**Request:**
```bash
curl http://localhost:8080/api/data
```

**Response Example (Status 201):**
```json
{
  "randomNumber": 45678,
  "loremIpsum": "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
  "statusCode": 201,
  "timestamp": 1768928098146
}
```

**Logging**: Console (JSON format)

---

### 2. POST /api/submit

Accepts JSON payload and returns acknowledgment.

**Request:**
```bash
curl -X POST http://localhost:8080/api/submit \
  -H "Content-Type: application/json" \
  -d '{"test": "data", "user": "john"}'
```

**Response Example (Status 400):**
```json
{
  "status": "received",
  "message": "Data submitted successfully",
  "receivedPayload": {
    "test": "data",
    "user": "john"
  },
  "statusCode": 400,
  "timestamp": 1768928110896
}
```

**Logging**: Syslog (JSON format)

---

### 3. PUT /api/update

Returns only HTTP status code with no response body.

**Request:**
```bash
curl -X PUT http://localhost:8080/api/update -v
```

**Response:**
- Status code only (e.g., `HTTP/1.1 503`)
- No response body

**Logging**: File at `logs/app.log` (JSON format)

---

## curl Testing Examples

### Test All Endpoints

```bash
# Test GET endpoint
curl -v http://localhost:8080/api/data

# Test POST endpoint
curl -v -X POST http://localhost:8080/api/submit \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "value": 123}'

# Test PUT endpoint
curl -v -X PUT http://localhost:8080/api/update
```

### Test Multiple Times (Verify Random Status Codes)

```bash
# Test GET endpoint 10 times
for i in {1..10}; do
  echo "Request $i:"
  curl -s http://localhost:8080/api/data | grep statusCode
  echo ""
done
```

### Pretty Print JSON Responses

```bash
# Using Python (macOS/Linux)
curl -s http://localhost:8080/api/data | python3 -m json.tool

# Using jq (if installed)
curl -s http://localhost:8080/api/data | jq
```

## Logging Configuration

The application uses **Logback** with **JSON formatting** via `logstash-logback-encoder`. The logback file is at `/src/main/resources/logback-spring.xml`.

### Three Logging Destinations

1. **Console Appender** (GET endpoint)
   - Format: JSON
   - Output: Standard output (console)

2. **Syslog Appender** (POST endpoint)
   - Format: JSON
   - Output: Local syslog (localhost:514)
   - Note: Requires syslog daemon running

3. **File Appender** (PUT endpoint)
   - Format: JSON
   - Output: `logs/app.log`

### View Logs

```bash
# View console logs (GET endpoint)
# Logs appear in terminal where app is running

# View file logs (PUT endpoint)
cat logs/app.log

# Tail file logs in real-time
tail -f logs/app.log

# View syslog (macOS)
log show --predicate 'process == "java"' --last 10m

# View syslog (Linux)
tail -f /var/log/syslog | grep java
```

### Example Log Entry (JSON Format)

```json
{
  "@timestamp": "2026-01-21T00:54:58.146656+08:00",
  "@version": "1",
  "message": "GET /api/data - Status: 201 - RandomNumber: 99958",
  "logger_name": "com.jek...controller.GetEndpoint",
  "thread_name": "http-nio-8080-exec-1",
  "level": "INFO",
  "level_value": 20000
}
```

## Running Tests

The project includes Playwright integration tests for all endpoints.

### Run All Tests

```bash
./mvnw test
```

### Expected Output

```
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

### Tests Included

1. **testGetEndpoint**: Verifies GET /api/data returns valid status code
2. **testPostEndpoint**: Verifies POST /api/submit accepts JSON payload
3. **testPutEndpoint**: Verifies PUT /api/update returns status code
4. **testStatusCodeVariation**: Verifies different status codes across 20 requests
5. **testStatusCodeProbability**: Verifies ~30-40-30 distribution across 100 requests

### Run Specific Test

```bash
./mvnw test -Dtest=ApiEndpointTest#testGetEndpoint
```

## Ubuntu Linux Deployment

### Step 1: Install Java on Ubuntu

```bash
# Update package list
sudo apt update

# Install OpenJDK 17
sudo apt install openjdk-17-jdk

# Verify installation
java -version
```

### Step 2: Transfer JAR to Ubuntu Server

**Option A: Using scp (preferred)**
```bash
# From your local machine
scp -i "~/.ssh/<key file name>" target/springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar \ 
  ubuntu@xxxxxx.com:/home/ubuntu/
```

**Option B: Using rsync**
```bash
# From your local machine
rsync -avz target/*.jar user@ubuntu-server:/home/user/app/
```

### Step 3: Run Application on Ubuntu

```bash
# SSH into Ubuntu server
ssh user@ubuntu-server

# Navigate to app directory
cd /home/user/app

# Run the JAR file
java -jar springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar
```

### Step 4: Run as Background Process

```bash
# Run in background with nohup
nohup java -jar springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar \
  > output.log 2>&1 &

# Get process ID
echo $!
```

### Step 5: Verify Application is Running

```bash
# Check Java process
ps aux | grep java

# Check port 8080
netstat -tlnp | grep 8080
# or
ss -tlnp | grep 8080

# Test endpoint
curl http://localhost:8080/api/data
```

### Step 6: Stop Application

```bash
# Find process ID
ps aux | grep springboot3dot5dot9

# Kill process
kill <PID>

# Or force kill
pkill -f springboot3dot5dot9
```


## Collect JMX metrics

This application includes **Spring Boot Actuator** with JMX and JVM metrics enabled by default. The `spring-boot-starter-actuator` dependency and metric configuration are already included — no additional setup is required.

Once the application is running, JVM metrics (memory, threads, GC, classes) are exposed via HTTP at `/actuator/metrics` and via JMX.

### Checking if JMX is Enabled

**Method 1: Check Actuator Endpoints**
```bash
# Verify Actuator is responding
curl http://localhost:8080/actuator

# List all available metrics
curl http://localhost:8080/actuator/metrics
```

**Method 2: Check if JMX Port is Listening**
```bash
# While your Java app is running, check for JMX port (default 9010 or configured port)
netstat -an | grep 9010
# or
lsof -i :9010
```

**Method 3: Check JVM Arguments**
```bash
# Look for JMX-related arguments in the running process
ps aux | grep java | grep "jmxremote"
```

### Customizing JMX Configuration

JMX and Actuator metrics are already configured in `application.properties`:

```properties
spring.jmx.enabled=true
management.endpoints.web.exposure.include=health,metrics
management.endpoint.health.show-details=always
management.metrics.enable.jvm=true
```

**For remote JMX access**, add JVM arguments when starting the application:

```bash
java -Dcom.sun.management.jmxremote \
     -Dcom.sun.management.jmxremote.port=9010 \
     -Dcom.sun.management.jmxremote.local.only=false \
     -Dcom.sun.management.jmxremote.authenticate=false \
     -Dcom.sun.management.jmxremote.ssl=false \
     -jar target/springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar
```

**Override configuration via command line:**

```bash
java -jar target/springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar \
  --management.endpoints.web.exposure.include=health,metrics,info
```

### Spring Boot Actuator Setup

Spring Boot Actuator is already configured in this project. The `spring-boot-starter-actuator` dependency is included in `pom.xml`, and metric endpoints are configured in `application.properties`.

The following endpoints are exposed:
- `GET /actuator/health` — Application health status with details
- `GET /actuator/metrics` — List of all available metric names
- `GET /actuator/metrics/{metric.name}` — Detailed values for a specific metric

### JVM Metrics Exposed

#### 1. Memory Usage Metrics
- **jvm.memory.used**: Current memory usage (heap and non-heap)
- **jvm.memory.committed**: Memory guaranteed to be available
- **jvm.memory.max**: Maximum memory available
- **jvm.buffer.memory.used**: Buffer pool memory usage
- **jvm.buffer.count**: Number of buffers

**Why Important**: Monitor memory consumption, detect memory leaks, and optimize heap size settings.

#### 2. Garbage Collection Metrics
- **jvm.gc.pause**: GC pause duration and frequency
- **jvm.gc.memory.allocated**: Total memory allocated
- **jvm.gc.memory.promoted**: Memory promoted from young to old generation
- **jvm.gc.live.data.size**: Size of old generation after full GC

**Why Important**: Identify GC pressure, tune GC settings, and optimize application performance.

#### 3. Thread and Concurrency Metrics
- **jvm.threads.live**: Current number of live threads
- **jvm.threads.daemon**: Number of daemon threads
- **jvm.threads.peak**: Peak number of live threads
- **jvm.threads.states**: Thread count by state (runnable, blocked, waiting, etc.)

**Why Important**: Detect thread leaks, monitor thread pool usage, and identify concurrency issues.

#### 4. Class Loading Metrics
- **jvm.classes.loaded**: Number of classes currently loaded
- **jvm.classes.unloaded**: Total number of classes unloaded since JVM start

### Querying Metrics via curl

```bash
# List all available metrics
curl -s http://localhost:8080/actuator/metrics | jq

# Thread utilization
curl -s http://localhost:8080/actuator/metrics/jvm.threads.live | jq
curl -s http://localhost:8080/actuator/metrics/jvm.threads.states | jq

# Memory usage
curl -s http://localhost:8080/actuator/metrics/jvm.memory.used | jq
curl -s http://localhost:8080/actuator/metrics/jvm.memory.max | jq

# Garbage collection
curl -s http://localhost:8080/actuator/metrics/jvm.gc.pause | jq

# Application health
curl -s http://localhost:8080/actuator/health | jq
```


## Troubleshooting

### Port 8080 Already in Use

```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or change port in application.properties
echo "server.port=8081" >> src/main/resources/application.properties
```

### Java Version Issues

```bash
# Check Java version
java -version

# On macOS with SDKMAN
sdk list java
sdk use java 17.0.17-tem

# On Ubuntu
sudo update-alternatives --config java
```

### Build Failures

```bash
# Clean Maven cache
./mvnw clean

# Delete target directory
rm -rf target/

# Rebuild
./mvnw clean package
```

### Logs Not Appearing in File

```bash
# Check logs directory exists
ls -la logs/

# Create logs directory if missing
mkdir -p logs

# Check file permissions
chmod 755 logs
```

### Syslog Not Receiving Logs

On macOS, syslog configuration may require additional setup. For testing, you can:
1. Check Console.app for log entries
2. Or modify `logback-spring.xml` to use file appender instead

On Linux:
```bash
# Ensure rsyslog is running
sudo systemctl status rsyslog

# Check syslog file
tail -f /var/log/syslog
```

## Project Cleanup

```bash
# Remove build artifacts
./mvnw clean

# Remove log files
rm -rf logs/

# Remove all generated files
rm -rf target/ logs/
```

## Status Code Probabilities

The application uses weighted random generation:

| Status Code | Description | Probability | Implementation |
|------------|-------------|-------------|----------------|
| 200 | OK | ~10% | Part of 30% 2XX |
| 201 | Created | ~10% | Part of 30% 2XX |
| 204 | No Content | ~10% | Part of 30% 2XX |
| 400 | Bad Request | ~13% | Part of 40% 4XX |
| 404 | Not Found | ~13% | Part of 40% 4XX |
| 409 | Conflict | ~13% | Part of 40% 4XX |
| 500 | Internal Error | ~15% | Part of 30% 5XX |
| 503 | Service Unavailable | ~15% | Part of 30% 5XX |

**Note**: Actual distribution in small sample sizes may vary. Test with 100+ requests for accurate probability verification.

## Additional Notes

- **No Authentication**: This is a demo application without authentication
- **No Database**: All data is generated in-memory
- **Thread-Safe**: Uses ThreadLocalRandom for concurrent requests
- **Production Ready**: Includes proper logging, testing, and packaging
- **Docker**: Multi-stage Dockerfile included (see `Dockerfile`)
- **Kubernetes**: Deployment manifests included (see `k8s/`)

## License

This is a demonstration project for educational purposes.

## Version Information

- Application Version: 0.0.1-SNAPSHOT
- Spring Boot: 3.5.9
- Java: 17.0.17
- Tomcat: 10.1.50 (embedded)
- Last Updated: 2026-03-05
