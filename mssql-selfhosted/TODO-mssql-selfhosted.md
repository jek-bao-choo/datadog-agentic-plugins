# TODO — mssql-selfhosted

## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `mssql-selfhosted` plugin. Work proceeds in two phases: first provision the database, then set up Datadog Database Monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place provisioning scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Database Provisioning

**Goal:** Based on the PoC requirement, create a `setup-mssql-{os}` skill that provisions a VM, installs Microsoft SQL Server, and makes it ready for Datadog Database Monitoring — independent of any Datadog instrumentation.

There are two deployment paths. The PoC requirement determines which to use. If not specified, ask before assuming.

### Path A: Windows Server (Azure VM)

**Prerequisite:** A Windows Server VM must be provisioned first — either via the `azure-vm` plugin (Bicep) or Terraform with the `azurerm` provider. The IaC tool depends on the PoC requirement; if not specified, ask before assuming.

- Install SQL Server (2019 or 2022, depending on PoC) on the Windows Server VM using the SQL Server installer or `choco install sql-server-2022`
- Configure SQL Server: enable **Mixed Mode authentication** (Windows + SQL auth), enable **TCP/IP** protocol on port 1433, open firewall rule for 1433
- Install SQL Server Management Studio (SSMS) for administration (optional but recommended for PoC demos)
- Create a sample database with test tables and seed data for DBM validation
- Verify connectivity: `sqlcmd -S localhost -U sa -P '<PASSWORD>' -Q "SELECT @@VERSION"`

**Naming convention:** `setup-mssql-windows` (or `setup-mssql-win2022` if version-specific)

### Path B: Linux (EC2 or Azure VM)

**Prerequisite:** The `aws-ec2` plugin's `setup-ec2` skill (for EC2) or `azure-vm` plugin (for Azure Linux VM) must be completed first.

- Install SQL Server on Linux from Microsoft's official apt/yum repositories:
  - Ubuntu: `apt-get install -y mssql-server` + `mssql-conf setup`
  - RHEL: `yum install -y mssql-server` + `mssql-conf setup`
- Install `mssql-tools` and `unixodbc-dev` for `sqlcmd` CLI access
- Configure: accept EULA, set SA password, choose edition (Developer for PoC), enable TCP/IP on port 1433
- Create a sample database with test tables and seed data
- Verify connectivity: `sqlcmd -S localhost -U sa -P '<PASSWORD>' -Q "SELECT @@VERSION"`

**Naming convention:** `setup-mssql-linux` (or `setup-mssql-ubuntu22` if version-specific)

### For both paths:

- Optionally configure AlwaysOn Availability Groups or database mirroring if the PoC requires HA
- Document connection strings for application use
- Output: VM IP, SQL Server port, SA credentials (from environment variable, not hardcoded), connectivity verification steps

---

## Phase 2: Datadog Database Monitoring

**Goal:** Create an `install-dd-dbm` skill that installs the Datadog Agent and configures DBM for SQL Server — producing query metrics, explain plans, and activity monitoring in the Datadog UI.

**Implementation steps:**

- Install the Datadog Agent on the SQL Server host:
  - Windows: MSI installer (`datadog-agent-7-latest.amd64.msi`), configure via `C:\ProgramData\Datadog\datadog.yaml`
  - Linux: Install via the Datadog install script, configure via `/etc/datadog-agent/datadog.yaml`
- Create a Datadog DBM integration user on SQL Server with required permissions:
  ```sql
  CREATE LOGIN datadog WITH PASSWORD = '<PASSWORD>';
  CREATE USER datadog FOR LOGIN datadog;
  GRANT CONNECT ANY DATABASE to datadog;
  GRANT VIEW SERVER STATE to datadog;
  GRANT VIEW ANY DEFINITION to datadog;
  ```
- Configure the SQL Server integration in the Datadog Agent:
  - Windows: `C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml`
  - Linux: `/etc/datadog-agent/conf.d/sqlserver.d/conf.yaml`
  - Key settings: `host`, `port: 1433`, `username: datadog`, `password` (from env var), `dbm: true`
- Enable collection of:
  - **Query metrics** (sys.dm_exec_query_stats, sys.dm_exec_procedure_stats)
  - **Query samples** (sys.dm_exec_requests, sys.dm_exec_sql_text)
  - **Explain plans** (estimated execution plans for slow queries)
  - **Wait statistics** (sys.dm_os_wait_stats)
- Set unified service tags: `DD_ENV`, `DD_SERVICE`, `DD_VERSION`
- Restart the Datadog Agent

**Naming convention:** `install-dd-dbm`

**Prerequisite:** The corresponding `setup-mssql-{os}` skill (and the running SQL Server instance) must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Validation:**
- Run Agent status command and confirm the `sqlserver` check is running without errors
- Verify in Datadog UI: **Database Monitoring > Query Metrics** shows SQL Server queries
- Confirm query samples appear in **Database Monitoring > Query Samples**
- Check explain plans are available for slow queries
- Verify wait statistics are reported

---

## Guidelines

- **Simplicity:** Keep everything Hello World level — less is more.
- **Beginner-friendly:** Assume no prior SQL Server or database admin knowledge. Explain every step.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This is a public GitHub repo — never commit SA passwords, connection strings, API keys, or sensitive data. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `.terraform/`, `*.tfstate*`, `*.tfvars`, `.env`, and other sensitive files.
- **Teardown:** Document cleanup steps (VM deletion, SQL Server uninstall) in the README.
- **My setup:** Macbook, running Claude Code through the terminal.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

---

## Tools & References

### MCP Libraries (Context7)

- `/hashicorp/terraform` — Terraform documentation (for Linux path)
- `/hashicorp/terraform-provider-aws` — AWS provider (for EC2 Linux path)
- `/azure/azure-quickstart-templates` — Azure Bicep templates (for Windows path)

### Datadog Documentation

- [DBM for self-hosted SQL Server](https://docs.datadoghq.com/database_monitoring/setup_sql_server/selfhosted/)
- [SQL Server integration](https://docs.datadoghq.com/integrations/sqlserver/)
- [Windows Agent](https://docs.datadoghq.com/agent/basic_agent_usage/windows/)
- [Linux Agent (Ubuntu)](https://docs.datadoghq.com/agent/basic_agent_usage/deb/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate metrics and queries are received

### Microsoft Documentation

- [Install SQL Server on Linux](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup)
- [Install SQL Server on Windows](https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server)
- [SQL Server editions comparison](https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022)
