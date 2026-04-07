## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `aws-ec2` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning

**Goal:** Create `setup-{target}` skills that provision EC2 instances ready for Datadog agent installation.

**What a provisioning skill produces:**

- Terraform scripts for VPC, Subnet, Security Group (SSH + app ports), and EC2 instances
- SSH key pair configuration (key name: `jek-macbook-pro-key` in cloud provider, locally `~/.ssh/id_ed25519`)
- Auto-detection of current IP for security group ingress rules
- Region: ap-southeast-1
- Resource naming: "jek-" prefix with tags `owner="jek"`, `env="test"`
- README.md at the skill level documenting: terraform init/plan/apply, SSH access, verification, and teardown steps
- A .gitignore excluding `.terraform/`, `*.tfstate*`, and other sensitive Terraform outputs

**Naming convention:** `setup-{target}` (e.g., `setup-ec2`).

**Current tasks from original TODO:**
- Self-managed MySQL 8.4 LTS master-slave replication on two EC2 instances (simple setup without private subnet or bastion hosts)
- Bash scripts for MySQL installation, database setup, and replication testing
- Automate as much as possible, keep it simple

---

## Phase 2: Datadog Agent / Operator Setup

**Goal:** Create `install-dd-{method}` skills that install the Datadog Agent on provisioned EC2 instances.

**What an agent install skill produces:**

- Datadog Agent installation via the install script (`install_script_agent7.sh`)
- Log collection enabled (`logs_enabled: true` in datadog.yaml)
- Syslog forwarding configured
- Agent status verification commands
- Validation in the Datadog UI: Infrastructure list shows the host, Logs show syslog events

**Naming convention:** `install-dd-agent` with reference variants per AMI (e.g., `references/ubuntu.md`).

**Prerequisite:** The corresponding `setup-{target}` skill must be completed first.

---

## Guidelines

- **Simplicity:** Keep Terraform scripts really simple. Hello World level infrastructure.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Beginner-friendly:** Assume no prior Terraform knowledge. Explain steps clearly.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit private keys, API keys, or secrets. Use `.env` files (gitignored) and `terraform.tfvars` (gitignored).
- **Git hygiene:** Create a `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars`, and `.env`.
- **My setup:** Macbook, running Claude Code through the terminal.

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

- `/hashicorp/terraform` — Terraform documentation
- `/hashicorp/hcl` — HCL language reference
- `/hashicorp/terraform-provider-aws` — AWS provider
- `/terraform-aws-modules/terraform-aws-rds` — RDS module
- `/terraform-aws-modules/terraform-aws-ecs` — ECS module
- `/petoju/terraform-provider-mysql` — MySQL provider
- `/terraform-docs/terraform-docs` — Documentation generator

### Datadog MCP Libraries (Context7)

- `/terraform-provider-datadog` — Datadog Terraform provider
- `/datadog/datadog-agent` — Datadog Agent setup and configuration

### Datadog Documentation

- [Datadog Agent installation (Linux)](https://docs.datadoghq.com/agent/basic_agent_usage/ubuntu/)
- [Log collection](https://docs.datadoghq.com/logs/log_collection/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate metrics and logs are received
