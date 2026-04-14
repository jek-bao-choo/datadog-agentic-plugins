# setup-springboot3x-apachecamel

Step-by-step guide to build and run a Spring Boot 3.4 + Apache Camel ESB mock (Component C). This mocks IBM webMethods: receives JSON from upstream, transforms to XML, generates `houseway_bill_id`, applies 80/20 probabilistic branching, and forwards XML to Component D.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache Camel | 4.10.3 |
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3 |
| Port | 8083 |
| Service name | jek-otel-java-springboot3x-camel |
| Fault injection | 20% on all endpoints except /health |
| 80/20 branching | 80% pristine, 20% mutates transaction_id and airway_bill_id |

## What the Camel route does (simulating webMethods ESB)

```
JSON in (from Component B)
  → Unmarshal to Map (simulates IData pipeline)
  → Generate houseway_bill_id (simulates Java service node)
  → 80/20 branching (simulates BRANCH flow step)
     ├── 80%: pristine pass-through
     └── 20%: MUTATED- prefix on transaction_id and airway_bill_id
  → Marshal Map to XML (simulates pub.xml:documentToXMLString)
  → POST XML to Component D at localhost:8084/jek-receive-xml
```

## Prerequisites

- EC2 instance with Java 17 and Maven (from `setup-ec2-centos9`)
- Component D running on port 8084 (from `setup-springboot3x`)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`

## Step 0: Verify Component D is running

Component C forwards XML to Component D on port 8084. Verify D is running before starting C:

```bash
curl -sf http://localhost:8084/health
```

Expected: `{"status":"healthy","service":"jek-otel-java-springboot3x","port":8084}`

If Component D is not running, go back to `setup-springboot3x` and start it first.

## Step 1: Copy source to EC2

From your local machine (in the `setup-springboot3x-apachecamel` skill directory):

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'sudo mkdir -p /opt/cargostream/component-c && sudo chown ec2-user:ec2-user /opt/cargostream/component-c'

scp -i ~/.ssh/jek_rsa_pem -r references/* ec2-user@<EC2_PUBLIC_IP>:/opt/cargostream/component-c/
```

## Step 2: Build with Maven

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>

cd /opt/cargostream/component-c
mvn clean package -DskipTests
```

This produces `target/springboot3x-camel-0.0.1-SNAPSHOT.jar`.

## Step 3: Run the application

```bash
cd /opt/cargostream/component-c
java -jar target/springboot3x-camel-0.0.1-SNAPSHOT.jar
```

Or in the background:

```bash
nohup java -jar target/springboot3x-camel-0.0.1-SNAPSHOT.jar > /tmp/component-c.log 2>&1 &
sleep 15
curl -s http://localhost:8083/health
```

## Step 4: Verify

### 4a. Health check

```bash
curl -s http://localhost:8083/health
```

Expected: `{"status":"healthy","service":"jek-otel-java-springboot3x-camel","port":8083,"esb":"apache-camel-mock"}`

### 4b. Send JSON (Component D must be running on 8084)

```bash
curl -X POST http://localhost:8083/jek-process \
  -H "Content-Type: application/json" \
  -d '{"transaction_id": "test-tx-001", "airway_bill_id": "test-awb-001"}'
```

Expected: XML response from Component D containing `houseway_bill_id`.

### 4c. Verify 80/20 branching

```bash
for i in $(seq 1 20); do
  echo "--- Request $i ---"
  curl -sf -X POST http://localhost:8083/jek-process \
    -H "Content-Type: application/json" \
    -d "{\"transaction_id\": \"tx-$i\", \"airway_bill_id\": \"awb-$i\"}" 2>&1 | head -5
  echo ""
done
```

~4 out of 20 should show MUTATED- prefix in the response.

### 4d. Check logs

```bash
grep "80/20 BRANCH" /tmp/component-c.log | tail -10
```

Should show a mix of `PRISTINE pass-through` and `MUTATED transaction_id` entries.

## Battle-tested lesson: bridgeEndpoint

The Camel HTTP producer requires `?bridgeEndpoint=true` on the target URL:

```java
.to("http://localhost:8084/jek-receive-xml?bridgeEndpoint=true");
```

Without this, every request fails with:
```
IllegalArgumentException: Invalid url: /jek-process.
If you are forwarding/bridging http endpoints, then enable the bridgeEndpoint option
```

This happens because Camel's HTTP component tries to use the incoming request URI (`/jek-process`) as the outgoing path, overriding the target URL. `bridgeEndpoint=true` tells Camel to use the URL as-is.

## Troubleshooting

| Issue | Fix |
|---|---|
| `IllegalArgumentException: Invalid url` | Add `?bridgeEndpoint=true` to the `.to()` URL in EsbRoute.java |
| Port 8083 in use | `pkill -f springboot3x-camel` |
| Component D not reachable | Verify Component D is running: `curl http://localhost:8084/health` |
| Build fails on Camel deps | Ensure Maven can reach Maven Central (internet access) |
| All requests return 500 | Check `/tmp/component-c.log` — may be 20% fault injection or Camel route error |

## Teardown

```bash
pkill -f springboot3x-camel 2>/dev/null
rm -rf /opt/cargostream/component-c
```

## OTel instrumentation

This app is instrumented via `JAVA_TOOL_OPTIONS` (from `springboot3x-otel-java-tool-opt`). Ensure the full flags are set (agent + DSM extension + loader.path + header capture). The `transaction_id` appears as a span attribute via HTTP header capture (`-Dotel.instrumentation.http.server.capture-request-headers=transaction_id`).

## Next Step

Proceed to `springboot3x-otel-java-tool-opt` to set up JAVA_TOOL_OPTIONS system-wide, then instrument Component B with `setup-springboot3x-resilience4j`.
