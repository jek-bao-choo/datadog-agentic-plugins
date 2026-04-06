---
name: setup-openshift
description: >-
  Use this skill whenever the user needs to provision an Azure Red Hat OpenShift (ARO)
  cluster. Triggers on mentions of ARO setup, OpenShift on Azure, Red Hat OpenShift
  provisioning, or OCP cluster creation.
version: 0.1.0
---

# Azure Red Hat OpenShift Setup

Provision an ARO 4 cluster using the Azure CLI.

## Prerequisites

- Azure subscription with sufficient DSv5 family vCPU quota
- Azure CLI installed and authenticated (`az login`)

## Instructions

The complete setup is documented in `references/README.md`. Key steps:

### 1. Register providers

```bash
az provider register --namespace Microsoft.RedHatOpenShift --wait
az provider register --namespace Microsoft.Compute --wait
az provider register --namespace Microsoft.Storage --wait
az provider register --namespace Microsoft.Authorization --wait
```

### 2. Create networking

```bash
az group create --name <RESOURCE_GROUP> --location <LOCATION>
az network vnet create --resource-group <RESOURCE_GROUP> --name <VNET> --address-prefixes 10.0.0.0/22
az network vnet subnet create --resource-group <RESOURCE_GROUP> --vnet-name <VNET> --name master-subnet --address-prefixes 10.0.0.0/23
az network vnet subnet create --resource-group <RESOURCE_GROUP> --vnet-name <VNET> --name worker-subnet --address-prefixes 10.0.2.0/23
```

### 3. Create the cluster

```bash
az aro create --resource-group <RESOURCE_GROUP> --name <CLUSTER> --vnet <VNET> \
  --master-subnet master-subnet --worker-subnet worker-subnet
```

## Validation

```bash
az aro show --resource-group <RESOURCE_GROUP> --name <CLUSTER> --query "provisioningState" -o tsv
# Expected: Succeeded

# Get console URL
az aro show --resource-group <RESOURCE_GROUP> --name <CLUSTER> --query "consoleProfile.url" -o tsv
```

## Troubleshooting

### Quota exceeded error
**Cause:** Insufficient DSv5 vCPU quota in the region.
**Fix:** Request a quota increase: `az vm list-usage --location <LOCATION> --query "[?contains(name.value, 'standardDSv5Family')]"`
