## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `gcp-apigee` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---



## Phase 1: Infrastructure Provisioning
- Set up Apigee X via Terraform
- Components: VPC networking, Private Service Connect (PSC), load balancers, API proxies
- Note: Apigee X provisioning takes 45-90 minutes -- plan accordingly
- Consider the Apigee emulator option for local development and faster iteration
- Region: Asia Southeast (asia-southeast1)
- Directory structure: shallow directories
- Resource naming: all GCP resources use "jek-" prefix
- Tagging: `owner:jek`, `env=test`

## Phase 2: Datadog Agent / Operator Setup
- Set up OpenTelemetry-based observability for Apigee backend services
- Integrate Cloud Trace with Datadog for distributed tracing
- Collect APM traces from Apigee backend services and forward to Datadog
- Research how Apigee proxy telemetry data flows into Datadog
- Verify traces appear in Datadog APM
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
- Datadog docs: [APM & Distributed Tracing](https://docs.datadoghq.com/tracing/)
- Datadog docs: [GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
