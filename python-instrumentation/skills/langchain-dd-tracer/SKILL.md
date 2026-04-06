---
name: langchain-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a LangChain application with Datadog
  APM and LLM Observability. Triggers on mentions of LangChain tracing, LLM Observability,
  Datadog LangChain, or AI agent monitoring with Datadog.
version: 0.1.0
version_matrix:
  langchain_version: [0.2.11]
---

# LangChain — Datadog APM & LLM Observability

Instrument a deployed LangChain application with Datadog APM and LLM Observability.

## Prerequisites

- Skill `setup-langchain` has been completed successfully
- Datadog Agent running
- Datadog API key configured

## Instructions

### 1. Install ddtrace with LLM Observability

```bash
pip install ddtrace[langchain]
```

### 2. Enable LLM Observability

```bash
DD_SERVICE=langchain-agent DD_ENV=sandbox \
  DD_LLMOBS_ENABLED=1 DD_LLMOBS_AGENTLESS_ENABLED=0 \
  ddtrace-run uvicorn app.api.main:app --host 0.0.0.0 --port 8000
```

### 3. Generate traffic

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is Datadog?"}'
```

## Validation

In the Datadog UI:
- **APM > Services** — look for `langchain-agent`
- **LLM Observability** — verify LLM spans with tool calls appear

## Troubleshooting

### LLM spans not appearing
**Cause:** `DD_LLMOBS_ENABLED` not set or ddtrace[langchain] not installed.
**Fix:** Verify both the flag and the extra dependency are present.
