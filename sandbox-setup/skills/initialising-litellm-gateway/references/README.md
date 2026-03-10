# LiteLLM Gateway on GCP — Full Reference

LiteLLM Gateway deployed on Google Cloud Run with PostgreSQL (Cloud SQL) for budget-controlled access to Anthropic Claude models. Each virtual key enforces a spending limit and expiry, allowing safe distribution of API access.

## Architecture

```
                         ┌─────────────────────────────────────────────────────────┐
                         │                   Google Cloud Platform                 │
                         │                  (sandbox project)                      │
                         │                                                         │
┌──────────┐   HTTPS     │  ┌──────────────────────────────────┐                   │
│  Client   │────────────┼─>│        Cloud Run Service          │                   │
│ (curl /   │            │  │       litellm-proxy               │                   │
│  app /    │            │  │                                    │                   │
│  Claude   │            │  │  ┌────────────────────────────┐   │                   │
│  Code)    │            │  │  │    LiteLLM Proxy Server     │   │                   │
└──────────┘             │  │  │                            │   │                   │
     │                   │  │  │  - Auth (master key /       │   │                   │
     │ Authorization:    │  │  │    virtual keys)            │   │                   │
     │ Bearer <key>      │  │  │  - Budget enforcement       │   │                   │
     │                   │  │  │  - Model routing            │   │                   │
     │                   │  │  │  - Usage tracking           │   │                   │
     │                   │  │  └──────┬───────────┬──────────┘   │                   │
     │                   │  │         │           │              │                   │
     │                   │  └─────────┼───────────┼──────────────┘                   │
     │                   │            │           │                                  │
     │                   │   Unix     │           │  HTTPS                           │
     │                   │   Socket   │           │                                  │
     │                   │            v           │                                  │
     │                   │  ┌─────────────────┐   │                                  │
     │                   │  │   Cloud SQL      │   │                                  │
     │                   │  │   (PostgreSQL)   │   │                                  │
     │                   │  │  litellm-db-asia  │   │                                  │
     │                   │  │                  │   │                                  │
     │                   │  │  - Virtual keys  │   │                                  │
     │                   │  │  - Spend records │   │                                  │
     │                   │  │  - Budget state  │   │                                  │
     │                   │  └─────────────────┘   │                                  │
     │                   │                        │                                  │
     │                   └────────────────────────┼──────────────────────────────────┘
     │                                            │
     │                                            v
     │                                  ┌─────────────────────┐
     │                                  │    Anthropic API     │
     │                                  │                      │
     │                                  │  claude-opus-4-6     │
     │                                  │  claude-sonnet-4-6   │
     │                                  │  claude-haiku-4-5    │
     │                                  └─────────────────────┘
```

**Flow:** Client sends request with virtual key -> Cloud Run authenticates & checks budget -> If within budget, forwards to Anthropic -> Records spend in PostgreSQL -> Returns response to client.

## Current Deployment

| Resource | Value |
|---|---|
| **GCP Project** | See `.env` → `GCP_PROJECT_ID` |
| **Region** | `asia-southeast1` |
| **Cloud Run Service** | `litellm-proxy` |
| **Service URL** | See `.env` → `LITELLM_SERVICE_URL` |
| **Cloud SQL Instance** | `litellm-db-asia` (PostgreSQL 15, `db-custom-2-7680`, Enterprise) |
| **DB Connection Name** | `$GCP_PROJECT_ID:asia-southeast1:litellm-db-asia` |
| **DB Password** | See `.env` → `DB_PASSWORD` |
| **Master Key** | See `.env` → `LITELLM_MASTER_KEY` |
| **Container Image** | `ghcr.io/berriai/litellm:main-latest` |
| **Memory / CPU** | 4 GiB / 2 vCPU (with CPU boost, min 1 instance) |
| **Available Models** | `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5` |

## App Files

Two files are needed for the deployment — both are included in this directory:

### config.yaml

Defines which models are available and how they connect to the upstream provider.

```yaml
model_list:
  - model_name: claude-opus-4-6
    litellm_params:
      model: anthropic/claude-opus-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: claude-sonnet-4-6
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: claude-haiku-4-5
    litellm_params:
      model: anthropic/claude-haiku-4-5
      api_key: os.environ/ANTHROPIC_API_KEY

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/DATABASE_URL
```

To add a new model, append an entry under `model_list` and redeploy.

### Dockerfile

```dockerfile
FROM ghcr.io/berriai/litellm:main-latest
COPY config.yaml /app/config.yaml
CMD ["--config", "/app/config.yaml", "--port", "8080"]
```

### Environment Variables (set on Cloud Run)

| Variable | Description |
|---|---|
| `ANTHROPIC_API_KEY` | Your Anthropic `sk-ant-...` API key |
| `LITELLM_MASTER_KEY` | Admin key for managing virtual keys (see `.env`) |
| `DATABASE_URL` | PostgreSQL connection string via Cloud SQL Unix socket |

The `DATABASE_URL` format for Cloud SQL on Cloud Run:
```
postgresql://postgres:<DB_PASSWORD>@localhost:5432/postgres?host=/cloudsql/<CONNECTION_NAME>
```

## Setup Steps (from scratch)

### Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated (`gcloud auth login`)
- Anthropic API key with funded account

```bash
export GCP_PROJECT_ID="your-gcp-project-id"   # replace with your actual project ID
```

_Set this once — the commands below reference `$GCP_PROJECT_ID`._

### Step 1: Enable GCP APIs

```bash
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  sql-component.googleapis.com
```

### Step 2: Grant IAM Permissions

The Cloud Run default service account needs the Cloud SQL Client role:

```bash
PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client" \
  --condition=None
```

> Without this role, the Cloud SQL proxy sidecar cannot connect and the container will crash on startup with `httpx.ConnectError: All connection attempts failed`.

### Step 3: Provision PostgreSQL

```bash
# Create Cloud SQL instance
gcloud sql instances create litellm-db \
  --database-version=POSTGRES_15 \
  --edition=ENTERPRISE \
  --tier=db-custom-2-7680 \
  --region=asia-southeast1

# Set password (alphanumeric only — avoids URL encoding issues)
gcloud sql users set-password postgres \
  --instance=litellm-db \
  --password="YOUR_DB_PASSWORD"

# Get the connection name (needed for Step 5)
gcloud sql instances describe litellm-db --format="value(connectionName)"
```

### Step 4: App Files

The `config.yaml` and `Dockerfile` are already in this directory. See the [App Files](#app-files) section above for their contents.

### Step 5: Deploy to Cloud Run

```bash
gcloud run deploy litellm-proxy \
  --source . \
  --port 8080 \
  --allow-unauthenticated \
  --region asia-southeast1 \
  --memory 4Gi \
  --cpu 2 \
  --timeout 300 \
  --cpu-boost \
  --min-instances 1 \
  --set-cloudsql-instances="$GCP_PROJECT_ID:asia-southeast1:litellm-db" \
  --set-env-vars="ANTHROPIC_API_KEY=sk-ant-YOUR-KEY,LITELLM_MASTER_KEY=YOUR_MASTER_KEY,DATABASE_URL=postgresql://postgres:YOUR_DB_PASSWORD@localhost:5432/postgres?host=/cloudsql/$GCP_PROJECT_ID:asia-southeast1:litellm-db"
```

> **Note:** Replace `YOUR_DB_PASSWORD`, `YOUR_MASTER_KEY`, and `sk-ant-YOUR-KEY` with your actual values (see `.env.example`). The `--set-cloudsql-instances` value must match the connection name from Step 3.
> **Memory:** Must be at least 2 GiB (we use 4 GiB). The default 512 MiB causes OOM crashes.
> **CPU boost:** Recommended — LiteLLM + Prisma engine need extra CPU at startup.

> The actual deployment uses instance name `litellm-db-asia` and project from `.env` → `GCP_PROJECT_ID` — see the [Current Deployment](#current-deployment) table for exact values.

### Step 6: Update Anthropic API Key (if deployed with placeholder)

```bash
gcloud run services update litellm-proxy \
  --region asia-southeast1 \
  --update-env-vars="ANTHROPIC_API_KEY=sk-ant-YOUR-REAL-KEY"
```

## Testing

### Health Check

```bash
# Unauthenticated liveness probe
curl "$LITELLM_SERVICE_URL/health/liveliness"
# Returns: "I'm alive!"

# Authenticated health check (tests model connectivity)
curl "$LITELLM_SERVICE_URL/health" \
  -H "Authorization: Bearer YOUR_MASTER_KEY"
```

### Generate a Virtual Key

```bash
curl -X POST "$LITELLM_SERVICE_URL/key/generate" \
  -H "Authorization: Bearer YOUR_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "max_budget": 0.5,
    "budget_duration": "1d",
    "models": ["claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5"],
    "metadata": {"user": "example-user"}
  }'
```

The response contains a `key` field — this is the virtual token to distribute.

### Use with Claude Code

To point Claude Code at the LiteLLM proxy instead of the Anthropic API directly:

```bash
export ANTHROPIC_BASE_URL="$LITELLM_SERVICE_URL"
export ANTHROPIC_API_KEY="sk-YOUR-VIRTUAL-KEY"
claude
```

Or configure it in `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "$LITELLM_SERVICE_URL",
    "ANTHROPIC_API_KEY": "sk-YOUR-VIRTUAL-KEY"
  }
}
```

Replace `sk-YOUR-VIRTUAL-KEY` with the virtual key generated in the previous step.

### Test Chat Completion

```bash
curl -X POST "$LITELLM_SERVICE_URL/v1/chat/completions" \
  -H "Authorization: Bearer sk-VIRTUAL-KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Check Budget Usage

```bash
curl -X GET "$LITELLM_SERVICE_URL/key/info?key=sk-VIRTUAL-KEY" \
  -H "Authorization: Bearer YOUR_MASTER_KEY"
```

Key fields: `spend` (amount used), `max_budget` ($1.00), `budget_reset_at` (expiry timestamp).

## Maintenance

### Add a New Model

1. Edit `config.yaml` — add an entry under `model_list`:
   ```yaml
   - model_name: claude-sonnet-4-6
     litellm_params:
       model: anthropic/claude-sonnet-4-6
       api_key: os.environ/ANTHROPIC_API_KEY
   ```
2. Redeploy:
   ```bash
   gcloud run deploy litellm-proxy --source . --region asia-southeast1
   ```
3. Generate a new virtual key that includes the model, or update existing keys.

### Rotate the Anthropic API Key

```bash
gcloud run services update litellm-proxy \
  --region asia-southeast1 \
  --update-env-vars="ANTHROPIC_API_KEY=sk-ant-NEW-KEY"
```

### Rotate the Master Key

```bash
gcloud run services update litellm-proxy \
  --region asia-southeast1 \
  --update-env-vars="LITELLM_MASTER_KEY=sk-new-master-key"
```

All existing virtual keys remain valid. Only admin operations (key generation, health checks) require the new master key.

### View Logs

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=litellm-proxy" \
  --limit=50 --format="value(textPayload)" --project=$GCP_PROJECT_ID
```

### Revoke a Virtual Key

```bash
curl -X POST "$LITELLM_SERVICE_URL/key/delete" \
  -H "Authorization: Bearer YOUR_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"keys": ["sk-VIRTUAL-KEY-TO-REVOKE"]}'
```

### List All Virtual Keys

```bash
curl -X GET "$LITELLM_SERVICE_URL/key/list" \
  -H "Authorization: Bearer YOUR_MASTER_KEY"
```

### Tear Down

```bash
# Delete Cloud Run service
gcloud run services delete litellm-proxy --region asia-southeast1

# Delete Cloud SQL instance (irreversible)
gcloud sql instances delete litellm-db-asia
```

## Security Note

Sensitive values (DB password, master key, Anthropic API key, service URL, GCP project ID) are not stored in this README. See `.env.example` for the required secrets. For production deployments, store these in [GCP Secret Manager](https://cloud.google.com/secret-manager) and reference them via Cloud Run's secret mounting feature instead of `--set-env-vars`.

## Cost

Approximate ongoing costs for this setup:

| Resource | Estimated Cost |
|---|---|
| Cloud SQL `db-custom-2-7680` | ~$104/month (always-on) |
| Cloud Run | Pay-per-use (billed per request/CPU/memory, near-zero at low traffic) |
| Anthropic API | Usage-based (passed through to your Anthropic billing) |

To minimize costs during inactivity, consider stopping the Cloud SQL instance when not in use (`gcloud sql instances patch litellm-db-asia --activation-policy=NEVER`).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Container crashes on startup with `httpx.ConnectError` | Missing `roles/cloudsql.client` on service account | Grant the role (see Step 2) |
| `Memory limit of 512 MiB exceeded` | Default memory too low | Deploy with `--memory 2Gi` |
| `invalid x-api-key` from Anthropic | Placeholder or wrong Anthropic key | Update env var with real key |
| `key_model_access_denied` | Virtual key not scoped to requested model | Generate new key with correct `models` list |
| Health check shows model as unhealthy | Anthropic key invalid or account unfunded | Verify key and billing at console.anthropic.com |
