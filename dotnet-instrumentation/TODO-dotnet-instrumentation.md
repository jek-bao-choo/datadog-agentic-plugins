## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `dotnet-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each .NET framework and version combination, create a `setup-{framework}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to a REST API with multiple endpoints (GET, POST, and PUT at minimum) as the inbound entry point, as this is the most common PoC requirement. Only deviate from REST if the PoC explicitly requires an alternative — such as a message queue consumer (polling or long-polling), a gRPC server, a database reader, or another protocol-specific receiver. Do not mix inbound types unless explicitly instructed.
- For HTTP entry points, use a standardised JSON response payload across all endpoints: `{ "status": "ok" | "error", "message": "...", "data": {} }` to ensure predictable integration when connecting multiple services. Do NOT apply this schema to non-HTTP entry points (e.g., message queue consumers, gRPC services) — use the message format appropriate to that protocol instead. Simulate realistic error rates with a random HTTP status code distribution (30% 2XX, 40% 4XX, 30% 5XX).
- Include at least one outbound call to a downstream dependency appropriate to the PoC — such as a relational database (via Entity Framework Core or Dapper), message queue, another application service (via `HttpClient`), or external API — using the protocol the PoC requires (HTTP REST, gRPC, message publishing, or other). If the downstream dependency or protocol is not explicitly stated in the PoC requirements, ask before assuming.
- Structured logging via `Microsoft.Extensions.Logging` with a Serilog JSON sink (console and file outputs) so logs are ready for Datadog log collection

**Naming convention:** `setup-{framework}{dotnet-version}` (e.g., `setup-aspnetcore8`, `setup-aspnetcore6`). Omit the version suffix for the primary/default version.

**Reminder:** Always check if a .NET application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{framework}-dd-tracer` skill that instruments the running application with Datadog APM — producing traces, metrics, and correlated logs.

**What an instrumentation produces:**

- Datadog .NET tracer installed via the `datadog-dotnet-apm` package or installer script; CLR profiler enabled via environment variables (`CORECLR_ENABLE_PROFILING=1`, `CORECLR_PROFILER`, `CORECLR_PROFILER_PATH`, `DD_DOTNET_TRACER_HOME`)
- Unified service tags configured: `DD_SERVICE`, `DD_ENV`, `DD_VERSION`
- Trace-log correlation enabled via `DD_LOGS_INJECTION=true` (automatically injects trace and span IDs into Serilog log entries via the Datadog Serilog enricher)
- Runtime metrics collection enabled via `DD_RUNTIME_METRICS_ENABLED=true`
- Profiling enabled via `DD_PROFILING_ENABLED=auto`
- Traffic generation script that hits all endpoints for 2+ minutes to populate APM traces and runtime metrics
- Verification commands to confirm: CLR profiler attached (Datadog tracer logs on startup), traces received by agent, DogStatsD receiving .NET runtime metrics
- Validation in the Datadog UI: APM > Services shows the service, APM > Traces shows spans, Runtime Metrics sidebar shows .NET GC/thread/exception metrics

**Naming convention:** `{framework}{dotnet-version}-dd-tracer` (e.g., `aspnetcore8-dd-tracer`, `aspnetcore6-dd-tracer`). Omit the version suffix for the primary/default version.

**Prerequisite:** The corresponding `setup-{framework}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if dd-tracer is already running in the environment before instrumenting. If the `skills/` folder already has a relevant dd-tracer skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. Three endpoints with logging and random status codes is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Project structure:** Use `dotnet new` templates. Each app gets its own `.csproj` and solution file.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (.NET SDK LTS version, NuGet package versions, Datadog tracer version).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables, `appsettings.json` (non-sensitive only), and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `bin/`, `obj/`, `*.user`, `*.suo`, logs, and other build artifacts.

---

## Tools & References

### MCP Libraries (Context7)

- `/dotnet/aspnetcore` — ASP.NET Core documentation
- `/dotnet/efcore` — Entity Framework Core documentation

### Datadog MCP Libraries (Context7)

- `/datadog/dd-trace-dotnet` — .NET tracer library and auto-instrumentation
- `/datadog/datadog-agent` — Datadog Agent setup and configuration

### Datadog Documentation

- [.NET tracer library config](https://docs.datadoghq.com/tracing/trace_collection/library_config/dotnet-core/)
- [.NET tracer setup](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/dotnet-core/)
- [Trace-log correlation (.NET)](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/dotnet/)
- [Profiling .NET applications](https://docs.datadoghq.com/profiler/enabling/dotnet/)
- [OpenTelemetry API support (.NET)](https://docs.datadoghq.com/opentelemetry/instrument/dd_sdks/api_support/?platform=traces&prog_lang=dotnet)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate traces and spans are received
