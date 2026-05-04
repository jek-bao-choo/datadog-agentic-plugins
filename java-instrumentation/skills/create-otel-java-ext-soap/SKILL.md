---
name: create-otel-java-ext-soap
description: >-
  Create an OTel Java extension JAR that intercepts an outgoing CXF SOAP call
  on the client side, extracts `<TID>...</TID>` from the envelope, and adds it
  as a `tid` span attribute via `Span.current().setAttribute("tid", value)`.
  Validated end-to-end: `tid` shows up in the OTel Collector debug exporter
  output and in Datadog APM EU Trace Inspector's Tags panel. Sister skill to
  `create-otel-java-ext` (which is an INBOUND Jakarta Servlet Filter parsing
  the request body server-side); this one is the OUTBOUND CXF interceptor
  variant for SOAP clients. No application code changes — uses Spring Boot
  `@AutoConfiguration` to register the CXF interceptor on the default Bus.
  OTel API is shaded into the JAR (PropertiesLauncher classloader can't see
  bootstrap-classloader classes injected by the agent). Loaded into the
  consuming app via `-Dloader.path`. Use this whenever the user wants to
  attach a SOAP-payload field as a span attribute on an outbound CXF JAX-WS
  call without modifying app code, OR when the user provides a customer
  SOAP-client code snippet / WSDL / captured envelope and asks for an
  extension tailored to that customer's tech stack — this skill adapts the
  regex pattern, attribute name, and namespace handling based on the snippet.
  See "Adapting from a customer code snippet" section.
version: 0.1.0
version_matrix:
  java_version: [17]
  cxf_version: [4.0.5]
  opentelemetry_version: [1.48.0]
---

# Create OTel Java Extension — SOAP TID Outbound Interceptor

Build a JAR that automatically extracts `<TID>` from the outgoing SOAP envelope
of a CXF JAX-WS client call and adds it as a `tid` OTel span attribute. Loaded
into the consuming app (`setup-springboot3x-apachecamel-soap`) via
`-Dloader.path` — zero app code changes.

## How it works

```
App A invokes WebMethodsClient.submitShipment(req)
  → CXF JaxWsProxyFactoryBean serializes the SOAP envelope
  → OUT chain runs (PRE_STREAM phase)
  → SoapTidOutInterceptor wraps the OutputStream with CacheAndWriteOutputStream
  → CXF writes the envelope through the wrapped stream
  → On stream close, the cache callback regex-extracts <TID>([^<]+)</TID>
  → Calls Span.current().setAttribute("tid", value)
  → OTel agent flushes the active span → OTLP collector → Datadog
```

The extension is a Spring Boot auto-configuration library, discovered via
`META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.
It registers a single CXF interceptor on the default Bus
(`BusFactory.getDefaultBus()`) — the same Bus that
`JaxWsProxyFactoryBean.create()` uses by default in App A.

### Which span gets the `tid` attribute (validated on a real run)

`Span.current()` returns whichever span is active **on the calling thread at
the moment the OutputStream's `onClose` callback fires**. In CXF 4.x with the
OTel Java Agent 2.26.1, this turns out to be the **surrounding server span**
that the agent's Tomcat instrumentation created for the inbound HTTP request
that *triggered* the SOAP call — NOT a separate CXF/HTTP-client child span.

That's because PRE_STREAM (and the resulting onClose) runs while CXF is still
serializing the envelope, before the agent's `java.net.http.HttpClient`
instrumentation creates a child client span for the actual wire send. So:

- On App A: `tid` lands on the `POST /jek-trigger` server span (the inbound
  REST endpoint that Camel routes through the SOAP client).
- On App B (if the extension is also loaded there — see "Loading on App B"
  below): `tid` lands on the `/ws/WebMethodsMockService/submitShipment` server
  span, captured from the **outgoing response** envelope which echoes the same
  TID back.

In Datadog APM both spans live in the same trace — searching `tid:<value>`
returns the trace whether you set the attribute on the parent server span or a
hypothetical client child span. The captured behavior is documented here so
downstream filtering / facet creation is set up correctly.

### Loading on App B

The system-wide `JAVA_TOOL_OPTIONS` configured by `springboot3x-otel-java-tool-opt`
includes `-Dloader.path=/opt/otel/extensions/`. That means **every Spring Boot
app on the host with `<layout>ZIP</layout>` picks up this extension** —
including App B. App B's interceptor fires on its outgoing SOAP **response**
(not the incoming request — CXF's OUT chain is for outbound messages on either
side of the wire). This is harmless and gives you `tid` on App B's server span
"for free." If you want the extension scoped to App A only, either skip
`-Dloader.path` in the system-wide options and add it ad-hoc to App A's
launch, or stage app-specific extension subdirectories.

## Prerequisites

- Java 17 + Maven (from `setup-ec2-centos9`)
- The consuming Spring Boot app must use `<layout>ZIP</layout>` in
  `spring-boot-maven-plugin` so `PropertiesLauncher` is the entry point.
  Required for `-Dloader.path` to work. Both
  `setup-springboot3x-apachecamel-soap` and `setup-springboot3x-soap` set this
  by default.
- The OTel Java Agent must be running on the consuming app
  (`springboot3x-otel-java-tool-opt`) so there's an active client span for
  `Span.current()` to write to. Without the agent, `Span.current()` returns the
  no-op span and `setAttribute` is silently dropped.
- App B (`setup-springboot3x-soap`) must be running on port 8084 — otherwise
  the SOAP call fails before the envelope is fully serialized; the cache
  callback may still fire on partial bytes.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3+ |
| OTel API | 1.48.0 (**shaded into JAR** — compile scope, NOT provided) |
| Apache CXF | 4.0.5 (provided by the consuming app) |
| Spring Boot | 3.4.5 (provided by the consuming app) |
| Extension JAR name | `otel-extension-soap-tid-1.0.jar` |
| Extension JAR size | 213 KB (real captured size; includes shaded OTel API) |

## Why shaded OTel API

The OTel Java Agent injects `io.opentelemetry.api.*` classes into the bootstrap
classloader. Spring Boot's `PropertiesLauncher` (used because the consuming app
has `<layout>ZIP</layout>`) loads extension JARs into a child classloader that
cannot see bootstrap-loaded classes. If `opentelemetry-api` is `provided`
scope, you'll get `NoClassDefFoundError: io/opentelemetry/api/trace/Span` at
extension load. Shading bundles the OTel API classes inside the extension JAR
so the child classloader can see them — and the OTel agent's
`Span.current()` call still resolves correctly because `setAttribute` writes
to the active span via the agent's bridge logic.

## What's in the JAR

| File | Purpose |
|---|---|
| `SoapTidOutInterceptor.class` | CXF `AbstractPhaseInterceptor<Message>` in `Phase.PRE_STREAM` on the OUT chain. Wraps the outgoing `OutputStream` with CXF's `CacheAndWriteOutputStream`, registers a callback that fires on stream close; the callback regex-extracts `<TID>` and calls `Span.current().setAttribute("tid", value)`. |
| `SoapTidAutoConfiguration.class` | Spring Boot `@AutoConfiguration` — instantiates the interceptor and adds it to `BusFactory.getDefaultBus().getOutInterceptors()`. |
| `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` | Tells Spring Boot to discover the auto-configuration class. |
| `io/opentelemetry/api/**` | Shaded OTel API classes. |

## Build

```bash
cd references/
mvn clean package
# Produces target/otel-extension-soap-tid-1.0.jar
```

The `scripts/install.sh <EC2_PUBLIC_IP>` helper does the build + scp +
copy-to-extensions-dir in one shot. It does NOT restart the consuming app —
that's done separately when launching App A with `-Dloader.path` plus the
OTel agent.

## Validation

The full path requires:

1. App B running (`setup-springboot3x-soap` Step 4)
2. OTel Java Agent installed system-wide (`springboot3x-otel-java-tool-opt`)
3. App A running with the agent + this extension on `-Dloader.path`
4. OTel Collector running on `127.0.0.1:4318` (already done by
   `install-otelcol-contrib`)

Trigger a SOAP call:

```bash
curl -sS -X POST http://localhost:8083/jek-trigger \
  -H 'Content-Type: application/json' \
  -d '{"tid":"tid-ext-001","payload":"hello"}'
```

App A's interceptor logs the capture immediately:

```
INFO  c.e.o.SoapTidOutInterceptor - OTel SOAP extension — captured tid=tid-ext-001
```

Within ~5-10 s the OTel Collector debug exporter logs the span carrying the
attribute. Real captured (`tid-ext-success-1` was used in the validation run):

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
     -> tid: Str(tid-ext-success-1)                   ← OUR ATTRIBUTE
     -> http.request.method: Str(POST)
     -> url.path: Str(/jek-trigger)
```

Read that as: the trace contains a `tid` attribute set to the value that was
in the SOAP envelope. The fact that it's on the inbound server span (not a
separate HTTP client span) is explained in "Which span gets the `tid` attribute"
above. From a Datadog filtering / facet perspective, the trace is searchable
on `tid:<value>` either way.

### Datadog APM EU UI — confirmed (live screenshot 2026-05-04)

After triggering with `tid-ext-success-1`, the trace shows up in
`https://app.datadoghq.eu` → APM → Traces (filter
`service:jek-springboot3x-soap-client-stonebraker`). Clicking into the trace
and scrolling the right-hand "Tags" panel of the `POST /jek-trigger` span
displays:

```
tid    tid-ext-success-1
```

That's the success state. See the README's "Step 8: Verify in Datadog APM EU UI"
for the navigation walkthrough and screenshot reference.

If the attribute is missing:
- **Confirm the agent is loaded**: App A startup log shows
  `Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/...` and
  `[otel.javaagent] opentelemetry-javaagent - version: 2.26.1`.
- **Confirm the extension is loaded**: App A startup log shows
  `OTel SOAP extension — registered SoapTidOutInterceptor on default Bus`
  (the auto-config logs this at INFO).
- **Confirm `<layout>ZIP</layout>`**: `unzip -p .../app.jar META-INF/MANIFEST.MF | grep Main-Class`
  should show `org.springframework.boot.loader.launch.PropertiesLauncher`.
  If you see `JarLauncher` instead, the app pom is missing
  `<layout>ZIP</layout>` and `-Dloader.path` is silently ignored.

## Adapting from a customer code snippet

When invoked with a customer's SOAP-client code, WSDL, captured SOAP envelope,
or stack description as context, **derive the six signals below and apply the
mapping table** to produce a tailored version of the extension. If a signal is
missing, **ask the user before generating** — guessing at namespaces or field
names yields a JAR that compiles cleanly but silently never matches anything,
which is the worst-case outcome for a PoC.

### Signals to extract from the customer's input

| # | Signal | What to look for in the snippet | Example values |
|---|---|---|---|
| 1 | **SOAP framework** | The Java import or factory class building the client | `org.apache.cxf.jaxws.JaxWsProxyFactoryBean` (Apache CXF — this skill applies as-is); `org.springframework.ws.client.core.WebServiceTemplate` (Spring Web Services — see note below); `jakarta.xml.ws.Service` / `Service.create()` (JAX-WS RI / Metro); `<cxf:cxfEndpoint>` (CXF in Camel routes) |
| 2 | **Direction** | Whether the customer's code calls a remote SOAP service or implements one | "We POST a SOAP request to vendor X" → **outbound** (this skill). "We expose a SOAP endpoint at /ws/..." → **inbound** — use `create-otel-java-ext` as starting point instead. |
| 3 | **Field name on the wire** | The XML element name carrying the transaction id, exactly as it appears in the SOAP body. Capture is case-sensitive on the wire. | `<TID>`, `<TransactionId>`, `<correlationId>`, `<orderRef>`, `<txId>` |
| 4 | **Namespace prefix tolerance** | Whether the customer's envelope is bare (`<TID>`) or namespace-prefixed (`<ns2:TID>`, `<wm:TID>`). If unsure, default to tolerating both via `(?:\w+:)?` | bare → `<TID>([^<]+)</TID>`; prefixed → `<(?:\w+:)?TID>([^<]+)</(?:\w+:)?TID>` |
| 5 | **Datadog attribute name** | What the customer wants to call the attribute in Datadog. Datadog convention is lowercase + dot-separated. | `tid`, `transaction.id`, `correlation.id`, `order.ref` |
| 6 | **Multiple fields?** | Whether to extract more than one field per envelope (e.g., transaction id + customer id + order ref) | One Pattern + setAttribute per field |

### Mapping: signal → file change

| Signal | File to edit | Specific change |
|---|---|---|
| 1 (framework = CXF) | none | this skill applies as-is |
| 1 (framework = Spring WS) | `SoapTidOutInterceptor.java` | replace the CXF `AbstractPhaseInterceptor` with a Spring WS `org.springframework.ws.client.support.interceptor.ClientInterceptor#handleRequest`. Different API but same idea: cache outgoing message → regex extract → set on `Span.current()`. Pull in `spring-ws-core` as `provided`. |
| 1 (framework = JAX-WS RI / Metro) | `SoapTidOutInterceptor.java` | replace with a `jakarta.xml.ws.handler.soap.SOAPHandler<SOAPMessageContext>` registered via `BindingProvider.getBinding().setHandlerChain(...)`. Pull in `jakarta.xml.ws-api` as `provided`. |
| 2 (inbound) | use `create-otel-java-ext` instead | not this skill |
| 3 (field name) | `SoapTidOutInterceptor.java` line `TID_PATTERN` | change `TID` to the customer's element name on **both sides** of the regex |
| 4 (namespace prefix) | `SoapTidOutInterceptor.java` line `TID_PATTERN` | drop or keep the `(?:\w+:)?` prefix; default keep — it's harmless when no prefix is present |
| 5 (attribute name) | `SoapTidOutInterceptor.java` `Span.current().setAttribute("tid", ...)` AND the log line below it | rename the attribute key consistently |
| 6 (multiple fields) | `SoapTidOutInterceptor.java` | add one `Pattern` constant per field + one `Matcher` block per field inside the callback. Mirror the multi-pattern shape in `create-otel-java-ext`'s `XmlAttributeExtractorFilter`. |

### Worked examples

#### Example A — customer uses Apache CXF (this skill applies as-is, with rename)

Customer snippet:
```java
@Bean
public OrderService orderService() {
    JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
    factory.setServiceClass(OrderService.class);
    factory.setAddress("https://vendor.example.com/ws/orders");
    return (OrderService) factory.create();
}
```

Customer says their TID field is called `transactionId` and the namespace
prefix in their envelopes is `ord:`. They want it as `transaction.id` in
Datadog.

Changes — only `SoapTidOutInterceptor.java`:
```java
// Pattern (line ~28)
private static final Pattern TID_PATTERN =
    Pattern.compile("<(?:\\w+:)?transactionId>([^<]+)</(?:\\w+:)?transactionId>");

// Span attribute name (line ~58)
Span.current().setAttribute("transaction.id", tid);
log.info("OTel SOAP extension — captured transaction.id={}", tid);
```

`pom.xml`, `SoapTidAutoConfiguration.java`, build/deploy steps — unchanged.

#### Example B — customer uses Spring Web Services (different framework)

Customer snippet:
```java
@Bean
public WebServiceTemplate webServiceTemplate() {
    WebServiceTemplate t = new WebServiceTemplate();
    t.setDefaultUri("https://vendor.example.com/ws/orders");
    t.setMessageSender(new HttpComponents5MessageSender());
    return t;
}

// Caller:
template.sendSourceAndReceiveToResult(new StringSource(soapBody), result);
```

This is **Spring Web Services**, not CXF. The CXF `AbstractPhaseInterceptor`
won't apply. Replace `SoapTidOutInterceptor.java` with a Spring WS
`ClientInterceptor`:

```java
public class SoapTidClientInterceptor implements ClientInterceptor {
    private static final Pattern TID = Pattern.compile("<(?:\\w+:)?TID>([^<]+)</(?:\\w+:)?TID>");

    @Override
    public boolean handleRequest(MessageContext ctx) {
        // Cache the outgoing payload bytes
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try {
            ctx.getRequest().writeTo(baos);
            Matcher m = TID.matcher(baos.toString(StandardCharsets.UTF_8));
            if (m.find()) {
                Span.current().setAttribute("tid", m.group(1));
            }
        } catch (IOException e) { /* log */ }
        return true;
    }
    @Override public boolean handleResponse(MessageContext ctx) { return true; }
    @Override public boolean handleFault(MessageContext ctx) { return true; }
    @Override public void afterCompletion(MessageContext ctx, Exception ex) {}
}
```

And in `SoapTidAutoConfiguration.java`, register against the Spring WS
template instead of the CXF Bus:

```java
@AutoConfiguration
public class SoapTidAutoConfiguration {
    @Bean
    public ClientInterceptor soapTidInterceptor(WebServiceTemplate template) {
        SoapTidClientInterceptor interceptor = new SoapTidClientInterceptor();
        ClientInterceptor[] existing = template.getInterceptors();
        ClientInterceptor[] updated = Arrays.copyOf(
            existing != null ? existing : new ClientInterceptor[0],
            (existing != null ? existing.length : 0) + 1);
        updated[updated.length - 1] = interceptor;
        template.setInterceptors(updated);
        log.info("OTel SOAP extension — added SoapTidClientInterceptor to WebServiceTemplate");
        return interceptor;
    }
}
```

`pom.xml` — swap CXF for Spring WS (still `provided`):
```xml
<dependency>
    <groupId>org.springframework.ws</groupId>
    <artifactId>spring-ws-core</artifactId>
    <version>4.0.10</version>
    <scope>provided</scope>
</dependency>
```

The shaded OTel API + `<layout>ZIP</layout>` consumer requirement +
`AutoConfiguration.imports` + `Span.current().setAttribute(...)` semantics
all stay the same — those are framework-independent.

### Clarifying questions to ask if signals are missing

Default action when a snippet doesn't reveal a signal: **ask the user before
generating**. Concretely:

- **Signal 1 missing** ("which SOAP framework do you use?") — the answer
  determines whether this skill applies as-is, needs the Spring WS
  rewrite, or needs the JAX-WS-handler rewrite. Worst case: pick the wrong
  framework and the JAR won't even compile against the customer's classpath.
- **Signal 3 missing** ("what's the exact element name carrying the transaction
  identifier in your SOAP body?") — paste-in a sample envelope is the most
  reliable answer. Without this, the regex never matches and the whole
  extension is silently inert. This is the highest-risk missing signal.
- **Signal 5 missing** ("what name should the attribute have in Datadog?") —
  propose `tid`, `transaction.id`, or the dotted version of signal 3, and let
  the user pick.

Signals 2, 4, and 6 can usually be inferred safely (defaults: outbound,
namespace-prefix-tolerant, single-field) — confirm in the response but don't
gate generation on them.

### What stays the same regardless of customer specifics

These are framework-agnostic and should never change when adapting:

- OTel API at compile + shaded scope (otherwise `NoClassDefFoundError`)
- `<layout>ZIP</layout>` requirement on the consuming app
- Spring Boot `@AutoConfiguration` discovery via `AutoConfiguration.imports`
- `Span.current().setAttribute(key, value)` as the way to attach the attribute
- Loaded via `-Dloader.path=/opt/otel/extensions/`
- The OTel Java Agent must be running on the consuming app for the attribute
  to land on a non-noop span

## Teardown

The extension lives entirely in `/opt/otel/extensions/`. To remove:

```bash
# Stop App A first so it doesn't keep the JAR open
sudo fuser -k 8083/tcp
sudo rm -f /opt/otel/extensions/otel-extension-soap-tid-1.0.jar
# Restart App A WITHOUT -Dloader.path to confirm clean state, OR with -Dloader.path
# pointing at an empty directory
```

## Next Step

Use `load-otel-java-ext` to load the JAR into App A and verify `tid` shows up
on the App A client span in Datadog APM EU.
