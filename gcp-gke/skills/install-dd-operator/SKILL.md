---
name: install-dd-operator
description: >-
  Use this skill whenever the user wants to deploy the Datadog Agent on a GKE cluster
  using the Datadog Operator via Helm. Triggers on mentions of Datadog Operator, Helm
  Datadog install, Datadog on GKE, Kubernetes agent deployment, or GKE observability setup.
version: 0.1.0
---

# Install Datadog Operator on GKE

Deploy the Datadog Agent on a GKE Standard cluster using the Datadog Operator via Helm.

## Prerequisites

- GKE cluster configured for Datadog (see `setup-gke-cluster` skill)
- `kubectl` and `helm` CLI tools
- Datadog API key

## Instructions

### 1. Add the Datadog Helm repo

```bash
helm repo add datadog https://helm.datadoghq.com
```

### 2. Install the Datadog Operator

```bash
helm install datadog-operator datadog/datadog-operator
```

### 3. Create the API key secret

```bash
kubectl create secret generic datadog-secret --from-literal api-key=<YOUR_DATADOG_API_KEY>
```

### 4. Configure the Datadog Agent

Edit `references/datadog-agent.yaml` and set `clusterName` to your actual GKE cluster name:

```yaml
spec:
  global:
    clusterName: "your-actual-cluster-name"
```

### 5. Deploy the Agent

```bash
kubectl apply -f references/datadog-agent.yaml
```

## Validation

```bash
# Check agent pods are running
kubectl get pods -l app.kubernetes.io/name=datadog -o wide

# Check agent status
kubectl exec $(kubectl get pods -l app.kubernetes.io/component=agent -o name | head -1) \
  -c agent -- agent status 2>/dev/null | head -50
```

See `assets/proof-datadog-agent-operator.png` for expected output.

In the Datadog UI: **Infrastructure > Kubernetes** — verify the cluster appears.

## Troubleshooting

### Agent pods show `i/o timeout` or `Client.Timeout exceeded`
**Cause:** Cluster lacks outbound internet access.
**Fix:** Configure Cloud NAT (see `setup-gke-cluster` skill).

### Metrics not tagged with correct cluster name
**Cause:** `clusterName` in `datadog-agent.yaml` still has placeholder value.
**Fix:** Set it to your actual cluster name and reapply: `kubectl apply -f references/datadog-agent.yaml`
