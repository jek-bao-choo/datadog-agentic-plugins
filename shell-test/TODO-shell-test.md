# TODO — shell-test

## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `shell-test` plugin. Work proceeds in two phases: first create the test scripts, then validate telemetry in Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place scripts and docs in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Test Script Setup

- **Traces:** Create a bash script that sends test trace/span data to Datadog via the Traces API (`curl` to the Agent's trace endpoint or directly to the intake)
- **Logs:** Create a bash script that sends test logs to Datadog via the Logs HTTP API (`curl` to `https://http-intake.logs.datadoghq.com/v1/input`)
- **Events:** Create a bash script that sends test events to Datadog via the Events API
- All scripts read `DD_API_KEY` from a `.env` file — never hardcode
- Each script should be self-contained and runnable with a single command

## Phase 2: Datadog Telemetry Validation

- **Traces:** Verify in **APM > Traces** that test spans appear
- **Logs:** Verify in **Logs > Search** that test logs appear with the configured source tag
- **Events:** Verify in **Events > Explorer** that test events appear with configured tags

## Guidelines

- **Simplicity:** Each script should be the smallest thing that demonstrates the pattern — one curl command per script.
- **Atomic steps:** One change, one test, one commit.
- **Beginner-friendly:** Someone new to Datadog APIs should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This is a public repo. No API keys, no secrets, no credentials in code. Use `.env` files (gitignored).
- **Git hygiene:** `.gitignore` up to date.
- **My setup:** MacBook M4, Claude Code terminal.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.


## Datadog Credentials

Before sending any telemetry to Datadog, confirm these with the user:

- **Datadog Site (DD_SITE):** Ask which Datadog site the prospect uses. Do NOT assume `datadoghq.com`. Options: `datadoghq.com` (US1), `us3.datadoghq.com` (US3), `us5.datadoghq.com` (US5), `datadoghq.eu` (EU1), `ap1.datadoghq.com` (AP1), `ap2.datadoghq.com` (AP2), `ddog-gov.com` (US1-FED). Reference: https://docs.datadoghq.com/getting_started/site/
- **API Key (DD_API_KEY):** Required for all telemetry submission (metrics, traces, logs). Ask if not already provided. Store in `.env` file, never hardcode.
- **Application Key (DD_APP_KEY):** Required only if connecting to Datadog MCP server or using the Datadog API for read operations (e.g., querying metrics, listing monitors). Not needed for basic telemetry submission.

## Tools & References

### Datadog Documentation

- [Logs HTTP API](https://docs.datadoghq.com/api/latest/logs/)
- [Events API](https://docs.datadoghq.com/api/latest/events/)
- [Tracing API](https://docs.datadoghq.com/api/latest/tracing/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate telemetry is received
