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

**Implementation steps:**
- Deploy the Datadog Agent on the GKE cluster hosting the Apigee backend (see `gcp-gke` plugin for Datadog Operator setup)
- Instrument the backend Spring Boot application with `dd-java-agent.jar` (see `java-instrumentation` plugin) so Datadog captures traces from the backend service
- Enable GCP Cloud Trace on the Apigee X instance for API proxy-level trace collection
- Configure the Datadog GCP integration to pull Cloud Trace data into Datadog APM
- Set unified service tags (`DD_SERVICE`, `DD_ENV`, `DD_VERSION`) on the backend application

**Research tasks (document findings in README.md):**
- How Apigee proxy telemetry (latency, error rates, request counts) flows into Datadog — via Cloud Trace, Cloud Monitoring, or direct OTLP export
- Whether Apigee X natively supports OpenTelemetry trace context propagation through the proxy layer
- How to correlate Apigee proxy traces with backend service traces in Datadog APM

**Validation:**
- Verify traces appear in **APM > Traces** in the Datadog UI, with spans from both the Apigee proxy layer and the backend service
- Check **APM > Service Map** shows the request flow: Client → Apigee → Backend
- Confirm Cloud Trace data is visible in the GCP Console as a cross-reference

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
- Datadog docs: [APM & Distributed Tracing](https://docs.datadoghq.com/tracing/)
- Datadog docs: [GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
