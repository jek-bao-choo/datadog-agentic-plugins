## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `aws-lambda` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning

Build .NET Lambda functions on AWS:

- **.NET 10 Lambda Native AOT (C#)** — HTTP GET endpoint that returns a random number with a 34%/33%/33% status distribution (success / warning / error). Compile with Native AOT for fast cold starts. Repackage to Amazon Linux 2023 runtime as a SKILL with the application code in that skill.
- Target: Macbook ARM64 M4 (cross-compile for Linux x86_64/arm64 as needed)

Important .NET Native AOT context:
- Native AOT supports EventPipe (`EventSource.WriteEvent`), which is OpenTelemetry-compatible
- This is the telemetry mechanism for instrumented Native AOT binaries

## Phase 2: Datadog Lambda Extension & Layer

- Setup Datadog Lambda Extension & Layer and have the steps in a SKILL

## Phase 3: Datadog dd-tracer or OTel SDK

Instrument with OpenTelemetry (NOT dd-trace-dotnet):

- Use `opentelemetry-dotnet` with OTLP exporter — NuGet package approach and have the setup steps in another SKILL
- Configure OTLP endpoint to send traces to Datadog's OTLP ingestion
- Set up distributed tracing with proper context propagation
- **Important**: AWS does not recommend Lambda layers for .NET — compile all dependencies directly into the deployment package
- **Important**: Use OpenTelemetry, not dd-trace-dotnet, for .NET Native AOT compatibility
- Verify traces appear in Datadog APM via OTLP ingestion

## Guidelines

- Keep it simple. Each function should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to .NET Lambda development should be able to follow along.
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

- Context7 MCP: `/aws/aws-lambda-dotnet` — AWS Lambda .NET SDK and tooling
- Context7 MCP: `/websites/aws_amazon_lambda_dg?topic=csharp` — AWS Lambda C# developer guide
- Context7 MCP: `/open-telemetry/opentelemetry-dotnet?topic=nuget` — OpenTelemetry .NET NuGet packages
- Datadog: Serverless monitoring docs, OTLP ingestion docs
- .NET Native AOT: https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/
