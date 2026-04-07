## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `sandbox-setup` plugin. Work proceeds in two phases: first set up sandbox environments, then validate Datadog telemetry. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place scripts, configs, and Docker files in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Environment Setup

- **Docker Containers** — Run Datadog Agent 7.68.3 with DogStatsD enabled. Read `DD_API_KEY` from `.env`. Configure for local metric and log collection.
- **Shell scripts** — Send test logs to Datadog via HTTP API (`curl` to `https://http-intake.logs.datadoghq.com/v1/input`), send test events via Events API, send test traces.
- **OTel Collector** — Run OpenTelemetry Collector via Docker Compose, configured to export to Datadog.
- **Cloud-Prem** — Run Datadog Observability Pipelines locally for log routing.

My setup: Macbook Pro M4, Claude Code terminal + VS Code

## Phase 2: Datadog Telemetry Validation

For each sandbox environment, validate that telemetry reaches Datadog:

- **Agent validation:** Run `docker exec <agent-container> agent status` and confirm: API key valid, Forwarder connected, DogStatsD listening on port 8125/UDP
- **Logs validation:** Check **Logs > Search** in Datadog UI — filter by the configured source tag
- **Metrics validation:** Check **Metrics > Explorer** — search for custom metrics sent via DogStatsD
- **Traces validation:** Check **APM > Traces** — filter by service name used in test trace scripts
- **Events validation:** Check **Events > Explorer** — look for test events with configured tags
- **OTel validation:** Verify OTLP traces flow through the collector to Datadog APM
- **Cloud-Prem validation:** Verify logs appear in Datadog after routing through the pipeline

## Guidelines

- Keep it simple. Each script/container should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to Datadog Agent setup should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.



## Datadog Credentials

Before sending any telemetry to Datadog, confirm these with the user:

- **Datadog Site (DD_SITE):** Ask which Datadog site the prospect uses. Do NOT assume `datadoghq.com`. Options: `datadoghq.com` (US1), `us3.datadoghq.com` (US3), `us5.datadoghq.com` (US5), `datadoghq.eu` (EU1), `ap1.datadoghq.com` (AP1), `ap2.datadoghq.com` (AP2), `ddog-gov.com` (US1-FED). Reference: https://docs.datadoghq.com/getting_started/site/
- **API Key (DD_API_KEY):** Required for all telemetry submission (metrics, traces, logs). Ask if not already provided. Store in `.env` file, never hardcode.
- **Application Key (DD_APP_KEY):** Required only if connecting to Datadog MCP server or using the Datadog API for read operations (e.g., querying metrics, listing monitors). Not needed for basic telemetry submission.

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

- Shell scripts: no Context7 needed — standard bash/curl
- Docker: general Docker documentation
- Datadog: Logs HTTP API docs (https://docs.datadoghq.com/api/latest/logs/)
- Datadog: DogStatsD docs (https://docs.datadoghq.com/developers/dogstatsd/)
- Datadog Agent: Docker setup docs (https://docs.datadoghq.com/containers/docker/)
