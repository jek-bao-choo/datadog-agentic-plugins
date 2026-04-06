## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `gcp-gke` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---



## Phase 1: Infrastructure Provisioning
- Provision a GKE Standard cluster via Terraform
- Region: Asia Southeast (asia-southeast1)
- Research Datadog GCP Monitoring Integration via the `terraform-gcp-datadog-integration` module (https://github.com/GoogleCloudPlatform/terraform-gcp-datadog-integration) for Log Collection Integration of GCP to Datadog
- Directory structure: shallow directories
- Resource naming: all GCP resources use "jek-" prefix
- Tagging: `owner:jek`, `env=test`
- Cloud Monitoring integration research using `terraform-gcp-datadog-integration` module

## Phase 2: Datadog Agent / Operator Setup

**Implementation steps:**
- Install the Datadog Operator via Helm (`helm install datadog-operator datadog/datadog-operator`)
- Create a Kubernetes secret for the Datadog API key
- Apply the DatadogAgent custom resource with cluster name, log/APM/process collection enabled
- Configure Cloud NAT for private clusters — default to creating a new Cloud NAT. First check if one exists: `gcloud compute routers list --filter="region:<REGION>"`. If an existing NAT gateway is found, reuse it; otherwise create a new Cloud Router + Cloud NAT
- Reference architecture diagram: https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-gcp-datadog-integration/refs/heads/main/gcp-to-datadog-diagram.png

**Validation:**
- Verify Agent pods are running: `kubectl get pods -l app.kubernetes.io/name=datadog`
- Check Agent status: `kubectl exec <agent-pod> -c agent -- agent status | head -50`
- Verify in Datadog UI: **Infrastructure > Kubernetes** shows the GKE cluster
- Confirm metrics and logs are flowing from GKE workloads

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior Terraform knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Create a `.gitignore` to avoid committing sensitive Terraform files (state, tfvars, etc.)
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Do NOT reveal PII or secrets -- this is a public GitHub repo
- Development machine: MacBook M4
- Explain steps in clear, beginner-friendly language

## Tools & References
- Context7 library: `/googlecloudplatform/terraform-google-cloud-run`
- Context7 library: `/googlecloudplatform/cloud-run-samples`
- Context7 library: `/hashicorp/terraform`
- Context7 library: `/hashicorp/hcl`
- Context7 library: `/websites/cloud_google_terraform`
- Context7 library: `/terraform-google-modules/terraform-google-network`
- Datadog docs: [GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- Datadog docs: [Datadog Operator](https://docs.datadoghq.com/containers/kubernetes/installation/?tab=operator)
- GitHub: [terraform-gcp-datadog-integration](https://github.com/GoogleCloudPlatform/terraform-gcp-datadog-integration)
