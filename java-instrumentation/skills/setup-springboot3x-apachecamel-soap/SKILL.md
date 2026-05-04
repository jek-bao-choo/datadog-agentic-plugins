---
name: setup-springboot3x-apachecamel-soap
description: >-
  Build and run a Spring Boot 3.4 + Apache Camel 4.10 + Apache CXF JAX-WS SOAP
  client (port 8083) — the upstream "App A" that sends SOAP requests to the
  webMethods mock (App B from `setup-springboot3x-soap` on port 8084). Camel
  REST DSL exposes `POST /jek-trigger` accepting JSON `{"tid":"..."}`; a Camel
  route invokes a CXF `JaxWsProxyFactoryBean`-built client to call the
  `submitShipment` SOAP operation in the `http://example.com/webmethods`
  namespace. Maven `<layout>ZIP</layout>` (PropertiesLauncher) so the
  `create-otel-java-ext-soap` extension JAR can be loaded later via
  `-Dloader.path`. Use this whenever the user wants a Spring Boot 3.x app that
  triggers a SOAP call to webMethods, the upstream side of a Camel→SOAP
  integration, or the SOAP client for a Datadog PoC. Skip when the user wants
  a plain JSON→XML→HTTP forwarder (use `setup-springboot3x-apachecamel`
  instead) or a SOAP server (use `setup-springboot3x-soap`).
version: 0.1.0
version_matrix:
  java_version: [17]
  springboot_version: [3.4.5]
  camel_version: [4.10.3]
  cxf_version: [4.0.5]
---

# Spring Boot 3.4 + Apache Camel + Apache CXF — SOAP Client (App A)

Build and run the upstream SOAP client. Receives a JSON trigger, builds a SOAP
envelope via a CXF JAX-WS proxy, and calls App B's `submitShipment` operation.
Sister skill to `setup-springboot3x-apachecamel` (which is plain JSON→XML→HTTP
forwarder with no SOAP) — use this one when the downstream is a SOAP/JAX-WS
endpoint and the on-the-wire payload must be a real `<soapenv:Envelope>`.

## Prerequisites

- EC2 instance with Java 17 and Maven (from `setup-ec2-centos9`)
- **App B running on port 8084** (from `setup-springboot3x-soap`) — without it,
  `/jek-trigger` returns HTTP 500 with an empty body (the failure is at the
  HTTP transport layer; there's no SOAP envelope to wrap a fault in). See
  "What happens when App B is down" below for the captured stack trace.
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP>`

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache Camel | 4.10.3 |
| Apache CXF | 4.0.5 (`cxf-rt-frontend-jaxws` — client only, no servlet) |
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3+ |
| Port | 8083 |
| Service name | jek-otel-java-springboot3x-apachecamel-soap |
| Trigger | `POST /jek-trigger` (JSON `{"tid":"..."}`) |
| Downstream SOAP | `http://127.0.0.1:8084/ws/webmethods` (literal `127.0.0.1`, NOT `localhost` — see below) |
| Maven layout | `ZIP` (PropertiesLauncher — required so `create-otel-java-ext-soap` can be loaded via `-Dloader.path`) |

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/jek-trigger` | Camel REST DSL endpoint. Accepts `{"tid":"...","payload":"..."}`. Returns the SOAP response as JSON. |
| GET | `/actuator/health` | Spring Boot Actuator. |

## Why `127.0.0.1` and not `localhost`

The downstream SOAP address is hardcoded as `http://127.0.0.1:8084/ws/webmethods`.
Using `localhost` triggers IPv6 dual-stack resolution that can produce intermittent
connection failures with the OTel Java Agent's HTTP client interception. The
literal IPv4 address bypasses this. Confirmed in prior PoCs and recorded as
durable guidance.

## Why JAX-WS proxy (and not `camel-cxf-soap-starter`)

`camel-cxf-soap-starter` operates in PAYLOAD or POJO mode and has its own
data-format and message-list quirks. For App A — which is just *one* SOAP call
per Camel route step — it's cleaner to keep Camel for routing and let CXF's
JAX-WS proxy build the envelope:

```java
@Bean
public WebMethodsClient webMethodsClient(@Value("${webmethods.endpoint}") String endpoint) {
    JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
    factory.setServiceClass(WebMethodsClient.class);
    factory.setAddress(endpoint);
    return (WebMethodsClient) factory.create();
}
```

The Camel route then injects this bean into a `.process(...)` step and just calls
`webMethodsClient.submitShipment(req)`. This keeps the wire format identical to
what App B's WSDL describes (because both sides share the same SEI annotations
and JAXB DTOs) and avoids `MessageContentsList` ergonomics.

## Build

Run on the EC2 host (Maven is preinstalled by `setup-ec2-centos9` user_data):

```bash
cd /opt/cargostream/soap-client    # after scp-ing references/ here, see README Step 1
mvn clean package -DskipTests
# Produces target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar
```

The `scripts/install.sh <EC2_PUBLIC_IP>` helper performs Steps 1–3 from the
README (scp + mkdir + chown + Maven build) in one shot. It does **not** start
the JVM — same reason as `setup-springboot3x-soap`: backgrounding from a
single-shot SSH command is unreliable on this stack. Start the server in an
interactive SSH session you keep open:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/cargostream/soap-client
java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar
```

If you need to close the SSH session, use this from inside the interactive
session:

```bash
nohup java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar </dev/null \
  >/var/log/cargostream/soap-client.stdout.log 2>&1 &
disown
exit
```

## Validation

### Health (Spring MVC)

```bash
curl -s http://localhost:8083/actuator/health
# {"status":"UP"}
```

### End-to-end SOAP call (App B must be running on 8084 first)

```bash
curl -sS -X POST http://localhost:8083/jek-trigger \
  -H 'Content-Type: application/json' \
  -d '{"tid":"tid-trigger-001","payload":"hello-from-app-a"}'
```

Real captured response — App B's SOAP response, JSON-marshaled back through
Camel (nanosecond timestamp from `Instant.now()` on the server side):

```json
{"tid":"tid-trigger-001","status":"received","received_at":"2026-05-04T14:35:06.075340892Z"}
```

Real captured log lines:

```
# App A — /var/log/cargostream/soap-client.log
2026-05-04 14:35:05,096 [task-1] INFO  c.e.s.route.TriggerRoute - Calling webMethods SOAP submitShipment — TID=tid-trigger-001

# App B — /var/log/cargostream/soap-server.log
2026-05-04 14:35:06,074 [http-nio-8084-exec-2] INFO  c.e.s.e.WebMethodsMockEndpointImpl - Received SOAP submitShipment — TID=tid-trigger-001, payload=hello-from-app-a
```

The ~1-second gap between A's "Calling" line and B's "Received" line is the
JAX-WS proxy's first-call cost (CXF builds the WSDL-driven service model on
demand). Real captured latency profile on a t3.large with both apps on the
same host (`curl -w '%{time_total}'`):

```
call  1  1.448536 s   ← cold; CXF service-model construction
call  2  0.031815 s
call  3  0.028175 s
...
n=20 (warm) min=0.015 s  p50=0.024 s  p90=0.032 s  max=0.034 s  mean=0.024 s
```

So expect **~1.5 s on the very first call** after JVM start, **~15-35 ms
thereafter** while the JVM is warm.

### What happens when App B is down

```bash
# Stop App B (sudo fuser -k 8084/tcp from your laptop, or Ctrl+C in App B's SSH session)
curl -sS -w '\nHTTP %{http_code}\n' -X POST http://localhost:8083/jek-trigger \
  -H 'Content-Type: application/json' \
  -d '{"tid":"tid-no-server","payload":"x"}'
```

App A returns **HTTP 500 with an empty body** (Camel's default error handler
doesn't pass through transport-level failures as a SOAP fault — there's no
SOAP fault to propagate, since the request never reached App B). The error
*detail* is in App A's log. Real captured stack trace:

```
WARN  o.a.cxf.phase.PhaseInterceptorChain - Interceptor for {http://example.com/webmethods}WebMethodsClientService#{http://example.com/webmethods}submitShipment has thrown exception, unwinding now
org.apache.cxf.interceptor.Fault: Could not send Message.
    at org.apache.cxf.transport.http.HttpClientHTTPConduit$HttpClientWrappedOutputStream...
    ...
ERROR o.a.c.p.e.DefaultErrorHandler - Failed delivery for ... caught: jakarta.xml.ws.WebServiceException: Could not send Message.
Caused by: java.net.ConnectException: null
    at java.net.http/jdk.internal.net.http.PlainHttpConnection.connectAsync(...)
```

Two things to note:
- CXF 4.x uses the **JDK HTTPClient** (`java.net.http.*`), not Apache
  HttpClient. The cause is `java.net.ConnectException` with a literal `null`
  message field — the "Connection refused" wording shows up only in the
  underlying socket exception further down the chain.
- The wire path is genuinely `App A → 127.0.0.1:8084`. Confirmed by the
  `WebMethodsClientService` qualifier in the WARN line — that's the CXF
  service constructed from `WebMethodsClient.class` pointing at the configured
  `webmethods.endpoint`.

## OTel Instrumentation (next steps)

This skill ships uninstrumented. The full PoC then:

1. **Auto-inject the OTel Java Agent system-wide** — see `springboot3x-otel-java-tool-opt`.
   Both Camel and CXF are auto-instrumented; you'll see App A's outbound SOAP
   call as a client span connected to App B's server span without code changes.
2. **Add a custom `tid` span attribute extracted from the SOAP envelope** — see
   `create-otel-java-ext-soap`. That extension is loaded into App A via
   `-Dloader.path` (which is why `<layout>ZIP</layout>` is required here).

## Teardown

In an interactive SSH session:

```bash
pkill -f 'springboot3x-camel-soap-0.0.1-SNAPSHOT.jar' 2>/dev/null
rm -rf /opt/cargostream/soap-client
sudo rm -f /var/log/cargostream/soap-client.log* /var/log/cargostream/soap-client.stdout.log
```

From a single-shot `ssh ... "cmd"` (script-driven cleanup):

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<IP> 'sudo fuser -k 8083/tcp; rm -rf /opt/cargostream/soap-client'
```

## Next Step

After both apps are up and the end-to-end SOAP call works, instrument both with
`springboot3x-otel-java-tool-opt`, then build and load the
`create-otel-java-ext-soap` extension JAR into App A.
