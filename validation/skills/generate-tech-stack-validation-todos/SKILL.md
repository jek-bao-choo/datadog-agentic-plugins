---
name: generate-tech-stack-validation-todos
description: >-
  Use this skill whenever the user needs to validate a prospect's tech stack for
  PoC prework — gathering tech stack and transaction flow, then generating
  sequenced TODO files that replicate the stack layer-by-layer. Triggers on
  mentions of tech stack validation, validate prospect tech stack, PoC prework,
  PoC prework validation, generate prework TODOs, Datadog PoC planning, evaluation plan,
  TMAP, implementation guide, prospect tech stack analysis, or transaction flow
  mapping. Also applies when the user provides IMPLEMENTATION_GUIDE.md,
  evalplan CSV, or TMAP spreadsheets and wants to turn them into actionable
  prework validation steps.
---

# Tech Stack Validation TODOs — Gather Requirements and Generate the Prework Run Sheet

This skill runs tech stack validation as PoC prework — gathering the prospect's tech stack and transaction flow, then generating a manifest and sequenced TODO files that replicate the prospect's environment layer-by-layer.

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

### Output Directory

Generate all output files in the `validation/backlog/` folder (relative to the repo root — the `datadog-agentic-plugins` directory that contains the `validation/` plugin). Create the directory if it does not already exist. The folder is gitignored at the repo level, which ensures prospect-specific output is never accidentally committed.

**`validation/backlog/` is write-only for this skill.** When planning or generating new manifest and TODO files, do NOT read any existing file in `validation/backlog/` — no `*-TODO-*.md`, no `*-manifest.md`, from any past PoC run or the current run in progress. The folder holds ephemeral, prospect-specific outputs; treating those files as templates would leak one prospect's versions, resource names, or transaction flow into another prospect's plan. The sources of truth for template structure are strictly `{plugin}/skills/*/SKILL.md` (preferred — most specific) and `{plugin}/TODO-{plugin}.md` (fallback — generic per-plugin template), both at the plugin root. Every TODO file is derived fresh from the Phase 1 inputs + those plugin-rooted templates, not from peer files in the backlog.

### Output Files

1. **`validation/backlog/{dummy-name}-manifest.md`** — The execution manifest listing all TODO files in sequential order with dependencies. This is the "run sheet" for the PoC prework.

2. **`validation/backlog/{dummy-name}-TODO-{plugin-name}.md`** files — One per plugin/layer, based on the existing `TODO-*.md` templates in each plugin directory. Each file is a concrete, filled-in version of the template with:
   - Specific versions, frameworks, and configurations from the prospect's tech stack
   - Resource names that follow the `jek-{resource-type}[-{qualifier}]-{dummy-name}` convention (see **Resource Naming Convention** below — suffix is mandatory to prevent collision between concurrent PoC runs)
   - Specific infrastructure details (region, instance size, etc.)
   - References to upstream/downstream dependencies in the transaction flow

### Resource Naming Convention

Every cloud-created resource and every Datadog-side name (service name, env tag, distinguishing resource tag) for this PoC must follow the pattern `jek-{resource-type}[-{qualifier}]-{dummy-name}`. Both the `jek-` **prefix** and the `-{dummy-name}` **suffix** are mandatory:

- The **`jek-` prefix** marks the resource as belonging to Jek's PoC namespace (distinguishes from customer/shared resources in the same account).
- The **`-{dummy-name}` suffix** prevents collision between concurrent PoC runs on the same account (two PoCs must not both try to create `jek-ec2-centos9`; they become `jek-ec2-centos9-greenfield` and `jek-ec2-centos9-skybridge`).

**This pattern applies ONLY to infrastructure resource names and Datadog service/tag names.** Skill names, plugin names, `SKILL.md` filenames, plugin directory names, and Terraform file/module/variable identifiers never carry the `jek-` prefix and never carry the `-{dummy-name}` suffix — they stay exactly as written in the repo. See "Scope — what the convention does NOT apply to" below.

**Pattern:** `jek-{resource-type}[-{qualifier}]-{dummy-name}`

**Examples** (with dummy-name = `greenfield`):

| Resource category | Un-suffixed default (don't use) | Required suffixed form |
|---|---|---|
| VPC | `jek-vpc` | `jek-vpc-greenfield` |
| Subnet | `jek-public-subnet` | `jek-public-subnet-greenfield` |
| Route table | `jek-rt-centos9` | `jek-rt-centos9-greenfield` |
| Security group | `jek-sg-centos9` | `jek-sg-centos9-greenfield` |
| EC2 instance | `jek-ec2-centos9` | `jek-ec2-centos9-greenfield` |
| GKE cluster | `jek-gke-cluster` | `jek-gke-cluster-greenfield` |
| Azure VM | `jek-vm-win2022` | `jek-vm-win2022-greenfield` |
| S3 / GCS bucket | `jek-logs` | `jek-logs-greenfield` |
| Datadog service name | `jek-spring-api` | `jek-spring-api-greenfield` |
| Datadog env tag | `jek-poc` | `jek-poc-greenfield` |

**Scope — what the convention DOES apply to:** ALL `jek-` named artifacts *created for this PoC* — cloud networking (VPC, subnet, route table, security group), compute (VMs, clusters, nodes), storage (buckets, volumes), message queues, databases, Kubernetes namespaces/deployments, and Datadog-side names (service, env tag, distinguishing resource tags). These are the literal name strings Terraform / Helm / cloud SDKs pass to cloud APIs.

**Scope — what the convention does NOT apply to** (neither the `jek-` prefix nor the `-{dummy-name}` suffix touches these — they are per-user, per-plugin, or per-repo, NOT per-PoC):

| Artifact | Stays as-is | Why |
|---|---|---|
| SSH key pair | `jek_rsa_pem` | Pre-existing, shared across all of Jek's PoCs. Uses a `jek_` underscore prefix (distinct from the `jek-` hyphen convention above); never gets a `-{dummy}` suffix. |
| Datadog API / APP keys, client tokens | unchanged | Global account credentials |
| Skill names | `setup-ec2-centos9`, `springboot3x-dd-tracer`, `generate-tech-stack-validation-todos`, etc. | Plugin-level artifacts — **no `jek-` prefix, no `-{dummy}` suffix**, stays exactly as written |
| Plugin names | `aws-ec2`, `java-instrumentation`, `validation`, `quickstart`, etc. | Repo-level artifacts — **no `jek-` prefix, no `-{dummy}` suffix** |
| Skill frontmatter `name:` fields | unchanged | Part of the skill's identity — changing breaks triggering |
| `SKILL.md` filenames / skill directory names | unchanged | Repo-level artifacts |
| Plugin directory names | `aws-ec2/`, `java-instrumentation/`, `validation/` | Repo-level artifacts |
| `TODO-{plugin}.md` template filenames | unchanged | Plugin-level templates |
| Skill trigger phrases (example user prompts) | unchanged | Part of the skill description, not a resource |
| Terraform file / module / variable names inside a setup skill | `main.tf`, `variables.tf`, `resource "aws_instance" "this"`, `variable "instance_type"` | Repo-level code identifiers; only the *literal resource-name strings* (e.g., the `"jek-ec2-centos9"` value passed to a `name` or `Name` tag attribute) get the `sed`-rename |
| `jek-` variables in shared config files that are not cloud-created resources | unchanged | Not cloud resources |

**Rule of thumb:** If the artifact lives in git on disk at commit time, it stays un-suffixed. If the artifact is a *value* passed to a cloud API (AWS/GCP/Azure/Datadog) at `terraform apply` / `kubectl apply` / dd-trace-agent-attach time, it gets the `jek-…-{dummy}` treatment.

**Overriding downstream setup skills.** Many setup skills (e.g., `aws-ec2/skills/setup-ec2-centos9`, `gcp-gke/skills/setup-gke-cluster`) hardcode un-suffixed names in their Terraform or scripts. When a generated TODO cites such a skill, the TODO must include an explicit rename step.

Important: the skill path (e.g., `aws-ec2/skills/setup-ec2-centos9`) **stays exactly as written** in the `Use skill:` line and in `## Recommended Skills`. Do NOT suffix the skill name or the skill directory. What gets renamed is the `jek-*` resource-name strings *inside* that skill's `scripts/*.tf` files — the Terraform file names, module names, and variable identifiers are not touched either.

**Preferred path:** if the setup skill already exposes a `name_suffix` (or equivalent) Terraform variable, use it — `terraform apply -var name_suffix=-{dummy-name}` — and document that invocation in the generated TODO instead of the `sed` fallback.

**Fallback path** (when the setup skill hardcodes the names, which is the current state for `setup-ec2-centos9`): rewrite the `.tf` files in place with `sed` before applying. Example Phase 1 block in a generated TODO:

````
### Phase 1: Provision the host
Use skill: `aws-ec2/skills/setup-ec2-centos9`

Before `terraform apply`, apply the dummy-name suffix to every jek- resource in the skill's scripts:

```bash
cd aws-ec2/skills/setup-ec2-centos9/scripts
sed -i '' \
  -e 's/jek-ec2-centos9/jek-ec2-centos9-greenfield/g' \
  -e 's/jek-rt-centos9/jek-rt-centos9-greenfield/g' \
  -e 's/jek-sg-centos9/jek-sg-centos9-greenfield/g' \
  -e 's/jek-vpc/jek-vpc-greenfield/g' \
  -e 's/jek-public-subnet/jek-public-subnet-greenfield/g' \
  *.tf
terraform init && terraform plan && terraform apply
```
````


**Character-length caveats.** Watch global-uniqueness limits when the combined name would overflow:
- S3 / GCS bucket: 63 chars (also must be DNS-compliant lowercase)
- Azure Storage Account: 24 chars lowercase alphanumeric — drop hyphens and shorten aggressively
- Kubernetes namespace / resource: 63 chars
- IAM role / policy: 64 chars
- RDS / Cloud SQL instance identifier: 63 chars

If `jek-{resource}[-{qualifier}]-{dummy}` would exceed a limit, shorten the dummy-name first (e.g., `greenfield-42` → `gf42`). Record the abbreviation in the manifest's Resource Name Inventory so downstream phases reference it consistently.

### Matching Skills to the Prospect's Tech Stack

Before writing each TODO file, enumerate `{plugin}/skills/*/SKILL.md` for the plugin that step covers, then match each skill's `name` and `description` frontmatter against the prospect's tech stack captured in Phase 1. Apply **most-specific-wins** priority:

1. **Most specific match** — the skill whose name/description most precisely encodes the prospect's language version, framework version, OS, runtime, or integration. Examples:
   - Prospect: Spring Boot 3.4 + Apache Camel → `java-instrumentation/skills/setup-springboot3x-apachecamel`
   - Prospect: Spring Boot 3.4 (no Camel) → `java-instrumentation/skills/setup-springboot3x`
   - Prospect: CentOS Stream 9 EC2 → `aws-ec2/skills/setup-ec2-centos9` (NOT the generic `setup-ec2`)
   - Prospect: Laravel 12 on Nginx → `php-instrumentation/skills/setup-laravel12-nginx`
2. **Less specific match** — a generic skill in the same plugin whose description covers the prospect's framework at a higher level (e.g., `setup-springboot` when no version-specific skill matches).
3. **Pair setup with instrumentation** — many plugins expose both a setup skill and an instrumentation skill (e.g., `setup-springboot3x` + `springboot3x-dd-tracer`). Cite both in the same TODO when the prospect will do both steps in that layer.
4. **Fallback** — if no skill in `{plugin}/skills/` matches, use the root `{plugin}/TODO-{plugin}.md` template and prepend the no-match notice (see "Citing Skills…" below).

When multiple skills match at the same specificity level (rare), cite them all as alternatives and note that the user should pick during execution.

### Citing Skills in the Generated TODO

Every generated `{dummy}-TODO-{plugin}.md` must follow this structure:

**(a) Top section — `## Recommended Skills`** immediately under the H1. When one or more skills matched:

```
## Recommended Skills (matched to prospect tech stack)

- **`java-instrumentation/skills/setup-springboot3x/SKILL.md`** — matches Spring Boot 3.4 application setup
  - Trigger: "Set up Spring Boot 3.x on CentOS 9 for the Datadog PoC"
- **`java-instrumentation/skills/springboot3x-dd-tracer/SKILL.md`** — matches Spring Boot 3.x Datadog APM instrumentation
  - Trigger: "Instrument Spring Boot 3.x with dd-java-agent"
```

When no skill matched, use this block instead:

```
## Recommended Skills

No skill in `{plugin}/skills/` matches the prospect's tech stack for this step. Falling back to the generic template `{plugin}/TODO-{plugin}.md`. If this combination recurs, run `/skill-creator:skill-creator` to add a matching skill.
```

**(b) Inline citation** at the start of each phase step that a skill covers:

```
### Phase 1: Provision the host
Use skill: `aws-ec2/skills/setup-ec2-centos9`
- Provision a CentOS Stream 9 EC2 instance in ap-southeast-1
- …
```

Keep the filled-in, prospect-specific details (versions, `jek-{resource}[-{qualifier}]-{dummy-name}` names per the **Resource Naming Convention**, infrastructure, upstream/downstream dependencies) in the phase steps. The matched skill guides execution; the `## Recommended Skills` block sits on top of the prospect-specific content, not instead of it.

### Example Output Structure

For a prospect with flow: React Frontend → Spring Boot API → PostgreSQL (dummy name: `greenfield`):

```
validation/backlog/greenfield-manifest.md                      # Execution run sheet
validation/backlog/greenfield-TODO-aws-ec2.md                  # 1. Provision EC2 for PostgreSQL
validation/backlog/greenfield-TODO-postgres-selfhosted.md      # 2. Install PostgreSQL, create tables, seed data, add DBM
validation/backlog/greenfield-TODO-aws-eks.md                  # 3. Provision EKS cluster
validation/backlog/greenfield-TODO-java-instrumentation.md     # 4. Deploy Spring Boot API, instrument with dd-trace-java
validation/backlog/greenfield-TODO-react-instrumentation.md    # 5. Deploy React frontend, instrument with Datadog RUM
```

### Manifest Format

The manifest should include:
- Dummy prospect name and date (never real prospect name)
- Transaction flow diagram (ASCII)
- Technical architecture diagram (ASCII)
- Tech stack summary table (component → language/framework → version)
- Resource name inventory: table of every `jek-` resource created for this PoC with its suffixed form (e.g., VPC → `jek-vpc-{dummy}`; EC2 → `jek-ec2-centos9-{dummy}`; Datadog service → `jek-spring-api-{dummy}`). Note length-limit abbreviations if any.
- Sequential execution table: step number, TODO file, plugin, matched skill(s) (or "generic template" if none matched), what it does, depends on
- Pre-flight checklist: what credentials/access is needed before starting (Datadog API key, cloud provider credentials, SSH keys, etc.)

## Rules

- **NEVER start generating validation TODOs without knowing the transaction flow sequence**
- **NEVER assume tech stack versions** — ask if not provided (unless user says "use latest")
- **ALWAYS build bottom-up** — foundation layer (infra + database) before application layer before frontend layer
- **ALWAYS name cloud resources and Datadog service/tags with the `jek-{resource-type}[-{qualifier}]-{dummy-name}` pattern** — both the `jek-` prefix and the `-{dummy-name}` suffix are mandatory for infrastructure resources (networking, compute, storage, queues, databases, Kubernetes objects) and Datadog names (service, env tag, resource tags). The suffix prevents collision between concurrent PoC runs on the same cloud account. Only the literal resource-name strings passed to cloud APIs get the `jek-…-{dummy}` treatment.
- **NEVER apply the `jek-` prefix OR the `-{dummy-name}` suffix to repo-level artifacts** — skill names (e.g., `setup-ec2-centos9`, `generate-tech-stack-validation-todos`, `springboot3x-dd-tracer`), plugin names (e.g., `aws-ec2`, `java-instrumentation`, `validation`), `SKILL.md` filenames, skill directory names, plugin directory names, skill `name:` frontmatter, skill trigger phrases, `TODO-{plugin}.md` template filenames, and Terraform file/module/variable names all stay exactly as written in the repo. Other un-suffixed exceptions (per-user, not per-PoC): SSH key `jek_rsa_pem` and Datadog API/APP keys.
- **ALWAYS prefer existing `{plugin}/skills/` skills over root-level `TODO-*.md` templates** — enumerate `{plugin}/skills/*/SKILL.md`, match the most specific skill against the prospect's tech stack, and cite that skill in the generated TODO (top-section `## Recommended Skills` + inline `Use skill:` line per phase).
- **FALL BACK to the root `{plugin}/TODO-{plugin}.md` template** only when no skill matches — prepend the no-match notice and suggest `/skill-creator:skill-creator`. The generated file should still be a filled-in, prospect-specific version, not invented from scratch.
- **NEVER read files inside `validation/backlog/` as a template source** — the backlog is write-only for this skill. When planning or generating new `*-TODO-*.md` and `*-manifest.md` files, do NOT read any existing `validation/backlog/*-TODO-*.md` or `validation/backlog/*-manifest.md`, whether from the current PoC run or past runs. Those files are ephemeral prospect-specific outputs; treating them as templates leaks one prospect's details into another's plan. Derive every generated file fresh from the Phase 1 inputs plus `{plugin}/skills/*/SKILL.md` (preferred) and `{plugin}/TODO-{plugin}.md` (fallback).
- **ALWAYS ask clarifying questions** before generating if any information is missing

## Security: Prospect Name Handling

- **ALWAYS use a dummy prospect name** for generated file names and resource prefixes — e.g., `helloworld`, `greenfield`. Generate a random one each time. Even if the user provides a real prospect name, replace it with a dummy name in ALL generated filenames and content.
- **NEVER commit generated output to git.** The `validation/backlog/` folder is already covered by the repo's `.gitignore`, which keeps prospect-specific output private by default. Do not override this — do not `git add -f` files in `validation/backlog/`, and do not write output anywhere outside `validation/backlog/`.
- **If the user provides file paths containing real prospect/company names**, read the files but do NOT echo the real company name into any generated output. Use the dummy name throughout.
- **Real prospect name may be kept only in the user's head or private notes** — never in files that could be committed to a public GitHub repo.
