# load-otel-java-ext

Step-by-step guide to load the OTel Java extension JAR into a Spring Boot application and verify that `transaction_id`, `airway_bill_id`, and `houseway_bill_id` appear as custom span attributes in Datadog traces.

## Prerequisites

- Extension JAR at `/opt/otel/extensions/otel-extension-xml-attributes-1.0.jar` (from `create-otel-java-ext`)
- Spring Boot app JAR at `/opt/cargostream/component-d/target/springboot3x-0.0.1-SNAPSHOT.jar` (from `setup-springboot3x`)
- OTel Java agent at `/opt/otel/opentelemetry-javaagent.jar` (from `springboot3x-otel-java`)
- OTel Collector running on `127.0.0.1:4318` (from `install-otelcol-contrib`)

## Step 0: Verify the app uses PropertiesLauncher

The Spring Boot app JAR must use `PropertiesLauncher` (not `JarLauncher`) for `-Dloader.path` to work. Check the app's `pom.xml`:

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <layout>ZIP</layout>  <!-- This enables PropertiesLauncher -->
    </configuration>
</plugin>
```

Verify the built JAR uses PropertiesLauncher:

```bash
cd /tmp && jar xf /opt/cargostream/component-d/target/springboot3x-0.0.1-SNAPSHOT.jar META-INF/MANIFEST.MF
grep Main-Class META-INF/MANIFEST.MF
```

Expected: `Main-Class: org.springframework.boot.loader.launch.PropertiesLauncher`

If it shows `JarLauncher`, add `<layout>ZIP</layout>` to the pom.xml and rebuild: `mvn clean package -DskipTests`

## Step 1: Verify the extension JAR exists

```bash
ls -lh /opt/otel/extensions/otel-extension-xml-attributes-1.0.jar
```

If it doesn't exist, go back to `create-otel-java-ext` and build it.

## Step 2: Stop the current application

```bash
pkill -f springboot3x 2>/dev/null
sleep 2
```

## Step 3: Start the application with the extension loaded

The key addition is `-Dloader.path=/opt/otel/extensions/` — this tells Spring Boot's executable JAR launcher to add the extensions directory to the classpath. Spring Boot then discovers the `@AutoConfiguration` class in the extension JAR and registers the XML attribute filter.

```bash
cd /opt/cargostream/component-d

java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dloader.path=/opt/otel/extensions/ \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar target/springboot3x-0.0.1-SNAPSHOT.jar --server.port=8084
```

### What changed from the original startup

| Flag | Purpose |
|---|---|
| `-Dloader.path=/opt/otel/extensions/` | **NEW** — adds the extension JAR to Spring Boot's classpath |
| All other flags | Same as before |

On startup, you should see the OTel agent load message AND the extension's auto-configuration being registered (check Spring Boot logs for `XmlAttributeAutoConfiguration`).

To run in the background:

```bash
nohup java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
  -Dloader.path=/opt/otel/extensions/ \
  -Dotel.service.name=jek-otel-java-springboot3x \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar target/springboot3x-0.0.1-SNAPSHOT.jar --server.port=8084 \
  > /tmp/component-d.log 2>&1 &

sleep 12
curl -s http://localhost:8084/health
```

## Step 4: Send a test XML request

```bash
curl -X POST http://localhost:8084/jek-receive-xml \
  -H "Content-Type: application/xml" \
  -d '<shipment>
    <transaction_id>tx-ext-test-001</transaction_id>
    <airway_bill_id>awb-ext-test-001</airway_bill_id>
    <houseway_bill_id>hwb-ext-test-001</houseway_bill_id>
    <timestamp>2026-04-13T00:00:00Z</timestamp>
    <source>extension-test</source>
  </shipment>'
```

## Step 5: Verify in Datadog (wait 1-2 minutes)

Go to **APM > Traces**. Search for `service:jek-otel-java-springboot3x`.

Click a `POST /jek-receive-xml` trace. In the span details, you should see:

| Attribute | Value |
|---|---|
| `transaction_id` | `tx-ext-test-001` |
| `airway_bill_id` | `awb-ext-test-001` |
| `houseway_bill_id` | `hwb-ext-test-001` |

These are custom span attributes added by the extension — without any changes to the Spring Boot application source code.

## Step 6: Generate traffic to see distributed attributes

```bash
for i in $(seq 1 10); do
  curl -sf -o /dev/null -w "HTTP %{http_code}\n" -X POST http://localhost:8084/jek-receive-xml \
    -H "Content-Type: application/xml" \
    -d "<shipment><transaction_id>tx-ext-${i}</transaction_id><airway_bill_id>awb-ext-${i}</airway_bill_id><houseway_bill_id>hwb-ext-${i}</houseway_bill_id><timestamp>$(date -u +%Y-%m-%dT%H:%M:%SZ)</timestamp><source>ext-traffic</source></shipment>"
  [ "${i}" -lt 10 ] && sleep 10
done
```

Each trace should have unique `transaction_id`, `airway_bill_id`, `houseway_bill_id` values.

## How it works (architecture)

```
┌────────────────────────────── JVM ──────────────────────────────┐
│                                                                  │
│  OTel Java Agent (bootstrap classloader)                        │
│    └── Creates spans for HTTP requests                          │
│    └── Provides Span.current() API to all classes               │
│                                                                  │
│  Spring Boot App (app classloader)                              │
│    └── ReceiveXmlController (no changes)                        │
│                                                                  │
│  Extension JAR (added via -Dloader.path)                        │
│    └── XmlAttributeAutoConfiguration (@AutoConfiguration)       │
│    └── XmlAttributeExtractorFilter (Filter)                     │
│          1. Caches XML body                                     │
│          2. chain.doFilter() → controller runs                  │
│          3. Parses cached XML → extracts IDs                    │
│          4. Span.current().setAttribute("transaction_id", ...)  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
         │
         ▼ OTLP
┌─────────────────────┐     ┌──────────┐
│  OTel Collector      │ ──→ │ Datadog  │
│  (127.0.0.1:4318)   │     │          │
└─────────────────────┘     └──────────┘
```

## Troubleshooting

| Issue | Fix |
|---|---|
| Extension not loading (no attributes in spans) | Check `-Dloader.path=/opt/otel/extensions/` is set. Verify JAR exists at the path. Check app logs for `XmlAttributeAutoConfiguration`. |
| `NoClassDefFoundError: io/opentelemetry/api/trace/Span` | The extension JAR must **shade** the OTel API (compile scope, not provided). Spring Boot's PropertiesLauncher classloader can't see bootstrap classes injected by the agent. Rebuild the extension with `create-otel-java-ext` — the pom.xml uses compile scope + maven-shade-plugin. |
| Span attributes don't appear for /health | Expected — the filter only processes `/jek-receive-xml` requests. |
| App can't read XML body (empty response) | The body caching wrapper may have an issue. Check `/tmp/component-d.log` for errors. |

## Teardown

To remove the extension, simply remove `-Dloader.path=/opt/otel/extensions/` from the startup command and restart. No other changes needed.
