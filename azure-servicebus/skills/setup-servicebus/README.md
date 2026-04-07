# Azure Service Bus Setup

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Datadog account (datadoghq.com / US1)

## Tech Stack

| Component | Value |
|---|---|
| Service Bus | Standard tier |
| Region | Southeast Asia (Singapore) |
| Namespace | jek-sb-pgw |
| Queue | jek-queue-pgw-transactions |

## Step-by-Step

### 1. Run the setup script

```bash
bash scripts/setup-servicebus.sh
```

Takes ~2 minutes. Creates resource group, namespace, queue, and SAS policy.

### 2. Save connection string

The script outputs the connection string. **Do NOT use `echo` — zsh breaks on special characters.** Use `nano` instead:

```bash
nano .env
```

Paste the `AZURE_SERVICEBUS_CONNECTION_STRING=Endpoint=sb://...` line. Save: `Ctrl+O` → Enter → `Ctrl+X`.

Verify:
```bash
cat .env
```

### 3. Create Datadog Azure integration (if not already configured)

```bash
# Create App Registration
APP_ID=$(az ad app create --display-name "jek-datadog-integration" --query appId -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Create Client Secret (SAVE THIS — shown only once)
CLIENT_SECRET=$(az ad app credential reset --id $APP_ID --append --query password -o tsv)
echo "Client Secret: $CLIENT_SECRET"

# Grant Reader role
az role assignment create --assignee $APP_ID --role Reader \
  --scope /subscriptions/$(az account show --query id -o tsv)

# Get Tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID"
echo "Client ID: $APP_ID"
```

### 4. Configure in Datadog UI

Go to **Integrations > Azure** → **Add New**:
- Tenant ID, Client ID, Client Secret from step 3
- Click **Install Integration**

### 5. Verify

```bash
# Service Bus active
az servicebus namespace show --name jek-sb-pgw --resource-group jek-rg-servicebus --query "status" -o tsv

# Queue active
az servicebus queue show --name jek-queue-pgw-transactions --namespace-name jek-sb-pgw --resource-group jek-rg-servicebus --query "status" -o tsv
```

In Datadog (wait ~5 min): **Metrics > Explorer** → search `azure.servicebus`.

> **Note:** `az servicebus queue send/peek` do NOT exist in Azure CLI. Use Azure Portal > Service Bus Explorer or the producer/consumer apps in later steps to test messaging.

## Teardown

### 1. Delete Azure resources

```bash
# Delete resource group (namespace + queue + SAS policy all deleted together)
az group delete --name jek-rg-servicebus --yes --no-wait
```

> `--no-wait` means deletion continues in the background. Verify with: `az group show --name jek-rg-servicebus 2>&1 | grep "not found"` (should say "not found" when complete).

### 2. Delete Datadog App Registration (optional)

Only delete if you won't reuse this integration for other Azure PoCs:

```bash
# If $APP_ID is no longer in your shell, find it:
az ad app list --display-name "jek-datadog-integration" --query "[0].appId" -o tsv

# Delete
az ad app delete --id <APP_ID>
```

### 3. Remove Datadog Azure integration (optional)

If this was the only Azure resource being monitored:
- Go to **Integrations > Azure** in Datadog → click the tenant → **Remove Integration**

### 4. Clean up local files

```bash
rm -f .env  # contains connection string
```
