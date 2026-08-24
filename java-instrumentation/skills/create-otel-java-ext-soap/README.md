# create-otel-java-ext-soap — End-to-End Walkthrough

Build, deploy, and verify an OTel Java extension JAR that captures `<TID>`
from an outgoing CXF SOAP envelope and adds it as a `tid` span attribute that
shows up in Datadog APM. **No application code changes** — Spring Boot
`@AutoConfiguration` picks it up via `-Dloader.path` at JVM start, and the
interceptor registers itself on CXF's default Bus.

This is the OUTBOUND SOAP-client variant of `create-otel-java-ext` (which is
INBOUND HTTP-server via Servlet Filter). Both use the same shaded-OTel-API
+ Spring Boot AutoConfiguration plumbing — only the interception point
differs.

## What you'll build

A ~213 KB Maven-built JAR (`otel-extension-soap-tid-1.0.jar`) containing:

- A CXF `AbstractPhaseInterceptor<Message>` that wraps the outbound
  SOAP envelope's OutputStream
- A Spring Boot `@AutoConfiguration` that registers the interceptor on
  `BusFactory.getDefaultBus()` at app start
- A shaded copy of the OTel API 1.48.0 (so the extension's classloader can
  resolve `io.opentelemetry.api.trace.Span`)

The end-state is: when App A makes a SOAP call, every outgoing envelope is
inspected for `<TID>...</TID>`, and if found the value lands as a `tid`
attribute on the active OTel span — visible in the OTel Collector debug
exporter and in Datadog APM Trace Inspector.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3+ |
| OTel API | 1.48.0 (shaded into JAR — compile scope) |
| OTel Java Agent | 2.26.1 (provided by `springboot3x-otel-java-tool-opt`) |
| Apache CXF | 4.0.5 (provided by the consuming app) |
| Spring Boot | 3.4.5 (provided by the consuming app) |
| Maven layout (consuming app) | `ZIP` (PropertiesLauncher; required for `-Dloader.path`) |

## Architecture (the picture before you start)

```
                   ┌─────────────────────────────────────────────────────────┐
                   │ App A (port 8083) — setup-springboot3x-apachecamel-soap │
                   │  Camel REST DSL ── direct:submit-shipment ──┐           │
                   │     /jek-trigger              │             │           │
                   │  (curl posts JSON here)       ▼             │           │
                   │                  WebMethodsClient (CXF JAX-WS proxy)    │
                   │                          │                              │
                   │                          ▼                              │
                   │  CXF OUT chain (PRE_STREAM phase)                       │
                   │   ─► SoapTidOutInterceptor wraps OutputStream ◄────┐    │
                   │       (THIS SKILL's interceptor)                   │    │
                   │   ─► StaxOutInterceptor writes envelope bytes      │    │
                   │   ─► OutputStream.close() → onClose callback fires─┘    │
                   │       ─► regex ExtractTID → Span.current().setAttribute │
                   │                                                         │
                   │  HTTP send (java.net.http.HttpClient, port 8084) ──────►│
                   └─────────────────────────────────────┬───────────────────┘
                                                         │ HTTP POST + SOAP envelope
                                                         ▼
                   ┌─────────────────────────────────────────────────────────┐
                   │ App B (port 8084) — setup-springboot3x-soap             │
                   │  CXF /ws/webmethods + WebMethodsMockEndpointImpl        │
                   │  Returns SOAP envelope echoing TID                      │
                   └─────────────────────────────────────────────────────────┘

   Both apps inherit JAVA_TOOL_OPTIONS from /etc/profile.d/otel-java.sh:
     -javaagent:/opt/otel/opentelemetry-javaagent.jar
     -Dloader.path=/opt/otel/extensions/        ← THIS SKILL drops the JAR here
     -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318
   ↓
   OTel Collector (otelcol-contrib :4318)  →  Datadog APM EU (datadoghq.eu)
```

## Prerequisites

Confirm all of these before you start. The walkthrough assumes you've already
executed:

- [ ] **Layer 1** (`demo-TODO-aws-ec2.md`) — EC2 host up, OTel
      Collector running, traces flowing to Datadog
- [ ] **`setup-springboot3x-soap`** (App B / the webMethods mock) deployed at
      `/opt/cargostream/soap-server` and started in a session
- [ ] **`setup-springboot3x-apachecamel-soap`** (App A / the SOAP client)
      deployed at `/opt/cargostream/soap-client` and started in a session
- [ ] **`springboot3x-otel-java-tool-opt`** has been run as `sudo
      ./setup-java-tool-options.sh` so `/opt/otel/opentelemetry-javaagent.jar`
      exists and `JAVA_TOOL_OPTIONS` is in `/etc/profile.d/otel-java.sh`

If any of those are missing, follow each skill in order before continuing
here.

---

## Step 0: Sanity-check the consuming app uses PropertiesLauncher

`-Dloader.path` is silently ignored unless the Spring Boot app is built with
`<layout>ZIP</layout>`, which switches the JAR's launcher from `JarLauncher`
to `PropertiesLauncher`. Confirm:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'unzip -p /opt/cargostream/soap-client/target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar \
       META-INF/MANIFEST.MF | grep -E "Main-Class|Start-Class"'
```

Real captured output:

```
Main-Class: org.springframework.boot.loader.launch.PropertiesLauncher
Start-Class: com.example.springboot3xcamelsoap.Springboot3xCamelSoapApplication
```

If you see `JarLauncher` instead, the app's `pom.xml` is missing
`<layout>ZIP</layout>` — fix it and rebuild before continuing.

## Step 1: Copy the extension source onto the EC2 instance

From your local machine, in the `create-otel-java-ext-soap` skill directory:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'sudo mkdir -p /opt/otel/extensions-src/soap-tid /opt/otel/extensions && \
   sudo chown -R ec2-user:ec2-user /opt/otel'

scp -i ~/.ssh/jek_rsa_pem -r references/* \
  ec2-user@<EC2_PUBLIC_IP>:/opt/otel/extensions-src/soap-tid/
```

Or use the helper: `./scripts/install.sh <EC2_PUBLIC_IP>` runs Steps 1–4 in
one shot. The walkthrough below is the manual version of what the helper
does — useful when you're learning the moving pieces.

## Step 2: Build the extension JAR with Maven

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
cd /opt/otel/extensions-src/soap-tid
mvn clean package
```

First run downloads CXF + Spring Boot + OTel API + maven-shade-plugin (~30 s
with internet access). Subsequent runs are <10 s. Output:

```
target/otel-extension-soap-tid-1.0.jar
```

Real captured size: **213 KB**. The size comes from the shaded OTel API
classes — the maven-shade-plugin bundles every compile-scope dependency into
the final JAR. Provided-scope deps (CXF, Spring Boot, SLF4J) are excluded
because the consuming app already has them.

### Why is the OTel API shaded in?

The OTel Java Agent injects `io.opentelemetry.api.*` classes into the
**bootstrap classloader**. Spring Boot's `PropertiesLauncher` (used because
the app has `<layout>ZIP</layout>`) loads extension JARs into a **child
classloader** that cannot see classes loaded into the bootstrap classloader.
If the OTel API were declared `provided` scope, you'd hit
`NoClassDefFoundError: io/opentelemetry/api/trace/Span` on extension load.

Shading bundles the OTel API classes inside the extension JAR — and the
agent's bridge logic still routes `Span.current().setAttribute(...)` to the
real, agent-managed span. So this is a load-time workaround, not a behavioral
divergence.

## Step 3: Stage the JAR in `/opt/otel/extensions/`

```bash
cp target/otel-extension-soap-tid-1.0.jar /opt/otel/extensions/
ls -lh /opt/otel/extensions/
```

This is the directory `springboot3x-otel-java-tool-opt`'s system-wide
`JAVA_TOOL_OPTIONS` points `-Dloader.path` at, so any `<layout>ZIP</layout>`
Spring Boot app started after this point will pick up the extension via
Spring's `@AutoConfiguration` discovery.

## Step 4: Inspect the JAR contents

```bash
jar tf /opt/otel/extensions/otel-extension-soap-tid-1.0.jar \
  | grep -E 'SoapTid|opentelemetry/api/trace/Span\.class|AutoConfiguration\.imports' \
  | head -10
```

Real captured output:

```
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
com/example/otelextsoap/SoapTidOutInterceptor$TidCaptureCallback.class
com/example/otelextsoap/SoapTidOutInterceptor.class
com/example/otelextsoap/SoapTidAutoConfiguration.class
io/opentelemetry/api/trace/Span.class
```

Why each entry matters:

- `SoapTidOutInterceptor.class` — the CXF interceptor (registered on the OUT
  chain at `Phase.PRE_STREAM`)
- `SoapTidOutInterceptor$TidCaptureCallback.class` — the `CachedOutputStreamCallback`
  inner class that fires on stream close
- `SoapTidAutoConfiguration.class` — the `@AutoConfiguration` that wires the
  interceptor onto `BusFactory.getDefaultBus()`
- `org.springframework.boot.autoconfigure.AutoConfiguration.imports` —
  Spring Boot 3.x's discovery file. Without this, the auto-config class is
  inert; with it, Spring Boot finds and instantiates the bean at app start
- `io/opentelemetry/api/trace/Span.class` — confirms the OTel API was
  actually shaded (this is the test for "did the shade plugin run correctly")

## Step 5: Restart App A so the extension loads

The extension is discovered at JVM start, so any app that's already running
won't pick it up. Restart App A:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
sudo fuser -k 8083/tcp 2>/dev/null   # stop the running App A; ignore if none
sleep 2
. /etc/profile.d/otel-java.sh        # source JAVA_TOOL_OPTIONS (-javaagent + -Dloader.path)
cd /opt/cargostream/soap-client
OTEL_SERVICE_NAME=jek-springboot3x-soap-client-demo \
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=jek-poc-demo,datadog.host.name=jek-ec2-centos9-demo \
java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar
```

Watch for these three real-captured boot lines (in order):

```
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/opentelemetry-javaagent.jar -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar -Dloader.path=/opt/otel/extensions/ ...
[otel.javaagent 2026-05-04 14:51:03:640 +0000] [main] INFO io.opentelemetry.javaagent.tooling.VersionLogger - opentelemetry-javaagent - version: 2.26.1
2026-05-04 14:51:18,722 [main] INFO  c.e.o.SoapTidAutoConfiguration - OTel SOAP extension — registered SoapTidOutInterceptor on default Bus
```

The third line is the key signal that **this skill is working**:
`SoapTidAutoConfiguration` found the JAR via `-Dloader.path`, instantiated
itself, and registered the interceptor on `BusFactory.getDefaultBus()`.

> **Tip**: if you also restart App B (port 8084) using the same JAVA_TOOL_OPTIONS
> flow, App B's interceptor will fire too — on its outgoing **response**
> envelopes (which echo the TID back). This is harmless and gives you the
> attribute on App B's server span as well.

### If you'd rather background the JVM

From inside the interactive SSH session (not from `ssh ... 'cmd &'` — see
`setup-springboot3x-soap/README.md` for why):

```bash
nohup java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar </dev/null \
  >/var/log/cargostream/soap-client.stdout.log 2>&1 &
disown
exit
```

## Step 6: Trigger a SOAP call and watch the interceptor fire

From your laptop or a second SSH session:

```bash
curl -sS -X POST http://<EC2_PUBLIC_IP>:8083/jek-trigger \
  -H 'Content-Type: application/json' \
  -d '{"tid":"tid-ext-success-1","payload":"hello-from-extension"}'
```

Successful response (real captured):

```json
{"tid":"tid-ext-success-1","status":"received","received_at":"2026-05-04T14:52:28.140776421Z"}
```

If you get HTTP 500 with an empty body, that's App B's 10% fault injection
firing (see `setup-springboot3x-soap` README 5d). Re-run a few times until
you get a 200 — the extension still captures the TID on faulted calls
because the OUT chain runs before the request even leaves App A.

App A's interceptor log (real captured) should show:

```
2026-05-04 14:51:38,304 [task-1] INFO  c.e.s.route.TriggerRoute - Calling webMethods SOAP submitShipment — TID=tid-ext-success-1
2026-05-04 14:52:28,109 [task-2] INFO  c.e.o.SoapTidOutInterceptor - OTel SOAP extension — captured tid=tid-ext-success-1
```

The two log lines together prove: (1) the Camel route reached the SOAP call,
and (2) our interceptor's regex extracted the TID from the serialized
envelope. Tail with:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'tail -f /var/log/cargostream/soap-client.log'
```

## Step 7: Verify the attribute in the OTel Collector debug exporter

The collector's `debug` exporter logs every span it receives to journald.
This is the lowest-latency way to confirm the attribute is on the wire
*before* it hits Datadog (typically within ~1 second of the trigger):

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'sudo journalctl -u otelcol-contrib --since "2 minutes ago" --no-pager \
     | grep -B 25 "Str(tid-ext-success-1)" | tail -30'
```

Real captured output:

```
Span #0
    Name           : POST /jek-trigger
    Kind           : Server
    Trace ID       : f5838b7c338d7e18fee5e04c7d2c44d4
    ID             : 2b5bad7139905185
Attributes:
     -> http.response.status_code: Int(200)
     -> user_agent.original: Str(curl/7.76.1)
     -> server.port: Int(8083)
     -> tid: Str(tid-ext-success-1)
     -> http.request.method: Str(POST)
     -> url.path: Str(/jek-trigger)
```

The `tid` attribute is present on App A's `POST /jek-trigger` server span.
(In a separate batch you'll see App B's `/ws/WebMethodsMockService/submitShipment`
server span also carry the attribute if App B's extension is mounted — that's
because App B's interceptor fires on the outgoing response.)

### Why the attribute landed on the server span (not a separate HTTP-client span)

CXF's `Phase.PRE_STREAM` runs while the envelope is still being serialized,
**before** the OTel Java Agent's `java.net.http.HttpClient` instrumentation
creates a child HTTP-client span for the wire send. So when our `onClose`
callback fires inside `Phase.PRE_STREAM`'s wrapped output stream,
`Span.current()` is still the **parent** server span (the one Tomcat created
for the inbound `/jek-trigger`). The agent's HTTP-client span gets created
right after, but doesn't receive our attribute.

In Datadog APM this is fine — `tid:<value>` is searchable on the trace
regardless of which span carries the attribute. If you specifically want it
on the HTTP-client child span, you'd need to move the interceptor to a later
phase (e.g., `Phase.WRITE_ENDING`) AND ensure the wrapped stream's close fires
inside the agent's HTTP-client scope. For most PoCs the parent-span placement
is what you want anyway.

## Step 8: Verify in Datadog APM EU UI

Confirmed working — captured screenshot from the live PoC shows `tid` as a
span attribute in Datadog APM Trace Inspector:

- Open `https://app.datadoghq.eu`
- **APM → Traces** → search bar: `service:jek-springboot3x-soap-client-demo`
  (substitute your service name if different)
- Click any recent trace → click the span named `POST /jek-trigger` (or the
  parent span carrying the trigger)
- In the right-hand "Tags" panel, scroll until you see `tid`. The value is
  the literal TID you sent in the trigger:

  ```
  tid    tid-ext-success-1
  ```

That's the success state. If `tid` is missing, work backward through the
troubleshooting table.

### Optional: make `tid` a Datadog facet for searching

By default, span attributes are searchable as `@tid:<value>` in the trace
search bar. To make `tid:<value>` a first-class facet (for filtering /
aggregation), open the trace, click the `tid` attribute → "Create facet". You
only need to do this once per Datadog org.

---

## How this extension extracts the TID — educational walkthrough

This section walks you through *why* the extension works, not just *how* to
use it. Read it once and the regex/auto-config patterns will make sense for
any prospect code you adapt this skill to.

### 1. The code we're intercepting (App A's SOAP-sending line)

The whole job of this extension is to fire when **one specific line in App A
runs**:

```java
// File: setup-springboot3x-apachecamel-soap/.../route/TriggerRoute.java (line 67)
SubmitShipmentResponse resp = webMethodsClient.submitShipment(req);
```

`webMethodsClient` is a CXF JAX-WS proxy built like this:

```java
// File: setup-springboot3x-apachecamel-soap/.../client/CxfClientConfig.java (lines 21-24)
JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
factory.setServiceClass(WebMethodsClient.class);
factory.setAddress(endpoint);
return (WebMethodsClient) factory.create();
```

When App A invokes `webMethodsClient.submitShipment(req)`, CXF runs an
**OUT chain** of interceptors before sending bytes to the wire. Each
interceptor lives in a named "phase" — `PRE_LOGICAL`, `PRE_STREAM`, `WRITE`,
`SEND`, etc. Our extension registers an interceptor in **`PRE_STREAM`**.

That phase is the sweet spot because:
- It runs **before** CXF's StAX writer starts emitting envelope bytes,
  so we can swap the `OutputStream` cleanly.
- It runs **after** the JAXB serialization decision has been made,
  so the envelope content is determined.
- It's still on the same thread as the HTTP send, so `Span.current()`
  resolves to the OTel agent's active span at the moment of capture.

### 2. The interceptor — `SoapTidOutInterceptor.java`

Path: `references/src/main/java/com/example/otelextsoap/SoapTidOutInterceptor.java`

#### 2a. Pick the phase and inherit from CXF's base class

```java
public class SoapTidOutInterceptor extends AbstractPhaseInterceptor<Message> {

    public SoapTidOutInterceptor() {
        super(Phase.PRE_STREAM);
    }
```

`AbstractPhaseInterceptor<Message>` is CXF's base for any interceptor that
wants to inspect or modify the message in flight. Passing `Phase.PRE_STREAM`
to the superclass constructor tells CXF when to invoke us in the chain.

#### 2b. Wrap the OutputStream in `handleMessage`

```java
@Override
public void handleMessage(Message message) throws Fault {
    OutputStream os = message.getContent(OutputStream.class);                   // [1]
    if (os == null) {
        return;
    }
    CacheAndWriteOutputStream cwos = new CacheAndWriteOutputStream(os);          // [2]
    message.setContent(OutputStream.class, cwos);                                // [3]
    cwos.registerCallback(new TidCaptureCallback());                             // [4]
}
```

**[1]** Pull the current outbound `OutputStream` from the CXF message — this
is the stream CXF's StAX writer is about to write the envelope bytes into.
**[2]** Wrap it in `CacheAndWriteOutputStream`, which is a pre-built CXF
utility that *both* writes bytes through to the underlying stream *and*
caches them in memory so we can read them later. **[3]** Replace the message's
OutputStream with our wrapper — now every byte CXF writes flows through us.
**[4]** Register a callback that fires when the stream is closed (i.e. when
the envelope has been fully written).

We do **not** modify the bytes — the wrapper is transparent.

#### 2c. The `onClose` callback — extract TID and write to span

```java
@Override
public void onClose(CachedOutputStream cos) {
    try {
        StringBuilder envelope = new StringBuilder();
        cos.writeCacheTo(envelope);                                              // [5]
        Matcher m = TID_PATTERN.matcher(envelope);                               // [6]
        if (m.find()) {
            String tid = m.group(1);
            Span.current().setAttribute("tid", tid);                             // [7]  ★
            log.info("OTel SOAP extension — captured tid={}", tid);
        }
    } catch (IOException e) {
        log.debug("OTel SOAP extension — could not read cached envelope: {}",
                e.getMessage());
    }
}
```

**[5]** `writeCacheTo(StringBuilder)` reads the cached envelope bytes
and decodes them as UTF-8 into a `StringBuilder`. We now have the full
SOAP envelope as a Java String. **[6]** Run the regex
`<(?:\w+:)?TID>([^<]+)</(?:\w+:)?TID>` against the envelope. The
`(?:\w+:)?` prefix tolerates either `<TID>` or `<ns2:TID>` shapes —
prospects vary on whether their wire envelopes carry a namespace prefix on
body elements. **[7] ★ This is where the magic happens**:
`Span.current()` returns the OTel agent's active span on the current thread.
`setAttribute("tid", tid)` writes a key-value pair onto that span — a pair
that Datadog APM treats as a searchable trace tag.

`Span.current()` is provided by the **shaded OTel API** classes inside
*this JAR* — but the call still resolves to the *agent's* live span,
because the OTel agent rewrites the API at bootstrap time to bridge to its
real instrumentation. That's why we can use the API freely without
depending on the agent at compile time.

### 3. The auto-configuration — `SoapTidAutoConfiguration.java`

Path: `references/src/main/java/com/example/otelextsoap/SoapTidAutoConfiguration.java`

```java
@AutoConfiguration
public class SoapTidAutoConfiguration {

    private static final Logger log = LoggerFactory.getLogger(SoapTidAutoConfiguration.class);

    @Bean
    public SoapTidOutInterceptor soapTidOutInterceptor() {
        SoapTidOutInterceptor interceptor = new SoapTidOutInterceptor();      // [1]
        Bus bus = BusFactory.getDefaultBus();                                  // [2]
        bus.getOutInterceptors().add(interceptor);                             // [3]
        log.info("OTel SOAP extension — registered SoapTidOutInterceptor on default Bus");
        return interceptor;
    }
}
```

This is **the wiring that makes the interceptor actually run**. Without
this, the JAR is just a class file sitting on disk.

**[1]** Instantiate the interceptor. **[2]** `BusFactory.getDefaultBus()`
returns CXF's JVM-wide default Bus (a singleton, lazily created the first
time anyone asks for it). The consuming app's
`JaxWsProxyFactoryBean.create()` *also* uses the default Bus when no
explicit Bus is set — so we end up registered on the same Bus the SOAP
client uses. **[3]** Add the interceptor to the Bus's outbound interceptor
list. From this moment on, every outbound SOAP message that goes through
this Bus runs through our `handleMessage` → `onClose` flow.

The class is annotated `@AutoConfiguration` (Spring Boot 3.x) — Spring
discovers it via the `META-INF/spring/...AutoConfiguration.imports` file
in the JAR's resources. That file contains exactly one line:

```
com.example.otelextsoap.SoapTidAutoConfiguration
```

If you ever rename the class, you must update that file too — otherwise
Spring can't find the class and the extension silently doesn't load.

---

## Loading and testing — recap

You've already done the loading and testing in Steps 0-8 above. Here's the
mental model in three lines:

**Loading.** `springboot3x-otel-java-tool-opt` sets system-wide
`JAVA_TOOL_OPTIONS=... -Dloader.path=/opt/otel/extensions/ ...`. When App A
starts, Spring Boot's `PropertiesLauncher` (active because App A's pom has
`<layout>ZIP</layout>`) scans every JAR under `-Dloader.path` for
`META-INF/spring/...AutoConfiguration.imports`, finds ours, instantiates
`SoapTidAutoConfiguration`, and our interceptor lands on the Bus before
any SOAP call fires.

**Testing — three confirmation signals in order.**

| Signal | Where to look | What you should see |
|---|---|---|
| 1. Extension loaded | App A's startup log | `OTel SOAP extension — registered SoapTidOutInterceptor on default Bus` |
| 2. Interceptor fired | App A's runtime log after a trigger | `OTel SOAP extension — captured tid=<value>` |
| 3. Attribute on span | OTel Collector debug exporter (`journalctl -u otelcol-contrib`) | `-> tid: Str(<value>)` in the span attributes block |
| 4. Visible in Datadog | `app.datadoghq.eu` → APM → Traces → service search → click trace → Tags panel | `tid    <value>` row |

If any signal is missing, drop into the **Troubleshooting** table below —
each row maps a missing signal to the most common root cause and the fix.

---

## What each source file does

| File | Purpose |
|---|---|
| `references/src/main/java/com/example/otelextsoap/SoapTidOutInterceptor.java` | CXF `AbstractPhaseInterceptor<Message>` in `Phase.PRE_STREAM` on the OUT chain. Wraps the outgoing `OutputStream` with CXF's `CacheAndWriteOutputStream`. The callback (private static inner class) fires on stream close, regex-extracts `<TID>([^<]+)</TID>` (with optional XML namespace prefix tolerance), and calls `Span.current().setAttribute("tid", value)`. |
| `references/src/main/java/com/example/otelextsoap/SoapTidAutoConfiguration.java` | Spring Boot `@AutoConfiguration` — instantiates the interceptor at app start and adds it to `BusFactory.getDefaultBus().getOutInterceptors()` (the same default Bus that `JaxWsProxyFactoryBean.create()` uses). Logs the registration at INFO so you can confirm the extension loaded. |
| `references/pom.xml` | Maven build with OTel API in `compile` scope (shaded into the JAR), CXF + Spring Boot + SLF4J in `provided` scope, and `maven-shade-plugin` configured for the `package` phase. |
| `references/src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` | Single-line file containing the FQN of the auto-configuration class — Spring Boot 3.x's discovery mechanism. Without this, the auto-config class is invisible to Spring. |

## Troubleshooting

| Symptom | Root cause | Fix |
|---|---|---|
| `mvn clean package` fails with `no suitable method found for writeCacheTo(java.io.StringWriter)` | CXF's `CachedOutputStream.writeCacheTo` only accepts `OutputStream` or `StringBuilder` (not `StringWriter`) | Use `StringBuilder` in the callback. The reference source does this; this row exists because we hit the bug live during this skill's first build. |
| `NoClassDefFoundError: io/opentelemetry/api/trace/Span` at app start | OTel API is `provided` scope instead of `compile` (so the shade plugin doesn't bundle it) | Make `opentelemetry-api` `compile` scope in `pom.xml` and rebuild — confirm `io/opentelemetry/api/trace/Span.class` is in the output JAR via `jar tf`. |
| `tid` attribute not showing on any span | App A doesn't have the OTel Java Agent loaded | Check App A's stdout for `Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/...`. Without the agent, `Span.current()` is a no-op and `setAttribute` is silently dropped. |
| Auto-config bean not registered (no `OTel SOAP extension — registered SoapTidOutInterceptor on default Bus` line) | `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` is missing or has the wrong class FQN | Confirm with `jar tf <JAR> \| grep AutoConfiguration.imports` and inspect the file content with `unzip -p <JAR> META-INF/spring/...`. |
| `-Dloader.path` is set but the extension isn't picked up | The consuming app uses `JarLauncher` instead of `PropertiesLauncher` | Add `<layout>ZIP</layout>` to `spring-boot-maven-plugin` configuration in the consuming app's `pom.xml` and rebuild. Verify with `unzip -p <APP_JAR> META-INF/MANIFEST.MF \| grep Main-Class`. |
| Multiple `<TID>` matches in one envelope | Regex `Matcher.find()` is called once, so only the first match wins | If you need every match, replace `if (m.find())` with a `while (m.find())` loop and either set multiple attributes or join the values. |
| Trigger returns HTTP 500 every time | App B is down (not a fault-injection issue) | `curl -sf http://localhost:8084/actuator/health` — should return `{"status":"UP"}`. If not, restart App B. |
| `tid` shows up on the HTTP-client child span instead of the parent | The OTel agent's HTTP-client instrumentation IS firing, and our `onClose` runs inside its scope | This is also fine — it's just a different placement. The trace is still searchable on `tid:<value>`. |

## Adapting for prospect code

The TID extraction is a single regex constant. To target a different field
(say `correlationId`):

```java
// CURRENT (in SoapTidOutInterceptor.java):
private static final Pattern TID_PATTERN =
    Pattern.compile("<(?:\\w+:)?TID>([^<]+)</(?:\\w+:)?TID>");

// CHANGE TO: prospect's field name (the (?:\\w+:)? prefix tolerates XML namespace prefixes
// like <ns2:correlationId> or <wm:correlationId>):
private static final Pattern TID_PATTERN =
    Pattern.compile("<(?:\\w+:)?correlationId>([^<]+)</(?:\\w+:)?correlationId>");
```

Then change the attribute name in the same file to match:

```java
Span.current().setAttribute("correlation.id", tid);   // Datadog convention prefers dot-separated names
```

To extract multiple fields, add more `Pattern` constants and a corresponding
`setAttribute` call for each — mirror the multi-field structure in
`create-otel-java-ext`'s `XmlAttributeExtractorFilter`.

### Customer code snippet → tailored extension

If you have a snippet of the customer's actual SOAP-client code, a WSDL, or a
captured envelope, see **`SKILL.md` → "Adapting from a customer code snippet"**
for the full signal-extraction checklist + mapping table + worked examples
covering Apache CXF, Spring Web Services, and JAX-WS RI / Metro. That section
also lists the clarifying questions to ask when a signal isn't visible in the
shared snippet (e.g., "which SOAP framework?", "what's the exact wire element
name?") — guessing on those produces a JAR that compiles cleanly but silently
never matches anything, which is the worst-case PoC outcome.

## Teardown

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
sudo fuser -k 8083/tcp                                       # stop App A first
sudo rm -f /opt/otel/extensions/otel-extension-soap-tid-1.0.jar
rm -rf /opt/otel/extensions-src/soap-tid
```

App A will pick up the absence of the JAR on its next start (no error, no
`registered SoapTidOutInterceptor` log line — confirming the extension is
gone).

## Next Step

Hand off to `load-otel-java-ext` for the same Step-5/Step-8 walkthrough using
its conventions (it's the same flow, but described from the load-side rather
than the build-side perspective).
