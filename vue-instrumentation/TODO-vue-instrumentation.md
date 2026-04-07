## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `vue-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Vue application, create a `setup-{app}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to UI-driven entry points — page navigation via Vue Router, button clicks (`@click` handlers), and form submissions (`@submit` handlers) — as the primary user-initiated triggers. Depending on the PoC, also consider: URL query parameters for deep-linking to specific application states, or Pinia reactive state changes triggered by external events. Do not implement HTTP server endpoints in a Vue SPA; it is a client, not a server. If the interaction pattern is not specified in the PoC requirements, ask before assuming.
- When the app calls a backend or mock API (typically via composables such as `useStockData`, `useTradingAPI`, etc.), expect and handle a standardised JSON response: `{ "status": "ok" | "error", "message": "...", "data": {} }` using `fetch` or `axios`. If the PoC does not include a real backend, implement a mock API using this schema. Do NOT apply this schema to WebSocket or GraphQL responses — use the appropriate format for that protocol instead. Simulate realistic backend error scenarios by returning a mix of success and error statuses from the mock.
- Include at least one outbound API call appropriate to the PoC — via `fetch` or `axios` inside a composable to a real or mock REST backend, a WebSocket client for real-time data, or a GraphQL client. If the backend service or protocol is not specified in the PoC requirements, ask before assuming.
- Consistent use of `console.error` and Vue's `app.config.errorHandler` global option throughout the application so unhandled exceptions are surfaced and automatically captured by Datadog RUM

**Example patterns built so far:**

- **Tradestocks App** — Mobile-responsive stock trading flow with mock API integration. Vue 3.5, Vite 7.1, Composition API. Components: TradingForm, StockDropdown, QuantityInput, BuyButton, BackButton, ResultPage. Composables: useStockData, useTradingAPI. Modern CSS with mobile-responsive design.

**Tooling:**

- Node.js 18+ with npm
- Vite 7.1 as build tool and dev server
- All code is Vue SFC (.vue) with Composition API

**Naming convention:** `setup-{app}` (e.g., `setup-tradestocks`, `setup-dashboard`). Use a short descriptive name matching the PoC's domain.

**Reminder:** Always check if a Vue application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{app}-datadog-rum` skill that instruments the running application with Datadog RUM — producing sessions, views, actions, resources, and errors.

**What an instrumentation produces:**

- Install `@datadog/browser-rum` and configure RUM initialization in `src/main.js`
- Configure RUM with these settings:
  - `sessionSampleRate: 100` (capture everything during development)
  - `sessionReplaySampleRate: 100`
  - `defaultPrivacyLevel: 'mask-user-input'`
- Set user information via `datadogRum.setUser()` for session identification
- Initialize RUM before `createApp(App).mount('#app')`
- Verify RUM sessions appear in Datadog dashboard

**Naming convention:** `{app}-datadog-rum` (e.g., `tradestocks-datadog-rum`).

**Prerequisite:** The corresponding `setup-{app}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if Datadog RUM is already configured in the environment before instrumenting. If the `skills/` folder already has a relevant RUM skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. A few screens with interactions and mock API responses is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Beginner-friendly:** Someone new to Vue development should be able to follow along.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Vue version, Vite version, npm package versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `node_modules/`, `dist/`, logs, and other build artifacts. Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

---


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

- `/websites/vite_dev` — Vite documentation
- `/websites/vuejs_guide` — Vue.js guide
- `/vuejs/vue-router` — Vue Router documentation

### Datadog MCP Libraries (Context7)

- `/datadog/browser-sdk` — Datadog Browser SDK source

### Datadog Documentation

- [RUM Browser Monitoring](https://docs.datadoghq.com/real_user_monitoring/browser/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate RUM sessions are received
