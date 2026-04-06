---
name: initialising-litellm-gateway
description: >-
  Use this skill whenever the user wants to deploy a LiteLLM Gateway on GCP for
  budget-controlled access to Anthropic Claude models. Triggers on mentions of LiteLLM,
  Claude API proxy, API budget control, virtual API keys, Claude Code gateway, or
  cost-controlled LLM access. Also applies when the user needs to provide multiple users
  with time-limited, budget-capped access to Claude models.
version: 0.1.0
---

# LiteLLM Gateway on GCP

Deploy a LiteLLM Gateway on Google Cloud Run with Cloud SQL PostgreSQL for budget-controlled access to Anthropic Claude models. Each virtual key enforces a spending limit and expiry, allowing safe distribution of API access.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- Anthropic API key with funded account
- Environment variables from `.env` file (see `references/.env.example`)

## Instructions

The complete setup is documented in `README.md`. Key steps:

### 1. Enable GCP APIs

```bash
gcloud services enable run.googleapis.com sqladmin.googleapis.com \
  cloudbuild.googleapis.com artifactregistry.googleapis.com sql-component.googleapis.com
```

### 2. Grant IAM permissions

The Cloud Run service account needs `roles/cloudsql.client`.

### 3. Provision PostgreSQL

```bash
gcloud sql instances create litellm-db \
  --database-version=POSTGRES_15 --edition=ENTERPRISE \
  --tier=db-custom-2-7680 --region=asia-southeast1
```

### 4. Deploy to Cloud Run

```bash
gcloud run deploy litellm-gateway --source . --port 8080 \
  --allow-unauthenticated --region asia-southeast1 \
  --memory 4Gi --cpu 2 --min-instances 1 \
  --set-cloudsql-instances="<CONNECTION_NAME>" \
  --set-env-vars="ANTHROPIC_API_KEY=...,LITELLM_MASTER_KEY=...,DATABASE_URL=..."
```

### 5. Generate virtual keys

```bash
curl -X POST "$LITELLM_SERVICE_URL/key/generate" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"max_budget": 1, "duration": "1d", "models": ["claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5"]}'
```

### 6. Use with Claude Code

```bash
export ANTHROPIC_BASE_URL="$LITELLM_SERVICE_URL"
export ANTHROPIC_API_KEY="sk-YOUR-VIRTUAL-KEY"
claude
```

## Reference Files

- `README.md` — Complete deployment guide with architecture diagram
- `references/config.yaml` — LiteLLM model and budget configuration
- `references/Dockerfile` — Container image definition
- `references/.env.example` — Required environment variables template

## Validation

```bash
# Health check (unauthenticated)
curl "$LITELLM_SERVICE_URL/health/liveliness"
# -> "I'm alive!"

# Authenticated health check
curl "$LITELLM_SERVICE_URL/health" -H "Authorization: Bearer $LITELLM_MASTER_KEY"

# Test chat completion with virtual key
curl -X POST "$LITELLM_SERVICE_URL/v1/chat/completions" \
  -H "Authorization: Bearer sk-VIRTUAL-KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-sonnet-4-6", "messages": [{"role": "user", "content": "Hello!"}]}'

# Check budget usage
curl "$LITELLM_SERVICE_URL/key/info?key=sk-VIRTUAL-KEY" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY"
```

## Troubleshooting

### Container crashes on startup with `httpx.ConnectError`
**Cause:** Missing `roles/cloudsql.client` on the Cloud Run service account.
**Fix:** Grant the role: `gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:..." --role="roles/cloudsql.client"`

### `Memory limit of 512 MiB exceeded`
**Cause:** Default memory too low for LiteLLM + Prisma engine.
**Fix:** Deploy with `--memory 4Gi` (minimum 2Gi required).

### `invalid x-api-key` from Anthropic
**Cause:** The `ANTHROPIC_API_KEY` on Cloud Run is a placeholder or expired.
**Fix:** Update: `gcloud run services update litellm-gateway --region asia-southeast1 --update-env-vars="ANTHROPIC_API_KEY=sk-ant-REAL-KEY"`

### `key_model_access_denied`
**Cause:** Virtual key not scoped to the requested model.
**Fix:** Generate a new key with the correct `models` list.
