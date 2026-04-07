## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `go-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Go framework and version combination, create a `setup-{framework}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to a REST API with multiple endpoints (GET, POST, and PUT at minimum) as the inbound entry point, as this is the most common PoC requirement. Only deviate from REST if the PoC explicitly requires an alternative — such as a message queue consumer (polling or long-polling), a gRPC server, a database reader, or another protocol-specific receiver. Do not mix inbound types unless explicitly instructed.
- For HTTP entry points, use a standardised JSON response payload across all endpoints: `{ "status": "ok" | "error", "message": "...", "data": {} }` to ensure predictable integration when connecting multiple services. Do NOT apply this schema to non-HTTP entry points (e.g., message queue consumers, gRPC services) — use the message format appropriate to that protocol instead. Simulate realistic error rates with a random HTTP status code distribution (30% 2XX, 40% 4XX, 30% 5XX).
- Include at least one outbound call to a downstream dependency appropriate to the PoC — such as a relational database, message queue, another application service, or external API — using the protocol the PoC requires (HTTP REST, gRPC, message publishing, or other). If the downstream dependency or protocol is not explicitly stated in the PoC requirements, ask before assuming.
- Structured logging via `slog` (Go 1.21+ stdlib) with a JSON handler (stdout and file outputs) so logs are ready for Datadog log collection. Fall back to `zap` or `zerolog` if the PoC targets Go versions below 1.21.

**Naming convention:** `setup-{framework}` (e.g., `setup-gin`, `setup-echo`, `setup-fiber`, `setup-chi`). Include a major version suffix only when multiple major versions of the same framework are in scope.

**Reminder:** Always check if a Go application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{framework}-dd-tracer` skill that instruments the running application with Datadog APM — producing traces, metrics, and correlated logs.

**What an instrumentation produces:**

- Datadog Go tracer (`gopkg.in/DataDog/dd-trace-go.v1`) imported and started via `tracer.Start()` / deferred `tracer.Stop()` in `main()`; framework-specific middleware applied (e.g., `gintrace.Middleware`, `echotrace.Middleware`, `chitrace.Middleware`)
- Unified service tags configured: `DD_SERVICE`, `DD_ENV`, `DD_VERSION`
- Trace-log correlation enabled by injecting trace and span IDs into `slog` log entries using the `ddtrace/ext` package constants
- Runtime metrics collection enabled via `DD_RUNTIME_METRICS_ENABLED=true`
- Profiling enabled via `DD_PROFILING_ENABLED=auto` using `gopkg.in/DataDog/dd-trace-go.v1/profiler`
- Traffic generation script that hits all endpoints for 2+ minutes to populate APM traces and runtime metrics
- Verification commands to confirm: tracer started (Datadog tracer configuration log on startup), traces received by agent, DogStatsD receiving Go runtime metrics
- Validation in the Datadog UI: APM > Services shows the service, APM > Traces shows spans, Runtime Metrics sidebar shows Go GC/goroutine/heap metrics

**Naming convention:** `{framework}-dd-tracer` (e.g., `gin-dd-tracer`, `echo-dd-tracer`, `fiber-dd-tracer`). Include a major version suffix only when multiple major versions of the same framework are in scope.

**Prerequisite:** The corresponding `setup-{framework}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if dd-tracer is already running in the environment before instrumenting. If the `skills/` folder already has a relevant dd-tracer skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. Three endpoints with logging and random status codes is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Modules:** Use Go modules (`go.mod`, `go.sum`). Each app gets its own module with an appropriate module path.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Go version, framework version, dependency versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude compiled binaries, `vendor/`, and other generated artifacts.

---


## Resource Naming Convention

All resources created in this plugin use the **"jek-"** prefix for easy identification in shared environments.

| Resource Type | Convention | Examples |
|---|---|---|
| HTTP endpoints | `jek-endpoint-{method}` | `jek-endpoint-get`, `jek-endpoint-post`, `jek-endpoint-put` |
| Message queues | `jek-queue` | `jek-queue`, `jek-queue-orders` |
| Database name | `jek-database` | `jek-database`, `jek-database-master`, `jek-database-slave` |
| Database tables | `jek-table` | `jek-table`, `jek-table-users` |
| Infra resources | `jek-{resource}` | `jek-vpc`, `jek-eks-cluster`, `jek-ec2-master` |
| Services (DD_SERVICE) | `jek-{app-name}` | `jek-springboot-app`, `jek-fastapi-gateway` |
| Cloud tags | `owner="jek"`, `env="test"` | — |
| gRPC services | `jek-grpc-{service}` | `jek-grpc-orders`, `jek-grpc-payments` |
| WebSocket endpoints | `jek-ws-{purpose}` | `jek-ws-chat`, `jek-ws-notifications` |
| GraphQL endpoints | `jek-graphql` | `jek-graphql` (single endpoint by convention) |
| Event streams | `jek-stream-{name}` | `jek-stream-orders`, `jek-stream-events` |
| Other protocols | `jek-{protocol}-{name}` | `jek-rpc-auth`, `jek-mqtt-sensor` |

## Tools & References

### MCP Libraries (Context7)

- `/gin-gonic/gin` — Gin web framework documentation
- `/labstack/echo` — Echo web framework documentation
- `/gofiber/fiber` — Fiber web framework documentation
- `/go-chi/chi` — Chi router documentation

### Datadog MCP Libraries (Context7)

- `/datadog/dd-trace-go` — Go tracer library and contrib integrations
- `/datadog/datadog-agent` — Datadog Agent setup and configuration

### Datadog Documentation

- [Go tracer library config](https://docs.datadoghq.com/tracing/trace_collection/library_config/go/)
- [Go tracer setup](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/go/)
- [Trace-log correlation (Go)](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/go/)
- [Profiling Go applications](https://docs.datadoghq.com/profiler/enabling/go/)
- [OpenTelemetry API support (Go)](https://docs.datadoghq.com/opentelemetry/instrument/dd_sdks/api_support/?platform=traces&prog_lang=go)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate traces and spans are received
