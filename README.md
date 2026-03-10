# datadog-agentic-plugins

A marketplace of agentic plugins and skills that empower coding agents to set up and configure Datadog for a PoC. Not endorsed by Datadog. The plugins are unofficial and reflect my personal understanding of agentic coding plugins.

## Assuming a user starting on a fresh EC2 Ubuntu

Two commands on a fresh EC2 Ubuntu instance with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) already installed:

**Step 1 — Download the plugin:**

```bash
git clone --depth 1 https://github.com/jek-bao-choo/datadog-agentic-plugins /tmp/datadog-agentic-plugins
```

**Step 2 — Start Claude with credentials, plugin, and menu:**

```bash
claude --plugin-dir /tmp/datadog-agentic-plugins/starter-kit "/starter-kit:showing-menu"
```

or

```bash
claude --settings '{"env":{"ANTHROPIC_BASE_URL":"YYY_PROVIDED_BY_YOUR_ASSIGNED_SALES_ENGINEER_YYY","ANTHROPIC_AUTH_TOKEN":"YYY_PROVIDED_BY_YOUR_ASSIGNED_SALES_ENGINEER_YYY"}}' --plugin-dir /tmp/datadog-agentic-plugins/starter-kit "/starter-kit:showing-menu"
```

Replace the `YYY_PROVIDED_BY_YOUR_ASSIGNED_SALES_ENGINEER_YYY` placeholders with the values provided by your assigned Sales Engineer.

**What this does:**

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `git clone --depth 1` | Shallow clone of plugins (fast) |
| 2a | `--settings '{"env":{...}}'` | Injects `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` |
| 2b | `--plugin-dir /tmp/datadog-agentic-plugins/starter-kit` | Loads the starter-kit plugin |
| 2c | `"/starter-kit:showing-menu"` | Shows the getting-started menu |

## Project Structure

```
datadog-agentic-plugins/
├── starter-kit/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── commands/
│   │   └── showing-menu.md
│   └── skills/
│       └── fetching-datadog-docs/
│           └── SKILL.md
│
├── aws-integration/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       └── monitoring-ec2-ubuntu-v22/
│           └── SKILL.md
│
├── gcp-integration/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── monitoring-gcp-apigee/
│       └── monitoring-gke-standard-v1dot34/
│
├── java-instrumentation/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       └── monitoring-java-spring-boot-v3dot5dot9/
│
├── php-instrumentation/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── monitoring-laravel-v12-php-v8dot3-nginx/
│       └── monitoring-laravel-v8-php-v7dot4-apache2/
│
├── sandbox-setup/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── initialising-litellm-gateway/
│       └── initialising-splunk-enterprise/
│           └── SKILL.md
```
