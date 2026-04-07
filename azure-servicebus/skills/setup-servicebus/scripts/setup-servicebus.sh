#!/usr/bin/env bash
set -euo pipefail

# setup-servicebus.sh — Provision Azure Service Bus namespace + queue via Azure CLI
#
# Prerequisites: az login (already authenticated)
# Usage: bash setup-servicebus.sh
#
# Creates:
#   - Resource group: jek-rg-servicebus (southeastasia)
#   - Namespace: jek-sb-pgw (Standard tier)
#   - Queue: jek-queue-pgw-transactions
#   - SAS Policy: jek-sap-pgw (Send + Listen)

RESOURCE_GROUP="jek-rg-servicebus"
LOCATION="southeastasia"
NAMESPACE="jek-sb-pgw"
QUEUE_NAME="jek-queue-pgw-transactions"
SAS_POLICY="jek-sap-pgw"

echo "=== Step 1: Create Resource Group ==="
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags owner=jek env=test criticality=low

echo ""
echo "=== Step 2: Create Service Bus Namespace (Standard tier) ==="
echo "This takes 1-2 minutes..."
az servicebus namespace create \
  --name "$NAMESPACE" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard \
  --tags owner=jek env=test

echo ""
echo "=== Step 3: Create Queue ==="
az servicebus queue create \
  --name "$QUEUE_NAME" \
  --namespace-name "$NAMESPACE" \
  --resource-group "$RESOURCE_GROUP" \
  --max-delivery-count 10 \
  --lock-duration PT30S \
  --default-message-time-to-live P14D

echo ""
echo "=== Step 4: Create Shared Access Policy (Send + Listen) ==="
az servicebus namespace authorization-rule create \
  --name "$SAS_POLICY" \
  --namespace-name "$NAMESPACE" \
  --resource-group "$RESOURCE_GROUP" \
  --rights Send Listen

echo ""
echo "=== Step 5: Get Connection String ==="
CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list \
  --name "$SAS_POLICY" \
  --namespace-name "$NAMESPACE" \
  --resource-group "$RESOURCE_GROUP" \
  --query "primaryConnectionString" \
  --output tsv)

echo ""
echo "=== Done ==="
echo ""
echo "Namespace:  $NAMESPACE.servicebus.windows.net"
echo "Queue:      $QUEUE_NAME"
echo "SAS Policy: $SAS_POLICY"
echo ""
echo "Connection string (save to .env — DO NOT commit):"
echo "AZURE_SERVICEBUS_CONNECTION_STRING=$CONNECTION_STRING"
echo ""
echo "Next: Configure Datadog Azure integration for Service Bus metrics."
