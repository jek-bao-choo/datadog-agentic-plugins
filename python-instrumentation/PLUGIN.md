---
name: python-instrumentation
description: >
  Instrument Python applications with Datadog APM. Covers FastAPI,
  LangChain, and LangGraph with the Datadog Python tracer and
  OpenTelemetry SDK.
category: instrumentation
requires: [aws-ec2, aws-eks, gcp-gke, gcp-cloudrun]
supported_versions:
  python_version: [3.9]
  fastapi_version: [0.116]
  langchain_version: [0.2.11]
  langgraph_version: [0.6.5]
---

## Overview

The python-instrumentation plugin provides skills for setting up and instrumenting Python applications with Datadog APM. Covers FastAPI REST APIs, LangChain agent applications, and LangGraph conversational AI services.

## Prerequisites

- Python 3.9+ installed
- Docker (for containerized deployment)
- A running infrastructure environment (see aws-ec2, aws-eks, or gcp-gke plugins)
- Datadog API key

## Skills

### setup-fastapi
Build and deploy a FastAPI application with OpenAI API gateway functionality. Includes Gunicorn/Uvicorn production setup and Docker deployment.

### fastapi-dd-tracer
Instrument a deployed FastAPI application with Datadog APM using `ddtrace`.

### setup-langchain
Build and deploy a LangChain agent application with tool calling (DuckDuckGo search, Datadog metrics).

### langchain-dd-tracer
Instrument a deployed LangChain application with Datadog APM and LLM Observability.

### setup-langgraph
Build and deploy a LangGraph conversational AI service with state-based conversation management.

### langgraph-dd-tracer
Instrument a deployed LangGraph application with Datadog APM and LLM Observability.

## Recommended Skill Order

1. setup-fastapi (or setup-langchain, or setup-langgraph)
2. fastapi-dd-tracer (or langchain-dd-tracer, or langgraph-dd-tracer)

## Compatibility Notes

Tested with Python 3.9.6 (CPython). FastAPI 0.116, LangChain 0.2.11, LangGraph 0.6.5.
