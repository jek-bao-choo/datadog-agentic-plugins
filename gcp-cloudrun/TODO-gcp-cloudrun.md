## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning
- Create a Terraform project to set up a Java Spring Boot app on Cloud Run
- Directory: `cloudrun__java`
- Components: Artifact Registry (for container images), service account, health checks
- Region: Asia Southeast (asia-southeast1)
- Recommend a sample Java Spring Boot app for testing an API endpoint
- Directory structure: shallow directories
- Resource naming: all GCP resources use "jek-" prefix
- Tagging: `owner:jek`, `env=test`

## Phase 2: Datadog Agent / Operator Setup
- Expose JVM metrics via Spring Boot Actuator
- Integrate Datadog monitoring for Cloud Run services
- Research Datadog GCP Monitoring Integration via `terraform-gcp-datadog-integration` module for log collection
- Reference: https://github.com/GoogleCloudPlatform/terraform-gcp-datadog-integration
- Verify metrics and logs flow into Datadog
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
- Datadog docs: [GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- Datadog docs: [Cloud Run Integration](https://docs.datadoghq.com/integrations/google_cloud_run/)
