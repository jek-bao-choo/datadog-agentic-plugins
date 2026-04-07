## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `openshift-onprem` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning
- Provision an Azure Red Hat OpenShift (ARO) cluster via Azure CLI
- Region: southeastasia
- Components: VPC (VNet), subnets (master subnet, worker subnet)
- Ensure DSv5 quota is available in the target region
- Resource naming: use "jek-" prefix where applicable

## Phase 2: Datadog Agent / Operator Setup

**Implementation steps (online phase — while internet is available):**
- Install the Datadog Operator via OLM (OperatorHub) or Helm on the OpenShift cluster
- Create a Kubernetes secret for the Datadog API key
- Apply the DatadogAgent custom resource (`datadog-agent.yaml`) with OpenShift-specific settings (SecurityContextConstraints)
- If using DDOT Collector, apply the `datadog-subscription.yaml` for the OpenTelemetry components
- Verify Agent pods are running: `oc get pods -l app.kubernetes.io/name=datadog`
- Verify Agent is reporting: `oc exec <agent-pod> -c agent -- agent status`

**Offline/air-gapped preparation (for environments that will lose internet):**
- Mirror all required container images to an internal registry (Datadog Agent, Operator, DDOT Collector)
- Package the Helm chart for offline installation (`helm pull`, `helm package`)
- Document the air-gapped registry configuration and image pull secrets
- Reference offline Helm chart installation guide: https://raw.githubusercontent.com/jek-bao-choo/splunk-otel-example/refs/heads/main/infrastructure-kubernetes/k8s-no-internet-offline-installation/README.md

**Research tasks (document findings in README.md with simple diagrams):**
- How the Datadog Operator works in an OpenShift cluster
- How the Datadog Agent runs in the OpenShift cluster (DaemonSet, node-level collection)
- Whether the Datadog OpenTelemetry (DDOT) Collector is included with the Operator
- The overall architecture of Operator → Agent → Datadog backend

**Validation:**
- Verify in Datadog UI: **Infrastructure > Kubernetes** shows the OpenShift cluster
- Confirm metrics, logs, and (if DDOT) traces are flowing

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior OpenShift or Kubernetes operator knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Do NOT reveal PII or secrets -- this is a public GitHub repo
- Development machine: MacBook M4
- Explain steps in clear, beginner-friendly language
- Use simple ASCII/text diagrams to illustrate architecture
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.


## Resource Naming Convention

All resources created in this plugin use the **"jek-"** prefix for easy identification in shared environments.

| Resource Type | Convention | Examples |
|---|---|---|
| HTTP endpoints | `jek-endpoint-{method}` | `jek-endpoint-get`, `jek-endpoint-post`, `jek-endpoint-put` |
| Message queues | `jek-queue` | `jek-queue`, `jek-queue-orders` |
| Database name | `jek-database` | `jek-database`, `jek-database-master`, `jek-database-slave` |
| Database tables | `jek-table` | `jek-table`, `jek-table-users` |
| Infra resources | `jek-{resource}` | `jek-vpc`, `jek-eks-cluster`, `jek-ec2-master` |
| Services (DD_SERVICE) | `jek-{app-name}` | `jek-springboot-app`, `jek-fastapi-gateway` |
| Cloud tags | `owner="jek"`, `env="test"` | — |
| gRPC services | `jek-grpc-{service}` | `jek-grpc-orders`, `jek-grpc-payments` |
| WebSocket endpoints | `jek-ws-{purpose}` | `jek-ws-chat`, `jek-ws-notifications` |
| GraphQL endpoints | `jek-graphql` | `jek-graphql` (single endpoint by convention) |
| Event streams | `jek-stream-{name}` | `jek-stream-orders`, `jek-stream-events` |
| Other protocols | `jek-{protocol}-{name}` | `jek-rpc-auth`, `jek-mqtt-sensor` |

## Tools & References
- Context7 library: `/datadog/datadog-operator`
- Datadog docs: [Datadog Operator for OpenShift](https://docs.datadoghq.com/containers/kubernetes/installation/?tab=operator)
- Datadog docs: [Datadog Operator GitHub](https://github.com/DataDog/datadog-operator)
- Reference: [Offline Helm Chart Installation Guide](https://raw.githubusercontent.com/jek-bao-choo/splunk-otel-example/refs/heads/main/infrastructure-kubernetes/k8s-no-internet-offline-installation/README.md)
