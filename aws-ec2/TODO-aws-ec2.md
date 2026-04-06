## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

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
- **Documentation:** Every skill needs a README.md with setup, deployment, verification, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit private keys, API keys, or secrets. Use `.env` files (gitignored) and `terraform.tfvars` (gitignored).
- **Git hygiene:** Create a `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars`, and `.env`.
- **My setup:** Macbook, running Claude Code through the terminal.

---

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
