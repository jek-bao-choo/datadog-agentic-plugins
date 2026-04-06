## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Java framework and version combination, create a `setup-{framework}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to a REST API with multiple endpoints (GET, POST, and PUT at minimum) as the inbound entry point, as this is the most common PoC requirement. Only deviate from REST if the PoC explicitly requires an alternative — such as a message queue consumer (polling or long-polling), a gRPC or RPC server, a database reader, or another protocol-specific receiver. Do not mix inbound types unless explicitly instructed.
- For HTTP entry points, use a standardised JSON response payload across all endpoints: `{ "status": "ok" | "error", "message": "...", "data": {} }` to ensure predictable integration when connecting multiple services. Do NOT apply this schema to non-HTTP entry points (e.g., message queue consumers, gRPC services) — use the message format appropriate to that protocol instead. Simulate realistic error rates with a random HTTP status code distribution (30% 2XX, 40% 4XX, 30% 5XX).
- Include at least one outbound call to a downstream dependency appropriate to the PoC — such as a relational database, message queue, another application service, or external API — using the protocol the PoC requires (HTTP REST, gRPC, SOFA RPC, message publishing, or other). If the downstream dependency or protocol is not explicitly stated in the PoC requirements, ask before assuming.
- Structured logging via SLF4J + Logback (console, syslog, and file appenders) so logs are ready for Datadog log collection

**Naming convention:** `setup-{framework}{major-version}` (e.g., `setup-springboot2x`, `setup-springboot4x`). Omit the version suffix for the primary/default version.

**Reminder:** Always check if a Java application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup, create a matching `{framework}-dd-tracer` skill that instruments the running application with Datadog APM — producing traces, metrics, and correlated logs.

**What an instrumentation produces:**

- Datadog Java tracer (`dd-java-agent.jar`) attached via `-javaagent` JVM argument or Kubernetes init container injection
- Unified service tags configured: `DD_SERVICE`, `DD_ENV`, `DD_VERSION`
- Trace-log correlation enabled via `DD_LOGS_INJECTION=true`
- Runtime metrics collection enabled via `DD_RUNTIME_METRICS_ENABLED=true`
- Profiling enabled via `DD_PROFILING_ENABLED=auto`
- Dynamic instrumentation configured for collecting additional error context
- Traffic generation script that hits all endpoints for 2+ minutes to populate APM traces and runtime metrics
- Verification commands to confirm: tracer attached (DATADOG TRACER CONFIGURATION in logs), traces received by agent, DogStatsD receiving JVM metrics
- Validation in the Datadog UI: APM > Services shows the service, APM > Traces shows spans, Runtime Metrics sidebar shows JVM heap/GC/threads

**Naming convention:** `{framework}{major-version}-dd-tracer` (e.g., `springboot2x-dd-tracer`, `springboot4x-dd-tracer`). Omit the version suffix for the primary/default version.

**Prerequisite:** The corresponding `setup-{framework}` skill (as well as the application) must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if dd-tracer is already running in the environment before instrumenting. If the `skills/` folder already has a relevant dd-tracer skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. Three endpoints with logging and random status codes is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Java version, Spring Boot version, Tomcat version, Maven plugins).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `target/`, `.idea/`, `*.class`, `*.jar`, logs, and other build artifacts.

---

## Tools & References

### MCP Libraries (Context7)

- `/context7/spring_io-spring-boot` — Spring Boot documentation
- `/context7/tomcat_apache_tomcat-10_1-doc` — Tomcat documentation
- `/context7/gradle?tokens=5000` — Gradle build tool
- `/openjdk/jdk?tokens=5000` — OpenJDK documentation
- `/microsoft/playwright-java` — Playwright Java for endpoint testing

### Datadog MCP Libraries (Context7)

- `/datadog/dd-trace-java` — Automatic and dynamic instrumentation
- `/datadog/datadog-agent` — Datadog Agent setup and configuration

### Datadog Documentation

- [Java tracer library config](https://docs.datadoghq.com/tracing/trace_collection/library_config/java/)
- [Dynamic instrumentation (Java)](https://docs.datadoghq.com/tracing/trace_collection/dynamic_instrumentation/enabling/java/?tab=curl)
- [Dynamic instrumentation probes](https://docs.datadoghq.com/tracing/trace_collection/dynamic_instrumentation/)
- [Trace-log correlation (Java)](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/java/?tab=maven)
- [OpenTelemetry API support (Java)](https://docs.datadoghq.com/opentelemetry/instrument/dd_sdks/api_support/?platform=traces&prog_lang=java)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate traces and spans are received
