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
- **README.md**: Each skill folder must have a README.md with setup, deployment, verification, and teardown steps
- **Security**: This is a public GitHub repo — never commit secrets, API keys, database passwords, SSH keys, or sensitive data
- **Git hygiene**: Create a `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `.terraform.lock.hcl`, `*.tfvars` (if containing secrets)
- **Teardown**: Document `terraform destroy` and any manual cleanup in the README
- **Macbook**: Development is on a Macbook running Claude Code in the terminal

## Tools & References

### MCP Libraries (Context7)
- `/hashicorp/terraform`
- `/hashicorp/terraform-provider-aws`
- `/petoju/terraform-provider-mysql`

### Datadog References
- DBM for self-hosted MySQL: https://docs.datadoghq.com/database_monitoring/setup_mysql/selfhosted/
- Datadog MySQL integration: https://docs.datadoghq.com/integrations/mysql/
- Datadog Agent installation (Ubuntu): https://docs.datadoghq.com/agent/basic_agent_usage/deb/
