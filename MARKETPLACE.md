# MARKETPLACE.md — Contributor Conventions & Specifications

This document is the authoritative reference for anyone authoring or maintaining plugins and skills in the `datadog-agentic-plugins` repository. It defines the exact schemas for `plugin.json`, `marketplace.json`, `PLUGIN.md`, `SKILL.md`, commands, hooks, and all other file types, plus the step-by-step process for contributing new content.

The [README.md](./README.md) explains what this repository is, who it's for, and why it's structured this way. This document explains **how** to build within it.

---

## Table of Contents

- [Repository Layout](#repository-layout)
- [Marketplace Registry Specification](#marketplace-registry-specification)
- [plugin.json Specification](#pluginjson-specification)
- [PLUGIN.md Specification](#pluginmd-specification)
  - [Frontmatter Schema](#plugin-frontmatter-schema)
  - [Body Structure](#plugin-body-structure)
  - [Complete PLUGIN.md Template](#complete-pluginmd-template)
  - [PLUGIN.md Examples](#pluginmd-examples)
- [Command Specification](#command-specification)
- [Hook Specification](#hook-specification)
- [SKILL.md Specification](#skillmd-specification)
  - [Frontmatter Schema](#skill-frontmatter-schema)
  - [Body Structure](#skill-body-structure)
  - [Complete SKILL.md Template](#complete-skillmd-template)
  - [SKILL.md Examples](#skillmd-examples)
- [Reference Files Specification](#reference-files-specification)
  - [When to Create a Reference File](#when-to-create-a-reference-file)
  - [Reference File Template](#reference-file-template)
  - [Substitution Variables](#substitution-variables)
- [Scripts Specification](#scripts-specification)
  - [Validation Script Template](#validation-script-template)
  - [Setup Script Guidelines](#setup-script-guidelines)
- [Assets Specification](#assets-specification)
  - [Sample App Requirements](#sample-app-requirements)
  - [Database Workload Requirements](#database-workload-requirements)
  - [Queue Workload Requirements](#queue-workload-requirements)
- [Naming Rules — Quick Reference](#naming-rules--quick-reference)
- [Dependency Rules — Quick Reference](#dependency-rules--quick-reference)
- [Version Matrix Design Guide](#version-matrix-design-guide)
- [Contribution Workflow](#contribution-workflow)
  - [Step-by-Step: New Plugin](#step-by-step-new-plugin)
  - [Step-by-Step: New Skill](#step-by-step-new-skill)
  - [Step-by-Step: New Reference Variant](#step-by-step-new-reference-variant)
  - [Pull Request Checklist](#pull-request-checklist)
- [Quality Standards](#quality-standards)
- [Common Mistakes to Avoid](#common-mistakes-to-avoid)

---

## Repository Layout

```
datadog-agentic-plugins/
  .claude-plugin/
    marketplace.json               # Marketplace registry — required
  README.md                        # Public-facing overview (do not put conventions here)
  MARKETPLACE.md                   # This file — conventions and specifications
  {plugin-name}/                   # One directory per plugin at the repo root
    .claude-plugin/
      plugin.json                  # Claude Code plugin manifest — required
    PLUGIN.md                      # Plugin overview (category, deps, versions) — required
    skills/                        # All skills live under this directory
      {skill-name}/                # One directory per skill
        SKILL.md                   # Skill entry point — required
        references/                # Version-variant instruction docs — optional
          {variant-name}.md
        scripts/                   # Executable automation — optional
          {script-name}.sh
        assets/                    # Deployable files for the prospect — optional
          {asset-dir}/
            ...
    commands/                      # Slash commands — optional
      {command-name}.md
    hooks/                         # Event-driven automation — optional
      hooks.json
      {hook-script}.sh
    agents/                        # Subagent definitions — optional
      {agent-name}.md
    .mcp.json                      # MCP server integrations — optional
```

Every plugin sits at the repository root. There are no grouping subdirectories for categories — the naming convention itself makes the category clear.

---

## Marketplace Registry Specification

The root `.claude-plugin/marketplace.json` registers all available plugins in this marketplace. Claude Code reads this file to discover which plugins can be installed.

```json
{
  "name": "datadog-agentic-plugins",
  "owner": {
    "name": "Maintainer Name"
  },
  "metadata": {
    "description": "Description of the marketplace"
  },
  "plugins": [
    {
      "name": "{plugin-name}",
      "source": "./{plugin-name}",
      "description": "Brief description",
      "version": "0.1.0"
    }
  ]
}
```

**Field rules:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | Yes | string | Marketplace identifier |
| `owner.name` | Yes | string | Marketplace maintainer |
| `metadata.description` | Yes | string | Brief description of the marketplace |
| `plugins[].name` | Yes | string | Must match the plugin's directory name exactly |
| `plugins[].source` | Yes | string | Relative path to the plugin directory (`./{plugin-name}`) |
| `plugins[].description` | Yes | string | Brief description of the plugin |
| `plugins[].version` | Yes | string | Semver version string |

**Every new plugin must be added to this file.** A plugin directory that exists but is not registered in `marketplace.json` will not be discoverable by Claude Code.

---

## plugin.json Specification

Every plugin must have a `.claude-plugin/plugin.json` at its root. This is the Claude Code manifest — **required for Claude Code to discover and load the plugin**.

```json
{
  "name": "{plugin-name}",
  "version": "0.1.0",
  "description": "What this plugin does — written for the prospect, not the contributor",
  "author": {
    "name": "Author Name"
  }
}
```

**Field rules:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | Yes | string | Must exactly match the plugin's directory name. Use kebab-case. |
| `version` | Yes | string | Semver version string (e.g., `0.1.0`, `1.0.0`) |
| `description` | Yes | string | 1–3 sentences. Should answer "what does this plugin help me do?" |
| `author.name` | No | string | Name of the plugin author or team |

> **Important:** `plugin.json` is what Claude Code uses for plugin discovery and loading. `PLUGIN.md` (described next) is a supplementary convention specific to this marketplace that provides category, dependency, and version matrix information. Both files are required for plugins in this repository.

---

## PLUGIN.md Specification

Every plugin must have a PLUGIN.md at its root alongside its `.claude-plugin/plugin.json`. While `plugin.json` is the Claude Code manifest for discovery and loading, PLUGIN.md is a **marketplace convention** that provides richer metadata: category, dependencies, version support, and a structured overview that Claude reads when guiding a prospect.

> **Convention note:** The `category`, `requires`, and `supported_versions` fields in PLUGIN.md are **conventions that Claude interprets as structured instructions** — they are not programmatically enforced by Claude Code. The `requires` field is advisory: Claude reads it and can warn the user if a dependency is missing, but the plugin system does not enforce dependencies at installation time.

### Plugin Frontmatter Schema

```yaml
---
name: {plugin-name}                   # Must match the directory name exactly
description: >
  One to three sentences describing what this plugin covers
  and when a prospect would use it.
category: {onboarding | infrastructure | instrumentation | database-managed | database-selfhosted | database-k8s | queue-managed | queue-selfhosted | queue-k8s}
requires: []                          # List of compatible infra plugin names, or empty
supported_versions:                   # Summary of version coverage
  {axis_name}: [{values}]
---
```

**Field rules:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | Yes | string | Must exactly match the plugin's directory name |
| `description` | Yes | string | 1–3 sentences. Written for the prospect, not the contributor. Should answer "what does this plugin help me do?" |
| `category` | Yes | enum | One of: `onboarding`, `infrastructure`, `instrumentation`, `database-managed`, `database-selfhosted`, `database-k8s`, `queue-managed`, `queue-selfhosted`, `queue-k8s` |
| `requires` | Yes | list | Empty `[]` for infrastructure and managed plugins. Lists compatible infra plugin names for all others. |
| `supported_versions` | Yes | map | Top-level version axes this plugin covers. Individual skills may cover subsets. |

### Plugin Body Structure

After the frontmatter, the PLUGIN.md body contains these sections in order:

```markdown
## Overview

Expanded description of the plugin's scope, the Datadog features it enables,
and any important context about the technology.

## Prerequisites

What the prospect needs before using this plugin:
- Access credentials, accounts, permissions
- Software already installed
- Network or firewall requirements

## Skills

### {skill-name}
Brief description of what this skill does and when to use it.

### {skill-name}
Brief description of what this skill does and when to use it.

## Recommended Skill Order

The order in which skills should typically be executed:
1. {setup skill}
2. {agent/operator installation skill}

## Compatibility Notes

Any known limitations, unsupported combinations, or version-specific
caveats that apply at the plugin level (not at the individual skill level).
```

### Complete PLUGIN.md Template

```markdown
---
name: {plugin-name}
description: >
  {1-3 sentence description for the prospect}
category: {category}
requires: [{list of infra plugin names, or empty}]
supported_versions:
  {axis}: [{values}]
---

## Overview

{2-4 paragraphs expanding on what this plugin covers, which Datadog products
it enables (APM, DBM, Infrastructure Monitoring, etc.), and the prospect's
typical use case.}

## Prerequisites

{Bulleted list of what must be true before using this plugin.}

## Skills

### {skill-name}
{1-2 sentences on what this skill does.}

### {skill-name}
{1-2 sentences on what this skill does.}

## Recommended Skill Order

1. {first skill — usually setup}
2. {second skill — usually agent/operator install}
3. {third skill — if applicable}

## Compatibility Notes

{Any known limitations, caveats, or unsupported version combinations
at the plugin level. Leave empty if none.}
```

### PLUGIN.md Examples

**Infrastructure plugin (no dependencies):**

```yaml
---
name: aws-eks
description: >
  Set up and instrument a Datadog-monitored environment on Amazon Elastic
  Kubernetes Service. Covers EKS cluster provisioning, Datadog Operator
  installation, and Helm-based DaemonSet deployment.
category: infrastructure
requires: []
supported_versions:
  k8s_version: [1.27, 1.28, 1.29, 1.30, 1.31]
---
```

**Instrumentation plugin (depends on infra):**

```yaml
---
name: java-instrumentation
description: >
  Instrument Java applications with Datadog APM or OpenTelemetry. Supports
  Spring Boot and generic Java apps with both DD tracer and OTel SDK options.
category: instrumentation
requires: [aws-ec2, aws-eks, aws-lambda, gcp-gke, kubernetes-onprem, openshift-onprem, rhel-onprem]
supported_versions:
  java_version: [8, 11, 17, 21]
  springboot_version: [2.7, 3.0, 3.1, 3.2, 3.3]
  dd_tracer_version: [1.28, 1.29, 1.30, 1.31, latest]
  otel_version: [1.32, 1.33, 1.34, latest]
---
```

**Self-hosted database plugin (depends on infra):**

```yaml
---
name: oracle-selfhosted
description: >
  Configure Datadog Database Monitoring for self-hosted Oracle Database
  instances. Covers Oracle setup, user permissions, and DBM integration.
category: database-selfhosted
requires: [aws-ec2, rhel-onprem]
supported_versions:
  oracle_version: [12c, 19c, 21c, 23ai]
---
```

**Managed queue plugin (no dependencies):**

```yaml
---
name: aws-msk
description: >
  Configure Datadog integration for Amazon Managed Streaming for Apache
  Kafka. Covers MSK cluster setup and Kafka metric/log collection.
category: queue-managed
requires: []
supported_versions:
  kafka_version: [3.5, 3.6]
---
```

---

## Command Specification

Commands are optional. They live as markdown files in the `commands/` directory and provide slash commands users invoke as `/{plugin-name}:{command-name}`.

### Command Frontmatter

```yaml
---
description: >-
  When to trigger this command. Include specific trigger phrases
  so Claude can match user intent.
argument-hint: "[optional argument description]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - WebFetch
  - WebSearch
  - Glob
  - Grep
---
```

| Field | Required | Type | Notes |
|---|---|---|---|
| `description` | Yes | string | Trigger description — include phrases users might say |
| `argument-hint` | No | string | Describes optional arguments the user can pass |
| `allowed-tools` | No | list | Tools the command is allowed to use |

### Command Body

After the frontmatter, the body contains the full instructions Claude follows when the command is invoked. The body should be self-contained — Claude reads it as a complete prompt. See `quickstart/commands/menu.md` for a working example.

---

## Hook Specification

Hooks are optional. They provide event-driven automation and are defined in `hooks/hooks.json`.

### hooks.json Schema

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

| Field | Required | Type | Notes |
|---|---|---|---|
| `hooks` | Yes | object | Top-level container |
| `{EventType}` | Yes | string | Event to hook into (e.g., `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`) |
| `matcher` | Yes | string | Pattern to match — `*` matches all |
| `hooks[].type` | Yes | string | Hook type — typically `command` |
| `hooks[].command` | Yes | string | Shell command to execute. Use `${CLAUDE_PLUGIN_ROOT}` for portable paths. |
| `hooks[].timeout` | No | number | Timeout in seconds |

### Hook Script Guidelines

1. Scripts must output valid JSON to communicate with Claude
2. Use `${CLAUDE_PLUGIN_ROOT}` to reference files relative to the plugin root — never hardcode paths
3. Keep scripts fast — they run synchronously and block the session
4. For `SessionStart` hooks, output a `systemMessage`:
   ```json
   {"systemMessage": "Your welcome message here"}
   ```

See `quickstart/hooks/` for a working example.

---

## SKILL.md Specification

Every skill must have a SKILL.md in its directory. This is the entry point Claude reads when the skill is triggered.

> **Convention note:** The `version_matrix`, `routing`, and `match` fields below are **conventions that Claude interprets as structured instructions** — they are not programmatically enforced by Claude Code. When Claude reads a routing table, it understands it as "if the prospect has version X, read reference file Y" and follows the logic. This convention allows a single SKILL.md to cover many version combinations while keeping the instructions version-aware.

### Skill Frontmatter Schema

```yaml
---
name: {skill-name}                    # Must match the skill's directory name exactly
description: >
  When to trigger this skill and what it does. Be specific about
  the action and the technology. Include trigger phrases.
version_matrix:                       # All version axes this skill supports
  {axis_name}: [{values}]
routing:                              # Maps version combos to reference files (optional)
  - match: { {axis}: {value_or_pattern} }
    variant: references/{filename}.md
---
```

**Field rules:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | Yes | string | Must exactly match the skill's directory name |
| `description` | Yes | string | Written as a trigger description — include what the skill does AND when Claude should use it. Be pushy: "Use this skill whenever..." |
| `version` | No | string | Semver version string (e.g., `1.0.0`). Recommended for tracking skill revisions. |
| `version_matrix` | Conditional | map | Required when the skill supports multiple version-specific procedures. Lists every version axis and its supported values. Omit for skills without version axes (e.g., doc lookup, generic setup). |
| `routing` | Conditional | list | Required if the skill has `references/` with version-variant files. Maps version inputs to reference files. |

**Routing match syntax:**

| Pattern | Meaning | Example |
|---|---|---|
| `{axis}: {value}` | Exact match | `java_version: 8` |
| `{axis}: [{v1}, {v2}]` | Match any in list | `java_version: [17, 21]` |
| `{axis}: "{prefix}*"` | Wildcard prefix | `springboot_version: "3.*"` |

### Skill Body Structure

After the frontmatter, the SKILL.md body contains these sections in order:

```markdown
## Prerequisites

What must be true before this skill runs:
- Which prior skills must have completed
- Required access, credentials, or configurations
- Environment assumptions

## Instructions

The core procedure. If the skill uses reference variants, this section
contains the routing logic and a pointer:

"Based on the prospect's version selections, read the appropriate
reference file from `references/` and follow its instructions."

If the skill does NOT use reference variants, the full step-by-step
procedure goes here directly.

## Validation

How to confirm this skill succeeded. Include:
- Specific commands to run
- Expected output or observable results
- What to check in the Datadog UI
- Reference to validation script if one exists in `scripts/`

## Troubleshooting

Common failure modes organized by symptom:

### {Symptom description}
Cause: {why this happens}
Fix: {what to do}

### {Symptom description}
Cause: {why this happens}
Fix: {what to do}
```

### Complete SKILL.md Template

```markdown
---
name: {skill-name}
description: >
  {Trigger description. Be specific and pushy. Example: "Use this skill
  whenever the prospect needs to install the Datadog Agent on an EC2
  instance running Ubuntu or Amazon Linux. Triggers on mentions of
  agent install, DD agent, host monitoring on EC2."}
version_matrix:
  {axis}: [{values}]
  {axis}: [{values}]
routing:
  - match: { {axis}: {value_or_pattern} }
    variant: references/{filename}.md
  - match: { {axis}: {value_or_pattern} }
    variant: references/{filename}.md
---

## Prerequisites

{Bulleted list of requirements. Be explicit about which prior skills
must have completed.}

- Skill `{prior-skill-name}` has been completed successfully
- {Access or credential requirement}
- {Environment requirement}

## Instructions

{If using reference variants:}

Determine the prospect's version selections for the following axes:

| Axis | Prospect's Value |
|---|---|
| {axis_name} | {to be filled} |
| {axis_name} | {to be filled} |

Based on these values, load and follow the matching reference file
from `references/`. The routing table in the frontmatter maps
version combinations to the correct file.

For version axes that do not affect the procedure (such as
`{axis_name}`), substitute the prospect's value wherever
`{{axis_name}}` appears in the reference file.

{If NOT using reference variants, write the full procedure here.}

## Validation

{Step-by-step verification. Be specific about what success looks like.}

1. Run the validation script:
   ```bash
   bash scripts/{validate-script}.sh
   ```
2. Verify in the Datadog UI:
   - Navigate to {specific page}
   - Confirm {specific observable result}
3. Expected output:
   ```
   {example of successful output}
   ```

## Troubleshooting

### {Symptom: e.g., "Agent reports 'connection refused'"}
**Cause:** {explanation}
**Fix:** {step-by-step resolution}

### {Symptom: e.g., "Traces appear in Agent log but not in Datadog UI"}
**Cause:** {explanation}
**Fix:** {step-by-step resolution}
```

### SKILL.md Examples

**Simple skill (no reference variants):**

```yaml
---
name: setup-ec2
description: >
  Use this skill to provision and configure an EC2 instance for Datadog
  monitoring. Triggers when the prospect needs to set up a new EC2 host
  or prepare an existing one for agent installation.
version_matrix:
  ami: [ubuntu-22.04, ubuntu-24.04, amazon-linux-2, amazon-linux-2023]
---
```

**Complex skill (with reference variants and routing):**

```yaml
---
name: springboot-dd-tracer
description: >
  Use this skill to instrument a Spring Boot application with the Datadog
  Java tracer. Supports Spring Boot 2.x and 3.x across Java 8 through 21.
  Triggers on mentions of Spring Boot tracing, Java APM, dd-trace-java,
  or Datadog Java agent for Spring applications.
version_matrix:
  java_version: [8, 11, 17, 21]
  springboot_version: [2.7, 3.0, 3.1, 3.2, 3.3]
  dd_tracer_version: [1.28, 1.29, 1.30, 1.31, latest]
routing:
  - match: { java_version: 8, springboot_version: "2.*" }
    variant: references/java8-sb2x.md
  - match: { java_version: 11, springboot_version: "2.*" }
    variant: references/java11-sb2x.md
  - match: { java_version: [17, 21], springboot_version: "3.*" }
    variant: references/java17-sb3x.md
  - match: { java_version: 21, springboot_version: "3.*" }
    variant: references/java21-sb3x.md
---
```

---

## Reference Files Specification

Reference files live in `references/` within a skill directory. Each file is a self-contained instruction set for a specific version combination.

### When to Create a Reference File

Create a separate reference file when the **procedure itself changes** — different commands, different flags, different configuration keys, different API calls, different file paths. Do NOT create a separate file when only a version string in a URL or dependency declaration changes — that's a substitution variable.

**Decision guide:**

| What changes | Action |
|---|---|
| CLI flags, JVM options | New reference file |
| Package namespace (`javax` → `jakarta`) | New reference file |
| Config file format or structure | New reference file |
| Security model (SCCs on OpenShift) | New reference file |
| API version in a YAML manifest | New reference file |
| Version string in a download URL | Substitution variable in existing file |
| Version string in `pom.xml` or `requirements.txt` | Substitution variable in existing file |
| Minor version of a tracer or agent | Substitution variable in existing file |

### Reference File Template

```markdown
# {Variant description}

> **Applies to:** {axis1} {values}, {axis2} {values}
> **Substitution variables:** `{{axis_name}}` — substitute the prospect's specific value

## Prerequisites

{Any prerequisites specific to THIS variant that differ from the
general skill prerequisites.}

## Step 1: {Action}

{Detailed instructions with exact commands, file contents, and
configuration. Use substitution variables where version strings
appear but don't change the procedure.}

```bash
{exact command with {{substitution_variables}}}
```

## Step 2: {Action}

{Continue with numbered steps.}

## Step N: Verify

{Variant-specific verification steps. These supplement the main
validation in SKILL.md — include anything version-specific here.}

## Known Issues for This Variant

{Any gotchas specific to this version combination.}
```

### Substitution Variables

Use double-brace syntax: `{{variable_name}}`. Variable names must match an axis in the skill's `version_matrix`.

```markdown
Download the Datadog Java tracer:

```bash
wget https://dtdg.co/latest-java-tracer -O dd-java-agent-{{dd_tracer_version}}.jar
```

Add the following to your `pom.xml`:

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
  <version>{{springboot_version}}</version>
</dependency>
```
```

Claude substitutes the prospect's actual version value when following the instructions. If a variable value is `latest`, the reference file should document how to resolve `latest` to an actual version number (e.g., checking the Datadog releases page).

---

## Scripts Specification

Scripts live in `scripts/` within a skill directory. They are executable files that Claude runs in the prospect's environment.

### Validation Script Template

```bash
#!/usr/bin/env bash
# validate-{what}.sh — Verify that {skill outcome} is working
#
# Usage: bash scripts/validate-{what}.sh [options]
# Exit codes: 0 = pass, 1 = fail
#
# Prerequisites:
#   - {what must be true for this script to work}

set -euo pipefail

TIMEOUT=${TIMEOUT:-120}       # seconds to wait for telemetry
CHECK_INTERVAL=5              # seconds between checks
ELAPSED=0

echo "=== Validating {what} ==="

# --- Check 1: {description} ---
echo -n "Checking {thing}... "
if {check_command}; then
  echo "PASS"
else
  echo "FAIL — {what this means and what to do}"
  exit 1
fi

# --- Check 2: {description} (with retry/timeout) ---
echo -n "Waiting for {thing} (timeout: ${TIMEOUT}s)... "
while [ $ELAPSED -lt $TIMEOUT ]; do
  if {check_command}; then
    echo "PASS (${ELAPSED}s)"
    break
  fi
  sleep $CHECK_INTERVAL
  ELAPSED=$((ELAPSED + CHECK_INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "FAIL — timed out after ${TIMEOUT}s"
  echo "  Hint: {troubleshooting guidance}"
  exit 1
fi

echo ""
echo "=== All checks passed ==="
exit 0
```

**Rules for validation scripts:**

1. Always use `set -euo pipefail`
2. Always include a usage comment header
3. Always exit 0 on success, 1 on failure
4. Always include a timeout for checks that wait for telemetry
5. Always print clear PASS/FAIL per check with guidance on failure
6. Never modify the system — read-only checks only
7. Never require credentials to be passed as arguments — read from environment variables or standard Datadog config paths

### Setup Script Guidelines

Setup scripts (as opposed to validation scripts) are less common but sometimes needed for repeatable provisioning steps. They follow the same rules plus:

1. Must be idempotent — running twice produces the same result as running once
2. Must check for existing state before creating resources
3. Must output what they created or changed
4. Should support a `--dry-run` flag when feasible

---

## Assets Specification

Assets live in `assets/` within a skill directory. They are files the prospect deploys to their environment.

### Sample App Requirements

Every sample application must include:

| File | Purpose |
|---|---|
| `README.md` | How to build, run, and what telemetry to expect in Datadog |
| `Dockerfile` | Container build for the application |
| `docker-compose.yml` | Single-command launch including any dependencies |
| App source files | The application code with Datadog instrumentation |
| Dependency manifest | `requirements.txt`, `pom.xml`, `package.json`, etc. with **pinned versions** |

**Content standards for sample apps:**

1. **Multiple endpoints** — at least 3 routes that exercise different code paths (CRUD operations, error handling, external calls)
2. **Realistic telemetry** — generate traces, custom metrics, and structured logs, not just a single "hello world" response
3. **Inline comments** — annotate which Datadog features each code section exercises:
   ```python
   # Datadog APM: This endpoint generates a trace with a database span
   @app.route("/users/<int:user_id>")
   def get_user(user_id):
       ...
   ```
4. **Configurable DD_AGENT_HOST** — the agent endpoint must be configurable via environment variable, not hardcoded
5. **No floating dependency versions** — pin everything. Use `==` in Python, exact versions in `pom.xml`, exact versions in `package.json`
6. **Health check endpoint** — include a `/health` route for container orchestration

**docker-compose.yml must:**
- Set `DD_AGENT_HOST` and other DD environment variables
- Not include the Datadog Agent itself (the agent is installed by a separate skill)
- Expose the app on a configurable port
- Include any required backing services (e.g., a local Redis if the app uses caching)

### Database Workload Requirements

Database workload assets generate query traffic for DBM validation:

| File | Purpose |
|---|---|
| `README.md` | How to run and what to expect in Datadog DBM |
| `generate-queries.py` | Python script that runs representative queries |
| `requirements.txt` | Pinned Python dependencies |
| `sample-schema.sql` | DDL to create tables and seed data |

**Standards:**
1. Generate a mix of query types (SELECT, INSERT, UPDATE, aggregate queries)
2. Include slow queries that will appear in DBM's slow query view
3. Run continuously or for a configurable duration
4. Connect using environment variables (`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`)

### Queue Workload Requirements

Queue workload assets generate producer/consumer traffic:

| File | Purpose |
|---|---|
| `README.md` | How to run and what to expect in Datadog |
| `producer.py` | Publishes messages to the queue |
| `consumer.py` | Consumes messages from the queue |
| `requirements.txt` | Pinned Python dependencies |
| `docker-compose.yml` | Runs both producer and consumer |

**Standards:**
1. Configurable message rate and payload size
2. Connect using environment variables (`QUEUE_HOST`, `QUEUE_PORT`, etc.)
3. Generate enough traffic to be visible in Datadog within 60 seconds

---

## Naming Rules — Quick Reference

| What | Pattern | Examples |
|---|---|---|
| **Infra plugin (cloud)** | `{provider}-{service}` | `aws-eks`, `gcp-gke` |
| **Infra plugin (on-prem)** | `{platform}-onprem` | `kubernetes-onprem`, `rhel-onprem` |
| **Instrumentation plugin** | `{language}-instrumentation` | `java-instrumentation` |
| **Managed DB/queue** | `{provider}-{service}-{engine}` or `{provider}-{service}` | `aws-rds-postgres`, `aws-sqs` |
| **Self-hosted DB/queue** | `{engine}-selfhosted` | `mysql-selfhosted`, `kafka-selfhosted` |
| **K8s DB/queue** | `{engine}-k8s` | `postgres-k8s`, `rabbitmq-k8s` |
| **Setup skill** | `setup-{target}` | `setup-ec2`, `setup-eks-cluster` |
| **Agent install skill** | `install-dd-{method}` | `install-dd-agent`, `install-dd-operator` |
| **Instrumentation skill** | `{framework}-{tracer}` | `springboot-dd-tracer`, `flask-dd-tracer` |
| **DBM skill** | `install-dd-dbm` | — |
| **Integration skill** | `install-dd-integration` | — |
| **Reference file** | `{version-axes}.md` | `java17-sb3x.md`, `k8s-1.29-plus.md` |
| **Sample app asset** | `{framework}{ver}-{tracer}-sample-app/` | `flask3x-dd-sample-app/` |
| **DB workload asset** | `{engine}-sample-workload/` | `pg-sample-workload/` |
| **Queue workload asset** | `{engine}-sample-producer-consumer/` | `kafka-sample-producer-consumer/` |

**Version suffixes in reference file names:**
- `-plus` means "this version and all later" (e.g., `k8s-1.29-plus.md`)
- `x` is a minor version wildcard (e.g., `sb3x` means Spring Boot 3.anything)
- Ranges use a hyphen (e.g., `k8s-1.27-1.28.md`)

**General naming rules:**
- All lowercase
- Hyphens as separators (no underscores, no dots)
- No spaces, no special characters
- Plugin names must be globally unique in the repository
- Skill names must be unique within their plugin

---

## Dependency Rules — Quick Reference

| Plugin Category | `requires:` | Depends On |
|---|---|---|
| Infrastructure | `[]` (empty) | Nothing — base layer |
| Instrumentation | `[list of infra plugins]` | At least one infra plugin |
| Database — managed | `[]` (empty) | Nothing — provider manages host |
| Database — self-hosted | `[list of host infra plugins]` | At least one host-based infra plugin |
| Database — K8s | `[list of K8s infra plugins]` | At least one K8s infra plugin |
| Queue — managed | `[]` (empty) | Nothing — provider manages host |
| Queue — self-hosted | `[list of host infra plugins]` | At least one host-based infra plugin |
| Queue — K8s | `[list of K8s infra plugins]` | At least one K8s infra plugin |

**Host-based infra plugins:** `aws-ec2`, `rhel-onprem` (and future equivalents)

**K8s infra plugins:** `aws-eks`, `gcp-gke`, `kubernetes-onprem`, `openshift-onprem` (and future equivalents)

**Dependency direction:** Dependencies always point downward toward infrastructure. There are no cross-dependencies between instrumentation and database/queue plugins. There are no circular dependencies.

---

## Version Matrix Design Guide

Designing the version matrix is the most important decision when creating a skill. Follow these guidelines:

### 1. List only tested versions

Every version in the matrix is a claim that the skill works with that version. Only include versions you have actually tested or are confident work based on documented compatibility.

### 2. Identify divergence axes

For each pair of adjacent versions, ask: "Do the instructions change?" If yes, that's a divergence point that may need a separate reference file. If no, those versions can share a reference file.

### 3. Group non-divergent versions

If Java 17 and 21 use the same instructions (both support modules, both use jakarta namespace), group them in a single routing rule: `java_version: [17, 21]`.

### 4. Keep the matrix honest

If you haven't tested Oracle 12c, don't include it. A smaller, verified matrix is better than a larger, aspirational one. Add versions as you test them.

### 5. Document the "latest" value

If an axis supports `latest`, the reference file must explain how to resolve `latest` to a concrete version number at execution time.

---

## Contribution Workflow

### Step-by-Step: New Plugin

1. **Determine the category** using the table in [Plugin Categories](./README.md#plugin-categories)
2. **Choose the name** using the rules in [Naming Rules](#naming-rules--quick-reference)
3. **Check for duplicates** — search the repo for existing plugins covering the same technology
4. **Create the directory structure:**
   ```
   {plugin-name}/
     .claude-plugin/
       plugin.json          # Required by Claude Code
     PLUGIN.md              # Marketplace convention
     skills/
   ```
5. **Write `plugin.json`** — the Claude Code manifest:
   ```json
   {
     "name": "{plugin-name}",
     "version": "0.1.0",
     "description": "What this plugin does"
   }
   ```
6. **Write PLUGIN.md** following the [PLUGIN.md template](#complete-pluginmd-template)
7. **Register in `marketplace.json`** — add an entry to `.claude-plugin/marketplace.json` at the repo root
8. **Add at least one skill** following the [New Skill](#step-by-step-new-skill) workflow
9. **Test the full flow** — compose with a compatible infra plugin if applicable, run all skills in order, verify telemetry in Datadog
10. **Submit a pull request** using the [PR checklist](#pull-request-checklist)

### Step-by-Step: New Skill

1. **Create the skill directory:**
   ```
   {plugin-name}/skills/{skill-name}/
     SKILL.md
   ```
2. **Design the version matrix** — list all axes and supported values
3. **Determine divergence points** — which version combinations need different instructions?
4. **Write SKILL.md** following the [SKILL.md template](#complete-skillmd-template)
5. **Create reference files** if needed, following the [Reference File Template](#reference-file-template)
6. **Write a validation script** if the skill produces observable results
7. **Build sample app assets** if the skill involves instrumentation or workload generation
8. **Test every routing path** — run the skill with at least one version combination per reference file
9. **Submit a pull request**

### Step-by-Step: New Reference Variant

When a new version is released (e.g., Java 22, Spring Boot 3.4):

1. **Determine if instructions diverge** from the nearest existing variant
2. **If they diverge:** create a new reference file and add a routing rule
3. **If they don't:** add the new version to the existing routing rule's match list and add it to the version matrix
4. **Update the version_matrix** in SKILL.md frontmatter
5. **Update supported_versions** in PLUGIN.md frontmatter
6. **Test the new version** end to end
7. **Submit a pull request**

### Pull Request Checklist

Before submitting, verify:

- [ ] `.claude-plugin/plugin.json` exists with all required fields (name, version, description)
- [ ] `plugin.json` `name` matches the directory name exactly
- [ ] Plugin is registered in `.claude-plugin/marketplace.json` at the repo root
- [ ] Plugin/skill name follows naming conventions
- [ ] PLUGIN.md frontmatter has all required fields
- [ ] SKILL.md frontmatter has all required fields
- [ ] `requires:` lists correct dependencies (or is empty for appropriate categories)
- [ ] Every version in `version_matrix` has a matching routing path (no dead ends)
- [ ] Every routing rule points to a reference file that exists
- [ ] Reference files are self-contained (no back-references to SKILL.md for instructions)
- [ ] Substitution variables in reference files match axis names in `version_matrix`
- [ ] Validation scripts exit 0 on success, non-zero on failure
- [ ] Sample apps include Dockerfile, docker-compose.yml, README.md, and pinned dependencies
- [ ] All file and directory names are lowercase with hyphens
- [ ] SKILL.md is under 500 lines
- [ ] Reference files are under 300 lines each
- [ ] Tested at least one version combination per reference file end to end

---

## Quality Standards

**Completeness:** A skill is complete when a prospect can follow it from start to finish and see telemetry in Datadog without needing to consult external documentation.

**Accuracy:** Every command, config snippet, and file path must be correct for the stated version. Test before committing. If a command differs between OS versions, it belongs in a reference variant, not an inline conditional.

**Clarity:** Write for a technical audience that knows their own stack but does not know Datadog. Avoid assuming familiarity with Datadog-specific terminology without defining it on first use.

**Maintainability:** When Datadog releases a new agent version, tracer version, or Helm chart version, updating the skills should require changing version strings, not rewriting procedures. That's what the substitution variable system is for.

---

## Common Mistakes to Avoid

**Missing `.claude-plugin/plugin.json`.** Every plugin must have this file — it is the Claude Code manifest. Without it, Claude Code cannot discover or load the plugin. `PLUGIN.md` alone is not sufficient.

**Forgetting to register in `marketplace.json`.** A plugin directory that exists but is not registered in `.claude-plugin/marketplace.json` at the repo root will not be discoverable by users installing from the marketplace.

**Creating a reference file per minor version.** If Flask 3.0 and 3.1 use the exact same instrumentation steps, they share a reference file (`flask3x.md`) with the minor version as a substitution variable.

**Putting instructions in PLUGIN.md.** PLUGIN.md is a declaration and index. Instructions belong in SKILL.md and reference files.

**Hardcoding the Datadog API key or agent host.** These are always environment variables. Never embed them in sample code or scripts.

**Writing a validation script that modifies state.** Validation scripts are read-only checks. They verify; they never install, configure, or change anything.

**Using `-onprem` for self-hosted databases or queues.** MySQL on an EC2 instance is `mysql-selfhosted`, not `mysql-onprem`. The `-onprem` suffix is reserved for infrastructure plugins where "on-premises" is the accurate description (the prospect's own data center, not a cloud provider's managed service).

**Sharing skill folders across plugins with symlinks.** Even if `install-dd-operator` is similar across EKS and GKE, each plugin gets its own copy. Duplication is intentional — see [Design Principles](./README.md#design-principles) in the README.

**Forgetting to update PLUGIN.md when adding a skill.** The Skills section of PLUGIN.md must list every skill in the plugin. If you add `install-dd-dbm` to a database plugin, add its description to PLUGIN.md.

**Including prospect-specific information.** This repository is public. No customer names, no API keys, no internal URLs, no account-specific configuration. The prospect brings their own configuration; the marketplace provides the instructions.
