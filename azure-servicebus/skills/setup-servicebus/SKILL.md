---
name: setup-servicebus
description: >-
  Use this skill to provision an Azure Service Bus namespace with queues
  using the Azure CLI, and configure Datadog Azure integration for metrics
  and Data Streams Monitoring. Triggers on mentions of Azure Service Bus
  setup, message queue provisioning on Azure, or Datadog queue monitoring.
version: 0.2.0
---

# Azure Service Bus Setup

Provision an Azure Service Bus namespace (Standard tier) in Southeast Asia with a transaction queue, and configure Datadog monitoring.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Datadog account (DD_SITE: datadoghq.com)
- Azure subscription with Service Bus and AD permissions

## Instructions

### Phase 1: Provision Service Bus

Run the automated setup script:

```bash
bash scripts/setup-servicebus.sh
```

This creates:
- Resource group `jek-rg-servicebus` in `southeastasia`
- Service Bus namespace `jek-sb-pgw` (Standard tier, ~2 min)
- Queue `jek-queue-pgw-transactions` (max delivery 10, lock 30s, TTL 14 days)
- Shared Access Policy `jek-sap-pgw` (Send + Listen)

The script outputs the connection string at the end. Save it to `.env`:

> **Important:** Do NOT use `echo '...' >> .env` — zsh breaks on the special characters (`+`, `=`, `;`) in the connection string. Use `nano` instead:

```bash
nano .env
```

Paste the connection string line, save (`Ctrl+O` → Enter → `Ctrl+X`), then verify:

```bash
cat .env
```

### Phase 2: Datadog Azure Integration

If you don't already have a Datadog Azure integration, create one:

**1. Create App Registration:**

```bash
APP_ID=$(az ad app create --display-name "jek-datadog-integration" --query appId -o tsv)
echo "App ID: $APP_ID"
```

**2. Create Service Principal:**

```bash
az ad sp create --id $APP_ID --query appId -o tsv
```

**3. Create Client Secret (save immediately — shown only once):**

```bash
CLIENT_SECRET=$(az ad app credential reset --id $APP_ID --append --query password -o tsv)
echo "Client Secret: $CLIENT_SECRET"
```

> **Save this secret now.** It is only displayed once. If lost, you must create a new one.

**4. Grant Reader role on the subscription:**

```bash
az role assignment create \
  --assignee $APP_ID \
  --role Reader \
  --scope /subscriptions/$(az account show --query id -o tsv)
```

**5. Get Tenant ID:**

```bash
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID"
```

**6. Configure in Datadog UI:**

Go to **Integrations > Azure** (https://app.datadoghq.com/integrations/azure) → **Add New**:

| Field | Value |
|---|---|
| Tenant ID | from step 5 |
| Client ID | APP_ID from step 1 |
| Client Secret | CLIENT_SECRET from step 3 |

Click **Install Integration**.

**7. Data Streams Monitoring:**

DSM for Azure Service Bus requires the producer/consumer applications to be instrumented with a Datadog tracer. This will be configured when the PGW app is set up in a later step.

Reference: https://docs.datadoghq.com/data_streams/setup/technologies/azure_service_bus.md

## Validation

### Service Bus validation

```bash
# Verify namespace is active
az servicebus namespace show \
  --name jek-sb-pgw \
  --resource-group jek-rg-servicebus \
  --query "status" -o tsv
# Expected: Active

# Verify queue is active
az servicebus queue show \
  --name jek-queue-pgw-transactions \
  --namespace-name jek-sb-pgw \
  --resource-group jek-rg-servicebus \
  --query "status" -o tsv
# Expected: Active

# Verify SAS policy has correct rights
az servicebus namespace authorization-rule show \
  --name jek-sap-pgw \
  --namespace-name jek-sb-pgw \
  --resource-group jek-rg-servicebus \
  --query "rights" -o tsv
# Expected: Send Listen
```

> **Note:** `az servicebus queue send` and `az servicebus queue peek` do NOT exist in the Azure CLI. To test message send/receive, use the producer/consumer applications built in later steps, or use the Azure Portal > Service Bus > Queue > Service Bus Explorer.

### Datadog Azure integration validation

Wait ~5 minutes after configuring the integration, then:

- **Metrics > Explorer** → search `azure.servicebus` → verify metrics from `jek-sb-pgw` are flowing
- **Infrastructure > Azure** → verify `jek-sb-pgw` namespace appears
- **Integrations > Azure** → verify the tile shows status "OK" with no errors

```bash
# Verify App Registration exists
az ad app show --id $APP_ID --query displayName -o tsv
# Expected: jek-datadog-integration

# Verify Reader role assigned
az role assignment list --assignee $APP_ID --query "[].roleDefinitionName" -o tsv
# Expected: Reader

# Verify service principal exists
az ad sp show --id $APP_ID --query appId -o tsv
```

## Troubleshooting

### Namespace creation fails with "NamespaceAlreadyExists"
**Cause:** The name `jek-sb-pgw` is globally unique — someone else may have it.
**Fix:** Change the namespace name in the script (e.g., `jek-sb-pgw-2`).

### Connection string save fails in zsh (`parse error near '\n'`)
**Cause:** `echo` and `printf` break on `+`, `=`, `;` characters in the connection string.
**Fix:** Use `nano .env` to paste the connection string manually. Do NOT use `echo` or `printf`.

### No Azure metrics in Datadog after 10 minutes
**Cause:** App Registration missing Reader role, client secret expired/wrong, or service principal not created.
**Fix:** Run the validation commands above. Verify: app exists, SP exists, Reader role assigned. Re-check client secret in Datadog Azure tile.

### Queue send fails with "Unauthorized"
**Cause:** SAS policy doesn't have Send claim, or connection string is for a different policy.
**Fix:** `az servicebus namespace authorization-rule show --name jek-sap-pgw --namespace-name jek-sb-pgw --resource-group jek-rg-servicebus --query rights`

## Teardown

```bash
# Delete Service Bus resources
az group delete --name jek-rg-servicebus --yes --no-wait

# Delete Datadog App Registration (optional — can reuse for other PoCs)
az ad app delete --id $APP_ID
```
