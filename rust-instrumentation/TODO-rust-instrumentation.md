## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `rust-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Rust web framework and version combination, create a `setup-{framework}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to a REST API with multiple endpoints (GET, POST, and PUT at minimum) as the inbound entry point, as this is the most common PoC requirement. Only deviate from REST if the PoC explicitly requires an alternative — such as a message queue consumer, a gRPC server (via `tonic`), a database reader, or another protocol-specific receiver. Do not mix inbound types unless explicitly instructed.
- For HTTP entry points, use a standardised JSON response payload across all endpoints: `{ "status": "ok" | "error", "message": "...", "data": {} }` to ensure predictable integration when connecting multiple services. Do NOT apply this schema to non-HTTP entry points (e.g., message queue consumers, gRPC services) — use the message format appropriate to that protocol instead. Simulate realistic error rates with a random HTTP status code distribution (30% 2XX, 40% 4XX, 30% 5XX).
- Include at least one outbound call to a downstream dependency appropriate to the PoC — such as a relational database (via `sqlx` or `diesel`), message queue, another application service (via `reqwest`), or external API — using the protocol the PoC requires (HTTP REST, gRPC, message publishing, or other). If the downstream dependency or protocol is not explicitly stated in the PoC requirements, ask before assuming.
- Structured logging via the `tracing` crate with `tracing-subscriber` configured for JSON output (stdout) so logs are ready for Datadog log collection

**Naming convention:** `setup-{framework}` (e.g., `setup-axum`, `setup-actix`, `setup-rocket`). Include a major version suffix only when multiple major versions of the same framework are in scope.

**Reminder:** Always check if a Rust application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{framework}-dd-tracer` skill that instruments the running application with Datadog APM — producing traces, metrics, and correlated logs.

**Note:** Datadog does not currently provide a native Rust APM tracer. Instrumentation is done via the OpenTelemetry Rust SDK (`opentelemetry` crate family) with the OTLP exporter, using the Datadog Agent as the OTLP collector endpoint.

**What an instrumentation produces:**

- OpenTelemetry Rust SDK (`opentelemetry`, `opentelemetry-otlp`, `opentelemetry_sdk`) configured with the OTLP exporter pointing to the Datadog Agent (`DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT`)
- `tracing-opentelemetry` bridge installed to connect `tracing` crate spans to OpenTelemetry traces
- Unified service tags configured: `DD_SERVICE`, `DD_ENV`, `DD_VERSION` (mapped to OpenTelemetry resource attributes `service.name`, `deployment.environment`, `service.version`)
- Trace-log correlation via a `tracing-subscriber` layer that injects trace and span IDs into JSON log output
- Traffic generation script that hits all endpoints for 2+ minutes to populate APM traces
- Verification commands to confirm: OTLP exporter initialised (startup log), traces received by the Datadog Agent OTLP endpoint, spans visible in Datadog APM
- Validation in the Datadog UI: APM > Services shows the service, APM > Traces shows spans

**Naming convention:** `{framework}-dd-tracer` (e.g., `axum-dd-tracer`, `actix-dd-tracer`, `rocket-dd-tracer`). Include a major version suffix only when multiple major versions of the same framework are in scope.

**Prerequisite:** The corresponding `setup-{framework}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if dd-tracer is already running in the environment before instrumenting. If the `skills/` folder already has a relevant dd-tracer skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. Three endpoints with logging and random status codes is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Build tooling:** Use `cargo` for building and dependency management. Each app is a separate cargo package with its own `Cargo.toml`.
- **Async runtime:** Default to `tokio` as the async runtime (required by Axum and most ecosystem crates). Use `async-std` only if explicitly required by the PoC.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Rust edition, framework version, Tokio version, dependency versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `target/` and other build artifacts.

---

## Tools & References

### MCP Libraries (Context7)

- `/tokio-rs/axum` — Axum web framework documentation
- `/actix/actix-web` — Actix-web documentation
- `/SergioBenitez/Rocket` — Rocket web framework documentation
- `/tokio-rs/tokio` — Tokio async runtime documentation

### OpenTelemetry References (Context7)

- `/open-telemetry/opentelemetry-rust` — OpenTelemetry Rust SDK

### Datadog MCP Libraries (Context7)

- `/datadog/datadog-agent` — Datadog Agent setup and OTLP configuration

### Datadog Documentation

- [OTLP ingestion by Datadog Agent](https://docs.datadoghq.com/opentelemetry/interoperability/otlp_ingest_in_the_agent/)
- [OpenTelemetry with Datadog](https://docs.datadoghq.com/opentelemetry/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate traces and spans are received
