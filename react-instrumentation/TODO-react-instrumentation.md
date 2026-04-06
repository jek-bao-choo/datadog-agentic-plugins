## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `react-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each React application, create a `setup-{app}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to UI-driven entry points — page navigation via React Router, button clicks (onClick handlers), and form submissions (onSubmit handlers) — as the primary user-initiated triggers. Depending on the PoC, also consider: URL query parameters for deep-linking to specific application states, or browser push notifications (Web Push API) for notification-driven flows. Do not implement HTTP server endpoints in a React SPA; it is a client, not a server. If the interaction pattern is not specified in the PoC requirements, ask before assuming.
- When the app calls a backend or mock API, expect and handle a standardised JSON response: `{ "status": "ok" | "error", "message": "...", "data": {} }` using `fetch` or `axios`. If the PoC does not include a real backend, implement a mock API service using this schema. Do NOT apply this schema to WebSocket or GraphQL responses — use the appropriate format for that protocol instead. Simulate realistic backend error scenarios by returning a mix of success and error statuses from the mock.
- Include at least one outbound API call appropriate to the PoC — via `fetch` or `axios` to a real or mock REST backend, a WebSocket client for real-time data, or a GraphQL client. If the backend service or protocol is not specified in the PoC requirements, ask before assuming.
- Consistent use of `console.error` and React error boundaries throughout the application so unhandled exceptions are surfaced and automatically captured by Datadog RUM

**Example patterns built so far:**

- **Sendmoney App** — Mobile-responsive payment flow with mock API integration. React 19.1, Vite 7.1, component-based architecture. Components: SendMoneyForm, PayeesList, AddPayeeModal, ResultPage, ScamAlertModal. Mock API service for transaction simulation. Modern CSS with mobile-responsive design.

**Tooling:**

- Node.js 18+ with npm
- Vite 7.1 as build tool and dev server
- ESLint for code quality
- All code is JSX (React), not TypeScript

**Naming convention:** `setup-{app}` (e.g., `setup-sendmoney`, `setup-dashboard`). Use a short descriptive name matching the PoC's domain.

**Reminder:** Always check if a React application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{app}-datadog-rum` skill that instruments the running application with Datadog RUM — producing sessions, views, actions, resources, and errors.

**What an instrumentation produces:**

- Install `@datadog/browser-rum` and configure RUM initialization
- Configure RUM with these settings:
  - `sessionSampleRate: 100` (capture everything during development)
  - `sessionReplaySampleRate: 100`
  - `defaultPrivacyLevel: 'mask-user-input'`
- Set user information via `datadogRum.setUser()` for session identification
- Guard against duplicate initialization during Vite HMR
- Verify RUM sessions appear in Datadog dashboard

### Feature Flags (6-step OpenFeature process):

1. Install packages: `@datadog/openfeature-browser`, `@openfeature/web-sdk`, `@openfeature/core`
2. Create `src/datadog-feature-flags.js` with DatadogProvider configuration
3. Create `src/hooks/useFeatureFlag.js` custom React hook
4. Initialize Feature Flags before app render in `src/main.jsx` (async IIFE)
5. Use `useFeatureFlag` hook in components for conditional rendering
6. Ensure `targetingKey` matches `datadogRum.setUser({ id })` for proper analytics linking

**Naming convention:** `{app}-datadog-rum` (e.g., `sendmoney-datadog-rum`).

**Prerequisite:** The corresponding `setup-{app}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if Datadog RUM is already configured in the environment before instrumenting. If the `skills/` folder already has a relevant RUM skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. A few screens with interactions and mock API responses is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Beginner-friendly:** Someone new to React development should be able to follow along.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (React version, Vite version, npm package versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `node_modules/`, `dist/`, logs, and other build artifacts. Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

---

## Tools & References

### MCP Libraries (Context7)

- `/websites/vite_dev` — Vite documentation
- `/facebook/react` — React documentation

### Datadog MCP Libraries (Context7)

- `/datadog/browser-sdk` — Datadog Browser SDK source

### Datadog Documentation

- [RUM Browser Monitoring](https://docs.datadoghq.com/real_user_monitoring/browser/)
- [Feature Flags tracking](https://docs.datadoghq.com/real_user_monitoring/feature_flag_tracking/)
- [OpenFeature with Datadog](https://docs.datadoghq.com/real_user_monitoring/guide/setup-feature-flag-data-collection/?tab=openfeature)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate RUM sessions are received

### External References

- OpenFeature: https://openfeature.dev
