# datadog-agentic-plugins

A marketplace of agentic plugins and skills that empower coding agents to set up and configure Datadog for a PoC. Not endorsed by Datadog. The plugins are unofficial and reflect my personal understanding of agentic coding plugins.

## Claude Code

**Add the plugin:**


```bash
claude plugin marketplace add https://github.com/jek-bao-choo/datadog-agentic-plugins 
```

**Start Claude then add the plugin**

```bash
/plugin marketplace add https://github.com/jek-bao-choo/datadog-agentic-plugins

/plugin install quickstart@datadog-agentic-plugins

/reload-plugins
```

## Project Structure

```
datadog-agentic-plugins/
├── .claude-plugin/
│   └── marketplace.json
│
├── startup-toolkit/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── .mcp.json
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
│           ├── SKILL.md
│           ├── assets/
│           ├── references/
│           └── scripts/
│
├── gcp-integration/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── monitoring-gcp-apigee/
│       │   ├── assets/
│       │   └── references/
│       └── monitoring-gke-standard-v1dot34/
│           ├── assets/
│           └── references/
│
├── java-instrumentation/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       └── monitoring-java-spring-boot-v3dot5dot9/
│           ├── assets/
│           └── references/
│
├── php-instrumentation/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── monitoring-laravel-v12-php-v8dot3-nginx/
│       │   └── references/
│       └── monitoring-laravel-v8-php-v7dot4-apache2/
│           └── references/
│
├── sandbox-setup/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── initialising-litellm-gateway/
│       │   └── references/
│       └── initialising-splunk-enterprise/
│           ├── SKILL.md
│           ├── assets/
│           ├── references/
│           └── scripts/
```
