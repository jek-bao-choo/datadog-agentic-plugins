## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `sandbox-setup` plugin. Work proceeds in two phases: first set up sandbox environments, then validate Datadog telemetry. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place scripts, configs, and Docker files in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Environment Setup

- **Docker Containers** — Run Datadog Agent 7.68.3 with DogStatsD enabled. Read `DD_API_KEY` from `.env`. Configure for local metric and log collection.
- **Shell scripts** — Send test logs to Datadog via HTTP API (`curl` to `https://http-intake.logs.datadoghq.com/v1/input`), send test events via Events API, send test traces.
- **OTel Collector** — Run OpenTelemetry Collector via Docker Compose, configured to export to Datadog.
- **Cloud-Prem** — Run Datadog Observability Pipelines locally for log routing.

My setup: Macbook Pro M4, Claude Code terminal + VS Code

## Phase 2: Datadog Telemetry Validation

For each sandbox environment, validate that telemetry reaches Datadog:

- **Agent validation:** Run `docker exec <agent-container> agent status` and confirm: API key valid, Forwarder connected, DogStatsD listening on port 8125/UDP
- **Logs validation:** Check **Logs > Search** in Datadog UI — filter by the configured source tag
- **Metrics validation:** Check **Metrics > Explorer** — search for custom metrics sent via DogStatsD
- **Traces validation:** Check **APM > Traces** — filter by service name used in test trace scripts
- **Events validation:** Check **Events > Explorer** — look for test events with configured tags
- **OTel validation:** Verify OTLP traces flow through the collector to Datadog APM
- **Cloud-Prem validation:** Verify logs appear in Datadog after routing through the pipeline

## Guidelines

- Keep it simple. Each script/container should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to Datadog Agent setup should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Shell scripts: no Context7 needed — standard bash/curl
- Docker: general Docker documentation
- Datadog: Logs HTTP API docs (https://docs.datadoghq.com/api/latest/logs/)
- Datadog: DogStatsD docs (https://docs.datadoghq.com/developers/dogstatsd/)
- Datadog Agent: Docker setup docs (https://docs.datadoghq.com/containers/docker/)
