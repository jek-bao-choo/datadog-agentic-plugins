# quickstart

Interactive onboarding plugin that guides DevOps/SRE engineers through Datadog PoC setup — from session start to documented completion.

## Features

- **Quick welcome** — Displays a brief welcome on session start with pointers to `/quickstart:menu` and `/resume`
- **Datadog MCP integration** — Optionally connects to Datadog MCP server for live account queries
- **Live documentation** — Fetches current Datadog docs via `llms.txt` index
- **Session documentation** — Documents tech stack, steps, problems, solutions, and limitations to a local markdown file
- **Plan-then-execute** — Presents a plan before executing, waits for user approval

## Prerequisites

- An agentic coding CLI: [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [OpenCode](https://opencode.ai/)
- Internet access (recommended, for live docs and MCP)
- Datadog API key and application key (for MCP features)

## Installation

### Claude Code

```bash
claude plugin add /path/to/quickstart
```

### Manual

Copy the `quickstart/` directory into your project or plugins directory.

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

### Preferences (`.claude/quickstart.local.md`)

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
| `menu` | Command | Interactive use-case menu (`/quickstart:menu`) |
| `SessionStart` hook | Hook | Brief welcome on session start |
| `TaskCompleted` hook | Hook | Prompts task documentation before completion |
| Datadog MCP | Dynamic | Configured on-demand when user opts in |

## Usage

1. Start a new session — a brief welcome appears
2. Type `/quickstart:menu` to see the full 26-item use case menu
3. Pick a use case (number or description)
4. Optionally connect to Datadog MCP server
5. Follow guided setup with live documentation (plan shown first, then executed after approval)
6. On task completion, optionally document steps to PoC notes

## Cross-Tool Compatibility

This plugin is designed to work with:
- **Claude Code** — first-class support
- **OpenCode** — first-class support

The plugin uses prompt-based hooks and standard markdown components for maximum portability.

## License

MIT
