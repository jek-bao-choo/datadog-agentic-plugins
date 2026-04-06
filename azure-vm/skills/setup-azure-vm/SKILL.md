---
name: setup-azure-vm
description: >-
  Use this skill whenever the user needs to provision a Windows Server VM on Azure
  with .NET Framework. Triggers on mentions of Azure VM setup, Bicep deployment,
  Windows Server Azure, .NET Framework on Azure, or ASP.NET on Azure VM.
version: 0.1.0
---

# Azure VM Setup — Windows Server 2022

Provision a Windows Server 2022 VM on Azure with .NET Framework 4.8 and ASP.NET using Bicep templates.

## Prerequisites

- Azure subscription
- Azure CLI installed and authenticated (`az login`)
- Bicep CLI (included with Azure CLI)

## Instructions

The Bicep templates are in `references/ws2022__dotnetfx48__aspdotnet/`.

```bash
cd references/ws2022__dotnetfx48__aspdotnet/

# Deploy the Bicep template
az deployment group create \
  --resource-group <RESOURCE_GROUP> \
  --template-file main.bicep \
  --parameters @parameters.json
```

## Validation

```bash
# Check VM status
az vm show --resource-group <RESOURCE_GROUP> --name <VM_NAME> --show-details --output table

# Verify RDP access
az vm show --resource-group <RESOURCE_GROUP> --name <VM_NAME> --query "publicIps" --output tsv
```

## Troubleshooting

### Deployment fails with quota error
**Cause:** Azure subscription quota exceeded for the VM size.
**Fix:** Request a quota increase or use a smaller VM size.

### Cannot RDP to VM
**Cause:** NSG rules blocking RDP (port 3389).
**Fix:** Verify the network security group allows inbound RDP from your IP.
