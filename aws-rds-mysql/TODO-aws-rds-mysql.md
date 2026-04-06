## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `aws-rds-mysql` plugin. Work proceeds in two phases: first provision the database, then set up Datadog Database Monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place provisioning scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Database Provisioning

Provision an RDS MySQL instance with a read replica on AWS using Terraform.

- Create a Terraform script to deploy **Amazon RDS MySQL 8.4** in **ap-southeast-1**
- Deploy a **primary instance** and a **read replica**
- Include: VPC, public/private subnets, DB subnet group
- Include: Security groups (allow MySQL port 3306 from current IP, auto-detected)
- Instance class: `db.t3.micro` or `db.t3.small` (keep costs low)
- All resources use **"jek-"** prefix (e.g., `jek-rds-mysql-primary`, `jek-rds-mysql-replica`)
- Tags: `owner="jek"`, `env="test"`
- Master username/password: use Terraform variables (never hardcoded); document how to pass them securely
- Enable: automated backups, multi-AZ disabled (test environment)
- Output: primary endpoint, replica endpoint, connection instructions

## Phase 2: Datadog Database Monitoring

Configure Datadog Database Monitoring (DBM) for RDS MySQL.

- Create a Datadog DBM integration user on the RDS MySQL instance with appropriate grants
- Configure the Datadog Agent to collect:
  - **Query metrics** (performance_schema)
  - **Query samples** (events_statements_summary)
  - **Explain plans** for slow queries
- Set up the `mysql` integration check in the Datadog Agent config (`conf.d/mysql.d/conf.yaml`)
- Enable `dbm: true` in the integration config
- Verify metrics appear in Datadog (Database Monitoring > Query Metrics)
- Verify explain plans are collected for sampled queries

## Guidelines

- **Simplicity**: Keep everything Hello World level — less is more
- **Beginner-friendly**: Assume no prior Terraform or RDS knowledge; explain every step
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security**: This is a public GitHub repo — never commit secrets, API keys, database passwords, or sensitive data
- **Git hygiene**: Create a `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `.terraform.lock.hcl`, `*.tfvars` (if containing secrets)
- **Teardown**: Document `terraform destroy` and any manual cleanup in the README
- **Macbook**: Development is on a Macbook running Claude Code in the terminal

## Tools & References

### MCP Libraries (Context7)
- `/hashicorp/terraform`
- `/hashicorp/terraform-provider-aws`
- `/terraform-aws-modules/terraform-aws-rds`

### Datadog References
- DBM for RDS MySQL: https://docs.datadoghq.com/database_monitoring/setup_mysql/rds/
- Datadog MySQL integration: https://docs.datadoghq.com/integrations/mysql/
- DBM query metrics: https://docs.datadoghq.com/database_monitoring/query_metrics/
