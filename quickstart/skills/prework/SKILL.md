---
name: prework
description: >-
  Use this skill whenever the user needs to plan and generate PoC prework TODO files
  based on a prospect's tech stack, transaction flow, and PoC requirements. Triggers
  on mentions of prework, PoC planning, evaluation plan, TMAP, implementation guide,
  prospect tech stack analysis, transaction flow mapping, or generating TODO files for
  a PoC engagement. Also applies when the user provides IMPLEMENTATION_GUIDE.md,
  evalplan CSV, or TMAP spreadsheets and wants to turn them into actionable setup steps.
version: 0.1.0
---

# PoC Prework — Gather Requirements and Generate TODO Files

This skill gathers PoC requirements, tech stack details, and transaction flow information from the user, then generates a set of sequenced TODO files that replicate the prospect's environment for prework validation.

## Phase 1: Information Gathering

Collect the following BEFORE generating anything. Ask for any information not provided — do NOT assume.

### 1. Input Sources

Read PoC requirements from one or more of these input types:
- **Implementation guides** (e.g., `IMPLEMENTATION_GUIDE.md`)
- **Evaluation plans** (e.g., `evalplan_comprehensive.csv`, `TMAP-Evaluation-Plan.xlsx`)
- **TMAP spreadsheets** (e.g., technology mapping spreadsheets)
- **Custom notes** the user provides verbally or pastes

The user will provide file paths. Read and extract: tech stack (language, framework, version), infrastructure (cloud provider, OS, K8s), databases, message queues, and monitoring requirements.

### 2. Tech Stack (REQUIRED — do NOT assume)

For every component in the prospect's architecture, collect:
- **Language and version** (e.g., Java 17, Python 3.11, .NET 8, PHP 8.3)
- **Framework and version** (e.g., Spring Boot 3.5.9, FastAPI 0.116, Laravel 12, Express 5)
- **Runtime/server** (e.g., Tomcat 10.1, Gunicorn, Nginx, Apache, IIS)
- **Database engine and version** (e.g., MySQL 8.4, PostgreSQL 17, SQL Server 2022, Oracle 19c)
- **Message queue** (e.g., Azure Service Bus, Kafka 3.6, RabbitMQ 3.13, AWS SQS)
- **Infrastructure** (e.g., AWS EC2 Ubuntu 22.04, GKE 1.34, Azure VM Windows Server 2022, OpenShift 4.19)
- **Monitoring/observability** (e.g., Datadog Agent, Datadog Operator, OTel Collector, dd-trace-java)

If the user says "use latest" for any component, that is acceptable. Otherwise, ask for the specific version. NEVER guess versions.

### 3. Transaction Flow (REQUIRED — do NOT proceed without this)

Ask the user to describe how a transaction flows end-to-end through their prospect's architecture. Examples:

- **Three-tier:** Web Server → Business Logic Server → Database Server
- **With queue:** Web Server → Message Queue → Worker Service → Database Server
- **Microservices:** Web Frontend → API Gateway → Service A → Service B → Message Queue → Service C → Database
- **Mobile:** Mobile App → API Gateway → Backend Service → Database

The transaction flow determines the **build order** (bottom-up) and the **skill execution sequence**.

**If the user does NOT provide a transaction flow, ask for it explicitly before proceeding. Do NOT start generating anything without it.**

## Phase 2: Generate TODO Files

### Build Order: Bottom-Up (Foundation First)

Always build from the lowest downstream service to the upstream. For the flow `Web App → Business Logic → Database`:

1. **Database layer first:**
   - Provision the database server/instance (infrastructure)
   - Install/configure the database engine
   - Create tables and insert dummy data
   - Add Datadog monitoring (Agent/DBM integration)

2. **Business logic layer next:**
   - Provision the host/server (EC2, GKE pod, Azure VM, etc.)
   - Build and deploy the application
   - Instrument with Datadog APM (dd-trace, ddtrace, etc.)
   - Verify traces flow to Datadog

3. **Web/frontend layer last:**
   - Provision the host (if different from business logic)
   - Build and deploy the web application
   - Instrument with Datadog APM or RUM
   - Verify end-to-end trace propagation

### Output Files

Generate the following files in the current working directory:

1. **`{dummy-name}-manifest.md`** — The execution manifest listing all TODO files in sequential order with dependencies. This is the "run sheet" for the PoC prework.

2. **`{dummy-name}-TODO-{plugin-name}.md`** files — One per plugin/layer, based on the existing `TODO-*.md` templates in each plugin directory. Each file is a concrete, filled-in version of the template with:
   - Specific versions, frameworks, and configurations from the prospect's tech stack
   - Specific naming using the `jek-` resource prefix
   - Specific infrastructure details (region, instance size, etc.)
   - References to upstream/downstream dependencies in the transaction flow

### Referencing Existing Templates

Before writing each TODO file, read the corresponding template from the plugin directory:
- For database setup: read `{plugin}/TODO-{plugin}.md` (e.g., `mysql-selfhosted/TODO-mysql-selfhosted.md`)
- For infrastructure: read `{plugin}/TODO-{plugin}.md` (e.g., `aws-ec2/TODO-aws-ec2.md`)
- For instrumentation: read `{plugin}/TODO-{plugin}.md` (e.g., `java-instrumentation/TODO-java-instrumentation.md`)

The generated files should be filled-in, prospect-specific versions of these templates — not invented from scratch.

### Example Output Structure

For a prospect with flow: React Frontend → Spring Boot API → PostgreSQL (dummy name: `greenfield-42`):

```
greenfield-42-manifest.md                      # Execution run sheet
greenfield-42-TODO-aws-ec2.md                  # 1. Provision EC2 for PostgreSQL
greenfield-42-TODO-postgres-selfhosted.md      # 2. Install PostgreSQL, create tables, seed data, add DBM
greenfield-42-TODO-aws-eks.md                  # 3. Provision EKS cluster
greenfield-42-TODO-java-instrumentation.md     # 4. Deploy Spring Boot API, instrument with dd-trace-java
greenfield-42-TODO-react-instrumentation.md    # 5. Deploy React frontend, instrument with Datadog RUM
```

### Manifest Format

The manifest should include:
- Dummy prospect name and date (never real prospect name)
- Transaction flow diagram (ASCII)
- Technical architecture diagram (ASCII)
- Tech stack summary table (component → language/framework → version)
- Sequential execution table: step number, TODO file, plugin, what it does, depends on
- Pre-flight checklist: what credentials/access is needed before starting (Datadog API key, cloud provider credentials, SSH keys, etc.)

## Rules

- **NEVER start prototyping without knowing the transaction flow sequence**
- **NEVER assume tech stack versions** — ask if not provided (unless user says "use latest")
- **ALWAYS build bottom-up** — foundation layer (infra + database) before application layer before frontend layer
- **ALWAYS reference existing TODO-*.md templates** — the generated files should be filled-in versions of these templates, not invented from scratch
- **ALWAYS ask clarifying questions** before generating if any information is missing

## Security: Prospect Name Handling

- **ALWAYS use a dummy prospect name** for generated file names and resource prefixes — e.g., `helloworld-1`, `acme-corp`, `project-alpha`, `greenfield-42`. Generate a random one each time. Even if the user provides a real prospect name, replace it with a dummy name in ALL generated filenames and content.
- **NEVER commit generated output to git.** The generated `{dummy-name}-manifest.md` and `{dummy-name}-TODO-*.md` files contain prospect-specific tech stack details. Ensure they are covered by `.gitignore`.
- **If the user provides file paths containing real prospect/company names**, read the files but do NOT echo the real company name into any generated output. Use the dummy name throughout.
- **Real prospect name may be kept only in the user's head or private notes** — never in files that could be committed to a public GitHub repo.
