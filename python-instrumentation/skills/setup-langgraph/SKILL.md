---
name: setup-langgraph
description: >-
  Use this skill whenever the user needs to build and deploy a LangGraph conversational AI
  service. Triggers on mentions of LangGraph setup, LangGraph deployment, state-based AI
  conversation, or LangGraph with FastAPI.
version: 0.1.0
version_matrix:
  langgraph_version: [0.6.5]
---

# LangGraph Chat API Setup

Build and deploy a LangGraph conversational AI service with state-based conversation management and tool calling (online search, Datadog metrics).

## Prerequisites

- Python 3.9+
- OpenAI API key (for LLM backend)

## Instructions

The complete application source is in `references/`. Key structure:

- `references/app/` — Application source (API, tools, core graph logic, models)
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
  -d '{"message": "Hello, search for latest Datadog features"}'
```

## Troubleshooting

### Conversation state not persisting
**Cause:** MemorySaver not configured.
**Fix:** Verify LangGraph checkpointer is initialized in the graph builder.
