# datadog-agentic-plugins

A marketplace of agentic plugins and skills that empower coding agents to set up and configure Datadog for a PoC. Not endorsed by Datadog. The plugins are unofficial and reflect my personal understanding of agentic coding plugins.

## Assuming a user starting on a fresh EC2 Ubuntu

Two commands on a fresh EC2 Ubuntu instance with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) already installed:

**Add the plugin:**


```bash
claude plugin marketplace add https://github.com/jek-bao-choo/datadog-agentic-plugins 
```

**Start Claude then add the plugin**

```bash
/plugin marketplace add https://github.com/jek-bao-choo/datadog-agentic-plugins

/plugin install startup-toolkit@datadog-agentic-plugins

/startup-toolkit:showing-menu
```

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
