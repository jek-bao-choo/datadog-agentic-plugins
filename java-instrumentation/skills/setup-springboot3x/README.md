# setup-springboot3x

Step-by-step guide to build and run a Spring Boot 3.4 REST API (Component D — terminal node) on CentOS Stream 9. This is Phase 1 — the application runs independently without any instrumentation.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Java | OpenJDK 17.0.18 2026-01-20 LTS |
| Maven | Apache Maven 3.6.3 (Red Hat 3.6.3-23) |
| Port | 8084 |
| Service name | jek-otel-java-springboot3x |
| Fault injection | 10% on all endpoints except /health |

## Prerequisites

- EC2 instance running CentOS Stream 9 with Java 17 and Maven (from `setup-ec2-centos9` skill)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`

## Step 1: Copy source code to the EC2 instance

From your local machine (in the `setup-springboot3x` skill directory):

```bash
# Create the target directory on EC2 (/opt is root-owned, so use sudo)
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> 'sudo mkdir -p /opt/cargostream/component-d && sudo chown -R ec2-user:ec2-user /opt/cargostream'

# Copy the Maven project
scp -i ~/.ssh/jek_rsa_pem -r references/* ec2-user@<EC2_PUBLIC_IP>:/opt/cargostream/component-d/
```

## Step 2: Build with Maven

SSH into the EC2 instance:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
```

Build the project:

```bash
cd /opt/cargostream/component-d
mvn clean package -DskipTests
```

This produces `target/springboot3x-0.0.1-SNAPSHOT.jar`.

## Step 3: Create the log directory

```bash
sudo mkdir -p /var/log/cargostream
sudo chown ec2-user:ec2-user /var/log/cargostream
```

## Step 4: Run the application

```bash
cd /opt/cargostream/component-d
java -jar target/springboot3x-0.0.1-SNAPSHOT.jar
```

You should see:
```
Started Springboot3xApplication in X.XX seconds
```

The app is running on port 8084.

## Step 5: Verify

Open a second SSH session (or use `&` to background the app).

### 5a. Health check

```bash
curl -s http://localhost:8084/health
```

Expected:
```json
{"status":"healthy","service":"jek-otel-java-springboot3x","port":8084}
```

### 5b. Send a test XML payload

```bash
curl -X POST http://localhost:8084/jek-receive-xml \
  -H "Content-Type: application/xml" \
  -d '<shipment>
    <transaction_id>test-tx-001</transaction_id>
    <airway_bill_id>test-awb-001</airway_bill_id>
    <houseway_bill_id>test-hwb-001</houseway_bill_id>
    <timestamp>2026-04-12T10:00:00Z</timestamp>
    <source>manual-test</source>
  </shipment>'
```

Expected XML response:
```xml
<response>
  <status>received</status>
  <houseway_bill_id>test-hwb-001</houseway_bill_id>
  <received_at>2026-04-12T10:00:00.000Z</received_at>
</response>
```

### 5c. Verify fault injection

Run 20+ requests and count how many return HTTP 500:

```bash
for i in $(seq 1 20); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8084/jek-receive-xml \
    -H "Content-Type: application/xml" \
    -d '<shipment><transaction_id>tx-'$i'</transaction_id><airway_bill_id>awb-'$i'</airway_bill_id><houseway_bill_id>hwb-'$i'</houseway_bill_id><timestamp>2026-04-12T10:00:00Z</timestamp><source>test</source></shipment>')
  echo "Request $i: HTTP $CODE"
done
```

Approximately 2 out of 20 requests should return HTTP 500 (10% fault rate).

### 5d. Check logs

```bash
cat /var/log/cargostream/component-d.log
```

You should see `Received shipment` entries with the transaction IDs and `FAULT INJECTION` warnings for the failed requests.

## Troubleshooting

| Issue | Fix |
|---|---|
| `mvn: command not found` | Java 17 and Maven should be installed by `setup-ec2-centos9` user_data. Check with `mvn --version`. |
| Port 8084 already in use | Kill the existing process: `pkill -f springboot3x` |
| Permission denied on /var/log/cargostream | Run `sudo chown ec2-user:ec2-user /var/log/cargostream` |

## Teardown

```bash
# Stop the application (Ctrl+C or kill the process)
pkill -f springboot3x 2>/dev/null

# Remove the project
rm -rf /opt/cargostream/component-d
```

## Next Step

After verifying the application runs correctly, proceed to `springboot3x-otel-java` to instrument it with the OTel Java agent for distributed tracing.
