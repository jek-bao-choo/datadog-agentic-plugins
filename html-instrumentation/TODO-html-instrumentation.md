## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `html-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Static HTML + Nginx

- Create static HTML pages (index.html, CSS, static assets)
- Create an Nginx configuration file for serving static content
- Create a Dockerfile based on the official `nginx` image
- Build and run the Docker container
- Verify the static site is accessible at `http://localhost:8080`

## Phase 2: Datadog RUM Instrumentation

**Default approach: CDN script tag** (simpler, works everywhere)

Add the Datadog RUM CDN script to the `<head>` of every HTML file:

```html
<script src="https://www.datadoghq-browser-agent.com/us1/v5/datadog-rum.js" type="text/javascript"></script>
<script>
  window.DD_RUM && window.DD_RUM.init({
    clientToken: '<DD_CLIENT_TOKEN>',
    applicationId: '<DD_APPLICATION_ID>',
    site: 'datadoghq.com',
    service: 'html-webapp',
    env: 'sandbox',
    sessionSampleRate: 100,
    sessionReplaySampleRate: 100,
    trackUserInteractions: true,
    trackResources: true,
    trackLongTasks: true,
  });
</script>
```

**Advanced option: Nginx auto-injection module** — automatically injects the RUM script into all HTML responses without modifying source files. Use when you cannot edit the HTML source.

**Validation:**
- Open the HTML page in a browser, click around, then check **RUM > Sessions** in the Datadog UI
- Verify page views, user interactions, and resource timing appear
- Check browser console for any CSP errors (add `https://www.datadoghq-browser-agent.com` to `script-src` if needed)

## Guidelines

- Keep it simple. The static site should be the smallest thing that demonstrates the RUM pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to frontend observability should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files. Use placeholders like `<DD_CLIENT_TOKEN>`.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.



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

## Tools

- `/datadog/browser-sdk` - Datadog Browser SDK for RUM instrumentation
