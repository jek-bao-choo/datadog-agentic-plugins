## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning
- Provision an Azure Red Hat OpenShift (ARO) cluster via Azure CLI
- Region: southeastasia
- Components: VPC (VNet), subnets (master subnet, worker subnet)
- Ensure DSv5 quota is available in the target region
- Resource naming: use "jek-" prefix where applicable

## Phase 2: Datadog Agent / Operator Setup
- Research on-prem offline Datadog Operator installation for OpenShift
- Assumption: prospect has initial internet access, then loses internet connectivity permanently
- Reference offline Helm chart installation guide: https://raw.githubusercontent.com/jek-bao-choo/splunk-otel-example/refs/heads/main/infrastructure-kubernetes/k8s-no-internet-offline-installation/README.md
- In research, explain the following using simple diagrams:
  - How the Datadog Operator works in an OpenShift cluster
  - How the Datadog Agent runs in the OpenShift cluster (DaemonSet, node-level collection)
  - Whether the Datadog OpenTelemetry (DDOT) Collector is included with the Operator
  - The overall architecture of Operator -> Agent -> Datadog backend
- Document the offline installation steps (image mirroring, chart packaging, air-gapped registry)
- Append setup, deployment, verification, and cleanup steps to `README.md` after the task is fully completed

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior OpenShift or Kubernetes operator knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Do NOT reveal PII or secrets -- this is a public GitHub repo
- Development machine: MacBook M4
- Explain steps in clear, beginner-friendly language
- Use simple ASCII/text diagrams to illustrate architecture

## Tools & References
- Context7 library: `/datadog/datadog-operator`
- Datadog docs: [Datadog Operator for OpenShift](https://docs.datadoghq.com/containers/kubernetes/installation/?tab=operator)
- Datadog docs: [Datadog Operator GitHub](https://github.com/DataDog/datadog-operator)
- Reference: [Offline Helm Chart Installation Guide](https://raw.githubusercontent.com/jek-bao-choo/splunk-otel-example/refs/heads/main/infrastructure-kubernetes/k8s-no-internet-offline-installation/README.md)
