---
name: setup-springboot3x-soap
description: >-
  Build and run a Spring Boot 3.4 + Apache CXF JAX-WS SOAP server (port 8084) that
  mocks IBM webMethods. Publishes a `@WebService` endpoint at `/ws/webmethods`
  accepting a SOAP envelope with `<TID>...</TID>`, logs the TID, and returns a SOAP
  response echoing it. Includes 10% probabilistic SOAP fault injection on the
  operation (skipped on `/actuator/health`). Maven project uses `<layout>ZIP</layout>`
  (PropertiesLauncher) so OTel Java extensions can be loaded via `-Dloader.path`.
  Use this whenever the user wants to set up a Spring Boot 3.x SOAP server, mock IBM
  webMethods over SOAP, or stand up a CXF JAX-WS endpoint for a Datadog PoC. Skip
  when the user wants a REST endpoint (use `setup-springboot3x` instead) or a
  Camel-based ESB mock with JSON→XML transformation (use `setup-springboot3x-apachecamel`).
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.4.5]
  cxf_version: [4.0.5]
---

# Spring Boot 3.4 + Apache CXF — SOAP Server (IBM webMethods Mock)

Build and run the SOAP server that mocks IBM webMethods. Receives a SOAP envelope
containing `<TID>` (transaction identifier) plus a payload, logs the TID, and returns
a SOAP response with the same TID echoed back. Sister skill to `setup-springboot3x`
(which is REST-only) — use this one when the upstream caller is a SOAP client.

## Prerequisites

- EC2 instance with Java 17 and Maven (from `setup-ec2-centos9`)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP>`

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache CXF | 4.0.5 (`cxf-spring-boot-starter-jaxws`) |
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3+ |
| Port | 8084 |
| Service name | jek-otel-java-springboot3x-soap |
| SOAP path prefix | `/ws` (CXF servlet) |
| Endpoint | `/ws/webmethods` |
| Fault injection | 10% on the SOAP operation (CXF interceptor); none on `/actuator/health` |
| Maven layout | `ZIP` (PropertiesLauncher — required so consumers can use `-Dloader.path` for OTel extensions) |

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/ws/webmethods` | SOAP endpoint — `submitShipment` operation. Accepts `<TID>` + `<payload>`. Returns SOAP response echoing the TID and a `<received_at>` timestamp. |
| GET | `/ws/webmethods?wsdl` | WSDL document published by CXF. |
| GET | `/actuator/health` | Spring Boot Actuator health (Spring MVC; not on the CXF chain, so fault injection does not apply). |

## SOAP Operation Shape

The SEI uses **document-literal-bare** style so the wire envelope matches what an
upstream caller (or `curl`) would naturally produce. The request element is named
`submitShipment`, the response element is `submitShipmentResponse`, both in the
`http://example.com/webmethods` namespace. Parameter element names are
`TID` and `payload` (uppercase TID is intentional — it mirrors the casing seen in
the prospect's real SOAP traffic).

## Why `<layout>ZIP</layout>`

App A (the SOAP client built by `setup-springboot3x-apachecamel-soap`) loads the
`create-otel-java-ext-soap` extension JAR via `-Dloader.path`, which only works
under Spring Boot's `PropertiesLauncher`. App B is built with the same layout
purely for consistency — if you ever want to load an extension into App B (e.g.,
to attach the TID to B's server span as well), the plumbing is already in place.

## Build

Run on the EC2 host (Maven is preinstalled by `setup-ec2-centos9` user_data):

```bash
cd /opt/cargostream/soap-server   # after scp-ing references/ here, see README Step 1
mvn clean package -DskipTests
# Produces target/springboot3x-soap-0.0.1-SNAPSHOT.jar (~32 MB)
```

The `scripts/install.sh <EC2_PUBLIC_IP>` helper performs Steps 1–3 from the README
(scp + mkdir + chown + Maven build) in one shot. It does **not** start the JVM —
backgrounding from a single-shot SSH command is unreliable on this stack
(the JVM is torn down with the SSH pty on session close, despite `nohup`). Start
the server in an interactive SSH session you keep open:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/cargostream/soap-server
java -jar target/springboot3x-soap-0.0.1-SNAPSHOT.jar     # boots in ~7-10 s
```

If you need to close the SSH session and leave the app running, use this pattern
**from inside the interactive session** (not from `ssh ... 'nohup ... &'`):

```bash
nohup java -jar target/springboot3x-soap-0.0.1-SNAPSHOT.jar </dev/null \
  >/var/log/cargostream/soap-server.stdout.log 2>&1 &
disown
exit
```

## Validation

### Health (Spring MVC, not SOAP)

```bash
curl -s http://localhost:8084/actuator/health
# {"status":"UP"}
```

### WSDL (CXF auto-publishes from the SEI)

```bash
curl -s 'http://localhost:8084/ws/webmethods?wsdl' | head -50
```

### SOAP smoke test

```bash
curl -sS -X POST http://localhost:8084/ws/webmethods \
  -H 'Content-Type: text/xml; charset=utf-8' \
  -H 'SOAPAction: ""' \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                       xmlns:wm="http://example.com/webmethods">
        <soapenv:Body>
          <wm:submitShipment>
            <TID>tid-smoke-001</TID>
            <payload>hello</payload>
          </wm:submitShipment>
        </soapenv:Body>
      </soapenv:Envelope>'
```

Real captured response (CXF emits compact XML; element order is fixed by the
`@XmlType(propOrder = ...)` annotation on `SubmitShipmentResponse`):

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:submitShipmentResponse xmlns:ns2="http://example.com/webmethods"><TID>tid-smoke-001</TID><status>received</status><received_at>2026-05-04T14:19:04.533189391Z</received_at></ns2:submitShipmentResponse></soap:Body></soap:Envelope>
```

`received_at` is `Instant.now().toString()` — RFC 3339 / ISO 8601 with nanosecond
precision (Zulu/UTC). Confirm the TID is also in the app log:

```bash
grep tid-smoke-001 /var/log/cargostream/soap-server.log
# 2026-05-04 14:19:04,532 [http-nio-8084-exec-3] INFO  c.e.s.e.WebMethodsMockEndpointImpl - Received SOAP submitShipment — TID=tid-smoke-001, payload=hello
```

### Verify fault injection

Run 30 SOAP requests; ~3 should return HTTP 500 with a SOAP fault envelope:

```bash
for i in $(seq 1 30); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:8084/ws/webmethods \
    -H 'Content-Type: text/xml; charset=utf-8' \
    -H 'SOAPAction: ""' \
    -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                         xmlns:wm="http://example.com/webmethods">
          <soapenv:Body><wm:submitShipment><TID>tid-fault-'"$i"'</TID><payload>x</payload></wm:submitShipment></soapenv:Body>
        </soapenv:Envelope>')
  echo "Request $i: HTTP $CODE"
done
```

Bernoulli variance on n=30 with p=0.10 is non-trivial — a real run on this stack
returned 5/30 (17%) the first time and 3/30 the second. Both are within
expected variance. The body of each failure is a SOAP fault envelope:

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Simulated infrastructure fault on jek-otel-java-springboot3x-soap</faultstring></soap:Fault></soap:Body></soap:Envelope>
```

Look for `FAULT INJECTION` warnings in the log:

```bash
grep 'FAULT INJECTION' /var/log/cargostream/soap-server.log | head -3
# 2026-05-04 14:19:22,052 [http-nio-8084-exec-6] WARN  c.e.s.interceptor.FaultInterceptor - FAULT INJECTION: Simulated 10% failure on {http://example.com/webmethods}submitShipment
```

The operation name in the log is fully qualified (`{namespace}operation`)
because CXF stores it as a QName in `Message.WSDL_OPERATION`.

`/actuator/health` is not on the CXF chain, so fault injection never affects it
(verified: 20/20 health checks returned HTTP 200 during a fault-injection run).
Useful when this app is fronted by a Datadog Agent / OTel Collector liveness probe.

## OTel Instrumentation (next steps)

This skill ships the app *uninstrumented*. To add tracing:

- **Auto-inject the OTel Java Agent system-wide** — see `springboot3x-otel-java-tool-opt`. Both this app and any sister apps on the host pick up `JAVA_TOOL_OPTIONS` automatically. CXF / JAX-WS is auto-instrumented by the OTel Java Agent's `cxf` and `http-url-connection` modules; you'll see SOAP server spans without code changes.
- **(Optional) Custom span attributes from the SOAP body** — see `create-otel-java-ext-soap` for the outbound-client variant (used on App A) or `create-otel-java-ext` for the inbound-Servlet variant (which works on this app via Spring MVC's Actuator, not the CXF chain — so it is not the right pattern for SOAP body extraction here).

## Teardown

In an interactive SSH session — `pkill -f` is fine here because pkill skips its
own PID and the parent (interactive bash) doesn't carry the JAR name in its
command line:

```bash
pkill -f 'springboot3x-soap-0.0.1-SNAPSHOT.jar' 2>/dev/null
rm -rf /opt/cargostream/soap-server
sudo rm -f /var/log/cargostream/soap-server.log* /var/log/cargostream/soap-server.stdout.log
```

From a single-shot `ssh ... "cmd"` (script-driven cleanup) — use port-based
killing because `pkill -f <pattern>` inside `bash -c` matches its own argv and
SIGKILLs the parent shell, dropping SSH with exit 255:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP> 'sudo fuser -k 8084/tcp; rm -rf /opt/cargostream/soap-server'
```

## Next Step

Build the upstream SOAP client with `setup-springboot3x-apachecamel-soap` (Camel +
CXF), then auto-inject OTel via `springboot3x-otel-java-tool-opt`.
