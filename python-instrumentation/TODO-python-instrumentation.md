## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `python-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup
- **LangGraph Conversational AI** — Multi-turn conversational agent using LangGraph. Use MemorySaver for checkpoint-based state persistence.

Environment and tooling:
- Python 3.9.6 (system Python on macOS)
- `uv` for package management (not pip, not poetry)
- Credentials stored in `.env` files (never committed — ensure `.gitignore` covers them)
- Each app gets its own directory with its own `pyproject.toml`
- My tools: Macbook, iTerm2, tmux, Claude Code, VS Code

## Phase 2: Datadog Instrumentation
- Install `ddtrace[langchain]` in each project
- Enable LLM Observability via `DD_LLMOBS_ENABLED=1` environment variable
- Configure ddtrace auto-instrumentation for LangChain and LangGraph
- Set up trace-log correlation so Datadog links traces to structured logs
- Verify traces appear in Datadog APM and LLM Observability dashboards

## Guidelines
- Keep it simple. Each app should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to Python LLM development should be able to follow along.
- Every app directory gets a `README.md` explaining what it does and how to run it.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References
- Context7 MCP: `/llmstxt/python_langchain_llms_txt?tokens=5000` — LangChain documentation
- FastAPI docs: https://fastapi.tiangolo.com
- LangGraph docs: https://langchain-ai.github.io/langgraph/
- uv docs: https://docs.astral.sh/uv/
