# TODO — cloudprem-selfhosted

## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `cloudprem-selfhosted` plugin. Work proceeds in two phases: first set up the pipeline infrastructure, then configure Datadog integration. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Docker configs, scripts, and docs in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Pipeline Infrastructure Setup

- **Cloud-Prem (Observability Pipelines):** Run Datadog Observability Pipelines locally via Docker Compose. Two renditions with different pipeline configurations for log routing, filtering, and enrichment.
- **Scality ZenkoCloudServer:** Run S3-compatible object storage locally via Docker — use as a pipeline destination for storing processed logs.

## Phase 2: Datadog Integration

- Verify logs flow through the pipeline to Datadog (**Logs > Search**)
- Validate pipeline metrics and health in the Datadog UI
- Test pipeline routing rules: filter, enrich, and forward logs to different destinations

## Guidelines

- **Simplicity:** Keep everything Hello World level — Docker Compose up, send data, verify routing.
- **Atomic steps:** Small, individually testable steps.
- **Beginner-friendly:** Assume no prior Observability Pipelines knowledge.
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

- [Observability Pipelines](https://docs.datadoghq.com/observability_pipelines/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate logs are received

### Scality Documentation

- [ZenkoCloudServer Docker](https://hub.docker.com/r/scality/zenkocloudserver)
