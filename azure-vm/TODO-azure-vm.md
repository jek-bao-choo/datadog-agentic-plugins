## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `azure-vm` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Infrastructure Provisioning
- Create a Windows Server 2022 VM using Bicep in Azure
- VM size: Standard_D4_v5 (4 vCPUs, 16GB RAM) or similar DSv5 series
- Region: Southeast Asia
- Components: Resource Group, VPC (VNet), Subnet, Network Security Group (pointing to My IP)
- After VM creation, install .NET Framework v4.8.1 app running on IIS in the Windows Server 2022
- Directory structure: shallow directories
- Resource naming: all Azure resources use "jek-" prefix
- Tagging: `owner="jek"`, `env="test"`, `criticality="low"`

## Phase 2: Datadog Agent / Operator Setup

**Implementation steps:**
- Download and install the Datadog Agent on Windows Server 2022 using the MSI installer (`datadog-agent-7-latest.amd64.msi`)
- Configure the Agent: set `DD_API_KEY`, `DD_SITE`, `DD_HOSTNAME` in `C:\ProgramData\Datadog\datadog.yaml`
- Enable the IIS integration: create `C:\ProgramData\Datadog\conf.d\iis.d\conf.yaml` with site names and metrics configuration
- Enable .NET CLR metrics collection via the `dotnet_clr` check
- Enable Windows Event Log collection: configure `win32_event_log.d/conf.yaml` for Application, System, and Security logs
- Enable Windows performance counters: Processor, Memory, Disk, Network via `windows_performance_counters.d/conf.yaml`
- Restart the Datadog Agent service: `& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" restart-service`

**Validation:**
- Run `& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status` and confirm: API key valid, IIS check running, .NET CLR check running
- Verify in Datadog UI: **Infrastructure > Host Map** shows the Windows Server host
- Check **Dashboards > IIS Overview** — request rates, response codes, connection counts
- Check **Logs > Search** — Windows Event Logs appearing with `source:windows`

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior Bicep/Azure knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Create a `.gitignore` to avoid committing sensitive Bicep output or parameter files with secrets
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Do NOT reveal PII or secrets -- this is a public GitHub repo
- Development tools: iTerm and Visual Studio Code
- Development machine: MacBook M4
- Explain steps in clear, beginner-friendly language



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
- Context7 library: `/azure/azure-quickstart-templates`
- Context7 library: `/microsoft/referencesource`
- Datadog docs: [Windows Agent](https://docs.datadoghq.com/agent/basic_agent_usage/windows/)
- Datadog docs: [IIS Integration](https://docs.datadoghq.com/integrations/iis/)
