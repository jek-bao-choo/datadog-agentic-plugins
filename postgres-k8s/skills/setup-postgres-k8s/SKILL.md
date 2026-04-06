---
name: setup-postgres-k8s
description: >-
  Use this skill whenever the user needs to deploy PostgreSQL on Kubernetes using the
  Zalando Postgres Operator. Triggers on mentions of PostgreSQL on Kubernetes, Zalando
  operator, postgres-operator Helm, PostgreSQL on OpenShift, or Kubernetes database
  deployment. Also applies when the user needs a PostgreSQL cluster for Datadog DBM
  testing on K8s.
version: 0.1.0
version_matrix:
  postgres_version: [17]
  operator: [zalando-1.15.1]
---

# PostgreSQL 17 on Kubernetes — Zalando Operator

Deploy PostgreSQL 17 on Kubernetes using the Zalando Postgres Operator via Helm.

## Prerequisites

- Kubernetes or OpenShift cluster with `kubectl`/`oc` access
- `helm` v3 installed
- Storage class available (or use the bundled local-storage config)

## Instructions

The complete setup is documented in `README.md`. Key steps:

### 1. Install the Zalando Postgres Operator

```bash
helm repo add postgres-operator-charts \
  https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm repo update

helm install postgres-operator postgres-operator-charts/postgres-operator \
  -n zalando-postgres --create-namespace \
  -f references/values-openshift-pg17.yaml

kubectl wait deployment/postgres-operator -n zalando-postgres \
  --for=condition=Available --timeout=120s
```

### 2. (Optional) Configure local storage

For on-premise clusters without a dynamic storage provisioner:

```bash
kubectl apply -f references/local-storage.yaml
```

### 3. Deploy the PostgreSQL cluster

```bash
kubectl apply -f references/postgresql-cluster.yaml
```

### 4. (OpenShift) Patch ClusterRole

If the operator cannot list nodes:

```bash
kubectl apply -f references/patch-clusterrole.yaml
```

## Reference Files

- `README.md` — Full deployment guide with pinned versions
- `references/values-openshift-pg17.yaml` — Helm values for OpenShift + PG17
- `references/postgresql-cluster.yaml` — PostgreSQL cluster custom resource
- `references/local-storage.yaml` — Local StorageClass and PersistentVolume
- `references/patch-clusterrole.yaml` — ClusterRole patch for node listing

## Validation

```bash
# Check operator is running
kubectl get pods -n zalando-postgres

# Check PostgreSQL cluster status
kubectl get postgresql
# Expected: Running

# Get the password and connect
export PGPASSWORD=$(kubectl get secret <CLUSTER>.<USER>.credentials.postgresql.acid.zalan.do \
  -o jsonpath='{.data.password}' | base64 -d)
kubectl port-forward svc/<CLUSTER> 5432:5432 &
psql -h localhost -U <USER> -d <DB> -c "SELECT version();"
# Expected: PostgreSQL 17.x
```

## Troubleshooting

### Operator cannot list nodes
**Cause:** ClusterRole missing `nodes` list permission (common on OpenShift).
**Fix:** Apply the patch: `kubectl apply -f references/patch-clusterrole.yaml`

### Pods stuck in Pending (no PVC bound)
**Cause:** No StorageClass available or PV not provisioned.
**Fix:** Apply local storage config: `kubectl apply -f references/local-storage.yaml`

### PostgreSQL cluster stays in Creating state
**Cause:** Operator logs may show image pull or permission errors.
**Fix:** Check operator logs: `kubectl logs -n zalando-postgres deployment/postgres-operator`
