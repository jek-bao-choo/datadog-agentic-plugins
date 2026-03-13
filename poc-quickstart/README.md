# poc-quickstart

Interactive onboarding plugin that guides DevOps/SRE engineers through Datadog PoC setup — from session start to documented completion.

## Features

- **Auto-start menu** — Displays 26 Datadog use cases on session start (Agent setup, APM instrumentation, RUM, logs, cloud integrations, troubleshooting)
- **Datadog MCP integration** — Optionally connects to Datadog MCP server for live account queries
- **Live documentation** — Fetches current Datadog docs via `llms.txt` index
- **Session documentation** — Documents tech stack, steps, problems, solutions, and limitations to a local markdown file
- **Session review** — Optionally reviews PoC notes for completeness before ending

## Prerequisites

- An agentic coding CLI: [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [OpenCode](https://opencode.ai/)
- Internet access (recommended, for live docs and MCP)
- Datadog API key and application key (for MCP features)

## Installation

### Claude Code

```bash
claude plugin add /path/to/poc-quickstart
```

### Manual

Copy the `poc-quickstart/` directory into your project or plugins directory.

## Configuration

### Datadog Credentials (`.env.datadog`)

For MCP server features, create a `.env.datadog` file in your project root:

```bash
DD_API_KEY=your-api-key-here
DD_APPLICATION_KEY=your-app-key-here
DD_SITE=us1
```

**Supported sites:** `us1` (default), `us3`, `us5`, `eu1`, `ap1`, `ap2`

> **Security:** The plugin auto-adds `.env.datadog` to `.gitignore` and sets permissions to `chmod 600`. Never commit this file.

### Preferences (`.claude/poc-quickstart.local.md`)

Optional non-sensitive settings:

```yaml
---
poc_notes_path: ./datadog-poc-notes.md
internet_access: true
---
```

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| `fetching-datadog-docs` | Skill | Live Datadog documentation lookup |
| `showing-menu` | Command | Interactive use-case menu |
| `SessionStart` hook | Hook | Auto-displays menu on session start |
| `TaskCompleted` hook | Hook | Documents task completion to markdown |
| `SessionEnd` hook | Hook | Reviews PoC notes for completeness |
| Datadog MCP | Dynamic | Configured on-demand when user opts in |

## Usage

1. Start a new session — the menu appears automatically
2. Pick a use case (number or description)
3. Optionally connect to Datadog MCP server
4. Follow guided setup with live documentation
5. On task completion, document steps to PoC notes
6. On session end, optionally review notes

## Cross-Tool Compatibility

This plugin is designed to work with:
- **Claude Code** — first-class support
- **OpenCode** — first-class support

The plugin uses prompt-based hooks and standard markdown components for maximum portability.

## License

MIT
