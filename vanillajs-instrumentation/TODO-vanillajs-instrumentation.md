## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `vanillajs-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Vanilla JS application, create a `setup-{app}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to UI-driven entry points — DOM event listeners (`addEventListener` for click, submit, input), view transitions via the History API or hash-based routing, and page load events — as the primary user-initiated triggers. Depending on the PoC, also consider: URL query parameters for deep-linking to specific application states. Do not implement HTTP server endpoints in a Vanilla JS app; it is a client, not a server. If the interaction pattern is not specified in the PoC requirements, ask before assuming.
- When the app calls a backend or mock API, expect and handle a standardised JSON response: `{ "status": "ok" | "error", "message": "...", "data": {} }` using the browser `fetch` API and `response.json()`. If the PoC does not include a real backend, implement a mock using this schema (e.g., a local JSON stub or an in-memory function). Do NOT apply this schema to WebSocket messages — use the appropriate message format for that protocol instead. Simulate realistic backend error scenarios by returning a mix of success and error statuses from the mock.
- Include at least one outbound API call appropriate to the PoC — via the browser `fetch` API to a real or mock REST backend, or a WebSocket client for real-time data. If the backend service or protocol is not specified in the PoC requirements, ask before assuming.
- Consistent use of `console.error` and `window.addEventListener('unhandledrejection', ...)` throughout the application so unhandled exceptions and promise rejections are surfaced and automatically captured by Datadog RUM

**Example patterns built so far:**

- **Meter Reading App** — 3-page flow: Landing → Enter Meter → Submitted. Mobile-responsive for field workers on phones. Utility company color theme (blues/greens). Client-side routing via view transitions.

**Tooling:**

- Node.js 18+ with npm
- Vite with the `vanilla` template as build tool and dev server
- No framework — plain HTML, CSS, and JavaScript (ES modules)

**Naming convention:** `setup-{app}` (e.g., `setup-meter-reading`, `setup-form-flow`). Use a short descriptive name matching the PoC's domain.

**Reminder:** Always check if a Vanilla JS application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog RUM SDK

**Goal:** For each setup skill, create a matching `{app}-datadog-rum` skill that instruments the running application with Datadog RUM — producing sessions, views, actions, resources, and errors.

**What an instrumentation produces:**

- Install `@datadog/browser-rum` SDK
- Import and initialize `datadogRum` in `main.js`
- Configure application ID, client token, service name, and environment
- Verify RUM events appear in the Datadog dashboard

**Naming convention:** `{app}-datadog-rum` (e.g., `meter-reading-datadog-rum`).

**Prerequisite:** The corresponding `setup-{app}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if Datadog RUM is already configured in the environment before instrumenting. If the `skills/` folder already has a relevant RUM skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. A few views with interactions and mock API responses is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Node.js version, Vite version, npm package versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `node_modules/`, `dist/`, logs, and other build artifacts. Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

---



## Datadog Credentials

Before sending any telemetry to Datadog, confirm these with the user:

- **Datadog Site (DD_SITE):** Ask which Datadog site the prospect uses. Do NOT assume `datadoghq.com`. Options: `datadoghq.com` (US1), `us3.datadoghq.com` (US3), `us5.datadoghq.com` (US5), `datadoghq.eu` (EU1), `ap1.datadoghq.com` (AP1), `ap2.datadoghq.com` (AP2), `ddog-gov.com` (US1-FED). Reference: https://docs.datadoghq.com/getting_started/site/
- **API Key (DD_API_KEY):** Required for all telemetry submission (metrics, traces, logs). Ask if not already provided. Store in `.env` file, never hardcode.
- **Application Key (DD_APP_KEY):** Required only if connecting to Datadog MCP server or using the Datadog API for read operations (e.g., querying metrics, listing monitors). Not needed for basic telemetry submission.

## Resource Naming Convention

All resources created in this plugin use the **"jek-"** prefix for easy identification in shared environments.

| Resource Type | Convention | Examples |
|---|---|---|
| HTTP endpoints | `jek-endpoint-{method}` | `jek-endpoint-get`, `jek-endpoint-post`, `jek-endpoint-put` |
| Message queues | `jek-queue` | `jek-queue`, `jek-queue-orders` |
| Database name | `jek-database` | `jek-database`, `jek-database-master`, `jek-database-slave` |
| Database tables | `jek-table` | `jek-table`, `jek-table-users` |
| Infra resources | `jek-{resource}` | `jek-vpc`, `jek-eks-cluster`, `jek-ec2-master` |
| Services (DD_SERVICE) | `jek-{app-name}` | `jek-springboot-app`, `jek-fastapi-gateway` |
| Cloud tags | `owner="jek"`, `env="test"` | — |
| gRPC services | `jek-grpc-{service}` | `jek-grpc-orders`, `jek-grpc-payments` |
| WebSocket endpoints | `jek-ws-{purpose}` | `jek-ws-chat`, `jek-ws-notifications` |
| GraphQL endpoints | `jek-graphql` | `jek-graphql` (single endpoint by convention) |
| Event streams | `jek-stream-{name}` | `jek-stream-orders`, `jek-stream-events` |
| Other protocols | `jek-{protocol}-{name}` | `jek-rpc-auth`, `jek-mqtt-sensor` |

## Tools & References

### MCP Libraries (Context7)

- `/websites/vite_dev` — Vite build tool documentation

### Datadog MCP Libraries (Context7)

- `/datadog/browser-sdk` — Datadog Browser SDK for RUM instrumentation

### Datadog Documentation

- [RUM Browser Monitoring](https://docs.datadoghq.com/real_user_monitoring/browser/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate RUM sessions are received
