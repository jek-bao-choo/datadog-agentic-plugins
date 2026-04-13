# create-otel-java-ext

Step-by-step guide to build an OTel Java extension JAR that extracts custom business IDs from HTTP request bodies and adds them as span attributes in Datadog traces. **No application code changes needed.**

This PoC extracts `transaction_id`, `airway_bill_id`, and `houseway_bill_id` from XML request bodies. The "Adapting for Your Prospect's Code" section at the end explains how to modify the extension for different payload formats, field names, and endpoints.

## How it works

```
HTTP Request (XML body)
  → OTel Java agent creates span
  → XmlAttributeExtractorFilter intercepts (caches body)
  → Spring MVC controller processes request normally
  → Filter parses cached XML body with regex
  → Filter calls Span.current().setAttribute("transaction_id", "...")
  → Span exported to Datadog with custom attributes
```

The extension is a Spring Boot auto-configuration library. It's loaded at runtime via `-Dloader.path` — Spring Boot discovers the `@AutoConfiguration` class and registers the filter. No application source code changes.

## Tech Stack

| Component | Confirmed Version |
|---|---|
| Java | OpenJDK 17.0.18 LTS |
| Maven | 3.6.3 |
| OTel API | 1.48.0 (**shaded into JAR** — not provided scope) |
| Spring Boot | 3.4.5 (provided by app) |
| Jakarta Servlet | 6.0 (provided by Tomcat) |
| Extension JAR size | ~214KB (includes shaded OTel API) |

**Important**: The OTel API dependency must be `compile` scope (shaded into the JAR), NOT `provided`. Spring Boot's `PropertiesLauncher` classloader cannot see classes injected into the bootstrap classloader by the OTel agent — this causes `NoClassDefFoundError: io/opentelemetry/api/trace/Span` if the API isn't bundled.

## Prerequisites

- Java 17 and Maven on the EC2 instance (from `setup-ec2-centos9`)
- The Spring Boot application's `pom.xml` must use `<layout>ZIP</layout>` in the `spring-boot-maven-plugin` — this switches the launcher from `JarLauncher` to `PropertiesLauncher`, which is required for `-Dloader.path` to work

## Step 0: Verify the Spring Boot app uses PropertiesLauncher

Check the application's `pom.xml` (e.g., `setup-springboot3x/references/pom.xml`):

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <!-- Required for -Dloader.path to load external JARs -->
        <layout>ZIP</layout>
    </configuration>
</plugin>
```

If `<layout>ZIP</layout>` is missing, add it and rebuild the app with `mvn clean package -DskipTests`. Without this, `-Dloader.path` has no effect and the extension won't load.

## Step 1: Copy the extension source to the EC2 instance

From your local machine (in the `create-otel-java-ext` skill directory):

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP> \
  'sudo mkdir -p /opt/otel/extensions-src && sudo chown ec2-user:ec2-user /opt/otel/extensions-src'

scp -i ~/.ssh/jek_rsa_pem -r references/* ec2-user@<EC2_PUBLIC_IP>:/opt/otel/extensions-src/
```

## Step 2: Build the extension JAR

SSH into the EC2 instance:

```bash
ssh -i ~/.ssh/jek_rsa_pem ec2-user@<EC2_PUBLIC_IP>
```

Build:

```bash
cd /opt/otel/extensions-src
mvn clean package
```

This produces `target/otel-extension-xml-attributes-1.0.jar` (~214KB, includes shaded OTel API).

## Step 3: Copy the JAR to the extensions directory

```bash
mkdir -p /opt/otel/extensions
cp target/otel-extension-xml-attributes-1.0.jar /opt/otel/extensions/
```

## Step 4: Verify the JAR contents

```bash
jar tf /opt/otel/extensions/otel-extension-xml-attributes-1.0.jar | head -20
```

You should see:
- `com/example/otelext/XmlAttributeExtractorFilter.class`
- `com/example/otelext/XmlAttributeAutoConfiguration.class`
- `io/opentelemetry/api/trace/Span.class` (shaded OTel API)
- `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`

## What each source file does

| File | Purpose |
|---|---|
| `XmlAttributeExtractorFilter.java` | Jakarta Servlet `Filter` that caches the XML request body, parses it with regex after `chain.doFilter()`, and sets `transaction_id`, `airway_bill_id`, `houseway_bill_id` as span attributes via `Span.current().setAttribute()` |
| `XmlAttributeAutoConfiguration.java` | Spring Boot `@AutoConfiguration` class that registers the filter for `/jek-receive-xml` URL pattern |
| `pom.xml` | Maven build with OTel API (compile scope for shading) + Spring Boot Web and Jakarta Servlet (provided scope) + maven-shade-plugin |
| `AutoConfiguration.imports` | Tells Spring Boot to discover and load the auto-configuration class |

## Next Step

After building, proceed to `load-otel-java-ext` to load the extension into the running app and verify in Datadog.

---

## Adapting for Your Prospect's Code

When you get access to your prospect's actual code or API specs, here's exactly what to change in the extension to extract their specific business IDs.

### What you'll need to know

Before modifying, gather these from the prospect:
1. **Endpoint path(s)** — which URL(s) carry the business IDs? (e.g., `/api/transaction`, `/process`)
2. **Payload format** — XML, JSON, or form-encoded?
3. **Field names** — what are the business ID field names? (e.g., `orderId`, `shipmentRef`, `correlationId`)
4. **Where the IDs live** — in the request body, HTTP headers, query parameters, or path variables?

### Change 1: Endpoint path (in XmlAttributeAutoConfiguration.java)

```java
// CURRENT: Only processes /jek-receive-xml
registration.addUrlPatterns("/jek-receive-xml");

// CHANGE TO: Your prospect's endpoint(s)
registration.addUrlPatterns("/api/transaction");
// For multiple endpoints:
registration.addUrlPatterns("/api/transaction", "/api/shipment", "/process");
```

### Change 2: URI and content-type filter (in XmlAttributeExtractorFilter.java)

```java
// CURRENT:
if (!uri.contains("/jek-receive-xml") || contentType == null || !contentType.contains("xml")) {

// CHANGE TO: Match your prospect's endpoint and content type
if (!uri.contains("/api/transaction") || contentType == null || !contentType.contains("json")) {
```

### Change 3: Field extraction patterns (in XmlAttributeExtractorFilter.java)

**For XML payloads** — change the regex patterns:

```java
// CURRENT:
private static final Pattern TX_ID = Pattern.compile("<transaction_id>([^<]+)</transaction_id>");
private static final Pattern AWB_ID = Pattern.compile("<airway_bill_id>([^<]+)</airway_bill_id>");
private static final Pattern HWB_ID = Pattern.compile("<houseway_bill_id>([^<]+)</houseway_bill_id>");

// CHANGE TO: Your prospect's XML field names
private static final Pattern ORDER_ID = Pattern.compile("<orderId>([^<]+)</orderId>");
private static final Pattern SHIPMENT_REF = Pattern.compile("<shipmentRef>([^<]+)</shipmentRef>");
```

**For JSON payloads** — replace XML regex with JSON regex:

```java
// JSON extraction (simple regex — works for flat JSON)
private static final Pattern ORDER_ID = Pattern.compile("\"orderId\"\\s*:\\s*\"([^\"]+)\"");
private static final Pattern CORR_ID = Pattern.compile("\"correlationId\"\\s*:\\s*\"([^\"]+)\"");
```

### Change 4: Span attribute names (in XmlAttributeExtractorFilter.java)

```java
// CURRENT:
setIfPresent(span, "transaction_id", TX_ID, body);
setIfPresent(span, "airway_bill_id", AWB_ID, body);
setIfPresent(span, "houseway_bill_id", HWB_ID, body);

// CHANGE TO: Your prospect's attribute names
setIfPresent(span, "order.id", ORDER_ID, body);
setIfPresent(span, "shipment.ref", SHIPMENT_REF, body);
setIfPresent(span, "correlation.id", CORR_ID, body);
```

### Alternative: IDs in HTTP headers (simpler — no body caching needed)

If the prospect sends IDs as HTTP headers, the extension is much simpler:

```java
@Override
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {
    HttpServletRequest httpReq = (HttpServletRequest) request;

    // Extract IDs from headers BEFORE processing
    String orderId = httpReq.getHeader("X-Order-Id");
    String corrId = httpReq.getHeader("X-Correlation-Id");

    // Set on current span
    Span span = Span.current();
    if (orderId != null) span.setAttribute("order.id", orderId);
    if (corrId != null) span.setAttribute("correlation.id", corrId);

    // Continue normal processing (no body caching needed)
    chain.doFilter(request, response);
}
```

In this case, you can also skip the extension entirely and use the OTel Java agent's built-in header capture:

```bash
-Dotel.instrumentation.http.server.capture-request-headers=X-Order-Id,X-Correlation-Id
```

### Alternative: IDs in query parameters

```java
String orderId = httpReq.getParameter("orderId");
if (orderId != null) Span.current().setAttribute("order.id", orderId);
```

### Summary: what to change per file

| File | What to change | When |
|---|---|---|
| `XmlAttributeExtractorFilter.java` | Regex patterns, attribute names, content-type check | Always — this is where the extraction logic lives |
| `XmlAttributeAutoConfiguration.java` | URL patterns in `addUrlPatterns()` | When the prospect's endpoint path differs |
| `pom.xml` | Add JSON parser dependency (e.g., `jackson-databind`) if using JSON with nested objects | Only if regex isn't sufficient for complex JSON |
| Nothing | Use `-Dotel.instrumentation.http.server.capture-request-headers` instead | When IDs are in HTTP headers (no extension needed) |

---

## Beyond Span Attributes: Data Streams Monitoring Extension

If your prospect uses **asynchronous messaging** (Kafka, SQS, RabbitMQ, Kinesis), you may need a much more advanced extension to enable Datadog's [Data Streams Monitoring (DSM)](https://docs.datadoghq.com/data_streams/) — which tracks end-to-end latency across producers, queues, and consumers.

This is a **fundamentally different extension** from the simple attribute extractor above. Here's how they compare:

| Aspect | This Extension (Span Attributes) | DSM Extension |
|---|---|---|
| Purpose | Extract business IDs → span attributes | Track pathway latency across async services |
| Loading | `-Dloader.path` (Spring Boot classpath) | `-Dotel.javaagent.extensions` (OTel agent SPI) |
| Registration | Spring Boot `@AutoConfiguration` | OTel `AutoConfigurationCustomizerProvider` + `ConfigurablePropagatorProvider` |
| Components | 1 Servlet Filter | 5 components (see below) |
| Dependencies | OTel API + Jakarta Servlet | OTel SDK + msgpack-core + JCTools |
| Output | Span attributes in traces | Proprietary payload to DD Agent `/v0.1/pipeline_stats` |
| Complexity | ~100 lines | ~1000+ lines |
| Requires DD Agent | No | **Yes** — sends to `localhost:8126` |

### The 5 components of a DSM extension

1. **`DatadogPathwayPropagator`** (`TextMapPropagator`)
   - Extracts/injects Datadog's proprietary `dd-pathway-ctx-base64` header across service boundaries
   - Decodes: `parentHash`, `pathwayStartMillis`, `edgeStartMillis` using VarInt/ZigZag encoding
   - This is how Datadog tracks the "pathway" an event takes across multiple services

2. **`DsmSpanProcessor`** (`SpanProcessor`)
   - Hooks into `onEnd()` for every span
   - Checks if the span is a messaging span (has `messaging.destination.name`)
   - Extracts `parentHash` from OTel Context
   - Computes 64-bit FNV-1a `newHash` = hash(nodeHash, parentHash)
   - Sets `pathway.hash`, `dsm.transaction.id`, `dsm.transaction.checkpoint` on the span
   - These attributes are **critical** — without them, Datadog can't link APM traces to DSM

3. **`PathwayHasher`**
   - Implements FNV-1a 64-bit hashing
   - Checkpoint string format: `type:kafka,direction:out,topic:orders`
   - Combines nodeHash + parentHash to produce the pathway hash

4. **`StatsAggregator`**
   - Background thread with non-blocking MPSC queue (JCTools)
   - Aggregates stats into 10-second time-windowed buckets
   - For business transactions: packs into `TransactionContainer` byte array:
     `[checkpointId (1 byte)] [timestamp (8 bytes)] [idLength (1 byte)] [transactionId bytes]`

5. **`PipelineStatsExporter`**
   - Serializes buckets into Datadog's proprietary MessagePack format
   - HTTP POST to `http://localhost:8126/v0.1/pipeline_stats`
   - Includes metadata: `Env`, `Service`, `TracerVersion`

### Additional Maven dependencies needed

```xml
<dependency>
    <groupId>org.msgpack</groupId>
    <artifactId>msgpack-core</artifactId>
    <version>0.9.8</version>
</dependency>
<dependency>
    <groupId>org.jctools</groupId>
    <artifactId>jctools-core</artifactId>
    <version>4.0.3</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk</artifactId>
    <version>${opentelemetry.version}</version>
    <scope>provided</scope>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk-extension-autoconfigure-spi</artifactId>
    <version>${opentelemetry.version}</version>
    <scope>provided</scope>
</dependency>
```

### Key requirement: Datadog Agent on localhost

Unlike the span attribute extractor (which only uses the OTel Collector), the DSM extension sends data directly to the Datadog Agent at `localhost:8126/v0.1/pipeline_stats`. This means you need a Datadog Agent running alongside the OTel Collector.

### Reference implementation

The DSM logic is reverse-engineered from Datadog's own Java tracer. The reference source code is in `dd-trace-java`:
- [datadog/trace/core/datastreams/](https://github.com/DataDog/dd-trace-java/tree/master/dd-trace-core/src/main/java/datadog/trace/core/datastreams)
- Key classes: `DefaultPathwayContext`, `DataStreamsPropagator`, `StatsBucket`, `StatsGroup`, `TransactionContainer`, `MsgPackDatastreamsPayloadWriter`

### Full plan document

See `references/otel-dsm-extension-plan.md` for the complete implementation plan, including verification strategy and alternatives considered.
