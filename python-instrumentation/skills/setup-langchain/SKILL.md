---
name: setup-langchain
description: >-
  Use this skill whenever the user needs to build and deploy a LangChain agent application.
  Triggers on mentions of LangChain setup, LangChain agent, tool calling with LangChain,
  or Python AI agent deployment.
version: 0.1.0
version_matrix:
  langchain_version: [0.2.11]
---

# LangChain Agent Application Setup

Build and deploy a LangChain agent application with tool calling capabilities (DuckDuckGo search, Datadog metrics retrieval).

## Prerequisites

- Python 3.9+
- OpenAI API key (for LLM backend)

## Instructions

The complete application source is in `references/`. Key structure:

- `references/app/` — Application source (API routes, tools, core agent logic, models)
- `references/tests/` — Unit tests
- `references/pyproject.toml` — Dependencies

```bash
cd references/
pip install -e .
uvicorn app.api.main:app --reload --port 8000
```

## Validation

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Search for Datadog pricing"}'
```

## Troubleshooting

### Agent fails with "model not found"
**Cause:** OpenAI API key not set or invalid.
**Fix:** Export `OPENAI_API_KEY` environment variable.
