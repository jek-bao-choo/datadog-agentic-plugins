## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `mysql-selfhosted` plugin. Work proceeds in two phases: first provision the database, then set up Datadog Database Monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place provisioning scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Database Provisioning

Provision a self-hosted MySQL master-slave replication setup on EC2 using Terraform.

- Create a Terraform script to deploy **2 EC2 instances** running **MySQL 8.4 LTS** in **ap-southeast-1**
- Instance 1: **master** (primary) MySQL server
- Instance 2: **slave** (replica) MySQL server
- Include: VPC, public subnet, security group (allow MySQL 3306 + SSH 22 from current IP, auto-detected)
- **Keep it simple**: No private subnets, no bastion hosts — direct SSH access
- Include **bash scripts** to:
  - Install MySQL 8.4 on each EC2 instance
  - Configure master-slave replication (server-id, binlog, relay-log)
  - Test replication (create DB on master, verify it appears on slave)
- Document steps to SCP bash scripts from local Macbook to EC2 and then SSH to run them
- All resources use **"jek-"** prefix (e.g., `jek-mysql-master`, `jek-mysql-slave`)
- Tags: `owner="jek"`, `env="test"`
- SSH key name in cloud provider: `jek-macbook-pro-key`
- SSH locally: `~/.ssh/id_ed25519`
- Output: master IP, slave IP, SSH commands, replication verification steps

## Phase 2: Datadog Database Monitoring

Install the Datadog Agent on each EC2 instance and configure DBM for self-hosted MySQL.

- Install the **Datadog Agent** on both master and slave EC2 instances
- Create a Datadog DBM integration user on MySQL with appropriate grants
- Configure the Datadog Agent to collect:
  - **Query metrics** (performance_schema)
  - **Query samples** (events_statements_summary)
  - **Explain plans** for slow queries
- Set up the `mysql` integration check in the Datadog Agent config (`conf.d/mysql.d/conf.yaml`)
- Enable `dbm: true` in the integration config
- Verify metrics appear in Datadog (Database Monitoring > Query Metrics) for both master and slave
- Verify replication lag metrics are reported

## Guidelines

- **Simplicity**: Keep everything Hello World level — less is more
- **Beginner-friendly**: Assume no prior Terraform, MySQL, or Linux knowledge; explain every step
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security**: This is a public GitHub repo — never commit secrets, API keys, database passwords, SSH keys, or sensitive data
- **Git hygiene**: Create a `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `.terraform.lock.hcl`, `*.tfvars` (if containing secrets)
- **Teardown**: Document `terraform destroy` and any manual cleanup in the README
- **Macbook**: Development is on a Macbook running Claude Code in the terminal



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

### MCP Libraries (Context7)
- `/hashicorp/terraform`
- `/hashicorp/terraform-provider-aws`
- `/petoju/terraform-provider-mysql`

### Datadog References
- DBM for self-hosted MySQL: https://docs.datadoghq.com/database_monitoring/setup_mysql/selfhosted/
- Datadog MySQL integration: https://docs.datadoghq.com/integrations/mysql/
- Datadog Agent installation (Ubuntu): https://docs.datadoghq.com/agent/basic_agent_usage/deb/
