## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Environment Setup & Validation
- **Docker Containers** — Run Datadog Agent 7.68.3 with DogStatsD enabled. Read `DD_API_KEY` from `.env`. Configure for local metric and log collection.
- Verify test metrics appear in the Datadog dashboard

My setup: Macbook Pro M4, Claude Code terminal + VS Code

## Guidelines

- Keep it simple. Each script/container should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to Datadog Agent setup should be able to follow along.
- Every sub-directory gets a `README.md` explaining what it does and how to run it.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Shell scripts: no Context7 needed — standard bash/curl
- Docker: general Docker documentation
- Datadog: Logs HTTP API docs (https://docs.datadoghq.com/api/latest/logs/)
- Datadog: DogStatsD docs (https://docs.datadoghq.com/developers/dogstatsd/)
- Datadog Agent: Docker setup docs (https://docs.datadoghq.com/containers/docker/)
