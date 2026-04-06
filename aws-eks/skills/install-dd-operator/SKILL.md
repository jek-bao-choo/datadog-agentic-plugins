---
name: install-dd-operator
description: >-
  Use this skill whenever the user wants to deploy the Datadog Agent on an EKS cluster
  using the Datadog Operator via Helm. Triggers on mentions of Datadog Operator on EKS,
  Helm Datadog install on AWS, EKS monitoring, or Datadog agent deployment on EKS.
version: 0.1.0
---

# Install Datadog Operator on EKS

Deploy the Datadog Agent on an EKS cluster using the Datadog Operator via Helm.

## Prerequisites

- EKS cluster provisioned and kubectl configured (see `setup-eks-cluster` skill)
- Helm CLI installed
- Datadog API key

## Instructions

### 1. Add the Datadog Helm repo

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
```

### 2. Create the API key secret

```bash
kubectl create secret generic datadog-secret --from-literal api-key=<YOUR_DATADOG_API_KEY>
```

### 3. Deploy the Datadog Operator with Helm values

Use the bundled Helm values file:

```bash
helm install datadog-operator datadog/datadog-operator -f references/datadog-values-helm.yaml
```

See `references/datadog-values-helm.yaml.example` for a template with all configurable options.

### 4. Apply the Datadog Agent operator configuration

```bash
kubectl apply -f references/datadog-agent-operator.yaml
```

## Validation

```bash
# Check operator and agent pods
kubectl get pods -l app.kubernetes.io/name=datadog

# Check agent status
kubectl exec $(kubectl get pods -l app.kubernetes.io/component=agent -o name | head -1) \
  -c agent -- agent status 2>/dev/null | head -50
```

In the Datadog UI: **Infrastructure > Kubernetes** — verify the EKS cluster appears.

## Troubleshooting

### Agent pods in CrashLoopBackOff
**Cause:** Invalid API key or missing secret.
**Fix:** Verify the secret: `kubectl get secret datadog-secret -o jsonpath='{.data.api-key}' | base64 -d`

### No data in Datadog UI
**Cause:** Agent cannot reach Datadog endpoints (egress blocked).
**Fix:** Ensure security groups allow outbound HTTPS (443) to `*.datadoghq.com`.
