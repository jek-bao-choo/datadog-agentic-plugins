# TODO — splunk-selfhosted

## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `splunk-selfhosted` plugin. Work proceeds in two phases: first set up the Splunk environment, then configure Datadog log migration. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Docker configs, scripts, and docs in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Splunk Environment Setup

**Goal:** Create a `setup-splunk-enterprise` skill that deploys Splunk Enterprise + Universal Forwarder locally via Docker Compose.

**What the setup skill produces:**

- Docker Compose configuration for Splunk Enterprise and Universal Forwarder on a bridge network
- Test data ingestion via the Universal Forwarder
- Indexing verification using `tstats` search via the REST API
- Data export via REST API — both one-off curl and chunked bash script for large datasets
- Web UI at http://localhost:8000, REST API at https://localhost:8089
- Default credentials: `admin` / configurable password (from environment variable, not hardcoded)

**Naming convention:** `setup-splunk-enterprise`

## Phase 2: Datadog Log Migration

**Goal:** Create a `splunk-to-datadog` skill that exports logs from Splunk and forwards them to Datadog.

**What the migration skill produces:**

- Export Splunk events to JSON files via the REST API (chunked by time window for large datasets)
- Forward exported logs to Datadog Logs API (`https://http-intake.logs.datadoghq.com/v1/input`)
- Optionally configure Splunk HEC (HTTP Event Collector) to forward logs in real-time to Datadog
- Verify logs appear in **Logs > Search** in the Datadog UI

**Prerequisite:** The `setup-splunk-enterprise` skill must be completed first.

---

## Guidelines

- **Simplicity:** Keep everything Hello World level — Docker Compose up, send data, verify, export.
- **Atomic steps:** Small, individually testable steps.
- **Beginner-friendly:** Assume no prior Splunk knowledge.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This is a public repo. No API keys, no secrets, no credentials in code. Use `.env` files (gitignored).
- **Git hygiene:** `.gitignore` up to date.
- **Teardown:** Document `docker compose down` and volume cleanup.
- **My setup:** MacBook M4, Claude Code terminal.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

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

### Datadog Documentation

- [Logs HTTP API](https://docs.datadoghq.com/api/latest/logs/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate logs are received

### Splunk Documentation

- [Splunk REST API](https://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTsearch)
- [Splunk Docker](https://splunk.github.io/docker-splunk/)
