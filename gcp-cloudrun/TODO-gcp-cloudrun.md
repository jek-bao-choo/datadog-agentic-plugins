## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `gcp-cloudrun` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

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

**Implementation steps:**
- Expose JVM metrics via Spring Boot Actuator (`/actuator/metrics`, `/actuator/health`)
- Add the Datadog Serverless agent as a sidecar to the Cloud Run service (via `--add-cloudsql-instances` or multi-container Cloud Run)
- Set environment variables on the Cloud Run service: `DD_API_KEY`, `DD_SITE`, `DD_SERVICE`, `DD_ENV`, `DD_VERSION`
- For APM tracing: attach `dd-java-agent.jar` via `JAVA_TOOL_OPTIONS=-javaagent:/path/to/dd-java-agent.jar`
- Configure the Datadog GCP integration via `terraform-gcp-datadog-integration` module for log collection from Cloud Run → Datadog
  - Reference: https://github.com/GoogleCloudPlatform/terraform-gcp-datadog-integration
- Enable Cloud Run request metrics forwarding to Datadog via the GCP integration

**Validation:**
- Verify JVM metrics appear in **Metrics > Explorer** (search `jvm.heap_memory`)
- Verify APM traces appear in **APM > Services** with the configured service name
- Verify Cloud Run logs appear in **Logs > Search**
- Check the **Serverless > Cloud Run** view in Datadog UI

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
- Datadog docs: [GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- Datadog docs: [Cloud Run Integration](https://docs.datadoghq.com/integrations/google_cloud_run/)
