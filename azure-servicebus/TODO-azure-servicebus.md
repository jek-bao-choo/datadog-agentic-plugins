# TODO — azure-servicebus

## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `azure-servicebus` plugin. Work proceeds in two phases: first provision the message queue infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place IaC scripts, configs, and sample code in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Queue Provisioning

**Goal:** Create a `setup-servicebus` skill that provisions an Azure Service Bus namespace with queues and/or topics, ready for Datadog monitoring.

**IaC tool:** Bicep or Terraform (`azurerm` provider) — the PoC requirement determines which. If not specified, ask before assuming.

**What the provisioning skill produces:**

- An Azure Service Bus Namespace (Standard or Premium tier, depending on PoC)
- At least one **Queue** for point-to-point messaging
- At least one **Topic** with one or more **Subscriptions** for publish-subscribe messaging (if the PoC requires pub-sub)
- A **Shared Access Policy** (Send, Listen, or Manage) for producer/consumer authentication — output the policy name and connection string retrieval command, never the actual connection string
- Resource Group (create new or use existing, depending on PoC)
- Region: configurable (default Southeast Asia)
- Resource naming: all Azure resources use "jek-" prefix
- Tagging: `owner="jek"`, `env="test"`, `criticality="low"`

**Sample producer/consumer for validation:**

Create minimal producer and consumer scripts to verify message flow. The language depends on the PoC requirement (Python, .NET, Node.js, Java). If not specified, default to Python with the `azure-servicebus` SDK. The scripts should:

- **Producer:** Send 10 test messages to a queue (or publish to a topic), reading the connection string from a `.env` file or environment variable
- **Consumer:** Receive and print messages from the queue (or subscription), reading the connection string from a `.env` file or environment variable
- Include a `requirements.txt` (or equivalent) with pinned dependencies
- Include a `.env.example` with placeholder connection string
- Never commit the actual `.env` file — ensure `.gitignore` excludes it

**Naming convention:** `setup-servicebus` (or `setup-servicebus-{tier}` if tier-specific).

---

## Phase 2: Datadog Integration

**Goal:** Create an `install-dd-integration` skill that configures the Datadog Azure integration to collect Service Bus metrics and (optionally) logs.

**Implementation steps:**

**Metrics (via Datadog Azure integration):**
- Ensure the Datadog Azure integration is configured — this requires an Azure AD App Registration (service principal) with Reader role on the subscription or resource group. If not already set up, document the steps:
  1. Create an App Registration in Azure AD
  2. Create a client secret
  3. Grant Reader role on the target subscription
  4. Enter the Tenant ID, Client ID, and Client Secret in the Datadog Azure integration tile
- Enable the **Azure Service Bus** metric collection in the Datadog Azure integration tile (it may be enabled by default)
- Key metrics to monitor:
  - `azure.servicebus.active_messages` — messages waiting to be consumed
  - `azure.servicebus.deadlettered_messages` — messages in the dead-letter queue
  - `azure.servicebus.incoming_messages` / `azure.servicebus.outgoing_messages` — throughput
  - `azure.servicebus.server_errors` — service-side errors
  - `azure.servicebus.throttled_requests` — rate-limited requests (Premium tier capacity signal)
  - `azure.servicebus.size` — namespace storage usage

**Logs (optional, via Azure Diagnostic Settings):**
- Configure Azure Monitor Diagnostic Settings on the Service Bus namespace to stream logs to an Event Hub
- Set up a Datadog Event Hub forwarder (Azure Function) to forward logs from Event Hub to Datadog
- Reference: https://docs.datadoghq.com/integrations/azure/?tab=eventhub#log-collection
- Log categories to enable: `OperationalLogs`, `VNetAndIPFilteringLogs`, `RuntimeAuditLogs`

**Tracing (Data Streams Monitoring):**
- If the PoC includes producer/consumer applications instrumented with a Datadog tracer (`ddtrace` for Python, `Datadog.Trace` for .NET, `dd-trace-js` for Node.js, etc.), enable Data Streams Monitoring (DSM) to track end-to-end latency and throughput across Azure Service Bus pipelines
- DSM automatically detects producer → queue → consumer pathways and measures lag at each stage
- Reference: https://docs.datadoghq.com/data_streams/setup/technologies/azure_service_bus.md
- Validation: check **Data Streams** in the Datadog UI — verify the Service Bus queue/topic appears with producer and consumer nodes

**Monitors (recommended):**
- Dead-letter queue depth > 0 for extended period (indicates consumer failures)
- Throttled requests > threshold (indicates need to scale up or switch to Premium tier)
- Server errors spike (indicates Azure-side issues)

**Validation:**
- Verify metrics appear in **Metrics > Explorer** — search for `azure.servicebus`
- Check the out-of-the-box **Azure Service Bus** dashboard in Datadog (Dashboards > Dashboard List > search "Service Bus")
- If logs are configured, verify in **Logs > Search** — filter by `source:azure.servicebus`
- Run the sample producer to send messages, verify `incoming_messages` metric increases in real-time
- Run the sample consumer to drain messages, verify `outgoing_messages` metric increases

---

## Guidelines

- **Simplicity:** Keep everything Hello World level — less is more.
- **Beginner-friendly:** Assume no prior Azure Service Bus knowledge. Explain messaging concepts (queues vs topics, dead-letter queues, Shared Access Policies) briefly when first introduced.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This is a public GitHub repo. Never commit connection strings, SAS keys, client secrets, or API keys. Use `.env` files (gitignored) and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `.env`, `.terraform/`, `*.tfstate*`, `*.tfvars`, and Bicep parameter files with secrets.
- **Teardown:** Document how to delete the namespace and all resources (`az servicebus namespace delete` or `terraform destroy`).
- **My setup:** MacBook M4, iTerm, Visual Studio Code, Claude Code terminal.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

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

- `/azure/azure-quickstart-templates` — Azure Bicep templates
- `/hashicorp/terraform` — Terraform documentation (if using Terraform)
- `/hashicorp/terraform-provider-azurerm` — Azure RM provider (if using Terraform)

### Datadog Documentation

- [Azure Integration setup](https://docs.datadoghq.com/integrations/azure/)
- [Azure Service Bus integration](https://docs.datadoghq.com/integrations/azure_service_bus/)
- [Azure log collection via Event Hub](https://docs.datadoghq.com/integrations/azure/?tab=eventhub#log-collection)
- [Data Streams Monitoring for Azure Service Bus](https://docs.datadoghq.com/data_streams/setup/technologies/azure_service_bus.md)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate metrics are received

### Microsoft Documentation

- [Azure Service Bus overview](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)
- [Service Bus Bicep quickstart](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-resource-manager-namespace-queue-bicep)
- [Service Bus Terraform (azurerm_servicebus_namespace)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace)
- [Azure Service Bus Python SDK](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-python-how-to-use-queues)
