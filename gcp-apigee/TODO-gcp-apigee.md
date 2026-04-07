## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `gcp-apigee` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---



## Phase 1: Infrastructure Provisioning
- Set up Apigee X via Terraform
- Components: VPC networking, Private Service Connect (PSC), load balancers, API proxies
- Note: Apigee X provisioning takes 45-90 minutes -- plan accordingly
- Consider the Apigee emulator option for local development and faster iteration
- Region: Asia Southeast (asia-southeast1)
- Directory structure: shallow directories
- Resource naming: all GCP resources use "jek-" prefix
- Tagging: `owner:jek`, `env=test`

## Phase 2: Datadog Agent / Operator Setup

**Implementation steps:**
- Deploy the Datadog Agent on the GKE cluster hosting the Apigee backend (see `gcp-gke` plugin for Datadog Operator setup)
- Instrument the backend Spring Boot application with `dd-java-agent.jar` (see `java-instrumentation` plugin) so Datadog captures traces from the backend service
- Enable GCP Cloud Trace on the Apigee X instance for API proxy-level trace collection
- Configure the Datadog GCP integration to pull Cloud Trace data into Datadog APM
- Set unified service tags (`DD_SERVICE`, `DD_ENV`, `DD_VERSION`) on the backend application

**Research tasks (document findings in README.md):**
- How Apigee proxy telemetry (latency, error rates, request counts) flows into Datadog — via Cloud Trace, Cloud Monitoring, or direct OTLP export
- Whether Apigee X natively supports OpenTelemetry trace context propagation through the proxy layer
- How to correlate Apigee proxy traces with backend service traces in Datadog APM

**Validation:**
- Verify traces appear in **APM > Traces** in the Datadog UI, with spans from both the Apigee proxy layer and the backend service
- Check **APM > Service Map** shows the request flow: Client → Apigee → Backend
- Confirm Cloud Trace data is visible in the GCP Console as a cross-reference

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior Terraform knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Create a `.gitignore` to avoid committing sensitive Terraform files (state, tfvars, etc.)
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Do NOT reveal PII or secrets -- this is a public GitHub repo
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
- Context7 library: `/googlecloudplatform/terraform-google-cloud-run`
- Context7 library: `/googlecloudplatform/cloud-run-samples`
- Context7 library: `/hashicorp/terraform`
- Context7 library: `/hashicorp/hcl`
- Context7 library: `/websites/cloud_google_terraform`
- Context7 library: `/terraform-google-modules/terraform-google-network`
- Datadog docs: [APM & Distributed Tracing](https://docs.datadoghq.com/tracing/)
- Datadog docs: [GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
