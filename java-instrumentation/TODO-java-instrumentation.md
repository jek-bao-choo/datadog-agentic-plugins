## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Java framework and version combination, create a `setup-{framework}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What a setup skill produces:**

- A working REST API with multiple endpoints (GET, POST, PUT at minimum) that exercise different code paths
- Structured logging via SLF4J + Logback (console, syslog, and file appenders) so logs are ready for Datadog log collection
- Random HTTP status code distribution (30% 2XX, 40% 4XX, 30% 5XX) to generate realistic error rates
- Multiple deployment options: local Maven, executable JAR, Docker (multi-stage build), and Kubernetes manifests with health probes
- A README.md at the skill level documenting: build instructions, run instructions, curl test commands, and project structure
- Playwright Java tests where viable for endpoint verification

**Naming convention:** `setup-{framework}{major-version}` (e.g., `setup-springboot2x`, `setup-springboot4x`). Omit the version suffix for the primary/default version.

**Reminder:** Always check if a Java application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{framework}-dd-tracer` skill that instruments the running application with Datadog APM — producing traces, metrics, and correlated logs.

**What an instrumentation skill produces:**

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

**Prerequisite:** The corresponding `setup-{framework}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if dd-tracer is already running in the environment before instrumenting. If the `skills/` folder already has a relevant dd-tracer skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. Three endpoints with logging and random status codes is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Java version, Spring Boot version, Tomcat version, Maven plugins).
- **Documentation:** Every skill needs a README.md with setup, deployment, verification, and cleanup steps.
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
