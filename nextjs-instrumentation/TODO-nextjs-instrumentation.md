## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `nextjs-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Next.js application, create a `setup-{app}` skill that builds and runs the application — independent of any Datadog instrumentation.

**What the application produces:**

- Default to page navigation (App Router `<Link>`, `useRouter`) and user interactions in Client Components (onClick, onSubmit) as the primary user-initiated entry points. Depending on the PoC, also consider: URL query parameters and dynamic route segments for deep-linking, API routes (`/api/*`) as lightweight server-side HTTP endpoints callable by the frontend or upstream services, or Server Components that fetch data directly from upstream backend services at render time. Do not add a server-side API layer unless the PoC explicitly requires it — prefer fetching in Server Components or Client Components where sufficient. If the entry point type is not specified in the PoC requirements, ask before assuming.
- For any HTTP data fetching — whether client-side (via `fetch`/`axios` in Client Components) or server-side (via `fetch` in Server Components, or API routes calling upstream services) — expect and handle a standardised JSON response: `{ "status": "ok" | "error", "message": "...", "data": {} }`. If the PoC does not include a real backend, implement a mock using this schema. Do NOT apply this schema to WebSocket or GraphQL responses — use the appropriate format for that protocol instead. For API route responses, always return this schema using `NextResponse.json(...)`.
- Include at least one outbound data fetch appropriate to the PoC — either server-side in a Server Component (`fetch` during SSR/RSC render), from an API route to an upstream service, or client-side from a Client Component. If the backend service or protocol is not specified in the PoC requirements, ask before assuming.
- Consistent use of `console.error` in Client Components and structured error responses (`NextResponse.json({ status: 'error', ... }, { status: 5xx })`) in API routes so errors are surfaced and captured by Datadog RUM

**Example patterns built so far:**

- **PlanHoliday App** — Multi-page holiday planning application. Next.js 15.4, TypeScript, App Router. Pages for browsing and planning holiday destinations.

**Tooling:**

- Node.js 18+ with npm
- Next.js 15.4 with App Router and TypeScript
- `next dev` for local development

**Naming convention:** `setup-{app}` (e.g., `setup-planholiday`, `setup-dashboard`). Use a short descriptive name matching the PoC's domain.

**Reminder:** Always check if a Next.js application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog RUM

**Goal:** For each setup skill, create a matching `{app}-datadog-rum` skill that instruments the running application with Datadog RUM — producing sessions, views, actions, resources, and errors.

**What an instrumentation produces:**

- Install `@datadog/browser-rum` SDK
- Create a `DatadogInit` Client Component using the `'use client'` directive (required for App Router — Server Components cannot run browser-side SDK code)
- Initialize `datadogRum.init()` inside a `useEffect` hook in the client component
- Include the `DatadogInit` component in the root layout (`app/layout.tsx`)
- Configure application ID, client token, service name, and environment
- Verify RUM events appear in the Datadog dashboard

**Naming convention:** `{app}-datadog-rum` (e.g., `planholiday-datadog-rum`).

**Prerequisite:** The corresponding `setup-{app}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if Datadog RUM is already configured in the environment before instrumenting. If the `skills/` folder already has a relevant RUM skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. A few pages with navigation and data fetching is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **App Router:** Always use the App Router (not Pages Router). Use Server Components by default; add `'use client'` only when browser APIs, hooks, or user interactivity are needed.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Node.js version, Next.js version, npm package versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `node_modules/`, `.next/`, logs, and other build artifacts. Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

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

- `/vercel/next.js` — Next.js framework documentation and APIs

### Datadog MCP Libraries (Context7)

- `/datadog/browser-sdk` — Datadog Browser SDK for RUM instrumentation

### Datadog Documentation

- [RUM Browser Monitoring](https://docs.datadoghq.com/real_user_monitoring/browser/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate RUM sessions are received
