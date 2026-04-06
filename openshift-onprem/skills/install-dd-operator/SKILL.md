---
name: install-dd-operator
description: >-
  Use this skill whenever the user wants to deploy the Datadog Operator and DDOT Collector
  on an OpenShift cluster. Triggers on mentions of Datadog on OpenShift, DDOT collector,
  Datadog Operator on ARO, or OpenShift monitoring with Datadog.
version: 0.1.0
---

# Install Datadog Operator on OpenShift

Deploy the Datadog Operator and DDOT Collector on an OpenShift cluster.

## Prerequisites

- OpenShift cluster provisioned (see `setup-openshift` skill)
- `oc` CLI logged in to the cluster
- Datadog API key

## Instructions

### 1. Install the Datadog Operator via OLM

Apply the operator subscription:

```bash
oc apply -f references/datadog-subscription.yaml
```

### 2. Create the Datadog API key secret

```bash
oc create secret generic datadog-secret --from-literal api-key=<YOUR_DATADOG_API_KEY>
```

### 3. Deploy the Datadog Agent

```bash
oc apply -f references/datadog-agent.yaml
```

## Validation

```bash
# Check operator and agent pods
oc get pods -l app.kubernetes.io/name=datadog

# Check agent status
oc exec $(oc get pods -l app.kubernetes.io/component=agent -o name | head -1) \
  -c agent -- agent status 2>/dev/null | head -50
```

In the Datadog UI: **Infrastructure > Kubernetes** — verify the OpenShift cluster appears.

## Troubleshooting

### Agent pods stuck due to SecurityContextConstraints
**Cause:** OpenShift SCCs blocking the Datadog agent containers.
**Fix:** The Datadog Operator should handle SCC creation. Verify with `oc get scc | grep datadog`.

### DDOT collector not sending traces
**Cause:** DDOT collector not configured or port conflicts.
**Fix:** Verify the DDOT configuration in `datadog-agent.yaml` and check collector logs.
