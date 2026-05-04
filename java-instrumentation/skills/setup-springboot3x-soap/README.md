# setup-springboot3x-soap

Step-by-step guide to build and run a Spring Boot 3.4 + Apache CXF SOAP server
(the "App B" / IBM webMethods mock) on CentOS Stream 9. Phase 1 is uninstrumented
— no OTel agent, no Datadog. Add tracing later via `springboot3x-otel-java-tool-opt`.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Spring Boot | 3.4.5 |
| Apache CXF | 4.0.5 |
| Java | OpenJDK 17.0.18 LTS |
| Maven | Apache Maven 3.6.3+ |
| Port | 8084 |
| Service name | jek-otel-java-springboot3x-soap |
| Endpoint | `/ws/webmethods` |

## Prerequisites

- EC2 instance running CentOS Stream 9 with Java 17 and Maven (from `setup-ec2-centos9`)
- SSH access: `ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>`

## Step 1: Copy source code to the EC2 instance

From your local machine, in this skill directory:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'sudo mkdir -p /opt/cargostream/soap-server && sudo chown -R ec2-user:ec2-user /opt/cargostream'

scp -i ~/.ssh/jek_rsa_pem -r references/* \
  ec2-user@<EC2_PUBLIC_IP>:/opt/cargostream/soap-server/
```

The helper `./scripts/install.sh <EC2_PUBLIC_IP>` runs Steps 1–3 (deploy + Maven build + create log dir) in one shot. It does **not** start the server — that's Step 4 below, in an interactive SSH session you keep open. (Backgrounding from a single-shot SSH command is unreliable: the JVM gets torn down with the SSH pty on session close. Tested and confirmed.)

## Step 2: Build with Maven

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/cargostream/soap-server
mvn clean package -DskipTests
```

Produces `target/springboot3x-soap-0.0.1-SNAPSHOT.jar`.

## Step 3: Create the log directory

```bash
sudo mkdir -p /var/log/cargostream
sudo chown ec2-user:ec2-user /var/log/cargostream
```

## Step 4: Run the application

In an SSH session you'll keep open:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/cargostream/soap-server
java -jar target/springboot3x-soap-0.0.1-SNAPSHOT.jar
```

The app boots in ~7-10 seconds. Look for these lines (taken from a real run on
CentOS Stream 9, Java 17.0.18, Spring Boot 3.4.5, CXF 4.0.5):

```
o.a.c.w.s.f.ReflectionServiceFactoryBean - Creating Service {http://example.com/webmethods}WebMethodsMockService from class com.example.springboot3xsoap.endpoint.WebMethodsMockEndpoint
org.apache.cxf.endpoint.ServerImpl - Setting the server's publish address to be /webmethods
o.s.b.a.e.web.EndpointLinksResolver - Exposing 1 endpoint beneath base path '/actuator'
o.s.b.w.e.tomcat.TomcatWebServer - Tomcat started on port 8084 (http) with context path '/'
c.e.s.Springboot3xSoapApplication - Started Springboot3xSoapApplication in 7.43 seconds (process running for 8.332)
```

### Backgrounding (only if you need to close the SSH session)

If you need to free up the SSH window — e.g., to leave the app running while
you switch contexts — do this **from inside the interactive SSH session** (not
from a single-shot `ssh ... 'cmd &'`):

```bash
cd /opt/cargostream/soap-server
nohup java -jar target/springboot3x-soap-0.0.1-SNAPSHOT.jar </dev/null \
  >/var/log/cargostream/soap-server.stdout.log 2>&1 &
disown
exit  # safe — the JVM keeps running
```

`</dev/null` + `disown` is what keeps the JVM alive after the session closes;
plain `nohup ... &` from a single-shot SSH command does not (verified failing
on CentOS Stream 9).

## Step 5: Verify

Open a second SSH session (or run from your laptop using `<EC2_PUBLIC_IP>`).

### 5a. Health check (Spring Actuator — not on the CXF chain)

```bash
curl -s http://localhost:8084/actuator/health
# {"status":"UP"}
```

### 5b. WSDL fetch (CXF auto-publishes)

```bash
curl -s 'http://localhost:8084/ws/webmethods?wsdl' | head -30
```

You should see `<wsdl:definitions>` with the `submitShipment` operation in the
`http://example.com/webmethods` target namespace, plus the request/response
schema. Real captured output:

```xml
<?xml version='1.0' encoding='UTF-8'?>
<wsdl:definitions ... name="WebMethodsMockService" targetNamespace="http://example.com/webmethods">
  <wsdl:types>
    <xs:schema ... targetNamespace="http://example.com/webmethods" version="1.0">
      <xs:element name="submitShipment" type="tns:submitShipment"/>
      <xs:element name="submitShipmentResponse" type="tns:submitShipmentResponse"/>
      <xs:complexType name="submitShipment">
        <xs:sequence>
          <xs:element name="TID" type="xs:string"/>
          <xs:element minOccurs="0" name="payload" type="xs:string"/>
        </xs:sequence>
      </xs:complexType>
      <xs:complexType name="submitShipmentResponse">
        <xs:sequence>
          <xs:element name="TID" type="xs:string"/>
          <xs:element minOccurs="0" name="status" type="xs:string"/>
          <xs:element minOccurs="0" name="received_at" type="xs:string"/>
        </xs:sequence>
      </xs:complexType>
    </xs:schema>
  </wsdl:types>
  <wsdl:message name="submitShipment">...
```

### 5c. SOAP smoke test

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
`@XmlType(propOrder = ...)` on `SubmitShipmentResponse`):

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:submitShipmentResponse xmlns:ns2="http://example.com/webmethods"><TID>tid-smoke-001</TID><status>received</status><received_at>2026-05-04T14:19:04.533189391Z</received_at></ns2:submitShipmentResponse></soap:Body></soap:Envelope>
```

The `received_at` is a Java `Instant.now().toString()` — RFC 3339 / ISO 8601 with
nanosecond precision (Zulu/UTC).

### 5d. Verify fault injection

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

About 3 of 30 should return HTTP 500 (10% fault rate; Bernoulli variance is
±2-3 across n=30 — a real run on this stack returned 5/30 = 17%, which is
within expected variance. Run a second batch to confirm if the first looks
high or low). The body of each failure is a SOAP fault envelope:

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Simulated infrastructure fault on jek-otel-java-springboot3x-soap</faultstring></soap:Fault></soap:Body></soap:Envelope>
```

`/actuator/health` is unaffected — it's served by Spring MVC, not the CXF
servlet, so the fault interceptor never sees it (verified: 20/20 health checks
returned HTTP 200 during a fault-injection run).

### 5e. Check logs

```bash
cat /var/log/cargostream/soap-server.log
```

Expect entries (real captured output):

- `INFO  c.e.s.e.WebMethodsMockEndpointImpl - Received SOAP submitShipment — TID=tid-smoke-001, payload=hello`
- `WARN  c.e.s.interceptor.FaultInterceptor - FAULT INJECTION: Simulated 10% failure on {http://example.com/webmethods}submitShipment` (for the failing requests — the operation name is fully-qualified because CXF stores it as a QName in `Message.WSDL_OPERATION`)

## Understand the code — how App B receives a SOAP envelope and replies

App B's job is purely server-side: receive a SOAP envelope, log the TID, and
send back a SOAP response that echoes the TID. There's no Camel and no
outbound call — just a JAX-WS endpoint published by Apache CXF on the path
`/ws/webmethods`.

### The single most important file — `WebMethodsMockEndpointImpl.java`

Path: `references/src/main/java/com/example/springboot3xsoap/endpoint/WebMethodsMockEndpointImpl.java`

```java
@Component
@WebService(
        targetNamespace = "http://example.com/webmethods",
        endpointInterface = "com.example.springboot3xsoap.endpoint.WebMethodsMockEndpoint",
        serviceName = "WebMethodsMockService",
        portName = "WebMethodsMockPort")
public class WebMethodsMockEndpointImpl implements WebMethodsMockEndpoint {

    private static final Logger log = LoggerFactory.getLogger(WebMethodsMockEndpointImpl.class);

    @Override
    public SubmitShipmentResponse submitShipment(SubmitShipmentRequest request) {                  // [1]
        String tid = request != null ? request.getTID() : null;
        String payload = request != null ? request.getPayload() : null;

        log.info("Received SOAP submitShipment — TID={}, payload={}", tid, payload);                // [2]

        SubmitShipmentResponse response = new SubmitShipmentResponse();                             // [3]
        response.setTID(tid);
        response.setStatus("received");
        response.setReceived_at(Instant.now().toString());
        return response;
    }
}
```

**[1]** When this method runs, **CXF has already done all the SOAP work for
you** — it parsed the incoming HTTP body, validated the SOAP envelope, and
deserialized `<submitShipment>...<TID>...</TID>...</submitShipment>` into a
plain Java `SubmitShipmentRequest` object via JAXB. The `@WebService` +
`@XmlElement` annotations on `WebMethodsMockEndpoint` (the interface) and on
`SubmitShipmentRequest` (the DTO) are what told CXF how to do that mapping.

**[2]** This log line is your proof that the TID survived the wire round-trip.
You'll see the literal value you sent in the trigger curl appear here — for
example, `TID=tid-trigger-001`.

**[3]** You build a plain Java response object, set fields, and return it.
**CXF takes that return value and serializes it back into a SOAP envelope**
on the way out — no manual XML construction in your code. The same JAXB
annotations on `SubmitShipmentResponse` define the shape of the outgoing
envelope.

### The wire-binding plumbing (you write it once, then forget about it)

Two small files handle the CXF setup. You don't need to read them line-by-line
unless you're customizing the SOAP behavior:

| File | What it does |
|---|---|
| `WebMethodsMockEndpoint.java` (the SEI) | The Java interface annotated with `@WebService` and `@SOAPBinding`. CXF reads these annotations to derive the WSDL and the wire format. The DTO classes referenced in the method signatures (`SubmitShipmentRequest`, `SubmitShipmentResponse`) are JAXB-annotated to define the XML element names. |
| `CxfConfig.java` lines 20–24 | `@Bean Endpoint webMethodsEndpoint(Bus bus, WebMethodsMockEndpointImpl impl)` — `endpoint.publish("/webmethods")` mounts the implementation at `/webmethods` (relative to `cxf.path=/ws` in `application.properties`). Combined: `/ws/webmethods`. |

### How the TID flows through this app

```
   curl POSTs SOAP envelope to /ws/webmethods
       │
       ▼
   CXF servlet receives HTTP POST + parses SOAP envelope + invokes JAXB
       │
       ▼
   submitShipment(SubmitShipmentRequest request)  ← [1] in the snippet above
       │  request.getTID() returns the value from the wire
       │
       ▼
   log.info("Received SOAP submitShipment — TID=...")  ← [2]
       │
       ▼
   Build SubmitShipmentResponse + set fields  ← [3]
       │
       ▼
   CXF takes the return value, serializes to SOAP envelope, writes to HTTP response
```

That's the whole "App B" story — most of the SOAP-handling complexity lives
inside CXF, not your code. The OTel Java Extension that captures the TID
(see `create-otel-java-ext-soap`) hooks into CXF's outbound chain on the
*response* side here as well, so when App B returns a SOAP envelope to App A,
the same `<TID>` extraction fires.

## Troubleshooting

| Issue | Fix |
|---|---|
| `mvn: command not found` | Java 17 + Maven are installed by `setup-ec2-centos9` user_data. Verify with `mvn --version`. |
| Port 8084 already in use | `pkill -f 'springboot3x-soap-0.0.1-SNAPSHOT.jar'` (use the JAR-specific pattern; a bare `pkill -f springboot3x-soap` will also match the `pkill` invocation itself when run via `bash -c`, killing the parent shell and dropping the SSH session with exit 255) |
| Single-shot SSH start (`ssh ... 'nohup ... &'`) — JVM dies immediately | Single-shot SSH closes the pty on exit and the JVM gets torn down despite `nohup`. Use the `nohup ... </dev/null & disown ; exit` pattern from inside an interactive SSH session instead (Step 4). |
| `curl ... ?wsdl` returns 404 | The CXF servlet path is `/ws` (set via `cxf.path=/ws`); the endpoint is published at `/webmethods` (set via `@Bean Endpoint`). Combined: `/ws/webmethods?wsdl`. |
| Permission denied on `/var/log/cargostream` | `sudo chown ec2-user:ec2-user /var/log/cargostream` |
| Logs missing | The Logback config writes to `/var/log/cargostream/soap-server.log` — confirm the directory exists and is writable. |

## Teardown

In an interactive SSH session:

```bash
pkill -f 'springboot3x-soap-0.0.1-SNAPSHOT.jar' 2>/dev/null
rm -rf /opt/cargostream/soap-server
sudo rm -f /var/log/cargostream/soap-server.log* /var/log/cargostream/soap-server.stdout.log
```

From a single-shot `ssh ... "cmd"` invocation (e.g. a script on your laptop), use
port-based killing instead — `pkill -f` inside `bash -c` will match its own
command line and SIGKILL the parent shell, dropping SSH with exit 255:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> '
  sudo fuser -k 8084/tcp
  rm -rf /opt/cargostream/soap-server
  sudo rm -f /var/log/cargostream/soap-server.log* /var/log/cargostream/soap-server.stdout.log
'
```

## Next Step

After verifying the SOAP server runs, build the upstream Camel + CXF SOAP client
with `setup-springboot3x-apachecamel-soap`, then instrument both apps with
`springboot3x-otel-java-tool-opt`.
