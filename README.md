# datadog-agentic-plugins

A curated library of agentic plugins and skills for Claude that guide prospects and customers through setting up, instrumenting, and validating a Datadog proof of concept across any tech stack.

Each plugin represents a technology domain — an infrastructure platform, a programming language, a database engine, or a message queue. Each skill within a plugin is a focused, version-aware procedure that Claude can execute: provisioning a cluster, installing the Datadog Agent, instrumenting a Spring Boot app, enabling Database Monitoring, or validating that telemetry is flowing.

Prospects pick the plugins that match their stack. Claude reads the relevant skills, adapts to their specific versions, and walks them through setup step by step — from zero to traces, metrics, and logs in Datadog. Disclaimer: this marketplace is not endorsed by Datadog - the plugins are unofficial.


---

## Table of Contents

- [Who This Is For](#who-this-is-for)
- [How to use this marketplace and plugins with Claude Code](#how-to-use-this-marketplace-and-plugins-with-claude-code)
- [Architecture Overview](#architecture-overview)
- [Plugin Categories](#plugin-categories)
- [Full Repository Structure](#full-repository-structure)
- [How It Works: Composing a Stack](#how-it-works-composing-a-stack)
- [Naming Conventions](#naming-conventions)
- [Dependency Model](#dependency-model)
- [Skill Folder Anatomy](#skill-folder-anatomy)
- [Version Handling](#version-handling)
- [Contributing](#contributing)
  - [Adding a New Plugin](#adding-a-new-plugin)
  - [Adding a New Skill to an Existing Plugin](#adding-a-new-skill-to-an-existing-plugin)
  - [Writing Reference Variants](#writing-reference-variants)
  - [Writing Validation Scripts](#writing-validation-scripts)
  - [Building Sample App Assets](#building-sample-app-assets)
- [Design Principles](#design-principles)

---

## Who This Is For

**Prospects and customers** use this repository during a Datadog PoC. You select the plugins that match your infrastructure, languages, databases, and queues. Claude loads the relevant skills and guides you through setup, instrumentation, and validation — adapted to your exact versions and configuration.

**Datadog Solutions Engineers** contribute to this repository. You author and maintain the plugins, skills, reference variants, validation scripts, and sample applications. Each contribution makes the PoC experience faster and more reliable for the next prospect. See the [Contributing](#contributing) section for how to add or improve plugins and skills.

---

## How to use this marketplace and plugins with Claude Code

**Add the plugin:**


```bash
claude plugin marketplace add https://github.com/jek-bao-choo/datadog-agentic-plugins 
```

**Start Claude then add the plugin**

```bash
/plugin marketplace add https://github.com/jek-bao-choo/datadog-agentic-plugins

/plugin install quickstart@datadog-agentic-plugins

/reload-plugins

/quickstart:menu
```

---

## Architecture Overview

The repository is a Claude Code **marketplace** registered via `.claude-plugin/marketplace.json` at the repo root. Each plugin is a directory with its own `.claude-plugin/plugin.json` manifest (required by Claude Code) and a `PLUGIN.md` overview (a convention for this marketplace).

```
datadog-agentic-plugins/
  .claude-plugin/
    marketplace.json       # Marketplace registry — lists all available plugins
  {plugin-name}/
    .claude-plugin/
      plugin.json          # Required — Claude Code plugin manifest (JSON)
    PLUGIN.md              # Convention — plugin overview, category, dependencies, versions
    skills/                # Required — at least one skill
      skill-name/
        SKILL.md           # Entry point — version matrix, routing logic, core instructions
        references/        # Version-variant instruction docs Claude reads into context
        scripts/           # Validation and setup automation Claude executes
        assets/            # Deployable sample apps, schemas, config files the prospect runs
    commands/              # Optional — slash commands (.md files)
    hooks/                 # Optional — event-driven automation (hooks.json)
    agents/                # Optional — subagent definitions (.md files)
    .mcp.json              # Optional — MCP server integrations
```

A **plugin** represents a technology domain. It groups related skills and declares dependencies on other plugins. The `.claude-plugin/plugin.json` manifest is required for Claude Code to discover and load the plugin. The `PLUGIN.md` file is a supplementary convention specific to this marketplace — it provides category, dependency, and version information that Claude reads and interprets.

A **skill** is the atomic unit of work. It is a single, focused procedure — install the Datadog Agent, instrument a Flask app, enable DBM on PostgreSQL. Each skill is version-aware: it declares which version combinations it supports and routes to the correct instructions for the prospect's specific setup.

> **Convention note:** Fields like `version_matrix`, `routing`, and `requires` in SKILL.md and PLUGIN.md are **conventions that Claude interprets as structured instructions** — they are not programmatically enforced by Claude Code. Claude reads them and follows the logic (e.g., routing to the correct reference file based on versions), but the plugin system itself does not parse or validate these fields.

Plugins can also include **commands** (slash commands users invoke), **hooks** (event-driven automation like session-start messages), **agents** (autonomous subagent definitions), and **MCP servers** (external service integrations). See the [quickstart plugin](./quickstart/) for a working example that uses commands and hooks.

For the full conventions governing plugin.json, PLUGIN.md, SKILL.md, and all folder contents, see [MARKETPLACE.md](./MARKETPLACE.md).

---

## Plugin Categories

Every plugin belongs to one of five categories. The category determines its naming convention, its dependency rules, and its role in a PoC stack.

### 1. Infrastructure

Where the prospect's workloads run. This is always the foundation layer of any PoC stack.

| Plugin | Description |
|---|---|
| `aws-ec2` | Bare-metal / VM hosting on AWS EC2 |
| `aws-eks` | Managed Kubernetes on AWS EKS |
| `aws-lambda` | Serverless compute on AWS Lambda |
| `gcp-gke` | Managed Kubernetes on Google GKE |
| `kubernetes-onprem` | Self-managed vanilla Kubernetes in the prospect's data center |
| `openshift-onprem` | Red Hat OpenShift Container Platform on-premises |
| `rhel-onprem` | Bare-metal / VM on Red Hat Enterprise Linux on-premises |

**Dependency rule:** Infrastructure plugins have no `requires:` — they are the base layer.

### 2. Instrumentation

APM tracing for the prospect's application code. Each plugin covers one language ecosystem and offers skills for specific frameworks and tracer types.

| Plugin | Description |
|---|---|
| `java-instrumentation` | Java apps — Spring Boot, generic Java, DD tracer and OTel SDK |
| `python-instrumentation` | Python apps — Flask, FastAPI, Django, DD tracer and OTel SDK |
| `nodejs-instrumentation` | Node.js apps — Express, DD tracer and OTel SDK |

**Dependency rule:** Instrumentation plugins declare `requires:` listing the infrastructure plugins they can be composed with. The prospect must have at least one matching infrastructure plugin active.

### 3. Databases — Managed

Cloud-provider-managed database services where the provider handles the engine and the prospect only configures Datadog's integration.

| Plugin | Description |
|---|---|
| `aws-rds-postgres` | Amazon RDS for PostgreSQL |
| `aws-rds-mysql` | Amazon RDS for MySQL |

**Dependency rule:** Managed database plugins have no `requires:` — the cloud provider manages the host.

### 4. Databases — Self-hosted and Kubernetes-hosted

Database engines the prospect installs and manages themselves, either directly on a host or as containers in Kubernetes.

| Plugin | Hosting | Description |
|---|---|---|
| `postgres-selfhosted` | VM / bare-metal | PostgreSQL installed on any host |
| `mysql-selfhosted` | VM / bare-metal | MySQL installed on any host |
| `oracle-selfhosted` | VM / bare-metal | Oracle Database installed on any host |
| `postgres-k8s` | Kubernetes | PostgreSQL running as a K8s workload |
| `mysql-k8s` | Kubernetes | MySQL running as a K8s workload |

**Dependency rule:** Self-hosted database plugins declare `requires:` listing compatible infrastructure plugins (e.g., `aws-ec2`, `rhel-onprem`). Kubernetes-hosted database plugins declare `requires:` listing compatible K8s infrastructure plugins (e.g., `aws-eks`, `gcp-gke`, `kubernetes-onprem`, `openshift-onprem`).

### 5. Message Queues — Managed, Self-hosted, and Kubernetes-hosted

Same hosting model as databases, applied to message queue and streaming systems.

| Plugin | Hosting | Description |
|---|---|---|
| `aws-sqs` | Managed | Amazon Simple Queue Service |
| `aws-msk` | Managed | Amazon Managed Streaming for Apache Kafka |
| `kafka-selfhosted` | VM / bare-metal | Apache Kafka installed on any host |
| `kafka-k8s` | Kubernetes | Kafka on K8s (Strimzi, Confluent Operator) |
| `rabbitmq-selfhosted` | VM / bare-metal | RabbitMQ installed on any host |
| `rabbitmq-k8s` | Kubernetes | RabbitMQ on K8s (RabbitMQ Operator) |

**Dependency rule:** Same as databases — managed has no `requires:`, self-hosted requires a host-based infra plugin, K8s-hosted requires a K8s infra plugin.

---

## Full Repository Structure

```
datadog-agentic-plugins/
  .claude-plugin/
    marketplace.json               # Marketplace registry
  README.md
  MARKETPLACE.md

  # ──────────────────────────────────────────────
  # Quickstart (interactive onboarding)
  # ──────────────────────────────────────────────

  quickstart/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    commands/
      menu.md                      # /quickstart:menu — 26-option use case menu
    hooks/
      hooks.json                   # SessionStart hook
      session-start.sh
    skills/
      fetching-datadog-docs/
        SKILL.md

  # ──────────────────────────────────────────────
  # Infrastructure
  # ──────────────────────────────────────────────

  aws-ec2/
    .claude-plugin/
      plugin.json
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-ec2/
        SKILL.md
      install-dd-agent/
        SKILL.md
        references/
          ubuntu.md
          amazon-linux.md
        scripts/
          validate-agent.sh

  aws-eks/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-eks-cluster/
        SKILL.md
        references/
          k8s-1.27-1.28.md
          k8s-1.29-plus.md
      install-dd-operator/
        SKILL.md
        references/
          k8s-1.27-1.28.md
          k8s-1.29-plus.md
        scripts/
          validate-operator.sh
      install-dd-helm/
        SKILL.md
        references/
          k8s-1.27-1.28.md
          k8s-1.29-plus.md
        scripts/
          validate-helm.sh

  aws-lambda/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-lambda/
        SKILL.md
      install-dd-lambda-extension/
        SKILL.md
        references/
          python-runtime.md
          nodejs-runtime.md
          java-runtime.md
        scripts/
          validate-lambda-extension.sh

  gcp-gke/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-gke-cluster/
        SKILL.md
        references/
          k8s-1.27-1.28.md
          k8s-1.29-plus.md
      install-dd-operator/
        SKILL.md
        references/
          k8s-1.27-1.28.md
          k8s-1.29-plus.md
        scripts/
          validate-operator.sh
      install-dd-helm/
        SKILL.md
        references/
          k8s-1.27-1.28.md
          k8s-1.29-plus.md
        scripts/
          validate-helm.sh

  kubernetes-onprem/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-vanilla-k8s/
        SKILL.md
        references/
          k8s-1.26-1.28.md
          k8s-1.29-plus.md
      install-dd-operator/
        SKILL.md
        references/
          k8s-1.26-1.28.md
          k8s-1.29-plus.md
        scripts/
          validate-operator.sh
      install-dd-helm/
        SKILL.md
        references/
          k8s-1.26-1.28.md
          k8s-1.29-plus.md
        scripts/
          validate-helm.sh

  openshift-onprem/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-openshift/
        SKILL.md
        references/
          ocp-4.12-4.13.md
          ocp-4.14-plus.md
      install-dd-operator/
        SKILL.md
        references/
          ocp-4.12-4.13.md
          ocp-4.14-plus.md
        scripts/
          validate-operator.sh

  rhel-onprem/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-rhel/
        SKILL.md
        references/
          rhel-8.md
          rhel-9.md
      install-dd-agent/
        SKILL.md
        references/
          rhel-8.md
          rhel-9.md
        scripts/
          validate-agent.sh

  # ──────────────────────────────────────────────
  # Instrumentation
  # ──────────────────────────────────────────────

  java-instrumentation/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-springboot/
        SKILL.md
      springboot-dd-tracer/
        SKILL.md
        references/
          java8-sb2x.md
          java11-sb2x.md
          java17-sb3x.md
          java21-sb3x.md
        scripts/
          validate-traces.sh
        assets/
          springboot2x-dd-sample-app/
            src/
            pom.xml
            Dockerfile
            docker-compose.yml
            dd-java-agent-config.yml
          springboot3x-dd-sample-app/
            src/
            pom.xml
            Dockerfile
            docker-compose.yml
            dd-java-agent-config.yml
      springboot-otel-sdk/
        SKILL.md
        references/
          java11-sb2x.md
          java17-sb3x.md
          java21-sb3x.md
        scripts/
          validate-otel-traces.sh
        assets/
          springboot2x-otel-sample-app/
            src/
            pom.xml
            Dockerfile
            docker-compose.yml
            otel-config.yml
          springboot3x-otel-sample-app/
            src/
            pom.xml
            Dockerfile
            docker-compose.yml
            otel-config.yml
      generic-dd-tracer/
        SKILL.md
        references/
          java8.md
          java11.md
          java17-plus.md
        scripts/
          validate-traces.sh
        assets/
          generic-java-dd-sample-app/
            src/
            pom.xml
            Dockerfile
            docker-compose.yml
            dd-java-agent-config.yml
      generic-otel-sdk/
        SKILL.md
        references/
          java11.md
          java17-plus.md
        scripts/
          validate-otel-traces.sh
        assets/
          generic-java-otel-sample-app/
            src/
            pom.xml
            Dockerfile
            docker-compose.yml
            otel-config.yml

  python-instrumentation/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      flask-dd-tracer/
        SKILL.md
        references/
          python38-39.md
          python310-plus.md
          flask2x.md
          flask3x.md
        scripts/
          validate-traces.sh
        assets/
          flask2x-dd-sample-app/
            app.py
            requirements.txt
            Dockerfile
            docker-compose.yml
            ddtrace-config.py
          flask3x-dd-sample-app/
            app.py
            requirements.txt
            Dockerfile
            docker-compose.yml
            ddtrace-config.py
      fastapi-otel-sdk/
        SKILL.md
        references/
          python39-310.md
          python311-plus.md
        scripts/
          validate-otel-traces.sh
        assets/
          fastapi-otel-sample-app/
            main.py
            requirements.txt
            Dockerfile
            docker-compose.yml
            otel-config.py
      django-dd-tracer/
        SKILL.md
        references/
          python38-39-django4x.md
          python310-plus-django5x.md
        scripts/
          validate-traces.sh
        assets/
          django4x-dd-sample-app/
            manage.py
            myproject/
            requirements.txt
            Dockerfile
            docker-compose.yml
            ddtrace-config.py
          django5x-dd-sample-app/
            manage.py
            myproject/
            requirements.txt
            Dockerfile
            docker-compose.yml
            ddtrace-config.py

  nodejs-instrumentation/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      express-dd-tracer/
        SKILL.md
        references/
          node16-18-express4x.md
          node20-plus-express4x.md
          node20-plus-express5x.md
        scripts/
          validate-traces.sh
        assets/
          express4x-dd-sample-app/
            app.js
            package.json
            Dockerfile
            docker-compose.yml
            dd-trace-init.js
          express5x-dd-sample-app/
            app.js
            package.json
            Dockerfile
            docker-compose.yml
            dd-trace-init.js
      express-otel-sdk/
        SKILL.md
        references/
          node16-18.md
          node20-plus.md
        scripts/
          validate-otel-traces.sh
        assets/
          express-otel-sample-app/
            app.js
            package.json
            Dockerfile
            docker-compose.yml
            otel-init.js

  # ──────────────────────────────────────────────
  # Databases: Managed
  # ──────────────────────────────────────────────

  aws-rds-postgres/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-rds-postgres/
        SKILL.md
        references/
          pg-14.md
          pg-15.md
          pg-16.md
      install-dd-dbm/
        SKILL.md
        references/
          pg-14.md
          pg-15-plus.md
        scripts/
          validate-dbm.sh
        assets/
          pg-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  aws-rds-mysql/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-rds-mysql/
        SKILL.md
        references/
          mysql-8.0.md
          mysql-8.4.md
      install-dd-dbm/
        SKILL.md
        references/
          mysql-8.0.md
          mysql-8.4.md
        scripts/
          validate-dbm.sh
        assets/
          mysql-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  # ──────────────────────────────────────────────
  # Databases: Self-hosted
  # ──────────────────────────────────────────────

  postgres-selfhosted/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-postgres/
        SKILL.md
        references/
          pg-14.md
          pg-15.md
          pg-16.md
      install-dd-dbm/
        SKILL.md
        references/
          pg-14.md
          pg-15-plus.md
        scripts/
          validate-dbm.sh
        assets/
          pg-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  mysql-selfhosted/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-mysql/
        SKILL.md
        references/
          mysql-8.0.md
          mysql-8.4.md
      install-dd-dbm/
        SKILL.md
        references/
          mysql-8.0.md
          mysql-8.4.md
        scripts/
          validate-dbm.sh
        assets/
          mysql-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  oracle-selfhosted/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-oracle/
        SKILL.md
        references/
          oracle-12c.md
          oracle-19c.md
          oracle-21c.md
          oracle-23ai.md
      install-dd-dbm/
        SKILL.md
        references/
          oracle-12c.md
          oracle-19c.md
          oracle-21c-plus.md
        scripts/
          validate-dbm.sh
        assets/
          oracle-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  # ──────────────────────────────────────────────
  # Databases: Kubernetes-hosted
  # ──────────────────────────────────────────────

  postgres-k8s/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-postgres-k8s/
        SKILL.md
        references/
          pg-operator.md
          pg-helm.md
      install-dd-dbm/
        SKILL.md
        scripts/
          validate-dbm.sh
        assets/
          pg-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  mysql-k8s/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-mysql-k8s/
        SKILL.md
        references/
          mysql-operator.md
          mysql-helm.md
      install-dd-dbm/
        SKILL.md
        scripts/
          validate-dbm.sh
        assets/
          mysql-sample-workload/
            generate-queries.py
            requirements.txt
            sample-schema.sql

  # ──────────────────────────────────────────────
  # Message Queues: Managed
  # ──────────────────────────────────────────────

  aws-sqs/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-sqs/
        SKILL.md
      install-dd-integration/
        SKILL.md
        scripts/
          validate-sqs-integration.sh

  aws-msk/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-msk/
        SKILL.md
        references/
          kafka-3.5.md
          kafka-3.6.md
      install-dd-integration/
        SKILL.md
        references/
          kafka-3.5.md
          kafka-3.6.md
        scripts/
          validate-kafka-integration.sh
        assets/
          kafka-sample-producer-consumer/
            producer.py
            consumer.py
            requirements.txt
            docker-compose.yml

  # ──────────────────────────────────────────────
  # Message Queues: Self-hosted
  # ──────────────────────────────────────────────

  kafka-selfhosted/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-kafka/
        SKILL.md
        references/
          kafka-3.5.md
          kafka-3.6.md
          kafka-3.7.md
      install-dd-integration/
        SKILL.md
        references/
          kafka-3.5.md
          kafka-3.6-plus.md
        scripts/
          validate-kafka-integration.sh
        assets/
          kafka-sample-producer-consumer/
            producer.py
            consumer.py
            requirements.txt
            docker-compose.yml

  rabbitmq-selfhosted/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-rabbitmq/
        SKILL.md
        references/
          rabbitmq-3.12.md
          rabbitmq-3.13.md
      install-dd-integration/
        SKILL.md
        references/
          rabbitmq-3.12.md
          rabbitmq-3.13.md
        scripts/
          validate-rabbitmq-integration.sh
        assets/
          rabbitmq-sample-producer-consumer/
            producer.py
            consumer.py
            requirements.txt
            docker-compose.yml

  # ──────────────────────────────────────────────
  # Message Queues: Kubernetes-hosted
  # ──────────────────────────────────────────────

  kafka-k8s/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-kafka-k8s/
        SKILL.md
        references/
          strimzi-operator.md
          confluent-operator.md
      install-dd-integration/
        SKILL.md
        scripts/
          validate-kafka-integration.sh
        assets/
          kafka-sample-producer-consumer/
            producer.py
            consumer.py
            requirements.txt
            docker-compose.yml

  rabbitmq-k8s/
    .claude-plugin/
      plugin.json
    PLUGIN.md
    skills/
      setup-rabbitmq-k8s/
        SKILL.md
        references/
          rabbitmq-operator.md
      install-dd-integration/
        SKILL.md
        scripts/
          validate-rabbitmq-integration.sh
        assets/
          rabbitmq-sample-producer-consumer/
            producer.py
            consumer.py
            requirements.txt
            docker-compose.yml
```

---

## How It Works: Composing a Stack

A Datadog PoC stack is built by composing plugins from different categories. The minimum viable stack is one infrastructure plugin. A typical stack adds instrumentation, a database, and possibly a queue on top of that.

**Example: E-commerce app on EKS with Java, PostgreSQL, and Kafka**

```
Infrastructure:    aws-eks           (EKS 1.29, DD Helm chart)
Instrumentation:   java-instrumentation   (Spring Boot 3.2, Java 17, DD tracer latest)
Database:          aws-rds-postgres       (PostgreSQL 16, DBM enabled)
Message Queue:     kafka-k8s             (Strimzi operator, DD integration)
```

Claude reads the PLUGIN.md for each selected plugin, loads the relevant SKILL.md files, selects the correct reference variant for the prospect's versions, and walks through each skill in order: set up infra first, install the Datadog Agent or operator, instrument the application, configure database monitoring, set up the queue integration, then validate everything end to end.

**Example: Legacy on-prem stack with Python and Oracle**

```
Infrastructure:    rhel-onprem            (RHEL 9.3, DD Agent RPM)
Instrumentation:   python-instrumentation (Django 4.2, Python 3.10, DD tracer)
Database:          oracle-selfhosted      (Oracle 19c, DBM enabled)
```

The prospect's private STACK.yaml (maintained outside this repository) records these selections and version pins. This repository provides the instructions; the prospect provides the configuration.

---

## Naming Conventions

Consistent naming is critical. Every plugin and skill name must be unambiguous, scannable, and self-documenting.

### Plugin Names

Plugin names follow the pattern `{technology}-{context}` where context indicates either the hosting model or the ecosystem.

**Infrastructure plugins** use the cloud provider's service name or `{platform}-onprem`:

| Pattern | Example | When to use |
|---|---|---|
| `{provider}-{service}` | `aws-eks`, `gcp-gke` | Cloud-managed infrastructure |
| `{platform}-onprem` | `kubernetes-onprem`, `rhel-onprem` | Self-managed infrastructure in the prospect's own data center |

The `-onprem` suffix specifically means "not managed by a cloud provider." It is accurate for data center deployments. Do not use `-onprem` when the hosting model is ambiguous — for example, vanilla Kubernetes running on EC2 instances can use the `kubernetes-onprem` plugin because the K8s cluster itself is self-managed regardless of where the nodes live.

**Instrumentation plugins** use `{language}-instrumentation`:

| Pattern | Example |
|---|---|
| `{language}-instrumentation` | `java-instrumentation`, `python-instrumentation` |

**Database and message queue plugins** use `{engine}-{hosting}`:

| Pattern | Example | When to use |
|---|---|---|
| `{provider}-{service}-{engine}` | `aws-rds-postgres`, `aws-msk` | Cloud-managed service — the provider handles the engine |
| `{engine}-selfhosted` | `mysql-selfhosted`, `kafka-selfhosted` | Prospect installed the engine on any host (EC2, RHEL, GCP VM, etc.) |
| `{engine}-k8s` | `postgres-k8s`, `rabbitmq-k8s` | Engine running as a containerized workload in Kubernetes |

The `-selfhosted` suffix means "the prospect installed and manages this engine." It is hosting-agnostic — MySQL on an EC2 instance is `-selfhosted`, not `-onprem`, because the instructions are the same regardless of whether the host is a cloud VM or a bare-metal server. The infrastructure plugin's `requires:` field handles the host-level differences.

The `-k8s` suffix means "running as a container inside a Kubernetes cluster." This implies a different deployment model (operators, Helm charts, StatefulSets) and different Datadog integration patterns than self-hosted.

### Skill Names

Skill names follow the pattern `{action}-{target}` or `{framework}-{tracer-type}`:

| Category | Pattern | Examples |
|---|---|---|
| Infrastructure setup | `setup-{platform}` | `setup-ec2`, `setup-eks-cluster`, `setup-openshift` |
| Agent installation | `install-dd-{method}` | `install-dd-agent`, `install-dd-operator`, `install-dd-helm` |
| Serverless | `install-dd-lambda-extension` | — |
| Instrumentation | `{framework}-{tracer}` | `springboot-dd-tracer`, `flask-dd-tracer`, `express-otel-sdk` |
| Generic instrumentation | `generic-{tracer}` | `generic-dd-tracer`, `generic-otel-sdk` |
| Database monitoring | `install-dd-dbm` | — |
| Integration | `install-dd-integration` | — |

### Reference File Names

Reference files are named by the version axes that cause the instructions to diverge:

| Pattern | Examples | When to use |
|---|---|---|
| `{version-range}.md` | `k8s-1.27-1.28.md`, `rhel-9.md` | Single version axis |
| `{axis1}-{axis2}.md` | `java17-sb3x.md`, `node20-plus-express5x.md` | Two axes that interact |
| `{platform}.md` | `ubuntu.md`, `amazon-linux.md` | Platform-specific variants |
| `{deployment-method}.md` | `pg-operator.md`, `strimzi-operator.md` | K8s deployment variants |

Use `-plus` to indicate "this version and all later versions" (e.g., `k8s-1.29-plus.md`). Use `x` as a wildcard for minor versions (e.g., `sb3x` means any Spring Boot 3.x).

### Asset Directory Names

Assets follow `{framework}{version}-{tracer-type}-sample-app/` for instrumentation and `{engine}-sample-workload/` or `{engine}-sample-producer-consumer/` for databases and queues:

| Category | Pattern | Examples |
|---|---|---|
| Instrumentation | `{framework}{version}-{tracer}-sample-app/` | `flask3x-dd-sample-app/`, `springboot2x-otel-sample-app/` |
| Database workload | `{engine}-sample-workload/` | `pg-sample-workload/`, `mysql-sample-workload/` |
| Queue workload | `{engine}-sample-producer-consumer/` | `kafka-sample-producer-consumer/` |

---

## Dependency Model

Dependencies are declared in each plugin's PLUGIN.md using the `requires:` field. The rules are straightforward:

```
Infrastructure plugins          → no requires (they are the base layer)
Managed database/queue plugins  → no requires (cloud provider manages the host)
Self-hosted database/queue      → requires: [list of host-based infra plugins]
K8s-hosted database/queue       → requires: [list of K8s infra plugins]
Instrumentation plugins         → requires: [list of infra plugins]
```

A valid PoC stack always satisfies all `requires:` constraints. If a prospect selects `java-instrumentation` and `mysql-selfhosted`, both must have at least one overlapping infrastructure plugin in their `requires:` lists.

Dependencies are **one-directional** — instrumentation and data services depend on infrastructure, never the reverse. There are no cross-dependencies between instrumentation and database/queue plugins; they are independent branches that both root at infrastructure.

### Why Skills Are Duplicated, Not Shared

Skills like `install-dd-operator` appear in multiple plugins (`aws-eks`, `gcp-gke`, `kubernetes-onprem`, `openshift-onprem`). These are intentionally separate copies, not symlinks or shared references. The reasons:

1. **Real differences exist.** The Datadog Operator on OpenShift requires specific SecurityContextConstraints that don't apply to vanilla K8s. EKS has IAM-specific considerations. Each copy can diverge without affecting the others.

2. **Independent testability.** Each plugin is a self-contained unit. You can test `openshift-onprem/skills/install-dd-operator/` in isolation without worrying about changes to `aws-eks/skills/install-dd-operator/`.

3. **No hidden coupling.** A shared skill creates an implicit contract — changing it for one platform might break another. Duplication makes the cost of divergence zero.

4. **Simpler contribution model.** A contributor improving the EKS operator installation doesn't need to audit whether their change works on OpenShift. Each plugin is owned independently.

When a cross-cutting improvement applies to all copies (e.g., a new Datadog Operator version), contributors should update each copy individually and verify it works in that plugin's context.

---

## Skill Folder Anatomy

Every skill folder follows the same structure. Only SKILL.md is required; the subdirectories are optional depending on the skill's complexity.

```
skill-name/
  SKILL.md           # Required — entry point
  references/        # Optional — version-variant instruction docs
  scripts/           # Optional — executable validation and setup automation
  assets/            # Optional — deployable sample apps, schemas, config files
```

### SKILL.md

The entry point Claude reads when the skill is triggered. It contains:

- **YAML frontmatter** declaring the skill's name, description, and version matrix
- **Routing logic** mapping version combinations to reference files
- **Prerequisites** — what must already be true before this skill runs
- **Core instructions** — the main procedure (or pointers to reference variants)
- **Validation** — how to confirm the skill succeeded
- **Troubleshooting** — common failure modes and fixes

SKILL.md should stay under 500 lines. If a skill needs more, move version-specific instructions into `references/` and keep SKILL.md as the router.

### references/

Markdown files that Claude reads into context based on the prospect's version selections. Each file is a self-contained instruction set for a specific version combination. Claude reads only the relevant file, keeping context focused.

Split reference files along the axes that cause **genuine instruction divergence** — different CLI flags, different APIs, different config formats, different namespaces. Do not split on axes where only a version string changes; those are substitution variables handled in the reference file itself.

### scripts/

Executable scripts (usually shell) that Claude runs to validate or automate steps. The most common pattern is a validation script that checks whether the skill succeeded — for example, verifying the Datadog Agent is reporting, traces are flowing, or DBM queries are visible.

Scripts should be idempotent and safe to run multiple times. They should output clear pass/fail results.

### assets/

Files that get deployed to the prospect's environment. These are not read by Claude for instructions — they are the deliverables. Common examples:

- **Sample applications** — pre-instrumented apps the prospect runs to generate telemetry
- **Schema files** — SQL scripts that create tables and seed data for DBM validation
- **Workload generators** — scripts that produce realistic traffic patterns
- **Config templates** — Datadog, OTel, or framework configuration files

Every sample app should include a `Dockerfile` and `docker-compose.yml` so the prospect can run it with a single command.

---

## Version Handling

Versions are handled through a three-layer system: the **version matrix** in SKILL.md declares what's supported, the **routing logic** selects the right reference file, and **substitution variables** within reference files handle minor version differences.

### Layer 1: Version Matrix

Declared in SKILL.md frontmatter. Lists every supported version for each axis.

```yaml
version_matrix:
  java_version: [8, 11, 17, 21]
  springboot_version: [2.7, 3.0, 3.1, 3.2, 3.3]
  dd_tracer_version: [1.28, 1.29, 1.30, 1.31, latest]
```

### Layer 2: Routing Logic

Maps version combinations to reference files. Only the axes that cause instruction divergence appear in the routing rules.

```yaml
routing:
  - match: { java_version: 8, springboot_version: "2.*" }
    variant: references/java8-sb2x.md
  - match: { java_version: 11, springboot_version: "2.*" }
    variant: references/java11-sb2x.md
  - match: { java_version: [17, 21], springboot_version: "3.*" }
    variant: references/java17-sb3x.md
  - match: { java_version: 21, springboot_version: "3.*" }
    variant: references/java21-sb3x.md
```

### Layer 3: Substitution Variables

Within a reference file, minor versions and tracer versions that don't change the procedure are handled as variables. The reference file uses placeholders like `{{dd_tracer_version}}` or documents the version string inline, and Claude substitutes the prospect's specific value.

This three-layer approach keeps the number of reference files manageable. A skill with 4 Java versions × 5 Spring Boot versions × 6 tracer versions (120 combinations) might only need 4 reference files because the tracer version and minor Spring Boot version are substitution variables that don't change the procedure.

---

## Contributing

This repository is maintained by Datadog Solutions Engineers. Every contribution — a new plugin, a new skill, an improved reference variant, a better validation script, a more realistic sample app — makes the PoC experience better for the next prospect.

### Adding a New Plugin

1. **Determine the category.** Is it infrastructure, instrumentation, a managed database/queue, a self-hosted database/queue, or a K8s-hosted database/queue? The category determines the naming convention and dependency model.

2. **Name the plugin** following the conventions in [Naming Conventions](#naming-conventions). If you're unsure, check existing plugins in the same category for precedent.

3. **Create the folder structure:**

```
{plugin-name}/
  .claude-plugin/
    plugin.json          # Required by Claude Code
  PLUGIN.md              # Marketplace convention
  skills/
```

4. **Write `plugin.json`** — the Claude Code manifest:
   ```json
   {
     "name": "{plugin-name}",
     "version": "0.1.0",
     "description": "What this plugin does"
   }
   ```

5. **Write PLUGIN.md** with the following sections:
   - **Frontmatter**: name, description, category
   - **requires**: list of compatible infrastructure plugins (empty for infra and managed plugins)
   - **Skills overview**: brief description of each skill the plugin offers
   - **Supported versions**: summary of the version ranges covered

6. **Register in `marketplace.json`** — add an entry to `.claude-plugin/marketplace.json` at the repo root.

7. **Add at least one skill** before submitting. A plugin with no skills is not useful.

8. **Test the plugin end to end.** Compose it with at least one compatible infrastructure plugin and verify the full flow works.

### Adding a New Skill to an Existing Plugin

1. **Create the skill folder** under the plugin's `skills/` directory:

```
{plugin-name}/skills/{skill-name}/
  SKILL.md
```

2. **Write SKILL.md** following the standard skeleton:
   - Frontmatter with name, description, version matrix
   - Routing logic (if using reference variants)
   - Prerequisites
   - Steps (core instructions or pointers to reference files)
   - Validation
   - Troubleshooting

3. **Determine if you need reference variants.** If the instructions differ meaningfully across versions, create `references/` with one file per divergent combination. If the instructions are the same across all versions with only version strings changing, keep everything in SKILL.md.

4. **Add a validation script** in `scripts/` if the skill produces observable results (agent running, traces flowing, DBM active). Validation scripts should be idempotent and output clear pass/fail.

5. **Add sample app assets** in `assets/` if the skill involves instrumentation or workload generation. Every sample app must include a Dockerfile and docker-compose.yml.

### Writing Reference Variants

- Split on axes that change the **procedure**, not just a version string.
- Each reference file must be self-contained — a reader should be able to follow it without jumping back to SKILL.md for instructions.
- Use substitution variables (e.g., `{{dd_tracer_version}}`) for version strings that don't affect the procedure.
- Keep each reference file under 300 lines. If it's longer, the split axis may be too broad.
- Include a brief header stating which version combination the file covers.

### Writing Validation Scripts

- Scripts must be idempotent — safe to run multiple times without side effects.
- Output clear, human-readable pass/fail results.
- Check for the specific observable outcome: agent heartbeat, traces in APM, metrics in dashboards, DBM queries visible.
- Include a timeout — don't wait forever for telemetry to appear.
- Exit with code 0 on success, non-zero on failure.

### Building Sample App Assets

- Every sample app must include `Dockerfile` and `docker-compose.yml`.
- The app should generate realistic telemetry — multiple endpoints, database queries, queue operations — not just a "hello world."
- Include comments in the code pointing to which Datadog features each part exercises (traces, custom metrics, logs, etc.).
- Pin dependency versions in `requirements.txt`, `pom.xml`, or `package.json`. Don't use floating ranges.
- Include a README.md inside the sample app directory explaining how to run it and what telemetry to expect in Datadog.

---

## Design Principles

These principles explain why the repository is structured the way it is. Follow them when making contribution decisions.

### 1. Plugins are self-contained

Every plugin is a standalone unit. It contains everything needed to understand and execute its skills, with no implicit dependencies on files outside its directory (except the infrastructure plugins declared in `requires:`). This means you can clone a single plugin, read its PLUGIN.md, and know exactly what it does and what it needs.

### 2. Skills are the atomic unit of work

A skill does one thing well. `install-dd-agent` installs the agent. `springboot-dd-tracer` instruments a Spring Boot app. Skills never combine multiple unrelated procedures — that's the job of stack composition. This keeps skills independently testable and reusable across different prospect configurations.

### 3. Duplication over hidden coupling

When two plugins need similar-but-different skills (e.g., Datadog Operator on EKS vs OpenShift), the skills are duplicated, not shared. Duplication costs a little disk space. Hidden coupling costs debugging time when a change to one platform breaks another. Duplication wins.

### 4. Split on divergence, not on enumeration

Reference files exist because real instructions differ across version combinations. Don't create a reference file for every possible version — create one for every meaningfully different procedure. "Different JVM flags" is a real divergence. "Different tracer version string in a download URL" is a substitution variable, not a divergence.

### 5. Three folders, three roles

`references/` is what Claude reads. `scripts/` is what Claude runs. `assets/` is what the prospect deploys. Never mix these roles — a sample app is an asset, not a reference; a validation check is a script, not an asset.

### 6. The prospect brings the configuration, the marketplace brings the instructions

This repository contains no customer-specific data — no account names, no API keys, no environment details. It is a public template library. Prospect-specific configuration (which plugins, which versions, which environment variables) is maintained privately outside this repository.

### 7. Version awareness is a first-class concern

Every skill explicitly declares which versions it supports and how version differences affect the procedure. No skill should ever contain instructions that silently assume a specific version. If a version matters, it appears in the version matrix and routing logic.

### 8. Validate everything

Every skill that produces an observable outcome should include a validation step. The prospect should never have to guess whether a step worked. Validation scripts and manual verification steps are how we prove telemetry is flowing — which is the entire point of a PoC.

