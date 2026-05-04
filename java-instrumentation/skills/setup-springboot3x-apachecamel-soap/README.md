# setup-springboot3x-apachecamel-soap

Step-by-step guide to build and run a Spring Boot 3.4 + Apache Camel + Apache
CXF SOAP client (the upstream "App A") on CentOS Stream 9. App A receives a
JSON trigger via Camel REST DSL, then calls App B's webMethods SOAP endpoint
through a CXF JAX-WS proxy. Phase 1 is uninstrumented — no OTel agent, no
Datadog.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache Camel | 4.10.3 |
| Apache CXF | 4.0.5 (`cxf-rt-frontend-jaxws` — client only) |
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3+ |
| Port | 8083 |
| Service name | jek-otel-java-springboot3x-apachecamel-soap |
| Trigger | `POST /jek-trigger` |
| Downstream SOAP | `http://127.0.0.1:8084/ws/webmethods` (App B) |

## Prerequisites

- EC2 instance running CentOS Stream 9 with Java 17 + Maven (from `setup-ec2-centos9`)
- **App B running on port 8084** (from `setup-springboot3x-soap` Step 4)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`

## Step 0: Verify App B is running

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  "curl -sf http://localhost:8084/actuator/health && echo && curl -sf 'http://localhost:8084/ws/webmethods?wsdl' | head -3"
```

If App B is not up, start it first per `setup-springboot3x-soap/README.md` Step 4.

## Step 1: Copy source code to the EC2 instance

From your local machine, in this skill directory:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'sudo mkdir -p /opt/cargostream/soap-client /var/log/cargostream && \
   sudo chown -R ec2-user:ec2-user /opt/cargostream /var/log/cargostream'

scp -i ~/.ssh/jek_rsa_pem -r references/* \
  ec2-user@<EC2_PUBLIC_IP>:/opt/cargostream/soap-client/
```

The helper `./scripts/install.sh <EC2_PUBLIC_IP>` runs Steps 1–3 (deploy + Maven
build) in one shot. It does **not** start the server — that's Step 4 below.

## Step 2: Build with Maven

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/cargostream/soap-client
mvn clean package -DskipTests
```

Produces `target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar`.

## Step 3: Confirm the log directory

```bash
ls -ld /var/log/cargostream
# drwxr-xr-x. ec2-user ec2-user — created by Step 1
```

## Step 4: Run the application

In an SSH session you'll keep open:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/cargostream/soap-client
java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar
```

Boot takes ~9-10 seconds (CXF service-model construction adds a beat over the
plain Camel skill). Real captured boot lines (CentOS Stream 9, Java 17.0.18,
Spring Boot 3.4.5, Camel 4.10.3, CXF 4.0.5):

```
o.a.c.w.s.f.ReflectionServiceFactoryBean - Creating Service {http://example.com/webmethods}WebMethodsClientService from class com.example.springboot3xcamelsoap.client.WebMethodsClient
o.s.b.w.e.tomcat.TomcatWebServer - Tomcat started on port 8083 (http) with context path '/'
o.a.c.i.engine.AbstractCamelContext - Apache Camel 4.10.3 (camel-1) is starting
o.a.c.i.engine.AbstractCamelContext - Routes startup (total:1 rest-dsl:1)
o.a.c.i.engine.AbstractCamelContext -     Started submit-shipment (rest://post:/jek-trigger)
o.a.c.i.engine.AbstractCamelContext - Apache Camel 4.10.3 (camel-1) started in 39ms (build:0ms init:0ms start:39ms)
c.e.s.Springboot3xCamelSoapApplication - Started Springboot3xCamelSoapApplication in 9.35 seconds (process running for 10.289)
```

### Backgrounding (only if you need to close the SSH session)

From inside the interactive SSH session (NOT from `ssh ... 'cmd &'`):

```bash
cd /opt/cargostream/soap-client
nohup java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar </dev/null \
  >/var/log/cargostream/soap-client.stdout.log 2>&1 &
disown
exit
```

## Step 5: Verify

Open a second SSH session (or run from your laptop using `<EC2_PUBLIC_IP>`).

### 5a. Health check

```bash
curl -s http://localhost:8083/actuator/health
# {"status":"UP"}
```

### 5b. End-to-end trigger (App B must be running on 8084)

```bash
curl -sS -X POST http://localhost:8083/jek-trigger \
  -H 'Content-Type: application/json' \
  -d '{"tid":"tid-trigger-001","payload":"hello-from-app-a"}'
```

Real captured response (`Instant.now()` on App B has nanosecond precision):

```json
{"tid":"tid-trigger-001","status":"received","received_at":"2026-05-04T14:35:06.075340892Z"}
```

Real captured log lines:

```
# App B — /var/log/cargostream/soap-server.log
2026-05-04 14:35:06,074 [http-nio-8084-exec-2] INFO  c.e.s.e.WebMethodsMockEndpointImpl - Received SOAP submitShipment — TID=tid-trigger-001, payload=hello-from-app-a

# App A — /var/log/cargostream/soap-client.log
2026-05-04 14:35:05,096 [task-1] INFO  c.e.s.route.TriggerRoute - Calling webMethods SOAP submitShipment — TID=tid-trigger-001
```

The first call has a ~1.5-second cost — CXF builds the JAX-WS service model
lazily on the first invocation. Subsequent calls are sub-100 ms. Real captured
latency on a t3.large with both apps on the same host (`curl -w '%{time_total}'`,
both apps freshly started):

```
call  1  1.448536 s   ← cold; CXF service-model construction
call  2  0.031815 s
call  3  0.028175 s
call  4  0.042585 s
call  5  0.121285 s   ← occasional outlier (GC / thread pool spin-up)
call  6  0.038586 s
...
n=20 (warm) min=0.015 s  p50=0.024 s  p90=0.032 s  max=0.034 s  mean=0.024 s
```

Plan for ~1.5 s on the cold call after each JVM start, ~15-35 ms per warm call.

### 5c. Sanity check — App B down → real captured failure mode

Stop App B (`sudo fuser -k 8084/tcp` on the EC2 host) and re-trigger:

```bash
curl -sS -w '\nHTTP %{http_code}\n' -X POST http://localhost:8083/jek-trigger \
  -H 'Content-Type: application/json' \
  -d '{"tid":"tid-no-b","payload":"x"}'
```

You'll see HTTP 500 with an **empty response body**. The error detail is in
App A's log (`/var/log/cargostream/soap-client.log`). Real captured trace:

```
WARN  o.a.cxf.phase.PhaseInterceptorChain - Interceptor for {http://example.com/webmethods}WebMethodsClientService#{http://example.com/webmethods}submitShipment has thrown exception, unwinding now
org.apache.cxf.interceptor.Fault: Could not send Message.
    at org.apache.cxf.transport.http.HttpClientHTTPConduit$HttpClientWrappedOutputStream.isConnectionAttemptCompleted(...)
ERROR o.a.c.p.e.DefaultErrorHandler - Failed delivery for ... caught: jakarta.xml.ws.WebServiceException: Could not send Message.
Caused by: java.net.ConnectException: null
    at java.net.http/jdk.internal.net.http.PlainHttpConnection.connectAsync(...)
```

CXF 4.x uses the JDK HTTPClient (not Apache HttpClient). The top-level
`ConnectException` message is literally `null` — the "Connection refused"
phrase only appears in the deeper socket exception. The
`WebMethodsClientService` qualifier in the WARN line confirms the wire path
is going through the CXF JAX-WS proxy you configured, not somewhere else.

### 5d. Check Camel route log

```bash
grep "Calling webMethods SOAP" /var/log/cargostream/soap-client.log | tail -5
```

Should show one entry per trigger.

## Understand the code — how App A builds and sends a SOAP envelope

App A is a pipeline of **three frameworks each doing what they're best at**:

```
Spring Boot Tomcat (HTTP listener on 8083)
    │
    ▼  REST DSL
Apache Camel (routes the JSON trigger and orchestrates the call)
    │
    ▼  RouteBuilder + processor
Apache CXF JAX-WS proxy (serializes Java to SOAP envelope + HTTP send)
    │
    ▼  SOAP/HTTP POST
App B :8084
```

Three small Java files connect those layers. The single line that **sends
the SOAP envelope on the wire** is `webMethodsClient.submitShipment(req)` —
let's see how we got there.

### Step A — `TriggerRoute.java` (the Camel route)

Path: `references/src/main/java/com/example/springboot3xcamelsoap/route/TriggerRoute.java`

The body of the route's processor (lines 52–75 in the file):

```java
from("direct:submit-shipment")
        .routeId("submit-shipment")
        .unmarshal().json(JsonLibrary.Jackson, Map.class)                  // [1]
        .process(exchange -> {
            Map<String, Object> body = exchange.getIn().getBody(Map.class);
            String tid     = String.valueOf(body.getOrDefault("tid", ""));
            String payload = String.valueOf(body.getOrDefault("payload", "from-camel-soap-client"));

            log.info("Calling webMethods SOAP submitShipment — TID={}", tid);

            SubmitShipmentRequest req = new SubmitShipmentRequest();       // [2]
            req.setTID(tid);
            req.setPayload(payload);

            SubmitShipmentResponse resp = webMethodsClient.submitShipment(req);   // [3]  ★ THIS LINE SENDS THE SOAP ENVELOPE ★

            Map<String, Object> result = new LinkedHashMap<>();            // [4]
            result.put("tid", resp.getTID());
            result.put("status", resp.getStatus());
            result.put("received_at", resp.getReceived_at());
            exchange.getMessage().setBody(result);
        })
        .marshal().json(JsonLibrary.Jackson);
```

**[1]** `unmarshal().json(...)` turns the curl-posted JSON body
(`{"tid":"...","payload":"..."}`) into a `Map<String, Object>` so we can
read fields by name.

**[2]** We construct a plain Java `SubmitShipmentRequest` DTO and copy
fields onto it. **No XML or SOAP construction in this code.**

**[3] ★ This is the line that sends the SOAP envelope.** The call to
`webMethodsClient.submitShipment(req)` looks like a plain method call, but
`webMethodsClient` is a CXF JAX-WS proxy — see Step B below. Under the hood
this single line:

   1. Reads the JAX-WS annotations on the `WebMethodsClient` interface to
      figure out the SOAP operation name and target namespace.
   2. Reads the JAXB annotations on `SubmitShipmentRequest` to serialize
      the Java object into XML.
   3. Wraps the XML in a SOAP envelope (`<soapenv:Envelope>...<soapenv:Body>
      ...<wm:submitShipment><TID>...</TID>...</wm:submitShipment>...</soapenv:Body>...</soapenv:Envelope>`).
   4. Sends an HTTP POST to `http://127.0.0.1:8084/ws/webmethods` with
      `Content-Type: text/xml; charset=utf-8` and `SOAPAction: ""`.
   5. Waits for App B's response, deserializes it back into a Java
      `SubmitShipmentResponse` object, and returns it.

This is also **the exact moment the OTel Java Extension fires** (see
`create-otel-java-ext-soap`) — the extension hooks into CXF's outbound
interceptor chain to read the envelope bytes before they leave the JVM.

**[4]** We project the SOAP response into a Map and let Camel's
`.marshal().json(...)` turn it back into JSON for the curl caller.

### Step B — `CxfClientConfig.java` (the JAX-WS proxy wiring)

Path: `references/src/main/java/com/example/springboot3xcamelsoap/client/CxfClientConfig.java`

```java
@Configuration
public class CxfClientConfig {

    @Bean
    public WebMethodsClient webMethodsClient(
            @Value("${webmethods.endpoint:http://127.0.0.1:8084/ws/webmethods}") String endpoint) {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();          // [1]
        factory.setServiceClass(WebMethodsClient.class);                      // [2]
        factory.setAddress(endpoint);                                         // [3]
        return (WebMethodsClient) factory.create();                           // [4]
    }
}
```

**[1]** `JaxWsProxyFactoryBean` is the CXF builder for client-side JAX-WS
proxies. **[2]** We tell it which Service Endpoint Interface (SEI) to
implement — `WebMethodsClient`. **[3]** We give it the URL of the remote
SOAP service. **[4]** `factory.create()` returns a runtime-generated proxy
that conforms to `WebMethodsClient`. Every method call on the proxy
becomes a SOAP call to the configured address.

The `127.0.0.1` is intentional (NOT `localhost`) — the OTel Java Agent's
HTTP-client interception can hit IPv6 dual-stack resolution issues with
`localhost`. The literal IPv4 address bypasses that.

### Step C — `WebMethodsClient.java` (the SEI)

Path: `references/src/main/java/com/example/springboot3xcamelsoap/client/WebMethodsClient.java`

```java
@WebService(targetNamespace = "http://example.com/webmethods", name = "WebMethodsMock")
@SOAPBinding(style = SOAPBinding.Style.DOCUMENT, parameterStyle = SOAPBinding.ParameterStyle.BARE)
public interface WebMethodsClient {

    @WebMethod(operationName = "submitShipment")
    @WebResult(name = "submitShipmentResponse", targetNamespace = "http://example.com/webmethods")
    SubmitShipmentResponse submitShipment(
            @WebParam(name = "submitShipment", targetNamespace = "http://example.com/webmethods")
            SubmitShipmentRequest request);
}
```

This is **the contract** between App A and App B. The annotations on this
interface dictate the SOAP wire format: target namespace, operation name,
parameter element names. App B's `WebMethodsMockEndpoint` interface has
**identical annotations** — that's how the wire envelope produced here
deserializes correctly there.

### Step D — `SubmitShipmentRequest.java` (the JAXB DTO that carries the TID)

Path: `references/src/main/java/com/example/springboot3xcamelsoap/model/SubmitShipmentRequest.java`

```java
@XmlRootElement(name = "submitShipment", namespace = "http://example.com/webmethods")
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "submitShipment", namespace = "http://example.com/webmethods",
         propOrder = {"TID", "payload"})
public class SubmitShipmentRequest {

    @XmlElement(name = "TID", required = true)            // ★ This is where <TID> on the wire comes from ★
    private String TID;

    @XmlElement(name = "payload")
    private String payload;
    // ...getters and setters omitted...
}
```

The `@XmlElement(name = "TID")` annotation is what makes the `<TID>` element
appear in the outgoing SOAP envelope. The OTel extension's regex matches
that `<TID>` element by name — so if you change this annotation, you must
also change the extension's regex (see
`create-otel-java-ext-soap/SKILL.md` → "Adapting from a customer code
snippet").

### Putting it all together — the data path

```
   curl POST /jek-trigger {"tid":"X","payload":"Y"}
         │
         ▼
   [Step A] Camel route parses JSON → builds SubmitShipmentRequest(TID=X, payload=Y)
         │
         ▼
   [Step A line ★] webMethodsClient.submitShipment(req)
         │
         ▼
   [Step B] CXF JaxWsProxyFactoryBean's runtime proxy:
         │   1. reads [Step C] @WebService annotations → operation, namespace
         │   2. reads [Step D] @XmlElement annotations → element names
         │   3. builds <soapenv:Envelope>...<TID>X</TID>...</soapenv:Envelope>
         │   4. POSTs to http://127.0.0.1:8084/ws/webmethods
         ▼
   App B (setup-springboot3x-soap) receives, processes, returns SOAP response
         │
         ▼
   [Step A] Camel projects SOAP response → JSON → curl caller
```

You write four small files (`TriggerRoute.java`, `CxfClientConfig.java`,
`WebMethodsClient.java`, `SubmitShipmentRequest.java`); CXF + Camel + Spring
Boot do the heavy lifting at runtime.

## Troubleshooting

| Issue | Fix |
|---|---|
| `mvn: command not found` | Java 17 + Maven are installed by `setup-ec2-centos9` user_data. Verify with `mvn --version`. |
| Port 8083 already in use | `pkill -f 'springboot3x-camel-soap-0.0.1-SNAPSHOT.jar'` (use the JAR-specific pattern; a bare `pkill -f springboot3x-camel-soap` from `bash -c` matches its own command line and SIGKILLs the parent shell, dropping SSH with exit 255) |
| `curl: (7) Failed to connect to ... port 8083: Connection refused` | App A itself isn't running. Re-run Step 4. |
| HTTP 500 with empty body on /jek-trigger | App B is not running on 8084. Verify with `curl -sf http://localhost:8084/actuator/health`. The empty body is normal — see 5c above for the captured stack trace and why Camel's default error handler doesn't surface a SOAP fault here. |
| `IllegalArgumentException: ... not a JAX-WS service` | Your `WebMethodsClient` SEI doesn't have `@WebService` or its package is missing JAXB annotations on the request/response DTOs. Compare against `references/src/main/java/com/example/springboot3xcamelsoap/client/WebMethodsClient.java`. |
| `JAXBException: ... namespace not bound` | The SEI / DTO `targetNamespace` doesn't match App B's (`http://example.com/webmethods`). All four annotations (`@WebService`, `@WebParam`, `@WebResult`, `@XmlRootElement`) must agree on the namespace. |
| `Unsupported Media Type` from App B | App B expects `text/xml; charset=utf-8`. CXF sets this automatically; if you see this, something is overriding the Content-Type — check for additional Camel processors. |

## Teardown

In an interactive SSH session:

```bash
pkill -f 'springboot3x-camel-soap-0.0.1-SNAPSHOT.jar' 2>/dev/null
rm -rf /opt/cargostream/soap-client
sudo rm -f /var/log/cargostream/soap-client.log* /var/log/cargostream/soap-client.stdout.log
```

From a single-shot `ssh ... "cmd"`:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> '
  sudo fuser -k 8083/tcp
  rm -rf /opt/cargostream/soap-client
  sudo rm -f /var/log/cargostream/soap-client.log* /var/log/cargostream/soap-client.stdout.log
'
```

## Next Step

Once both App A (port 8083) and App B (port 8084) are up and the trigger
end-to-end works, instrument both with `springboot3x-otel-java-tool-opt`
(system-wide JAVA_TOOL_OPTIONS), then build and load the TID-extracting
extension via `create-otel-java-ext-soap` + `load-otel-java-ext`.
