---
name: langgraph-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a LangGraph application with Datadog
  APM and LLM Observability. Triggers on mentions of LangGraph tracing, LangGraph monitoring,
  or Datadog LLM Observability for conversational AI.
version: 0.1.0
version_matrix:
  langgraph_version: [0.6.5]
---

# LangGraph — Datadog APM & LLM Observability

Instrument a deployed LangGraph application with Datadog APM and LLM Observability.

## Prerequisites

- Skill `setup-langgraph` has been completed successfully
- Datadog Agent running
- Datadog API key configured

## Instructions

### 1. Install ddtrace with LangChain support

```bash
pip install ddtrace[langchain]
```

LangGraph uses LangChain under the hood, so the LangChain integration covers LangGraph traces.

### 2. Enable LLM Observability

```bash
DD_SERVICE=langgraph-chat DD_ENV=sandbox \
  DD_LLMOBS_ENABLED=1 DD_LLMOBS_AGENTLESS_ENABLED=0 \
  ddtrace-run uvicorn app.api.main:app --host 0.0.0.0 --port 8000
```

### 3. Generate conversational traffic

```bash
for i in $(seq 1 5); do
  curl -s -X POST http://localhost:8000/chat \
    -H "Content-Type: application/json" \
    -d "{\"message\": \"Tell me about Datadog feature $i\"}" > /dev/null
done
```

## Validation

In the Datadog UI:
- **APM > Services** — look for `langgraph-chat`
- **LLM Observability** — verify graph execution spans with tool calls

## Troubleshooting

### Graph spans missing tool call details
**Cause:** Tool functions not properly decorated or ddtrace version too old.
**Fix:** Update ddtrace to latest: `pip install --upgrade ddtrace[langchain]`
