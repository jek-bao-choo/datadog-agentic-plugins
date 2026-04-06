---
name: setup-gke-cluster
description: >-
  Use this skill whenever the user needs to configure a GKE cluster for Datadog monitoring.
  Triggers on mentions of GKE setup, GKE private cluster egress, Cloud NAT for GKE,
  or preparing a GKE cluster for Datadog agent deployment.
version: 0.1.0
---

# GKE Cluster Setup for Datadog

Configure a GKE Standard cluster for Datadog monitoring, including egress configuration for private clusters.

## Prerequisites

- A running GKE Standard cluster
- `gcloud` CLI authenticated
- Cluster admin permissions

## Instructions

### 1. Verify cluster access

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION>
kubectl get nodes
```

### 2. Configure Cloud NAT (required for private clusters)

Private GKE clusters need Cloud NAT for the Datadog Agent to reach intake endpoints (`*.datadoghq.com`):

```bash
# Create a Cloud Router
gcloud compute routers create <ROUTER_NAME> \
  --network=<VPC_NAME> \
  --region=<REGION>

# Create Cloud NAT
gcloud compute routers nats create <NAT_NAME> \
  --router=<ROUTER_NAME> \
  --region=<REGION> \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges
```

### 3. Note your cluster name

```bash
gcloud container clusters list --format="value(name)"
```

You will need this for the `install-dd-operator` skill to set `clusterName` in the agent configuration.

## Validation

```bash
# Verify egress works (from a test pod)
kubectl run test-egress --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s -o /dev/null -w "%{http_code}" https://api.datadoghq.com
# Expected: 200 or 403 (reachable)
```

## Troubleshooting

### Pods cannot reach external endpoints
**Cause:** No Cloud NAT configured for the VPC.
**Fix:** Create Cloud NAT as described in Step 2.
