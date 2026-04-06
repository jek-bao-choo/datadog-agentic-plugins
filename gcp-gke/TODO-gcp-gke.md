## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

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
- Install Datadog Operator via Helm on the GKE cluster
- Configure Cloud NAT for private clusters (research whether to create new NAT Gateway or reuse existing)
- Reference architecture diagram: https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-gcp-datadog-integration/refs/heads/main/gcp-to-datadog-diagram.png
- Verify Datadog Agent is running and collecting metrics/logs from GKE workloads
- Document setup and teardown steps in `README.md`

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior Terraform knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Create a `.gitignore` to avoid committing sensitive Terraform files (state, tfvars, etc.)
- Document all steps in `README.md` including teardown
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
